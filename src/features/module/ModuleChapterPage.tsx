/**
 * ModuleChapterPage — the journey/level-path screen. Full-bleed redesign.
 *
 * Decisions after first-round feedback:
 *   - Drop the cramped 5/7 two-card split. Module info becomes a short hero
 *     ribbon at the top; the path takes the rest of the page horizontally.
 *   - Sticky bottom action bar replaces the floating "Let's start" card so
 *     the CTA is always visible without scrolling.
 *   - Subject-color tint stays subtle (~6% alpha background), no gradients.
 *   - Connector strokes are thinner + lower-opacity for a cleaner look.
 */
import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, AlertTriangle, ArrowRight } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'

import { useModuleChapters, useSubjectModules } from './useModuleChapters'
import { getSubjectById } from '../../api/subjects'
import { ChapterPlatform } from './ChapterPlatform'
import type { ModuleChapter } from '../../types/module'
import type { Subject } from '../../types/subject'
import type { Module } from '../../types/module'

type Params = { subjectId: string; moduleId: string }

const BRAND_BORDER = '#E0E0E0'
const BRAND_PRIMARY = '#365DEA'

const COLUMN_FOR_INDEX = (i: number): 'left' | 'center' | 'right' => {
  const p = i % 3
  if (p === 0) return 'center'
  if (p === 1) return 'right'
  return 'left'
}

