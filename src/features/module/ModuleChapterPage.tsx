/**
 * ModuleChapterPage — Learning Journey page, pixel-faithful rebuild of
 * Figma frame 10:4377 ("Life Processes 1", 1920 × 1006).
 *
 * Two-column layout:
 *   - LEFT (500 wide): topic preview card. Subject/module illustration up
 *     top, "Life Processes" + "7 Topics" header, overall progress bar,
 *     active topic preview (cyan-stroked card) with "Topic N / <name> /
 *     Overdue Date" and a navy Start button.
 *   - RIGHT (1116 wide): Learning Journey card. Header "Learning Journey /
 *     Follow the path to master <X>", the snake path of podiums, and a
 *     bottom CTA bar "Let's start with <next topic>" with a Start button.
 *
 * Podiums are laid out along a sine snake. Their assets are PNGs in
 * /images/podium/ — see ChapterPlatform.tsx for the state matrix.
 */
import { useMemo } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowRight, AlertTriangle, Play } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'

import { TopBar } from '../../shell/TopBar'
import { useModuleChapters, useSubjectModules } from './useModuleChapters'
import { getSubjectById } from '../../api/subjects'
import { ChapterPlatform } from './ChapterPlatform'
import type { Subject } from '../../types/subject'
import type { Module, ModuleChapter } from '../../types/module'

type Params = { subjectId: string; moduleId: string }

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

// Subject illustration map — same one used on the Subjects list. We look it
// up here so the topic-preview card renders the *actual* subject art instead
// of a generic placeholder.
const SUBJECT_PNG: Record<string, string> = {
  CHEM: '/images/figma/subj-1-chemistry.png',
  BIO:  '/images/figma/subj-2-biology.png',
  PHY:  '/images/figma/subj-3-physics.png',
  GEO:  '/images/figma/subj-4-geography.png',
  MATH: '/images/figma/subj-5-maths.png',
  ENG:  '/images/figma/subj-6-english.png',
  HIS:  '/images/figma/subj-7-history.png',
  SAN:  '/images/figma/subj-8-sanskrit.png',
  MATHS: '/images/figma/subj-5-maths.png',
  SCI:   '/images/figma/subj-3-physics.png',
  SCIENCE: '/images/figma/subj-3-physics.png',
  ENGLISH: '/images/figma/subj-6-english.png',
  HISTORY: '/images/figma/subj-7-history.png',
  GEN:  '/images/figma/subj-2-biology.png',
}
const subjectPngForCode = (code: string | null | undefined): string | null =>
  code ? (SUBJECT_PNG[code.toUpperCase()] ?? null) : null

