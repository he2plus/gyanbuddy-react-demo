/**
 * ChapterPlatform — one chapter card on the journey page.
 *
 * Mirrors the image-selection logic from module_chapter_screen.dart:694-798:
 *   in-progress + important  → important_platform.png + boy.png overlay
 *   in-progress              → platform.png            + boy.png overlay
 *   completed  + important   → important_platform.png  (no boy)
 *   completed  + last        → last_platform.png       (bigger)
 *   completed                → platform.png
 *   not_started + important  → disabled_important_stand.png
 *   not_started + last       → last_platform.png
 *   not_started              → disabled_platform.png
 *
 * Responsiveness (FIX from checkpoint #7 feedback):
 *   The previous version used fixed-pixel widths on boy.png and absolute-pixel
 *   `bottom` positioning. That made the platform shrink with the grid cell
 *   (thanks to Tailwind preflight `img { max-width: 100% }`) but left the boy
 *   at a constant 90px, floating awkwardly on narrow viewports.
 *
 *   Now: card has a responsive `max-width`, platform fills it with `w-full`,
 *   and the boy is sized + positioned in `%` units relative to the card —
 *   so they shrink together. Inspect-element from 1920 → 320 looks smooth.
 */
import { motion } from 'framer-motion'
import { Lock, Check } from 'lucide-react'
import type { ModuleChapter } from '../../types/module'

type Props = {
  chapter: ModuleChapter
  isLast: boolean
  onClick?: () => void
  /** When true, animates this card into view (used for the in-progress one). */
  highlight?: boolean
}

type Variant = 'regular' | 'important' | 'last'

/**
 * Intended max widths in CSS pixels at default zoom. On narrower grid cells
 * the whole card scales down because it's `w-full max-w-[X]`.
 */
const MAX_WIDTH: Record<Variant, number> = {
  regular: 132,
  important: 172,
  last: 240,
}

function pickAssets(chapter: ModuleChapter, isLast: boolean) {
  if (chapter.isInProgress) {
    return {
      platform: chapter.isImportant ? '/images/important_platform.png' : '/images/platform.png',
      withBoy: true,
      variant: (chapter.isImportant ? 'important' : 'regular') as Variant,
    }
  }
  if (chapter.isCompleted) {
    if (chapter.isImportant) {
      return { platform: '/images/important_platform.png', withBoy: false, variant: 'important' as Variant }
    }
    if (isLast) {
      return { platform: '/images/last_platform.png', withBoy: false, variant: 'last' as Variant }
    }
    return { platform: '/images/platform.png', withBoy: false, variant: 'regular' as Variant }
  }
  // not started
  if (chapter.isImportant) {
    return { platform: '/images/disabled_important_stand.png', withBoy: false, variant: 'important' as Variant }
  }
  if (isLast) {
    return { platform: '/images/last_platform.png', withBoy: false, variant: 'last' as Variant }
  }
  return { platform: '/images/disabled_platform.png', withBoy: false, variant: 'regular' as Variant }
}

export function ChapterPlatform({ chapter, isLast, onClick, highlight }: Props) {
  const { platform, withBoy, variant } = pickAssets(chapter, isLast)
  const interactive = chapter.isInProgress && !!onClick
  const maxW = MAX_WIDTH[variant]

  // Boy is sized as a percentage of the card width so it shrinks with it.
  // Important platforms are visually wider, so the boy occupies a smaller %.
  const boyWidthPct = variant === 'important' ? 52 : 68

  const content = (
    <div
      className="flex w-full flex-col items-center"
      style={{ maxWidth: maxW }}
    >
      {/* Stack: platform fills the card; boy overlaps from above. The
          card's height is dictated by the platform's intrinsic aspect ratio,
          plus padding-top reserved for the boy when present. */}
      <div
        className="relative w-full"
        style={{
          // When the boy is shown, reserve vertical space above the platform
          // by adding top padding equal to roughly the boy's apparent height
          // (~75% of card width). Otherwise no reserved space — platform-only
          // card is as tall as its natural aspect.
          paddingTop: withBoy ? '70%' : 0,
        }}
      >
        <img
          src={platform}
          alt=""
          draggable={false}
          className="block w-full select-none"
          style={{
            height: 'auto',
            filter:
              !chapter.isInProgress && !chapter.isCompleted
                ? 'saturate(0.6) opacity(0.85)'
                : undefined,
          }}
        />

        {withBoy && (
          <motion.img
            src="/images/boy.png"
            alt=""
            draggable={false}
            className="absolute select-none"
            style={{
              left: '50%',
              transform: 'translateX(-50%)',
              // Boy's lower edge overlaps the top of the platform.
              // bottom: ~58% of total card height lifts the boy just above the
              // platform top edge regardless of how wide the card is.
              bottom: '58%',
              width: `${boyWidthPct}%`,
              height: 'auto',
              filter: chapter.isImportant
                ? 'drop-shadow(0 6px 14px rgba(245, 158, 11, 0.35))'
                : 'drop-shadow(0 6px 14px rgba(54, 93, 234, 0.3))',
            }}
            initial={highlight ? { y: -8, opacity: 0 } : false}
            animate={
              highlight ? { y: [0, -4, 0], opacity: 1 } : { opacity: 1 }
            }
            transition={
              highlight
                ? {
                    y: { repeat: Infinity, duration: 2.2, ease: 'easeInOut' },
                    opacity: { duration: 0.4 },
                  }
                : undefined
            }
          />
        )}
      </div>

      {/* Status + chapter name */}
      <div className="mt-2 flex flex-col items-center text-center">
        <div
          className={`text-[10px] font-bold uppercase tracking-wider sm:text-xs ${
            chapter.isInProgress
              ? 'text-[var(--color-primary)]'
              : chapter.isCompleted
                ? 'text-emerald-600'
                : 'text-[var(--color-text-light)]'
          }`}
        >
          {chapter.isInProgress && (
            <span className="inline-flex items-center gap-1">
              <span className="inline-block h-1.5 w-1.5 animate-pulse rounded-full bg-[var(--color-primary)]" />
              In progress
            </span>
          )}
          {chapter.isCompleted && (
            <span className="inline-flex items-center gap-1">
              <Check className="h-3 w-3" strokeWidth={3} /> Completed
            </span>
          )}
          {chapter.isNotStarted && (
            <span className="inline-flex items-center gap-1">
              <Lock className="h-3 w-3" /> Locked
            </span>
          )}
        </div>
        <div
          className={`mt-0.5 max-w-full text-[11px] font-semibold leading-tight sm:text-sm ${
            chapter.isInProgress || chapter.isCompleted
              ? 'text-[var(--color-text-primary)]'
              : 'text-[var(--color-text-secondary)]'
          }`}
        >
          {chapter.name}
        </div>
      </div>
    </div>
  )

  if (interactive) {
    return (
      <motion.button
        type="button"
        onClick={onClick}
        whileTap={{ scale: 0.97 }}
        whileHover={{ y: -2 }}
        className="flex w-full cursor-pointer justify-center focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] focus-visible:ring-offset-2"
        aria-label={`Start chapter: ${chapter.name}`}
      >
        {content}
      </motion.button>
    )
  }

  return <div className="flex w-full justify-center" aria-label={chapter.name}>{content}</div>
}
