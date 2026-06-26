/**
 * TestListPage — pixel-faithful rebuild of Figma frame 83:2 ("Tests 1",
 * 1920 × 1080). Includes the empty-state variants from frames 83:1015 and
 * 93:580.
 *
 * Per docx test rules:
 *   - Tabs at top of the list: All / Upcoming / Skipped / Completed
 *     (default = All)
 *   - Replace "View Details" with a "Start" button on each row
 *   - Each row shows: status-coloured stroke, icon, title, subject + time,
 *     status chip, Start button
 *
 * Layout:
 *   - Header section (1499 × 134): "Assigned Tests" + summary + counter chips
 *     (Skipped peach / Upcoming cyan / Completed green)
 *   - Filter tab row (513 × 52)
 *   - Test cards stacked vertically (1499 × 150 each, gap 24)
 */
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  ClipboardList, CheckCircle2, Clock, AlertCircle, FileQuestion, Play,
} from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import { useMyTests } from './useTests'
import type { Test } from '../../types/test'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

type TestTab = 'all' | 'upcoming' | 'skipped' | 'completed'

type TestStatus = 'upcoming' | 'active' | 'skipped' | 'completed' | 'in_progress'

function statusOf(t: Test): TestStatus {
  // Single source of truth: the parsed `test.status` is window-aware
  // (upcoming = before start, active = inside the attempt window, skipped =
  // window passed and never finished, completed = done). Layer the user's
  // in-progress state on top.
  if (t.progress?.status === 'completed') return 'completed'
  if (t.progress?.status === 'in_progress') return 'in_progress'
  return t.status
}

// Which top-level tab / counter chip a test belongs to. Active and in-progress
// tests are still actionable, so they live under "Upcoming", NOT "Skipped".
type TestBucket = 'upcoming' | 'skipped' | 'completed'
function bucketOf(t: Test): TestBucket {
  const s = statusOf(t)
  if (s === 'completed') return 'completed'
  if (s === 'skipped') return 'skipped'
  return 'upcoming'
}

// A test can be started/continued only while it's actionable. Once the window
// has passed (skipped) or it's finished (completed), there's nothing to start.
function canStart(t: Test): boolean {
  const s = statusOf(t)
  return s === 'upcoming' || s === 'active' || s === 'in_progress'
}

const STATUS_TONE: Record<TestStatus, { strokeColor: string; chipBg: string; chipFg: string; label: string }> = {
  skipped:     { strokeColor: '#FF914D', chipBg: '#FFE7D7', chipFg: '#FF3131', label: 'Skipped' },
  upcoming:    { strokeColor: CYAN,      chipBg: '#CFF1FF', chipFg: CYAN,      label: 'Upcoming' },
  active:      { strokeColor: '#00BF63', chipBg: '#C9F1DE', chipFg: '#00BF63', label: 'Active' },
  completed:   { strokeColor: '#00BF63', chipBg: '#C9F1DE', chipFg: '#00BF63', label: 'Completed' },
  in_progress: { strokeColor: NAVY,      chipBg: '#E0E7FF', chipFg: NAVY,      label: 'In Progress' },
}