// ---------------------------------------------------------------------------
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

  // subjectQ is fetched purely to keep the cache warm for the TopBar /
  // breadcrumb work the wider app does; we don't read it directly here.
  void subjectQ.data
  const module = useMemo(
    () => modulesQ.data?.find((m: Module) => m.id === moduleId),
    [modulesQ.data, moduleId],
  )
  const chapters = chaptersQ.data ?? []

  const currentChapter = useMemo(() => {
    return (
      chapters.find((c) => c.isInProgress) ??
      chapters.find((c) => !c.isCompleted) ??
      null
    )
  }, [chapters])

  const completedCount = chapters.filter((c) => c.isCompleted).length
  const overallPct = chapters.length
    ? Math.round((completedCount / chapters.length) * 100)
    : 0

  const goToChapter = (chapterId: string) =>
    navigate(`/subjects/${subjectId}/modules/${moduleId}/chapters/${chapterId}`)

  const isLoading = chaptersQ.isLoading || subjectQ.isLoading
  const isError = chaptersQ.isError

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle={module?.name ?? 'Topic'} testCount={1} />

      <main
        className="mx-auto w-full"
        style={{
          maxWidth: 1920,
          padding: 'clamp(24px, 3vw, 50px) clamp(16px, 4vw, 120px) clamp(40px, 5vw, 60px)',
        }}
      >
        <div
          className="flex flex-col lg:flex-row"
          style={{ gap: 'clamp(24px, 3vw, 64px)' }}
        >
          {/* LEFT CARD — topic preview */}
          <TopicPreviewCard
            module={module ?? null}
            chapters={chapters}
            completedCount={completedCount}
            overallPct={overallPct}
            currentChapter={currentChapter}
            isLoading={isLoading}
            subjectCode={subjectQ.data?.code ?? null}
            onStart={() => currentChapter && goToChapter(currentChapter.id)}
          />

          {/* RIGHT CARD — Learning Journey */}
          <section
            className="bg-white flex flex-col min-w-0 overflow-hidden"
            style={{
              flex: 1, borderRadius: 34, padding: 'clamp(20px, 2.5vw, 34px)', gap: 24,
              minHeight: 'clamp(560px, 70vh, 806px)',
              boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
            }}
          >
            <header className="flex flex-col" style={{ gap: 6 }}>
              <h1
                className="font-body"
                style={{ fontSize: 26, fontWeight: 700, color: NAVY, lineHeight: '36px', margin: 0 }}
              >
                Learning Journey
              </h1>
              <p
                className="font-body"
                style={{ fontSize: 16, fontWeight: 600, color: TXT_MID, lineHeight: '22px', margin: 0 }}
              >
                Follow the path to master {module?.name ?? 'this topic'}
              </p>
            </header>

            {/* Path zone — minHeight matches the snake-path's intrinsic
                height so the absolutely-positioned platforms (including
                the FINISH-flag last platform with its name label) always
                fit without overlapping the bottom CTA. */}
            <div className="flex-1 relative overflow-hidden" style={{ minHeight: 'clamp(440px, 56vh, 620px)' }}>
              {isLoading && <LoadingPath />}
              {isError && (
                <ErrorState
                  message={
                    chaptersQ.error instanceof Error
                      ? chaptersQ.error.message
                      : 'Failed to load chapters'
                  }
                  onRetry={() => chaptersQ.refetch()}
                />
              )}
              {!isLoading && !isError && chapters.length === 0 && <EmptyState />}
              {!isLoading && !isError && chapters.length > 0 && (
                <SnakePath
                  chapters={chapters}
                  currentChapterId={currentChapter?.id ?? null}
                  onChapterClick={goToChapter}
                />
              )}
            </div>

            {/* Bottom CTA bar */}
            {currentChapter && !isLoading && !isError && (
              <motion.div
                className="flex items-center"
                style={{
                  borderRadius: 68, padding: '20px 44px', height: 97, gap: 14,
                  background: '#fff',
                  boxShadow: '0 6px 20px rgba(0,22,122,0.08)',
                  border: '1px solid #EAEAEA',
                }}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.45, delay: 0.2 }}
              >
                <span
                  className="font-body flex-1 truncate"
                  style={{
                    fontSize: 20, fontWeight: 700, color: NAVY, lineHeight: '28px',
                  }}
                >
                  Let's start with {currentChapter.name}
                </span>
                <motion.button
                  type="button"
                  onClick={() => goToChapter(currentChapter.id)}
                  className="grid place-items-center"
                  style={{
                    background: NAVY, color: '#fff', borderRadius: 42,
                    padding: '16px 24px', height: 57, gap: 14,
                  }}
                  whileTap={{ scale: 0.97 }}
                  whileHover={{ y: -2 }}
                >
                  <span className="flex items-center" style={{ gap: 14 }}>
                    <Play className="w-5 h-5" style={{ color: '#fff' }} strokeWidth={2.5} fill="#fff" />
                    <span style={{ fontSize: 18, fontWeight: 700, lineHeight: '25px' }}>
                      Start
                    </span>
                  </span>
                </motion.button>
              </motion.div>
            )}
          </section>
        </div>
      </main>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Left card — topic preview with illustration, progress, active topic chip,
