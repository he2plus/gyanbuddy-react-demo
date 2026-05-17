/**
 * TestListPage — flat brand palette, no invented gradients. Three sections
 * (Active / Upcoming / Past) with denser cards that fill available width.
 */
import { useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  CheckCircle2,
  Clock,
  PlayCircle,
  XCircle,
  AlertTriangle,
  ChevronRight,
} from 'lucide-react'

import { PageContainer } from '../../components/PageContainer'
import { useMyTests } from './useTests'
import type { Test, TestStatusLiteral } from '../../types/test'

const BRAND_PRIMARY = '#365DEA'
const BRAND_BORDER = '#E0E0E0'

export function TestListPage() {
  const navigate = useNavigate()
  const testsQ = useMyTests()

  const grouped = useMemo(() => {
    const all = testsQ.data ?? []
    return {
      active: all.filter((t) => t.status === 'active'),
      upcoming: all.filter((t) => t.status === 'upcoming'),
      past: all.filter((t) => t.status === 'completed' || t.status === 'skipped'),
    }
  }, [testsQ.data])

  return (
    <div className="min-h-screen bg-white">
      <header className="border-b border-[#F0F0F0] px-6 py-6">
        <PageContainer variant="wide" className="!px-0">
          <h1 className="text-2xl font-extrabold tracking-tight text-[#222] sm:text-3xl">
            Tests
          </h1>
          <p className="mt-1 text-sm text-[#666]">
            Scheduled assessments from your teacher. Active tests open right
            away; upcoming ones unlock at the start time.
          </p>
        </PageContainer>
      </header>

      <PageContainer variant="wide" className="pb-12 pt-6">
        {testsQ.isLoading && <LoadingState />}
        {testsQ.isError && (
          <ErrorState
            message={
              testsQ.error instanceof Error
                ? testsQ.error.message
                : 'Failed to load tests'
            }
            onRetry={() => testsQ.refetch()}
          />
        )}

        {!testsQ.isLoading && !testsQ.isError && testsQ.data && testsQ.data.length === 0 && (
          <EmptyState />
        )}

        {!testsQ.isLoading && !testsQ.isError && testsQ.data && testsQ.data.length > 0 && (
          <div className="flex flex-col gap-10">
            {grouped.active.length > 0 && (
              <Section
                title="Active now"
                rule="#10B981"
                tests={grouped.active}
                navigate={navigate}
              />
            )}
            {grouped.upcoming.length > 0 && (
              <Section
                title="Upcoming"
                rule="#F39C12"
                tests={grouped.upcoming}
                navigate={navigate}
              />
            )}
            {grouped.past.length > 0 && (
              <Section
                title="Past"
                rule="#9CA3AF"
                tests={grouped.past}
                navigate={navigate}
              />
            )}
          </div>
        )}
      </PageContainer>
    </div>
  )
}

function Section({
  title,
  rule,
  tests,
  navigate,
}: {
  title: string
  rule: string
  tests: Test[]
  navigate: (path: string) => void
}) {
  return (
    <section>
      <div className="mb-4 flex items-center gap-3">
        <div className="h-px flex-1" style={{ background: rule, opacity: 0.4 }} />
        <h2 className="flex items-center gap-2 text-xs font-bold uppercase tracking-widest text-[#666]">
          <span
            className="inline-block h-1.5 w-1.5 rounded-full"
            style={{ background: rule }}
          />
          {title}
          <span className="font-normal text-[#999]">· {tests.length}</span>
        </h2>
        <div className="h-px flex-1" style={{ background: rule, opacity: 0.4 }} />
      </div>
      <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {tests.map((t, i) => (
          <TestCard
            key={t.id}
            test={t}
            delay={i * 0.03}
            onClick={() => navigate(`/tests/${t.id}`)}
          />
        ))}
      </ul>
    </section>
  )
}

