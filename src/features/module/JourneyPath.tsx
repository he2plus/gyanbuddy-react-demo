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
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { motion } from 'framer-motion'
import type { ModuleChapter } from '../../types/module'

const J = '/images/ladder'

function hexColor(c: string | null | undefined): string {
  if (!c) return '#1ABCFE'
  return c.startsWith('#') ? c : `#${c}`
}

// Chapter state → podium art (the Ishaan ladder set). EXACTLY ONE character on
// the whole path — the single current chapter — so the boy "moves" up the
// ladder as the student progresses. No chapter names are drawn on the map; the
// name lives only on the side card.
//   - current      → blue podium + character (start-flag variant on chapter 1)
//   - completed    → green podium (start-flag variant on chapter 1)
//   - locked / not → grey podium with a lock
//   - last chapter → checkered FINISH podium (char if current, else completed/lock)
function artFor(
  c: ModuleChapter,
  isFirst: boolean,
  isLast: boolean,
  isCurrent: boolean,
): { src: string; w: number } {
  if (isLast) {
    if (isCurrent) return { src: 'finish-char.png', w: 188 }
    if (c.isCompleted) return { src: 'finish.png', w: 178 }
    return { src: 'finish-lock.png', w: 178 }
  }
  if (isCurrent) {
    return isFirst ? { src: 'blue-char-start.png', w: 168 } : { src: 'blue-char.png', w: 152 }
  }
  if (c.isCompleted) {
    return isFirst ? { src: 'green-start.png', w: 162 } : { src: 'green.png', w: 150 }
  }
  // locked / not started
  return { src: 'grey-lock.png', w: 150 }
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
  const contentRef = useRef<HTMLDivElement>(null)
  const currentRef = useRef<HTMLButtonElement>(null)
  // One ref per platform image so we can measure where each platform sits and
  // draw the connectors between them (mirrors the Flutter _ChapterConnectionPainter).
  const imgRefs = useRef<Array<HTMLImageElement | null>>([])
  const color = hexColor(subjectColor)
  const N = chapters.length

  const [paths, setPaths] = useState<string[]>([])
  const [box, setBox] = useState<{ w: number; h: number }>({ w: 0, h: 0 })

  // Measure each platform's slab anchor and build curved dashed connectors
  // between consecutive platforms — exactly the original's cubic-bézier:
  //   cp1 = (start.x, start.y + dy*0.7),  cp2 = (end.x, end.y - dy*0.7)
  // which makes the dashes exit one platform downward and approach the next
  // straight from above (the S-curve staircase).
  const measure = useCallback(() => {
    const content = contentRef.current
    if (!content) return
    const cRect = content.getBoundingClientRect()
    const pts: Array<{ x: number; y: number } | null> = []
    for (let i = 0; i < N; i++) {
      const el = imgRefs.current[i]
      if (!el) { pts.push(null); continue }
      const r = el.getBoundingClientRect()
      // Anchor on the platform slab (sits at the bottom of every art — plain
      // platform or boy-on-platform), a touch above the bottom edge.
      pts.push({
        x: r.left - cRect.left + r.width / 2,
        y: r.top - cRect.top + r.height - 16,
      })
    }
    const ds: string[] = []
    for (let i = 0; i < pts.length - 1; i++) {
      const a = pts[i]
      const b = pts[i + 1]
      if (!a || !b) continue
      const dy = b.y - a.y
      ds.push(`M ${a.x} ${a.y} C ${a.x} ${a.y + dy * 0.7} ${b.x} ${b.y - dy * 0.7} ${b.x} ${b.y}`)
    }
    setPaths(ds)
    setBox({ w: cRect.width, h: cRect.height })
  }, [N])

  useLayoutEffect(() => { measure() }, [measure, chapters])
  useEffect(() => {
    measure()
    const ro = new ResizeObserver(() => measure())
    if (contentRef.current) ro.observe(contentRef.current)
    window.addEventListener('resize', measure)
    return () => { ro.disconnect(); window.removeEventListener('resize', measure) }
  }, [measure])

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
      className="relative flex-1 min-h-0 overflow-y-auto"
    >
      <FloatingCircles color={color} />

      <div ref={contentRef} className="relative flex flex-col" style={{ gap: 18, padding: '28px 0 44px' }}>
        {/* Curved dashed connectors between consecutive platforms (behind them). */}
        {box.w > 0 && (
          <svg
            className="absolute pointer-events-none"
            style={{ left: 0, top: 0, width: '100%', height: '100%', zIndex: 0 }}
            viewBox={`0 0 ${box.w} ${box.h}`}
            preserveAspectRatio="none"
            aria-hidden="true"
          >
            {paths.map((d, i) => (
              <path
                key={i}
                d={d}
                fill="none"
                stroke="#C3CCD8"
                strokeWidth={2.5}
                strokeLinecap="round"
                strokeDasharray="5 6"
              />
            ))}
          </svg>
        )}

        {chapters.map((c, i) => {
          const isFirst = i === 0
          const isLast = i === N - 1
          const isCurrent = c.id === currentChapterId
          const { src, w } = artFor(c, isFirst, isLast, isCurrent)
          const interactive = c.isInProgress || c.isCompleted || i === 0
          const lane = laneFor(i)

          return (
            <div
              key={c.id}
              className="relative z-10 flex w-full"
              style={{
                justifyContent: lane === 'center' ? 'center' : lane === 'right' ? 'flex-end' : 'flex-start',
                paddingLeft: lane === 'left' ? '9%' : 0,
                paddingRight: lane === 'right' ? '9%' : 0,
              }}
            >
              <motion.button
                ref={isCurrent ? currentRef : undefined}
                type="button"
                onClick={interactive ? () => onChapterClick(c.id) : undefined}
                disabled={!interactive}
                aria-label={c.name}
                className={`flex ${interactive ? 'cursor-pointer' : 'cursor-default'}`}
                style={{ background: 'transparent', border: 'none', padding: 0 }}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.04 + i * 0.05, duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
              >
                {/* Podium art only — no chapter name on the map (it lives on the
                    side card). The character is part of the current podium art. */}
                <img
                  ref={(el) => { imgRefs.current[i] = el }}
                  src={`${J}/${src}`}
                  alt=""
                  draggable={false}
                  onLoad={measure}
                  className="block select-none"
                  style={{ width: w, height: 'auto', display: 'block' }}
                />
              </motion.button>
            </div>
          )
        })}
      </div>
    </div>
  )
}