// Start button. Mirrors Figma Frame 37 (500 × 622).
// ---------------------------------------------------------------------------
function TopicPreviewCard({
  module, chapters, completedCount, overallPct, currentChapter, isLoading, subjectCode, onStart,
}: {
  module: Module | null
  chapters: ModuleChapter[]
  completedCount: number
  overallPct: number
  currentChapter: ModuleChapter | null
  isLoading: boolean
  subjectCode: string | null
  onStart: () => void
}) {
  if (isLoading || !module) {
    return (
      <section
        className="bg-white animate-pulse w-full"
        style={{ maxWidth: 500, minHeight: 622, borderRadius: 34, padding: 24 }}
      />
    )
  }

  // Topic 1 index — currentChapter's order is 1-based
  const topicNum = currentChapter?.order ?? 1
  const overdueText = formatOverdue(currentChapter)
  const illustration = subjectPngForCode(subjectCode)

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
      {/* Illustration zone — real subject art, falls back to a tinted ball
          if the subject's code isn't in our PNG map. */}
      <div
        className="grid place-items-center relative overflow-hidden"
        style={{
          width: 236, height: 238, borderRadius: 24, marginTop: 24,
          background: 'radial-gradient(circle at 50% 30%, rgba(26,188,254,0.18), rgba(124,58,237,0.06) 60%, transparent 80%)',
        }}
      >
        {illustration ? (
          <motion.img
            src={illustration}
            alt=""
            draggable={false}
            className="select-none"
            style={{ maxHeight: 200, width: 'auto', filter: 'drop-shadow(0 14px 30px rgba(0,22,122,0.18))' }}
            animate={{ y: [0, -6, 0] }}
            transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut' }}
          />
        ) : (
          <motion.div
            style={{
              width: 130, height: 130, borderRadius: 999,
              background: `radial-gradient(circle at 32% 28%, #34D5FF 0%, ${CYAN} 50%, #0A95D4 100%)`,
              boxShadow: `0 12px 28px ${CYAN}55, inset 0 -8px 12px rgba(0,0,0,0.12), inset 0 6px 12px rgba(255,255,255,0.30)`,
            }}
            animate={{ y: [0, -8, 0] }}
            transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut' }}
          />
        )}
      </div>

      {/* Title + topic count + progress */}
      <div className="flex flex-col items-center w-full" style={{ gap: 14 }}>
        <div className="flex flex-col items-center" style={{ gap: 2 }}>
          <h2
            className="font-body"
            style={{ fontSize: 26, fontWeight: 700, color: NAVY, lineHeight: '36px', margin: 0 }}
          >
            {module.name}
          </h2>
          <span
            className="font-body"
            style={{ fontSize: 16, fontWeight: 600, color: TXT_MID, lineHeight: '22px' }}
          >
            {chapters.length} {chapters.length === 1 ? 'Topic' : 'Topics'}
          </span>
        </div>
        <div className="flex items-center w-full" style={{ gap: 10 }}>
          <div
            className="flex-1"
            style={{ height: 8, borderRadius: 14, background: '#F1F1F1', overflow: 'hidden' }}
          >
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${overallPct}%` }}
              transition={{ duration: 0.9, ease: 'easeOut' }}
              style={{ height: '100%', borderRadius: 14, background: CYAN }}
            />
          </div>
          <span
            className="font-body tabular-nums"
            style={{ fontSize: 16, fontWeight: 600, color: TXT_MID, lineHeight: '22px' }}
          >
            {completedCount}/{chapters.length}
          </span>
        </div>
      </div>

      {/* Active topic card */}
      {currentChapter && (
        <div
          className="flex flex-col w-full"
          style={{
            border: `1px solid ${CYAN}`, borderRadius: 34, padding: '20px 24px', gap: 14,
            background: '#fff',
          }}
        >
          <div className="flex flex-col items-center" style={{ gap: 10 }}>
            <span
              className="font-body"
              style={{ fontSize: 18, fontWeight: 700, color: NAVY, lineHeight: '25px' }}
            >
              Topic {topicNum}
            </span>
            <span
              className="font-body text-center"
              style={{ fontSize: 20, fontWeight: 700, color: TXT_DARK, lineHeight: '28px' }}
            >
              {currentChapter.name}
            </span>
            {overdueText && (
              <span
                className="flex items-center font-body"
                style={{ gap: 6, fontSize: 14, fontWeight: 700, color: '#FF3131', lineHeight: '19px' }}
              >
                <AlertTriangle className="w-4 h-4" strokeWidth={2.5} />
                {overdueText}
              </span>
            )}
          </div>
          <motion.button
            type="button"
            onClick={onStart}
            className="grid place-items-center w-full"
            style={{
              background: NAVY, color: '#fff', borderRadius: 42, padding: '16px 24px',
              height: 57, gap: 14,
            }}
            whileTap={{ scale: 0.97 }}
            whileHover={{ y: -2 }}
          >
            <span className="flex items-center" style={{ gap: 14 }}>
              <Play className="w-5 h-5" style={{ color: '#fff' }} strokeWidth={2.5} fill="#fff" />
              <span style={{ fontSize: 18, fontWeight: 700, lineHeight: '25px' }}>
                Start
              </span>
            </span>
          </motion.button>
        </div>
      )}
    </motion.section>
  )
}

function formatOverdue(c: ModuleChapter | null): string | null {
  // ModuleChapter type doesn't expose due_date; backend will when ready.
  // For now: in-progress chapters with status='due' would show this.
  if (!c) return null
  // Placeholder demo text mirroring the Figma "Overdue 1 May"
  if (c.isInProgress) return null
  if (c.status === 'not_started') return null
  return null
}

// ---------------------------------------------------------------------------
// Snake path — lays podiums out along a sine curve so the journey feels
// like a board game. Uses absolute positioning inside a fixed-aspect-ratio
// container so the curve scales with the available width.
// ---------------------------------------------------------------------------
function SnakePath({
  chapters, currentChapterId, onChapterClick,
}: {
  chapters: ModuleChapter[]
  currentChapterId: string | null
  onChapterClick: (id: string) => void
}) {
  const N = chapters.length

  // Position each podium on a normalised 0..1 coordinate space.
  //
  // Goals:
  //   - Always alternate sides so adjacent stages never stack vertically.
  //   - Keep y inside [0.06, 0.80] so the FIRST stage doesn't get clipped
  //     by the journey header and the LAST stage (FINISH flag + name
  //     label below it) doesn't extend past the container bottom and
  //     overlap the "Let's start with X" CTA bar. The old 0.08-0.88
  //     range left only ~12% headroom which a 150-180px tall platform
  //     could blow through. 0.80 leaves a full 100px+ of breathing room.
  //   - Work for N = 1, 2, 3, 4, 5+. Previous version assumed N ≥ 5 and
  //     collapsed both stages to x=0.5 when N=2 (sin(0) = sin(2π) = 0).
  const positions = useMemo(() => {
    if (N === 0) return [] as Array<{ x: number; y: number }>
    if (N === 1) return [{ x: 0.5, y: 0.5 }]
    const Y_TOP = 0.06
    const Y_BOTTOM = 0.80
    // Keep nodes inset from the container edges so the pedestal image AND its
    // name label (which can be wider than the image) stay inside the panel
    // instead of bleeding past the right/left edge on narrower viewports.
    const amplitude = N <= 3 ? 0.24 : N <= 5 ? 0.26 : 0.28
    return chapters.map((_, i) => {
      const yFrac = i / (N - 1)
      const y = Y_TOP + yFrac * (Y_BOTTOM - Y_TOP)
      // Alternate left / right with a smooth cosine so the connecting
      // bezier path reads as a real snake instead of zig-zag teeth.
      const x = 0.5 + amplitude * Math.cos(i * Math.PI)
      return { x, y }
    })
  }, [chapters, N])

  // Build SVG path connecting podium centres. Height matches the
  // container below so the curve scales with viewBox preservation.
  const pathD = useMemo(() => {
    if (positions.length < 2) return ''
    const w = 988
    const h = 600
    const pts = positions.map((p) => ({ x: p.x * w, y: p.y * h }))
    let d = `M ${pts[0].x} ${pts[0].y}`
    for (let i = 0; i < pts.length - 1; i++) {
      const a = pts[i], b = pts[i + 1]
      const midY = (a.y + b.y) / 2
      d += ` C ${a.x} ${midY}, ${b.x} ${midY}, ${b.x} ${b.y}`
    }
    return d
  }, [positions])

  return (
    <div className="relative w-full" style={{ height: 600 }}>
      <svg
        className="absolute inset-0 w-full h-full pointer-events-none"
        viewBox="0 0 988 600" preserveAspectRatio="none"
        aria-hidden="true"
      >
        <path
          d={pathD}
          stroke="#94A3B8" strokeWidth={3} strokeDasharray="6 10"
          strokeLinecap="round" fill="none" opacity={0.45}
        />
      </svg>

      {chapters.map((c, i) => {
        const p = positions[i]
        const isFirst = i === 0
        const isLast = i === N - 1
        const isCurrent = c.id === currentChapterId
        // Character on the active chapter, or on the first when nothing is in-progress
        const hasChar = isCurrent || (!currentChapterId && isFirst)
        // Wider for first/last (has flag), normal otherwise
        const w = isFirst || isLast ? 16 : 13
        return (
          <motion.div
            key={c.id}
            className="absolute"
            style={{
              left: `${p.x * 100}%`,
              top:  `${p.y * 100}%`,
              // translate(-50%, -50%) on a wrapper whose HEIGHT equals
              // the platform IMAGE (the name label is absolutely-
              // positioned in ChapterPlatform, so it doesn't inflate
              // the wrapper's bounding box). Result: the image's
              // visual centre lands on the path point, and the dashed
              // snake appears to weave through the pedestals.
              transform: 'translate(-50%, -50%)',
              width: `${w}%`,
              maxWidth: 168,
              minWidth: 84,
            }}
            initial={{ opacity: 0, y: 10, scale: 0.94 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ delay: 0.05 + i * 0.06, duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
          >
            <ChapterPlatform
              chapter={c}
              isFirst={isFirst}
              isLast={isLast}
              hasCharacter={hasChar}
              onClick={() => onChapterClick(c.id)}
            />
          </motion.div>
        )
      })}
    </div>
  )
}

// ---------------------------------------------------------------------------
function LoadingPath() {
  return (
    <div className="flex flex-wrap" style={{ gap: 24, justifyContent: 'space-between' }}>
      {Array.from({ length: 7 }).map((_, i) => (
        <div
          key={i}
          className="animate-pulse"
          style={{ width: 130, height: 90, borderRadius: 16, background: '#F1F1F1' }}
        />
      ))}
    </div>
  )
}

function EmptyState() {
  return (
    <div className="grid place-items-center py-12" style={{ color: TXT_MUTED }}>
      No chapters in this topic yet.
    </div>
  )
}

function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="grid place-items-center py-12 text-center">
      <AlertTriangle className="w-10 h-10" style={{ color: TXT_MUTED }} />
      <p className="font-body mt-3" style={{ fontSize: 16, color: TXT_DARK }}>
        {message}
      </p>
      <button
        type="button"
        onClick={onRetry}
        className="mt-4 grid place-items-center"
        style={{
          background: NAVY, color: '#fff', borderRadius: 42, padding: '10px 26px',
          fontFamily: 'var(--font-body)', fontSize: 16, fontWeight: 700,
        }}
      >
        Retry
      </button>
    </div>
  )
}

// Suppress unused-import lint
void ArrowRight