// ---------------------------------------------------------------------------
export function TestListPage() {
  const navigate = useNavigate()
  const testsQ = useMyTests()
  const tests = testsQ.data ?? []
  const [tab, setTab] = useState<TestTab>('all')

  const counts = useMemo(() => {
    const c = { upcoming: 0, skipped: 0, completed: 0 }
    for (const t of tests) c[bucketOf(t)]++
    return c
  }, [tests])

  const filtered = useMemo(() => {
    if (tab === 'all') return tests
    return tests.filter((t) => bucketOf(t) === tab)
  }, [tests, tab])

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="My Tests" testCount={counts.upcoming + counts.skipped} />

      <main
        className="mx-auto w-full"
        style={{
          maxWidth: 1680,
          padding: 'clamp(24px, 3vw, 50px) clamp(16px, 4vw, 120px) clamp(40px, 5vw, 60px)',
        }}
      >
        {/* Header section */}
        <header className="flex items-center" style={{ gap: 32, marginBottom: 40 }}>
          <div
            className="grid place-items-center shrink-0"
            style={{
              width: 71, height: 71, borderRadius: 28,
              background: '#F0F1F6', border: '1px solid #fff',
            }}
          >
            <ClipboardList className="w-7 h-7" style={{ color: NAVY }} strokeWidth={2.2} />
          </div>
          <div className="flex flex-col" style={{ gap: 4 }}>
            <h1
              className="font-body"
              style={{ fontSize: 24, fontWeight: 700, color: '#000', lineHeight: '33px', margin: 0 }}
            >
              Assigned Tests
            </h1>
            <span
              className="font-body"
              style={{ fontSize: 20, fontWeight: 600, color: TXT_MID, lineHeight: '28px' }}
            >
              {counts.skipped} skipped, {counts.upcoming} upcoming
            </span>
          </div>

          <div className="flex-1" />

          {/* Counter chips */}
          <div className="flex items-center" style={{ gap: 12 }}>
            <CounterChip
              icon={<AlertCircle className="w-6 h-6" style={{ color: '#FF3131' }} strokeWidth={2.5} />}
              label={`Skipped: ${counts.skipped}`}
              bg="#FFE7D7" fg="#FF3131"
            />
            <CounterChip
              icon={<Clock className="w-6 h-6" style={{ color: CYAN }} strokeWidth={2.5} />}
              label={`Upcoming: ${counts.upcoming}`}
              bg="#CFF1FF" fg={CYAN}
            />
            <CounterChip
              icon={<CheckCircle2 className="w-6 h-6" style={{ color: '#00BF63' }} strokeWidth={2.5} />}
              label={`Completed: ${counts.completed}`}
              bg="#C9F1DE" fg="#00BF63"
            />
          </div>
        </header>

        {/* Filter tab row */}
        <FilterTabs active={tab} onChange={setTab} />

        {/* Test cards list */}
        <div className="flex flex-col" style={{ gap: 24, marginTop: 40 }}>
          {testsQ.isLoading && (
            <>
              {Array.from({ length: 3 }).map((_, i) => (
                <div
                  key={i}
                  className="animate-pulse bg-white"
                  style={{ height: 150, borderRadius: 32, border: '1px solid #E7E7E7' }}
                />
              ))}
            </>
          )}
          {!testsQ.isLoading && filtered.length === 0 && (
            <EmptyState tab={tab} />
          )}
          {!testsQ.isLoading && filtered.map((t, i) => (
            <TestCard
              key={t.id}
              test={t}
              delay={i * 0.05}
              onStart={() => navigate(`/tests/${t.id}`)}
            />
          ))}
        </div>
      </main>
    </div>
  )
}

// ---------------------------------------------------------------------------
function CounterChip({
  icon, label, bg, fg,
}: {
  icon: React.ReactNode; label: string; bg: string; fg: string
}) {
  return (
    <div
      className="flex items-center"
      style={{
        height: 52, borderRadius: 50, padding: '12px 24px', gap: 12,
        background: bg,
      }}
    >
      {icon}
      <span
        className="font-body"
        style={{ fontSize: 20, fontWeight: 600, color: fg, lineHeight: '28px' }}
      >
        {label}
      </span>
    </div>
  )
}

const TABS: { id: TestTab; label: string }[] = [
  { id: 'all',       label: 'All' },
  { id: 'upcoming',  label: 'Upcoming' },
  { id: 'skipped',   label: 'Skipped' },
  { id: 'completed', label: 'Completed' },
]

function FilterTabs({
  active, onChange,
}: {
  active: TestTab; onChange: (t: TestTab) => void
}) {
  return (
    <div className="flex" style={{ gap: 12 }}>
      {TABS.map((t, i) => {
        const isActive = t.id === active
        return (
          <motion.button
            key={t.id}
            type="button"
            onClick={() => onChange(t.id)}
            className="grid place-items-center bg-white"
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.04 }}
            whileTap={{ scale: 0.96 }}
            style={{
              height: 52, borderRadius: 50, padding: '12px 26px',
              background: isActive ? NAVY : '#fff',
              border: isActive ? 'none' : '1px solid #BEBEBE',
              color: isActive ? '#fff' : TXT_MID,
              boxShadow: isActive ? '0 4px 12px rgba(0,22,122,0.18)' : 'none',
              fontFamily: 'var(--font-body)',
              fontSize: isActive ? 18 : 20,
              fontWeight: isActive ? 700 : 600,
              lineHeight: '28px',
            }}
          >
            {t.label}
          </motion.button>
        )
      })}
    </div>
  )
}

