/**
 * SubjectListPage — denser card grid that fills available width.
 *
 * Earlier version used a single-row icon + chevron card. Replaced with
 * richer cards that show subject icon, name, module count, and due flag.
 * No invented gradients — flat brand colors only, the subject's own color
 * is used as an accent strip.
 */
import {
  AlertTriangle,
  BookOpen,
  Atom,
  FlaskConical,
  Globe,
  Leaf,
  Layers,
  Dna,
  Castle,
  Scroll,
  type LucideIcon,
} from 'lucide-react'
import { motion } from 'framer-motion'
import { useNavigate } from 'react-router-dom'

import { PageContainer } from '../../components/PageContainer'
import { useSubjects } from './useSubjects'
import type { Subject } from '../../types/subject'

const BRAND_PRIMARY = '#365DEA'
const BRAND_BORDER = '#E0E0E0'

const SUBJECT_ICON: Record<string, LucideIcon> = {
  CHEM: FlaskConical,
  PHY: Atom,
  GEO: Globe,
  BIO: Leaf,
  MATH: Layers,
  GEN: Dna,
  HIS: Castle,
  SAN: Scroll,
}

function fallbackIcon(s: Subject): LucideIcon {
  return SUBJECT_ICON[(s.code || '').toUpperCase()] ?? BookOpen
}

export function SubjectListPage() {
  const { data, isLoading, isError, error, refetch } = useSubjects()
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-white">
      {/* Page header */}
      <header className="border-b border-[#F0F0F0] px-6 py-6">
        <PageContainer variant="wide" className="!px-0">
          <h1 className="text-2xl font-extrabold tracking-tight text-[#222] sm:text-3xl">
            Subjects
          </h1>
          <p className="mt-1 text-sm text-[#666]">
            Pick a subject to see its modules and pick up where you left off.
          </p>
        </PageContainer>
      </header>

      <PageContainer variant="wide" className="pb-12 pt-6">
        {isLoading && <LoadingState />}
        {isError && (
          <ErrorState
            message={
              error instanceof Error
                ? error.message
                : 'Failed to load subjects'
            }
            onRetry={() => refetch()}
          />
        )}

        {!isLoading && !isError && data && data.length === 0 && (
          <div className="grid place-items-center py-20 text-[#666]">
            No subjects available.
          </div>
        )}

        {!isLoading && !isError && data && data.length > 0 && (
          <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5">
            {data.map((s, i) => (
              <SubjectCard
                key={s.id}
                subject={s}
                delay={i * 0.03}
                onClick={() => navigate(`/subjects/${s.id}`)}
              />
            ))}
          </ul>
        )}
      </PageContainer>
    </div>
  )
}

function SubjectCard({
  subject,
  delay,
  onClick,
}: {
  subject: Subject
  delay: number
  onClick: () => void
}) {
  const accent = subject.color || BRAND_PRIMARY
  const Icon = fallbackIcon(subject)

  return (
    <motion.li
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.25, ease: 'easeOut' }}
    >
      <button
        type="button"
        onClick={onClick}
        className="group relative flex h-full w-full flex-col overflow-hidden rounded-xl border bg-white text-left shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#365DEA]"
        style={{ borderColor: BRAND_BORDER }}
      >
        {/* Top accent strip = subject color */}
        <div className="h-1 w-full" style={{ background: accent }} />

        <div className="flex flex-1 flex-col p-5">
          <div className="flex items-start justify-between gap-3">
            <span
              className="grid h-12 w-12 shrink-0 place-items-center rounded-lg"
              style={{ background: `${accent}14`, color: accent }}
            >
              {subject.logo ? (
                <img
                  src={subject.logo}
                  alt=""
                  className="h-7 w-7 object-contain"
                  onError={(e) => {
                    ;(e.currentTarget as HTMLImageElement).style.display = 'none'
                  }}
                />
              ) : (
                <Icon className="h-6 w-6" />
              )}
            </span>
            {subject.hasDueModule && (
              <span className="rounded-md border border-amber-300 bg-amber-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-amber-700">
                Due
              </span>
            )}
          </div>

          <h2 className="mt-4 text-lg font-bold text-[#222]">{subject.name}</h2>
          {subject.code && (
            <p className="mt-0.5 text-[11px] font-semibold uppercase tracking-widest text-[#999]">
              {subject.code}
            </p>
          )}

          <div className="mt-auto flex items-baseline gap-1.5 pt-4 text-sm text-[#666]">
            <span className="text-xl font-bold text-[#222]">
              {subject.moduleCount}
            </span>
            <span>{subject.moduleCount === 1 ? 'module' : 'modules'}</span>
          </div>
        </div>
      </button>
    </motion.li>
  )
}

function LoadingState() {
  return (
    <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {Array.from({ length: 6 }).map((_, i) => (
        <li
          key={i}
          className="rounded-xl border bg-white p-5"
          style={{ borderColor: BRAND_BORDER }}
        >
          <div className="h-12 w-12 animate-pulse rounded-lg bg-[#F5F5F5]" />
          <div className="mt-4 h-5 w-3/4 animate-pulse rounded bg-[#F5F5F5]" />
          <div className="mt-2 h-3 w-1/2 animate-pulse rounded bg-[#F5F5F5]" />
          <div className="mt-6 h-3 w-1/3 animate-pulse rounded bg-[#F5F5F5]" />
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
    <div className="grid place-items-center px-6 py-16 text-center">
      <AlertTriangle className="h-12 w-12 text-[#999]" />
      <h2 className="mt-3 text-base font-bold text-[#444]">
        Couldn't load subjects
      </h2>
      <p className="mt-1 text-sm text-[#888]">{message}</p>
      <button
        type="button"
        onClick={onRetry}
        className="mt-5 rounded-md border px-4 py-2 text-sm font-semibold text-[#333] hover:bg-[#F5F5F5]"
        style={{ borderColor: BRAND_BORDER }}
      >
        Retry
      </button>
    </div>
  )
}
