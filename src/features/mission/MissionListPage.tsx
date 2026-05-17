/**
 * MissionListPage — mirrors lib/screens/mission/mission_screen.dart (calendar)
 * + lib/screens/mission/mission_subject_screen.dart (list for selected date).
 *
 * The Flutter app splits these into two screens; on web we keep it on one
 * route because the calendar and list comfortably co-exist on desktop. On
 * mobile they stack.
 *
 * Click a mission → MissionDetailPage. Status badge: Completed / Started / Locked.
 */
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ChevronLeft,
  ChevronRight,
  CheckCircle2,
  PlayCircle,
  Clock,
  AlertTriangle,
} from 'lucide-react'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import { Button } from '../../components/Button'
import { useMissions } from './useMissions'
import type { Mission } from '../../types/mission'

const DAYS = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
]

function isoDateOf(d: Date): string {
  return d.toISOString().slice(0, 10)
}

function startOfMonth(year: number, month: number): Date {
  return new Date(year, month, 1)
}

export function MissionListPage() {
  const navigate = useNavigate()
  const today = useMemo(() => new Date(), [])
  const [cursor, setCursor] = useState(() => ({
    year: today.getFullYear(),
    month: today.getMonth(),
  }))
  const [selectedDate, setSelectedDate] = useState<string>(isoDateOf(today))

  const missionsQ = useMissions()
  const missionsByDate = useMemo(() => {
    const map = new Map<string, Mission[]>()
    for (const m of missionsQ.data ?? []) {
      const day = m.missionDate.slice(0, 10)
      const arr = map.get(day) ?? []
      arr.push(m)
      map.set(day, arr)
    }
    return map
  }, [missionsQ.data])

  const todaysMissions = missionsByDate.get(selectedDate) ?? []

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader title="Daily Missions" showBack={false} />

      <PageContainer variant="wide" className="pb-12 pt-2">
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
          {/* Calendar — sticky on desktop */}
          <div className="lg:col-span-5">
            <div className="rounded-2xl border border-[var(--color-input-border)] bg-white p-5 shadow-sm sm:p-6 lg:sticky lg:top-4">
              <CalendarHeader
                year={cursor.year}
                month={cursor.month}
                onPrev={() => {
                  setCursor((c) =>
                    c.month === 0
                      ? { year: c.year - 1, month: 11 }
                      : { year: c.year, month: c.month - 1 },
                  )
                }}
                onNext={() => {
                  setCursor((c) =>
                    c.month === 11
                      ? { year: c.year + 1, month: 0 }
                      : { year: c.year, month: c.month + 1 },
                  )
                }}
              />
              <CalendarGrid
                year={cursor.year}
                month={cursor.month}
                today={today}
                selected={selectedDate}
                missionsByDate={missionsByDate}
                onSelect={(d) => setSelectedDate(d)}
              />
              <Legend />
            </div>
          </div>

          {/* Missions for selected date */}
          <div className="lg:col-span-7">
            <h2 className="text-lg font-bold text-[var(--color-text-primary)]">
              {humanizeDate(selectedDate, today)}
            </h2>
            <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
              {todaysMissions.length > 0
                ? `${todaysMissions.length} ${todaysMissions.length === 1 ? 'mission' : 'missions'} for this day`
                : 'No missions scheduled.'}
            </p>

            <div className="mt-4">
              {missionsQ.isLoading && <LoadingState />}
              {missionsQ.isError && (
                <ErrorState
                  message={
                    missionsQ.error instanceof Error
                      ? missionsQ.error.message
                      : 'Failed to load missions'
                  }
                  onRetry={() => missionsQ.refetch()}
                />
              )}
              {!missionsQ.isLoading && !missionsQ.isError && todaysMissions.length === 0 && (
                <EmptyDayState />
              )}
              {!missionsQ.isLoading && !missionsQ.isError && todaysMissions.length > 0 && (
                <ul className="grid grid-cols-1 gap-3 md:grid-cols-2">
                  <AnimatePresence initial={false} mode="popLayout">
                    {todaysMissions.map((m, i) => (
                      <MissionCard
                        key={m.id}
                        mission={m}
                        delay={i * 0.05}
                        onClick={() => navigate(`/missions/${m.id}`)}
                      />
                    ))}
                  </AnimatePresence>
                </ul>
              )}
            </div>
          </div>
        </div>
      </PageContainer>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

function CalendarHeader({
  year,
  month,
  onPrev,
  onNext,
}: {
  year: number
  month: number
  onPrev: () => void
  onNext: () => void
}) {
  return (
    <div className="mb-3 flex items-center justify-between">
      <h3 className="text-base font-bold text-[var(--color-text-primary)]">
        {MONTHS[month]} {year}
      </h3>
      <div className="flex items-center gap-1">
        <button
          type="button"
          onClick={onPrev}
          aria-label="Previous month"
          className="grid h-9 w-9 place-items-center rounded-full text-[var(--color-text-secondary)] hover:bg-[var(--color-input-fill)]"
        >
          <ChevronLeft className="h-4 w-4" />
        </button>
        <button
          type="button"
          onClick={onNext}
          aria-label="Next month"
          className="grid h-9 w-9 place-items-center rounded-full text-[var(--color-text-secondary)] hover:bg-[var(--color-input-fill)]"
        >
          <ChevronRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  )
}

function CalendarGrid({
  year,
  month,
  today,
  selected,
  missionsByDate,
  onSelect,
}: {
  year: number
  month: number
  today: Date
  selected: string
  missionsByDate: Map<string, Mission[]>
  onSelect: (d: string) => void
}) {
  const first = startOfMonth(year, month)
  const startWeekday = first.getDay() // 0 = Sunday
  const daysInMonth = new Date(year, month + 1, 0).getDate()
  const totalCells = Math.ceil((startWeekday + daysInMonth) / 7) * 7

  const todayIso = isoDateOf(today)

  return (
    <div>
      <div className="grid grid-cols-7 gap-1 text-center text-[10px] font-bold uppercase tracking-widest text-[var(--color-text-light)]">
        {DAYS.map((d) => (
          <div key={d} className="py-1">
            {d}
          </div>
        ))}
      </div>
      <div className="mt-1 grid grid-cols-7 gap-1">
        {Array.from({ length: totalCells }).map((_, idx) => {
          const dayOfMonth = idx - startWeekday + 1
          const inMonth = dayOfMonth >= 1 && dayOfMonth <= daysInMonth
          if (!inMonth) {
            return <div key={idx} className="aspect-square" />
          }
          const date = new Date(year, month, dayOfMonth)
          const iso = isoDateOf(date)
          const isSelected = iso === selected
          const isToday = iso === todayIso
          const missions = missionsByDate.get(iso) ?? []
          const status =
            missions.length === 0
              ? 'none'
              : missions.every((m) => m.userCompleted)
                ? 'done'
                : missions.some((m) => m.userStarted)
                  ? 'started'
                  : 'fresh'
          return (
            <button
              key={idx}
              type="button"
              onClick={() => onSelect(iso)}
              aria-pressed={isSelected}
              className={`relative aspect-square rounded-lg text-sm font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] ${
                isSelected
                  ? 'bg-[var(--color-primary)] text-white shadow-md'
                  : isToday
                    ? 'bg-[color:var(--color-primary)]/10 text-[var(--color-primary)]'
                    : 'text-[var(--color-text-primary)] hover:bg-[var(--color-input-fill)]'
              }`}
            >
              <span>{dayOfMonth}</span>
              {status !== 'none' && (
                <span
                  className={`absolute bottom-1 left-1/2 h-1.5 w-1.5 -translate-x-1/2 rounded-full ${
                    status === 'done'
                      ? 'bg-emerald-500'
                      : status === 'started'
                        ? 'bg-amber-500'
                        : isSelected
                          ? 'bg-white'
                          : 'bg-[var(--color-primary)]'
                  }`}
                  aria-hidden="true"
                />
              )}
            </button>
          )
        })}
      </div>
    </div>
  )
}

function Legend() {
  return (
    <div className="mt-4 flex flex-wrap gap-3 text-xs text-[var(--color-text-secondary)]">
      <Dot color="var(--color-primary)" label="Available" />
      <Dot color="#F59E0B" label="In progress" />
      <Dot color="#10B981" label="Completed" />
    </div>
  )
}
function Dot({ color, label }: { color: string; label: string }) {
  return (
    <span className="inline-flex items-center gap-1.5">
      <span className="h-2 w-2 rounded-full" style={{ background: color }} />
      {label}
    </span>
  )
}

// ---------------------------------------------------------------------------
// Mission card
// ---------------------------------------------------------------------------

function MissionCard({
  mission,
  delay,
  onClick,
}: {
  mission: Mission
  delay: number
  onClick: () => void
}) {
  const accent = mission.subject.color || '#365DEA'
  return (
    <motion.li
      layout
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0 }}
      transition={{ delay, duration: 0.3, ease: 'easeOut' }}
    >
      <button
        type="button"
        onClick={onClick}
        className="group flex h-full w-full flex-col rounded-2xl border border-[var(--color-input-border)] bg-white p-5 text-left shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
      >
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0 flex-1">
            {mission.subject.name && (
              <div
                className="inline-flex items-center rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-widest text-white"
                style={{ background: accent }}
              >
                {mission.subject.name}
              </div>
            )}
            <h3 className="mt-2 text-base font-bold text-[var(--color-text-primary)]">
              {mission.title}
            </h3>
            {mission.description && (
              <p className="mt-1 line-clamp-2 text-sm text-[var(--color-text-secondary)]">
                {mission.description}
              </p>
            )}
          </div>
          <MissionStatusBadge mission={mission} />
        </div>

        <div className="mt-4 flex items-center justify-between text-sm text-[var(--color-text-secondary)]">
          <span>
            {mission.questionCount}{' '}
            {mission.questionCount === 1 ? 'question' : 'questions'}
          </span>
          <span className="text-xs font-semibold text-[var(--color-primary)] opacity-0 transition-opacity group-hover:opacity-100">
            Open →
          </span>
        </div>
      </button>
    </motion.li>
  )
}