// ---------------------------------------------------------------------------
function TestCard({
  test, delay, onStart,
}: {
  test: Test; delay: number; onStart: () => void
}) {
  const status = statusOf(test)
  const tone = STATUS_TONE[status]

  const dt = new Date(test.testDatetime)
  const dateLabel = isNaN(dt.getTime())
    ? '—'
    : dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  const timeLabel = isNaN(dt.getTime())
    ? ''
    : dt.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })

  return (
    <motion.section
      className="bg-white flex items-center"
      style={{
        minHeight: 150, borderRadius: 32, padding: '29px 32px', gap: 32,
        border: `1px solid ${tone.strokeColor}`,
      }}
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.35 }}
      whileHover={{ y: -2, boxShadow: '0 10px 24px rgba(0,0,0,0.08)' }}
    >
      {/* Icon */}
      <div
        className="grid place-items-center shrink-0"
        style={{
          width: 71, height: 71, borderRadius: 999,
          background: '#F8FAFC', border: '2px solid #fff',
          boxShadow: '0 4px 12px rgba(0,0,0,0.06)',
        }}
      >
        <FileQuestion className="w-8 h-8" style={{ color: NAVY }} strokeWidth={2} />
      </div>

      {/* Title + meta */}
      <div className="flex flex-col flex-1" style={{ gap: 16 }}>
        <div className="flex items-center" style={{ gap: 16 }}>
          <h3
            className="font-body"
            style={{ fontSize: 24, fontWeight: 700, color: TXT_DARK, lineHeight: '33px', margin: 0 }}
          >
            {test.title}
          </h3>
          {test.subjectName && (
            <span
              className="grid place-items-center"
              style={{
                height: 32, borderRadius: 999, padding: '4px 14px',
                background: `${test.subjectColor ?? CYAN}1A`,
                color: test.subjectColor ?? CYAN,
                fontFamily: 'var(--font-body)', fontSize: 14, fontWeight: 700, lineHeight: '24px',
              }}
            >
              {test.subjectName}
            </span>
          )}
        </div>
        <div className="flex items-center" style={{ gap: 40 }}>
          <span
            className="font-body"
            style={{ fontSize: 16, fontWeight: 400, color: TXT_MID, lineHeight: '22px' }}
          >
            {dateLabel} · {timeLabel}
          </span>
          <span
            className="font-body"
            style={{ fontSize: 16, fontWeight: 400, color: TXT_MID, lineHeight: '22px' }}
          >
            {test.questionCount} questions · {test.durationMinutes} min
          </span>
        </div>
      </div>

      {/* Status chip + Start button */}
      <div className="flex items-center shrink-0" style={{ gap: 12 }}>
        <div
          className="flex items-center"
          style={{
            height: 52, borderRadius: 50, padding: '12px 24px', gap: 12,
            background: tone.chipBg,
          }}
        >
          <span
            className="font-body"
            style={{ fontSize: 20, fontWeight: 600, color: tone.chipFg, lineHeight: '28px' }}
          >
            {tone.label}
          </span>
        </div>
        {canStart(test) && (
          <motion.button
            type="button"
            onClick={onStart}
            className="grid place-items-center"
            style={{
              background: NAVY, color: '#fff', borderRadius: 50,
              padding: '12px 24px', height: 52, gap: 12,
            }}
            whileTap={{ scale: 0.96 }}
            whileHover={{ y: -2 }}
          >
            <span className="flex items-center" style={{ gap: 12 }}>
              <Play className="w-5 h-5" strokeWidth={2.5} fill="#fff" />
              <span style={{ fontSize: 20, fontWeight: 600, lineHeight: '28px' }}>
                Start
              </span>
            </span>
          </motion.button>
        )}
      </div>
    </motion.section>
  )
}

// ---------------------------------------------------------------------------
function EmptyState({ tab }: { tab: TestTab }) {
  const copy: Record<TestTab, { title: string; subtitle: string }> = {
    all: {
      title: 'No tests assigned',
      subtitle: 'Your teacher has not assigned any tests yet. Come back later.',
    },
    upcoming: {
      title: 'No upcoming tests',
      subtitle: 'You are caught up — nothing scheduled at the moment.',
    },
    skipped: {
      title: 'Nothing skipped',
      subtitle: 'You haven’t missed any tests. Keep it up!',
    },
    completed: {
      title: 'No completed tests yet',
      subtitle: 'When you finish a test it will show up here.',
    },
  }
  const c = copy[tab]
  return (
    <div
      className="grid place-items-center bg-white"
      style={{
        minHeight: 280, borderRadius: 32, border: `1px solid #EAEAEA`,
        padding: 30, gap: 16,
      }}
    >
      <div
        className="grid place-items-center"
        style={{
          width: 88, height: 88, borderRadius: 999,
          background: '#F8FAFC', border: '1px solid #EAEAEA',
        }}
      >
        <ClipboardList className="w-9 h-9" style={{ color: TXT_MUTED }} strokeWidth={2} />
      </div>
      <div className="flex flex-col items-center text-center" style={{ gap: 6 }}>
        <span
          className="font-body"
          style={{ fontSize: 22, fontWeight: 700, color: TXT_DARK, lineHeight: '30px' }}
        >
          {c.title}
        </span>
        <span
          className="font-body"
          style={{ fontSize: 16, fontWeight: 400, color: TXT_MUTED, lineHeight: '22px' }}
        >
          {c.subtitle}
        </span>
      </div>
    </div>
  )
}
