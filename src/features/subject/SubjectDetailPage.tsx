/**
 * SubjectDetailPage — denser banner + module grid that fills width.
 *
 * Banner is compact (subject name + code + module count) on a flat
 * brand-color background. No gradients. Module cards have an accent edge,
 * progress bar, status pill, and the most useful next-action affordance.
 */
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import {
  ChevronRight,
  AlertTriangle,
  CheckCircle2,
  PlayCircle,
  Lock,
  Clock,
  ArrowLeft,
} from 'lucide-react'

import { PageContainer } from '../../components/PageContainer'
import { getSubjectById } from '../../api/subjects'
import { useSubjectModules } from '../module/useModuleChapters'
import type { Subject } from '../../types/subject'
import type { Module } from '../../types/module'

const BRAND_PRIMARY = '#365DEA'
const BRAND_BORDER = '#E0E0E0'

export function SubjectDetailPage() {
  const { subjectId = '' } = useParams<{ subjectId: string }>()
  const navigate = useNavigate()

  const subjectQ = useQuery<Subject>({
    queryKey: ['subjects', subjectId, 'detail'],
    queryFn: () => getSubjectById(subjectId),
    enabled: !!subjectId,
    staleTime: 5 * 60_000,
  })
  const modulesQ = useSubjectModules(subjectId)

  const subject = subjectQ.data
  const accent = subject?.color || BRAND_PRIMARY

  return (
    <div className="min-h-screen bg-white">
      {/* Compact top bar */}
      <header className="sticky top-0 z-10 flex h-14 items-center gap-3 border-b border-[#EEE] bg-white/95 px-5 backdrop-blur">
        <button
          type="button"
          onClick={() => navigate('/subjects')}
          aria-label="Back to subjects"
          className="grid h-9 w-9 place-items-center rounded-md text-[#555] hover:bg-[#F5F5F5]"
        >
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div className="min-w-0">
          <div className="truncate text-base font-bold text-[#222]">
            {subject?.name ?? 'Subject'}
          </div>
          {subject?.code && (
            <div className="truncate text-[11px] uppercase tracking-widest text-[#888]">
              {subject.code}
            </div>
          )}
        </div>
      </header>

      <PageContainer variant="wide" className="pb-12 pt-6">
        {/* Banner */}
        {subject && (
          <div
            className="mb-6 flex flex-col gap-4 rounded-xl p-6 text-white sm:flex-row sm:items-center sm:justify-between sm:p-7"
            style={{ background: accent }}
          >
            <div className="min-w-0">
              <div className="text-[11px] font-bold uppercase tracking-widest text-white/80">
                {subject.code}
              </div>
              <h1 className="mt-1 text-2xl font-extrabold tracking-tight sm:text-3xl">
                {subject.name}
              </h1>
              {subject.description && (
                <p className="mt-2 max-w-2xl text-sm text-white/90">
                  {subject.description}
                </p>
              )}
            </div>
            <div className="flex flex-wrap gap-3 text-sm">
              <span className="inline-flex items-center gap-1.5 rounded-md bg-white/15 px-3 py-1.5 font-semibold backdrop-blur">
                <span className="text-base font-bold">
                  {subject.moduleCount}
                </span>
                <span className="text-white/80">
                  {subject.moduleCount === 1 ? 'module' : 'modules'}
                </span>
              </span>
              {subject.hasDueModule && (
                <span className="inline-flex items-center gap-1.5 rounded-md bg-amber-400/30 px-3 py-1.5 font-semibold backdrop-blur">
                  <Clock className="h-4 w-4" /> Has due work
                </span>
              )}
            </div>
          </div>
        )}

        {modulesQ.isLoading && <LoadingState />}
        {modulesQ.isError && (
          <ErrorState
            message={
              modulesQ.error instanceof Error
                ? modulesQ.error.message
                : 'Failed to load modules'
            }
            onRetry={() => modulesQ.refetch()}
          />
        )}
        {modulesQ.data && modulesQ.data.length === 0 && (
          <div className="grid place-items-center py-20 text-[#666]">
            No modules available yet.
          </div>
        )}

        {modulesQ.data && modulesQ.data.length > 0 && (
          <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {modulesQ.data.map((m, i) => (
              <ModuleCard
                key={m.id}
                module={m}
                accent={accent}
                delay={i * 0.03}
                onClick={() =>
                  navigate(`/subjects/${subjectId}/modules/${m.id}/chapters`)
                }
              />
            ))}
          </ul>
        )}
      </PageContainer>
    </div>
  )
}

function ModuleCard({
  module,
  accent,
  delay,
  onClick,
}: {
  module: Module
  accent: string
  delay: number
  onClick: () => void
}) {
  const statusBadge =
    module.status === 'completed' ? (
      <span className="inline-flex items-center gap-1 rounded-md border border-emerald-200 bg-emerald-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-emerald-700">
        <CheckCircle2 className="h-3 w-3" /> Done
      </span>
    ) : module.status === 'in_progress' ? (
      <span
        className="inline-flex items-center gap-1 rounded-md border px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest"
        style={{ borderColor: `${accent}40`, background: `${accent}12`, color: accent }}
      >
        <PlayCircle className="h-3 w-3" /> Active
      </span>
    ) : module.status === 'locked' ? (
      <span className="inline-flex items-center gap-1 rounded-md border border-gray-200 bg-gray-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-gray-500">
        <Lock className="h-3 w-3" /> Locked
      </span>
    ) : (
      <span className="rounded-md border border-[#E0E0E0] bg-[#F5F5F5] px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-[#666]">
        Not started
      </span>
    )

  return (
    <motion.li
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.25, ease: 'easeOut' }}
    >
      <button
        type="button"
        onClick={onClick}
        className="group flex h-full w-full flex-col rounded-xl border bg-white p-5 text-left shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#365DEA]"
        style={{ borderColor: BRAND_BORDER }}
      >
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0 flex-1">
            <div className="text-[11px] font-bold uppercase tracking-widest text-[#999]">
              Module {module.order}
            </div>
            <div className="mt-1 text-lg font-bold text-[#222]">
              {module.name}
            </div>
          </div>
          {statusBadge}
        </div>

        {module.description && (
          <p className="mt-2 line-clamp-2 text-sm text-[#666]">
            {module.description}
          </p>
        )}

        <div className="mt-4 h-1.5 w-full overflow-hidden rounded-full bg-[#F0F0F0]">
          <div
            className="h-full rounded-full transition-all duration-700 ease-out"
            style={{
              width: `${module.userPercentage}%`,
              background: accent,
            }}
          />
        </div>

        <div className="mt-3 flex items-center justify-between text-sm text-[#666]">
          <span>
            {module.chapterCount}{' '}
            {module.chapterCount === 1 ? 'chapter' : 'chapters'}
          </span>
          <span
            className="flex items-center gap-1 font-semibold opacity-0 transition-opacity group-hover:opacity-100"
            style={{ color: BRAND_PRIMARY }}
          >
            Open <ChevronRight className="h-4 w-4" />
          </span>
        </div>
      </button>
    </motion.li>
  )
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
          <div className="mt-2 h-3 w-full animate-pulse rounded bg-[#F5F5F5]" />
          <div className="mt-4 h-1.5 w-full animate-pulse rounded bg-[#F5F5F5]" />
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
        Couldn't load modules
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
