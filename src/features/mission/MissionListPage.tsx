/**
 * MissionListPage — pixel-faithful rebuild of Figma frame 10:5406
 * ("Missions 1", 1920 × 1067).
 *
 * Per docx mission rules:
 *   - Only TODAY's missions are openable; past missions are read-only,
 *     future missions are locked.
 *   - When no mission is available for today → show "Explore Topics" CTA
 *     that navigates to /subjects.
 *
 * Layout:
 *   - LEFT card (500 × 602): Mission Progress for the selected day
 *       Illustration + "Mission Progress" + Date
 *       Progress bar (% of today's missions done)
 *       Mission preview card OR "No Mission Available" with Explore Topics
 *   - RIGHT card (1116 × 866): month-grid calendar
 *       Header "MAY 2026" with prev/next month buttons
 *       Weekday labels: Sun mon tue wed thu fri sat
 *       Date cells (127 × 100) with a small cyan dot under days that have
 *       missions; today highlighted with a cyan ring.
 */
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ChevronLeft, ChevronRight, Lock, Play, Sparkles, Target } from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import { useMissions } from './useMissions'
import type { Mission } from '../../types/mission'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

const WEEKDAYS = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
const MONTHS = [
  'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
  'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
]

// ---------------------------------------------------------------------------
export function MissionListPage() {
  const navigate = useNavigate()
  const missionsQ = useMissions()
  const missions = missionsQ.data ?? []

  const today = useMemo(() => new Date(), [])
  const [cursor, setCursor] = useState<{ year: number; month: number }>(() => ({
    year: today.getFullYear(),
    month: today.getMonth(),
  }))
  const [selectedISO, setSelectedISO] = useState<string>(() =>
    toISO(today.getFullYear(), today.getMonth(), today.getDate()),
  )

  const missionsByDate = useMemo(() => {
    const m = new Map<string, Mission[]>()
    for (const x of missions) {
      const arr = m.get(x.missionDate) ?? []
      arr.push(x)
      m.set(x.missionDate, arr)
    }
    return m
  }, [missions])

  const selectedMissions = missionsByDate.get(selectedISO) ?? []
  const todayISO = toISO(today.getFullYear(), today.getMonth(), today.getDate())
  const isPast = selectedISO < todayISO
  const isFuture = selectedISO > todayISO
  const isToday = selectedISO === todayISO
  const completedCount = selectedMissions.filter((m) => m.userCompleted).length
  const progressPct = selectedMissions.length
    ? Math.round((completedCount / selectedMissions.length) * 100)
    : 0

  const selectedLabel = useMemo(() => {
    const [y, m, d] = selectedISO.split('-').map(Number)
    return new Date(y, m - 1, d).toLocaleDateString('en-US', {
      month: 'long', day: 'numeric', year: 'numeric',
    })
  }, [selectedISO])

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Missions" />

      <main
        className="mx-auto w-full"
        style={{
          maxWidth: 1680,
          padding: 'clamp(24px, 3vw, 50px) clamp(16px, 4vw, 120px) clamp(40px, 5vw, 60px)',
        }}
      >
        <div
          className="flex flex-col lg:flex-row"
          style={{ gap: 'clamp(24px, 3vw, 64px)' }}
        >
          <DailyMissionCard
            dateLabel={selectedLabel}
            missions={selectedMissions}
            completedCount={completedCount}
            progressPct={progressPct}
            canOpen={isToday}
            isPast={isPast}
            isFuture={isFuture}
            onStart={(missionId) => navigate(`/missions/${missionId}`)}
            onExplore={() => navigate('/subjects')}
          />

          <CalendarCard
            year={cursor.year}
            month={cursor.month}
            today={today}
            selectedISO={selectedISO}
            missionsByDate={missionsByDate}
            onSelect={setSelectedISO}
            onPrev={() => setCursor(prevMonth(cursor))}
            onNext={() => setCursor(nextMonth(cursor))}
          />
        </div>
      </main>
    </div>
  )
}