function TestCard({
  test,
  delay,
  onClick,
}: {
  test: Test
  delay: number
  onClick: () => void
}) {
  const accent = test.subjectColor || BRAND_PRIMARY
  return (
    <motion.li
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.25, ease: 'easeOut' }}
    >
      <button
        type="button"
        onClick={onClick}
        className="group flex h-full w-full flex-col overflow-hidden rounded-xl border bg-white text-left shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#365DEA]"
        style={{ borderColor: BRAND_BORDER }}
      >
        <div className="h-1 w-full" style={{ background: accent }} />

        <div className="flex flex-1 flex-col p-5">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0 flex-1">
              {test.subjectName && (
                <div className="text-[11px] font-bold uppercase tracking-widest text-[#999]">
                  {test.subjectName}
                </div>
              )}
              <h3 className="mt-1 text-base font-bold text-[#222]">
                {test.title}
              </h3>
              {test.moduleName && (
                <div className="mt-0.5 text-xs text-[#888]">
                  {test.moduleName}
                </div>
              )}
            </div>
            <StatusBadge status={test.status} />
          </div>

          <dl className="mt-5 grid grid-cols-2 gap-3 text-sm">
            <div>
              <dt className="text-[10px] font-semibold uppercase tracking-widest text-[#999]">
                Starts
              </dt>
              <dd className="mt-0.5 font-medium text-[#222]">
                {formatDateTime(test.testDatetime)}
              </dd>
            </div>
            <div>
              <dt className="text-[10px] font-semibold uppercase tracking-widest text-[#999]">
                Duration
              </dt>
              <dd className="mt-0.5 font-medium text-[#222]">
                {test.durationMinutes} min
              </dd>
            </div>
          </dl>

          {test.progress && test.progress.status === 'completed' && (
            <div className="mt-4 rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
              <span className="font-bold">Score {test.progress.score}</span>
              {' · '}
              {test.progress.correctAnswers}/{test.progress.totalQuestions}{' '}
              correct
            </div>
          )}

          <div className="mt-auto flex items-center justify-between pt-4 text-sm text-[#666]">
            <span>
              {test.questionCount}{' '}
              {test.questionCount === 1 ? 'question' : 'questions'}
            </span>
            <span
              className="flex items-center gap-1 text-xs font-semibold opacity-0 transition-opacity group-hover:opacity-100"
              style={{ color: BRAND_PRIMARY }}
            >
              Open <ChevronRight className="h-4 w-4" />
            </span>
          </div>
        </div>
      </button>
    </motion.li>
  )
}

function StatusBadge({ status }: { status: TestStatusLiteral }) {
  switch (status) {
    case 'completed':
      return (
        <span className="inline-flex items-center gap-1 rounded-md border border-emerald-200 bg-emerald-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-emerald-700">
          <CheckCircle2 className="h-3 w-3" /> Done
        </span>
      )
    case 'active':
      return (
        <span className="inline-flex items-center gap-1 rounded-md border border-emerald-300 bg-emerald-500 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-white">
          <PlayCircle className="h-3 w-3" /> Active
        </span>
      )
    case 'skipped':
      return (
        <span className="inline-flex items-center gap-1 rounded-md border border-red-200 bg-red-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-red-700">
          <XCircle className="h-3 w-3" /> Missed
        </span>
      )
    case 'upcoming':
    default:
      return (
        <span className="inline-flex items-center gap-1 rounded-md border border-amber-300 bg-amber-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-amber-700">
          <Clock className="h-3 w-3" /> Upcoming
        </span>
      )
  }
}

function formatDateTime(iso: string): string {
  const d = new Date(iso)
  return d.toLocaleString(undefined, {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

function LoadingState() {
  return (
    <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {Array.from({ length: 4 }).map((_, i) => (
        <li
          key={i}
          className="rounded-xl border bg-white p-5"
          style={{ borderColor: BRAND_BORDER }}
        >
          <div className="h-3 w-16 animate-pulse rounded bg-[#F5F5F5]" />
          <div className="mt-3 h-5 w-2/3 animate-pulse rounded bg-[#F5F5F5]" />
          <div className="mt-4 grid grid-cols-2 gap-3">
            <div className="h-10 animate-pulse rounded bg-[#F5F5F5]" />
            <div className="h-10 animate-pulse rounded bg-[#F5F5F5]" />
          </div>
        </li>
      ))}
    </ul>
  )
}

function ErrorState({
  message,
  onRetry,
}: {
  message: string
  onRetry: () => void
}) {
  return (
    <div className="grid place-items-center px-6 py-12 text-center">
      <AlertTriangle className="h-12 w-12 text-[#999]" />
      <p className="mt-3 text-sm text-[#666]">{message}</p>
      <button
        type="button"
        onClick={onRetry}
        className="mt-4 rounded-md border px-4 py-2 text-sm font-semibold text-[#333] hover:bg-[#F5F5F5]"
        style={{ borderColor: BRAND_BORDER }}
      >
        Retry
      </button>
    </div>
  )
}

function EmptyState() {
  return (
    <div
      className="grid place-items-center rounded-xl border border-dashed px-6 py-16 text-center"
      style={{ borderColor: BRAND_BORDER }}
    >
      <h2 className="text-base font-bold text-[#444]">No tests scheduled</h2>
      <p className="mt-1 text-sm text-[#888]">
        You'll see them here when your teacher adds one.
      </p>
    </div>
  )
}