function MissionStatusBadge({ mission }: { mission: Mission }) {
  if (mission.userCompleted || mission.status === 'completed') {
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-bold text-emerald-700">
        <CheckCircle2 className="h-3 w-3" /> Done
      </span>
    )
  }
  if (mission.userStarted || mission.status === 'in_progress') {
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 px-2.5 py-1 text-xs font-bold text-amber-700">
        <PlayCircle className="h-3 w-3" /> Started
      </span>
    )
  }
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-[var(--color-input-fill)] px-2.5 py-1 text-xs font-bold text-[var(--color-text-secondary)]">
      <Clock className="h-3 w-3" /> New
    </span>
  )
}

// ---------------------------------------------------------------------------
// States + helpers
// ---------------------------------------------------------------------------

function humanizeDate(iso: string, today: Date): string {
  const d = new Date(iso + 'T00:00:00')
  const t = new Date(today.getFullYear(), today.getMonth(), today.getDate())
  const diff = Math.round((d.getTime() - t.getTime()) / 86_400_000)
  if (diff === 0) return 'Today'
  if (diff === 1) return 'Tomorrow'
  if (diff === -1) return 'Yesterday'
  return d.toLocaleDateString(undefined, {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  })
}

function LoadingState() {
  return (
    <ul className="grid grid-cols-1 gap-3 md:grid-cols-2">
      {Array.from({ length: 2 }).map((_, i) => (
        <li
          key={i}
          className="rounded-2xl border border-[var(--color-input-border)] bg-white p-5"
        >
          <div className="h-4 w-16 animate-pulse rounded-full bg-[var(--color-input-fill)]" />
          <div className="mt-3 h-5 w-2/3 animate-pulse rounded bg-[var(--color-input-fill)]" />
          <div className="mt-2 h-3 w-full animate-pulse rounded bg-[var(--color-input-fill)]" />
        </li>
      ))}
    </ul>
  )
}

function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="grid place-items-center px-6 py-12 text-center">
      <AlertTriangle className="h-12 w-12 text-[var(--color-text-light)]" />
      <p className="mt-3 text-sm text-[var(--color-text-secondary)]">{message}</p>
      <div className="mt-4">
        <Button onClick={onRetry}>Retry</Button>
      </div>
    </div>
  )
}

function EmptyDayState() {
  return (
    <div className="grid place-items-center rounded-2xl border border-dashed border-[var(--color-input-border)] bg-[var(--color-bg)] px-6 py-12 text-center">
      <div className="text-2xl">📭</div>
      <p className="mt-2 text-sm text-[var(--color-text-secondary)]">
        No missions for this day. Pick another date in the calendar.
      </p>
    </div>
  )
}