export function ModuleChapterPage() {
  const params = useParams<Params>()
  const subjectId = params.subjectId ?? ''
  const moduleId = params.moduleId ?? ''
  const navigate = useNavigate()

  const subjectQ = useQuery<Subject>({
    queryKey: ['subjects', subjectId, 'detail'],
    queryFn: () => getSubjectById(subjectId),
    enabled: !!subjectId,
    staleTime: 5 * 60_000,
  })
  const modulesQ = useSubjectModules(subjectId)
  const chaptersQ = useModuleChapters(moduleId)

  const subject = subjectQ.data
  const module = useMemo(
    () => modulesQ.data?.find((m: Module) => m.id === moduleId),
    [modulesQ.data, moduleId],
  )
  const chapters = chaptersQ.data ?? []
  const currentChapter =
    chapters.find((c) => c.isInProgress) ??
    chapters.find((c) => !c.isCompleted) ??
    null

  const accent = subject?.color || BRAND_PRIMARY
  const totalAssignments = useMemo(
    () =>
      module?.questionCount && module.questionCount > 0
        ? module.questionCount
        : chapters.reduce((s, c) => s + c.questionCount, 0),
    [module, chapters],
  )

  const isLoading = chaptersQ.isLoading || subjectQ.isLoading
  const isError = chaptersQ.isError

  return (
    <div
      className="relative flex min-h-screen flex-col"
      style={{ background: `${accent}08` }}
    >
      {/* Top bar */}
      <header className="sticky top-0 z-20 flex h-14 items-center gap-3 border-b border-[#EEE] bg-white/95 px-5 backdrop-blur">
        <button
          type="button"
          onClick={() => navigate(`/subjects/${subjectId}`)}
          aria-label="Back to subject"
          className="grid h-9 w-9 place-items-center rounded-md text-[#555] hover:bg-[#F5F5F5]"
        >
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div className="min-w-0 flex-1">
          <div className="truncate text-base font-bold text-[#222]">
            {module?.name ?? 'Module'}
          </div>
          {subject?.name && (
            <div className="truncate text-[11px] uppercase tracking-widest text-[#888]">
              {subject.name}
            </div>
          )}
        </div>
        {module && module.userPercentage > 0 && (
          <div className="hidden items-center gap-2 sm:flex">
            <span className="text-sm font-bold text-[#222]">
              {Math.round(module.userPercentage)}%
            </span>
            <div className="h-1.5 w-28 overflow-hidden rounded-full bg-[#EEE]">
              <div
                className="h-full rounded-full"
                style={{ width: `${module.userPercentage}%`, background: accent }}
              />
            </div>
          </div>
        )}
      </header>

      {/* Info ribbon */}
      <section className="border-b border-[#EEE] bg-white/70 px-5 py-4 backdrop-blur">
        <div className="mx-auto flex w-full max-w-[1760px] flex-wrap items-center gap-x-8 gap-y-3">
          <div className="min-w-0 flex-1">
            {module?.description ? (
              <p className="line-clamp-2 max-w-2xl text-sm text-[#555]">
                {module.description}
              </p>
            ) : (
              <p className="text-sm text-[#888]">
                Tap a platform to start the chapter.
              </p>
            )}
          </div>
          <div className="flex flex-wrap gap-x-6 gap-y-2 text-sm">
            <Stat label="Chapters" value={chapters.length} />
            {totalAssignments > 0 && (
              <Stat label="Assignments" value={totalAssignments} />
            )}
            {chapters.length > 0 && (
              <Stat
                label="Completed"
                value={chapters.filter((c) => c.isCompleted).length}
                tint={accent}
              />
            )}
          </div>
        </div>
      </section>

      {/* Path area — full width */}
      <main className="flex-1 px-3 pb-32 pt-6 sm:px-5 lg:px-8">
        <div className="mx-auto w-full max-w-[1440px]">
          {isLoading ? (
            <LoadingState />
          ) : isError ? (
            <ErrorState
              message={
                chaptersQ.error instanceof Error
                  ? chaptersQ.error.message
                  : 'Failed to load chapters'
              }
              onRetry={() => chaptersQ.refetch()}
            />
          ) : chapters.length === 0 ? (
            <EmptyState />
          ) : (
            <ZigZagPath
              chapters={chapters}
              onChapterStart={(c) => {
                navigate(
                  `/subjects/${subjectId}/modules/${moduleId}/chapters/${c.id}`,
                )
              }}
            />
          )}
        </div>
      </main>

      {/* Sticky CTA */}
      {currentChapter && !isLoading && !isError && (
        <div className="sticky bottom-0 z-20 border-t border-[#EEE] bg-white/95 px-5 py-3 backdrop-blur">
          <div className="mx-auto flex w-full max-w-[1440px] items-center justify-between gap-3">
            <div className="min-w-0">
              <div className="text-[11px] uppercase tracking-widest text-[#888]">
                Next up
              </div>
              <div className="truncate text-base font-bold text-[#222]">
                {currentChapter.name}
              </div>
            </div>
            <button
              type="button"
              onClick={() =>
                navigate(
                  `/subjects/${subjectId}/modules/${moduleId}/chapters/${currentChapter.id}`,
                )
              }
              className="inline-flex shrink-0 items-center gap-2 rounded-md px-5 py-2.5 text-sm font-semibold text-white"
              style={{ background: BRAND_PRIMARY }}
            >
              {currentChapter.isInProgress ? 'Continue' : 'Start'}
              <ArrowRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------
function Stat({
  label,
  value,
  tint,
}: {
  label: string
  value: number
  tint?: string
}) {
  return (
    <div className="flex items-baseline gap-1.5">
      <span
        className="text-lg font-bold"
        style={{ color: tint ?? '#222' }}
      >
        {value}
      </span>
      <span className="text-xs uppercase tracking-widest text-[#888]">
        {label}
      </span>
    </div>
  )
}

// ---------------------------------------------------------------------------
// ZigZag path with SVG connectors
// ---------------------------------------------------------------------------
function ZigZagPath({
  chapters,
  onChapterStart,
}: {
  chapters: ModuleChapter[]
  onChapterStart: (c: ModuleChapter) => void
}) {
  const containerRef = useRef<HTMLDivElement>(null)
  const cellRefs = useRef<Array<HTMLLIElement | null>>([])
  const [paths, setPaths] = useState<string[]>([])

  useEffect(() => {
    const compute = () => {
      const container = containerRef.current
      if (!container) return
      const cBox = container.getBoundingClientRect()
      const points: Array<{ x: number; y: number }> = []
      cellRefs.current.forEach((el) => {
        if (!el) return
        const r = el.getBoundingClientRect()
        points.push({
          x: r.left - cBox.left + r.width / 2,
          y: r.top - cBox.top + r.height / 2,
        })
      })
      const next: string[] = []
      for (let i = 0; i < points.length - 1; i++) {
        const a = points[i]
        const b = points[i + 1]
        const midY = (a.y + b.y) / 2
        next.push(
          `M ${a.x} ${a.y} C ${a.x} ${midY}, ${b.x} ${midY}, ${b.x} ${b.y}`,
        )
      }
      setPaths(next)
    }
    compute()
    const ro = new ResizeObserver(compute)
    if (containerRef.current) ro.observe(containerRef.current)
    window.addEventListener('resize', compute)
    return () => {
      ro.disconnect()
      window.removeEventListener('resize', compute)
    }
  }, [chapters.length])

  useEffect(() => {
    const ip = chapters.findIndex((c) => c.isInProgress)
    if (ip < 0) return
    const el = cellRefs.current[ip]
    if (el && 'scrollIntoView' in el) {
      requestAnimationFrame(() => {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' })
      })
    }
  }, [chapters])

  return (
    <div ref={containerRef} className="relative">
      <svg
        className="pointer-events-none absolute inset-0 h-full w-full"
        aria-hidden="true"
      >
        {paths.map((d, i) => (
          <path
            key={i}
            d={d}
            stroke="rgba(54, 93, 234, 0.22)"
            strokeWidth="1.5"
            strokeDasharray="5 8"
            strokeLinecap="round"
            fill="none"
          />
        ))}
      </svg>

      <ol className="relative grid grid-cols-3 gap-y-14 sm:gap-y-16 lg:gap-y-20">
        {chapters.map((chapter, i) => {
          const col = COLUMN_FOR_INDEX(i)
          const isLast = i === chapters.length - 1
          return (
            <li
              key={chapter.id}
              ref={(el) => {
                cellRefs.current[i] = el
              }}
              className="flex justify-center"
              style={{
                gridColumnStart: col === 'left' ? 1 : col === 'center' ? 2 : 3,
              }}
            >
              <ChapterPlatform
                chapter={chapter}
                isLast={isLast}
                highlight={chapter.isInProgress}
                onClick={
                  chapter.isInProgress
                    ? () => onChapterStart(chapter)
                    : undefined
                }
              />
            </li>
          )
        })}
      </ol>
    </div>
  )
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------
function LoadingState() {
  return (
    <div className="grid place-items-center py-20 text-center">
      <div
        className="h-8 w-8 animate-spin rounded-full border-4 border-t-transparent"
        style={{ borderColor: `${BRAND_PRIMARY} transparent ${BRAND_PRIMARY} ${BRAND_PRIMARY}` }}
      />
      <p className="mt-4 text-sm text-[#666]">Loading chapters…</p>
    </div>
  )
}

function EmptyState() {
  return (
    <div className="grid place-items-center py-20 text-[#666]">
      No chapters available yet.
    </div>
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
        Couldn't load chapters
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
