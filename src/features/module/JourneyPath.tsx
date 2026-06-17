/**
 * JourneyPath — faithful React port of the Flutter module_chapter_screen's
 * learning path.
 *
 * Mirrors the original exactly:
 *   - zig-zag layout: each chapter sits center / right / left following the
 *     original's `position = (i%3==0)?center : (i%3==1)?right : left`.
 *   - the boy stands on the CURRENT chapter only (one boy, never a crowd).
 *   - platform art is chosen purely by chapter state (completed / in-progress /
 *     locked / last) — the same mapping as `_buildChapterCard`.
 *   - a dashed spine runs down the middle, the platforms stepping off it.
 *   - auto-scroll centres the current chapter on load.
 *
 * Uses the original art copied to /images/journey/*.
 */
import { useEffect, useRef } from 'react'
import { motion } from 'framer-motion'
import type { ModuleChapter } from '../../types/module'

const NAVY = '#00167A'
const MUTED = '#8A93A5'
const J = '/images/journey'

function hexColor(c: string | null | undefined): string {
  if (!c) return '#1ABCFE'
  return c.startsWith('#') ? c : `#${c}`
}

// Chapter state → platform image (mirrors _buildChapterCard, minus the boy,
// which is placed on the *current* chapter only — see render below).
function platformFor(c: ModuleChapter, isLast: boolean): { src: string; w: number } {
  if (c.isCompleted) {
    if (isLast) return { src: 'last_platform.png', w: 168 }
    return { src: c.isImportant ? 'important_platform.png' : 'platform.png', w: c.isImportant ? 190 : 160 }
  }
  if (c.isInProgress) {
    return { src: c.isImportant ? 'important_platform.png' : 'platform.png', w: c.isImportant ? 190 : 160 }
  }
  // not started / locked
  if (c.isImportant) return { src: 'disabled_important_stand.png', w: 170 }
  if (isLast) return { src: 'last_platform.png', w: 168 }
  return { src: 'disabled_platform.png', w: 160 }
}

// Original zig-zag column: i%3 == 0 → centre, == 1 → right, == 2 → left.
function laneFor(i: number): 'center' | 'right' | 'left' {
  const m = i % 3
  return m === 0 ? 'center' : m === 1 ? 'right' : 'left'
}

function FloatingCircles({ color }: { color: string }) {
  const common = { borderRadius: '999px', position: 'absolute' as const, pointerEvents: 'none' as const }
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none" aria-hidden="true">
      <motion.div
        style={{ ...common, width: 180, height: 180, left: -50, top: 80, background: color, opacity: 0.12 }}
        animate={{ y: [0, 22, 0] }}
        transition={{ duration: 11, repeat: Infinity, ease: 'easeInOut' }}
      />
      <motion.div
        style={{ ...common, width: 140, height: 140, right: -30, top: 40, background: color, opacity: 0.14 }}
        animate={{ y: [0, -18, 0] }}
        transition={{ duration: 13, repeat: Infinity, ease: 'easeInOut', delay: 1 }}
      />
      <motion.div
        style={{ ...common, width: 60, height: 60, right: 24, bottom: 120, background: color, opacity: 0.16 }}
        animate={{ y: [0, 14, 0] }}
        transition={{ duration: 9, repeat: Infinity, ease: 'easeInOut', delay: 0.5 }}
      />
    </div>
  )
}

export function JourneyPath({
  chapters, currentChapterId, onChapterClick, subjectColor,
}: {
  chapters: ModuleChapter[]
  currentChapterId: string | null
  onChapterClick: (id: string) => void
  subjectColor: string | null
}) {
  const scrollRef = useRef<HTMLDivElement>(null)
  const currentRef = useRef<HTMLDivElement>(null)
  const color = hexColor(subjectColor)
  const N = chapters.length

  // Auto-scroll to the current chapter on load (mirrors _scrollToInProgressChapter).
  useEffect(() => {
    const t = setTimeout(() => {
      const el = currentRef.current
      const scroller = scrollRef.current
      if (el && scroller) {
        const top = el.offsetTop - scroller.clientHeight / 2 + el.clientHeight / 2
        scroller.scrollTo({ top: Math.max(0, top), behavior: 'smooth' })
      }
    }, 450)
    return () => clearTimeout(t)
  }, [currentChapterId, N])

  return (
    <div
      ref={scrollRef}
      className="relative flex-1 overflow-y-auto"
      style={{ minHeight: 'clamp(420px, 56vh, 680px)' }}
    >
      <FloatingCircles color={color} />

      <div className="relative flex flex-col" style={{ gap: 26, padding: '36px 0 52px' }}>
        {/* dashed spine the platforms step off */}
        {N > 1 && (
          <div
            className="absolute"
            style={{ left: '50%', top: 56, bottom: 70, borderLeft: '2px dashed #C7CFDB', transform: 'translateX(-50%)' }}
            aria-hidden="true"
          />
        )}

        {chapters.map((c, i) => {
          const isLast = i === N - 1
          const isCurrent = c.id === currentChapterId
          const { src, w } = platformFor(c, isLast)
          const boy = isCurrent
          const interactive = c.isInProgress || c.isCompleted || i === 0
          const lane = laneFor(i)
          const boxH = boy ? Math.round((w * 59) / 174) + 96 : isLast ? w : Math.round((w * 59) / 174)

          return (
            <div
              key={c.id}
              className="relative z-10 flex w-full"
              style={{
                justifyContent: lane === 'center' ? 'center' : lane === 'right' ? 'flex-end' : 'flex-start',
                paddingLeft: lane === 'left' ? '7%' : 0,
                paddingRight: lane === 'right' ? '7%' : 0,
              }}
            >
              <motion.div
                ref={isCurrent ? currentRef : undefined}
                className="flex flex-col items-center"
                style={{ gap: 10 }}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.04 + i * 0.05, duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
              >
                <button
                  type="button"
                  onClick={interactive ? () => onChapterClick(c.id) : undefined}
                  disabled={!interactive}
                  aria-label={c.name}
                  className={interactive ? 'cursor-pointer' : 'cursor-default'}
                  style={{ background: 'transparent', border: 'none', padding: 0 }}
                >
                  <div className="relative flex items-end justify-center" style={{ width: w, height: boxH }}>
                    {boy && (
                      <img
                        src={`${J}/boy.png`}
                        alt=""
                        draggable={false}
                        className="select-none"
                        style={{ position: 'absolute', bottom: Math.round((w * 59) / 174) - 6, left: '50%', transform: 'translateX(-50%)', height: 112, width: 'auto', zIndex: 2 }}
                      />
                    )}
                    <img
                      src={`${J}/${src}`}
                      alt=""
                      draggable={false}
                      className="block select-none"
                      style={{ width: '100%', height: 'auto', position: 'absolute', bottom: 0, left: 0, zIndex: 1 }}
                    />
                  </div>
                </button>
                <span
                  className="font-body text-center"
                  style={{
                    maxWidth: 168, fontSize: 13, fontWeight: isCurrent ? 800 : 600, lineHeight: '17px',
                    color: isCurrent ? NAVY : MUTED,
                    overflowWrap: 'break-word', wordBreak: 'break-word',
                  }}
                >
                  {c.name}
                </span>
              </motion.div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