// ---------------------------------------------------------------------------
function DailyMissionCard({
  dateLabel, missions, completedCount, progressPct, canOpen,
  isPast, isFuture, onStart, onExplore,
}: {
  dateLabel: string
  missions: Mission[]
  completedCount: number
  progressPct: number
  canOpen: boolean
  isPast: boolean
  isFuture: boolean
  onStart: (id: string) => void
  onExplore: () => void
}) {
  const active = missions[0]

  return (
    <motion.section
      className="bg-white flex flex-col items-center text-center w-full lg:max-w-[500px] lg:flex-shrink-0"
      style={{
        borderRadius: 34, padding: 24, gap: 24,
        boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
      }}
      initial={{ opacity: 0, x: -12 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
    >
      <div
        className="grid place-items-center relative overflow-hidden"
        style={{ width: 200, height: 200, marginTop: 12 }}
      >
        <motion.img
          src="/images/figma/mission-character.png"
          alt=""
          aria-hidden="true"
          draggable={false}
          className="select-none"
          style={{
            maxHeight: 200, width: 'auto', height: 'auto',
            filter: 'drop-shadow(0 12px 20px rgba(0,22,122,0.18))',
          }}
          animate={{ y: [0, -6, 0] }}
          transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
        />
      </div>

      <div className="flex flex-col items-center">
        <h2
          className="font-body"
          style={{ fontSize: 26, fontWeight: 700, color: NAVY, lineHeight: '36px', margin: 0 }}
        >
          Mission Progress
        </h2>
        <span
          className="font-body"
          style={{ fontSize: 16, fontWeight: 600, color: TXT_MID, lineHeight: '22px' }}
        >
          {dateLabel}
        </span>
      </div>

      <div className="flex flex-col w-full" style={{ gap: 6 }}>
        <div className="flex items-center" style={{ gap: 10 }}>
          <div
            className="flex-1"
            style={{ height: 8, borderRadius: 14, background: '#F1F1F1', overflow: 'hidden' }}
          >
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${progressPct}%` }}
              transition={{ duration: 0.9, ease: 'easeOut' }}
              style={{ height: '100%', borderRadius: 14, background: CYAN }}
            />
          </div>
          <span
            className="font-body tabular-nums"
            style={{ fontSize: 26, fontWeight: 700, color: TXT_DARK, lineHeight: '36px' }}
          >
            {progressPct}%
          </span>
        </div>
        <div className="flex items-center justify-between">
          <span
            className="font-body"
            style={{ fontSize: 16, fontWeight: 600, color: TXT_MUTED, lineHeight: '22px' }}
          >
            {completedCount} of {missions.length} missions done
          </span>
          <span
            className="font-body"
            style={{
              fontSize: 16, fontWeight: 600, color: TXT_MUTED, lineHeight: '22px',
              letterSpacing: '0.04em', textTransform: 'uppercase',
            }}
          >
            {missions.length > 0 && completedCount === missions.length ? 'Completed' : '—'}
          </span>
        </div>
      </div>

      {active ? (
        <div
          className="flex flex-col w-full"
          style={{
            border: `1px solid ${CYAN}`, borderRadius: 34, padding: '20px 24px', gap: 14,
          }}
        >
          <div className="flex flex-col items-center" style={{ gap: 10 }}>
            <span
              className="font-body"
              style={{ fontSize: 18, fontWeight: 700, color: NAVY, lineHeight: '25px' }}
            >
              {active.subject.name ?? 'Mission'}
            </span>
            <span
              className="font-body text-center"
              style={{ fontSize: 20, fontWeight: 700, color: TXT_DARK, lineHeight: '28px' }}
            >
              {active.title}
            </span>
            {active.description && (
              <p
                className="font-body text-center line-clamp-2"
                style={{ fontSize: 14, fontWeight: 400, color: TXT_MUTED, lineHeight: '20px' }}
              >
                {active.description}
              </p>
            )}
          </div>
          <motion.button
            type="button"
            disabled={!canOpen}
            onClick={canOpen ? () => onStart(active.id) : undefined}
            className="grid place-items-center w-full disabled:cursor-not-allowed"
            style={{
              background: canOpen ? NAVY : '#CBD5E1', color: '#fff',
              borderRadius: 42, padding: '16px 24px', height: 57,
              opacity: canOpen ? 1 : 0.7,
            }}
            whileTap={canOpen ? { scale: 0.97 } : undefined}
            whileHover={canOpen ? { y: -2 } : undefined}
          >
            <span className="flex items-center" style={{ gap: 14 }}>
              {canOpen
                ? <Play className="w-5 h-5" strokeWidth={2.5} fill="#fff" />
                : <Lock className="w-5 h-5" strokeWidth={2.5} />}
              <span style={{ fontSize: 18, fontWeight: 700, lineHeight: '25px' }}>
                {canOpen ? 'Start Mission' : isPast ? 'Past mission' : 'Locked'}
              </span>
            </span>
          </motion.button>
        </div>
      ) : (
        <NoMissionAvailable onExplore={onExplore} isFuture={isFuture} />
      )}
    </motion.section>
  )
}

function NoMissionAvailable({
  onExplore, isFuture,
}: {
  onExplore: () => void; isFuture: boolean
}) {
  return (
    <div
      className="flex flex-col w-full items-center"
      style={{
        border: `1px solid ${CYAN}`, borderRadius: 34, padding: '20px 24px', gap: 14,
      }}
    >
      <div
        className="grid place-items-center"
        style={{
          width: 44, height: 44, borderRadius: 14,
          background: '#fff', border: '1px solid #E7E7E7',
        }}
      >
        <Lock className="w-5 h-5" style={{ color: TXT_MID }} strokeWidth={2.5} />
      </div>
      <div className="flex flex-col items-center text-center" style={{ gap: 6 }}>
        <span
          className="font-body"
          style={{ fontSize: 20, fontWeight: 700, color: TXT_DARK, lineHeight: '28px' }}
        >
          No Mission Available
        </span>
        <span
          className="font-body"
          style={{ fontSize: 16, fontWeight: 600, color: TXT_MUTED, lineHeight: '22px' }}
        >
          {isFuture
            ? 'Missions for this date have not been released yet.'
            : 'Complete more topics to unlock missions on this day.'}
        </span>
      </div>
      <motion.button
        type="button"
        onClick={onExplore}
        className="grid place-items-center w-full"
        style={{
          // Cyan → navy gradient per Figma, with a matching glow.
          background: `linear-gradient(90deg, ${CYAN} 0%, ${NAVY} 100%)`,
          color: '#fff', borderRadius: 42,
          padding: '16px 24px', height: 57,
          boxShadow: '0 10px 22px rgba(0,22,122,0.25)',
        }}
        whileTap={{ scale: 0.97 }}
        whileHover={{ y: -2 }}
      >
        <span className="flex items-center" style={{ gap: 14 }}>
          <Sparkles className="w-5 h-5" strokeWidth={2.5} />
          <span style={{ fontSize: 18, fontWeight: 700, lineHeight: '25px' }}>
            Explore Topics
          </span>
        </span>
      </motion.button>
    </div>
  )
}

// ---------------------------------------------------------------------------
function CalendarCard({
  year, month, today, selectedISO, missionsByDate, onSelect, onPrev, onNext,
}: {
  year: number
  month: number
  today: Date
  selectedISO: string
  missionsByDate: Map<string, Mission[]>
  onSelect: (iso: string) => void
  onPrev: () => void
  onNext: () => void
}) {
  const cells = useMemo(() => buildMonthGrid(year, month), [year, month])
  const todayISO = toISO(today.getFullYear(), today.getMonth(), today.getDate())

  return (
    <motion.section
      className="bg-white flex flex-col"
      style={{
        flex: 1, borderRadius: 34, padding: '34px 84px', gap: 44,
        minHeight: 866,
        boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
      }}
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
    >
      <div className="flex flex-col" style={{ gap: 44 }}>
        <div className="flex items-center self-center" style={{ gap: 24 }}>
          <NavBtn icon={ChevronLeft} onClick={onPrev} />
          <div
            className="grid place-items-center"
            style={{
              background: NAVY, border: `1px solid ${CYAN}`, color: '#fff',
              borderRadius: 50, padding: '12px 26px', height: 58, minWidth: 300,
              fontFamily: 'var(--font-body)', fontSize: 24, fontWeight: 700, lineHeight: '33px',
              letterSpacing: '0.06em',
            }}
          >
            {MONTHS[month]} {year}
          </div>
          <NavBtn icon={ChevronRight} onClick={onNext} />
        </div>

        <div className="grid" style={{ gridTemplateColumns: 'repeat(7, 1fr)', gap: 10 }}>
          {WEEKDAYS.map((d) => (
            <div
              key={d}
              className="font-body text-center"
              style={{ fontSize: 16, fontWeight: 600, color: TXT_MID, lineHeight: '22px' }}
            >
              {d}
            </div>
          ))}
        </div>
      </div>

      <div className="grid" style={{ gridTemplateColumns: 'repeat(7, 1fr)', gap: 10 }}>
        {cells.map((cell, i) => {
          const iso = toISO(cell.year, cell.month, cell.day)
          const isToday = iso === todayISO
          const isSelected = iso === selectedISO
          const hasMissions = missionsByDate.has(iso)
          const inMonth = cell.month === month
          return (
            <motion.button
              key={`${iso}-${i}`}
              type="button"
              onClick={() => onSelect(iso)}
              className="relative flex flex-col items-center justify-center"
              style={{
                height: 100, borderRadius: 24,
                // Solid navy when this cell is selected; outlined cyan ring
                // when it's today but not selected; faint surface otherwise.
                background: isSelected
                  ? NAVY
                  : isToday
                    ? '#fff'
                    : '#F8FAFC',
                border: isSelected
                  ? `2px solid ${NAVY}`
                  : isToday
                    ? `2px solid ${CYAN}`
                    : '1px solid transparent',
                opacity: inMonth ? 1 : 0.35,
                cursor: 'pointer',
                boxShadow: isSelected ? '0 8px 18px rgba(0,22,122,0.25)' : 'none',
              }}
              whileTap={{ scale: 0.96 }}
              whileHover={inMonth ? { y: -2 } : undefined}
            >
              {/* Mission indicator — cyan target icon top-right when this
                  day has missions. Replaces the dot per Figma. */}
              {hasMissions && (
                <Target
                  className="absolute"
                  style={{
                    top: 8, right: 8, width: 18, height: 18,
                    color: isSelected ? '#fff' : CYAN,
                  }}
                  strokeWidth={2.4}
                />
              )}
              <span
                style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: 24, fontWeight: 600,
                  color: isSelected ? '#fff' : isToday ? NAVY : TXT_DARK,
                  lineHeight: '33px',
                }}
              >
                {cell.day}
              </span>
            </motion.button>
          )
        })}
      </div>
    </motion.section>
  )
}

function NavBtn({
  icon: Icon, onClick,
}: {
  icon: typeof ChevronLeft; onClick: () => void
}) {
  return (
    <motion.button
      type="button"
      onClick={onClick}
      className="grid place-items-center bg-white"
      style={{
        width: 58, height: 58, borderRadius: 50,
        border: '1px solid #EAEAEA',
      }}
      whileHover={{ y: -2 }}
      whileTap={{ scale: 0.94 }}
    >
      <Icon className="w-6 h-6" style={{ color: TXT_MID }} strokeWidth={2.5} />
    </motion.button>
  )
}

// ---------------------------------------------------------------------------
function toISO(y: number, m: number, d: number): string {
  return `${y}-${String(m + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`
}

type Cell = { year: number; month: number; day: number }

function buildMonthGrid(year: number, month: number): Cell[] {
  const first = new Date(year, month, 1)
  const start = new Date(first)
  start.setDate(first.getDate() - first.getDay())
  const cells: Cell[] = []
  for (let i = 0; i < 42; i++) {
    const d = new Date(start)
    d.setDate(start.getDate() + i)
    cells.push({ year: d.getFullYear(), month: d.getMonth(), day: d.getDate() })
  }
  return cells
}

function prevMonth(c: { year: number; month: number }): { year: number; month: number } {
  if (c.month === 0) return { year: c.year - 1, month: 11 }
  return { year: c.year, month: c.month - 1 }
}

function nextMonth(c: { year: number; month: number }): { year: number; month: number } {
  if (c.month === 11) return { year: c.year + 1, month: 0 }
  return { year: c.year, month: c.month + 1 }
}
