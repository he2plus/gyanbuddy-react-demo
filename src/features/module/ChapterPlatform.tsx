/**
 * ChapterPlatform — renders ONE chapter podium on the Learning Journey
 * using the new raster assets in /images/podium/*.
 *
 * Docx #13 state rules:
 *   - Blue podium    : chapter is DUE (has due_date) and not completed
 *   - Green podium   : chapter is COMPLETED
 *   - Grey + lock    : chapter is LOCKED (no due_date, not completed)
 *   - START flag     : only on the very first podium
 *   - FINISH flag    : only on the very last podium (chequered)
 *   - Character (GB boy) stands on the IN-PROGRESS platform OR on the
 *     first platform when the journey hasn't started yet
 *
 * The asset PNGs already contain the character + flag in the correct
 * positions, so the component is mostly "pick the right file".
 */
import { motion } from 'framer-motion'
import type { ModuleChapter } from '../../types/module'

type Props = {
  chapter: ModuleChapter
  isFirst: boolean
  isLast: boolean
  hasCharacter: boolean
  onClick?: () => void
}

// Height of the slab "anchor box" as a fraction of the podium width. Its centre
// is what SnakePath pins to the path point, so this controls how high through
// the pedestal the dashed path appears to weave. Tuned so the path crosses the
// slab's mid-body for every art variant. (Slab art ≈ bottom 0.45·width tall.)
const SLAB_BOX_RATIO = 0.46

function assetFor(c: ModuleChapter, isFirst: boolean, isLast: boolean, withChar: boolean): string {
  const completed = c.isCompleted
  const inProgress = c.isInProgress
  const due = inProgress || (!c.isCompleted && !c.isNotStarted)
  const locked = c.isNotStarted && !inProgress

  // Last chapter — always "check" (finish flag) variants
  if (isLast) {
    if (completed) return '/images/podium/check-finish-char.png'
    if (locked)    return withChar ? '/images/podium/check-finish-lock-char.png' : '/images/podium/check-finish-lock.png'
    if (inProgress || due) return withChar ? '/images/podium/check-finish-char.png' : '/images/podium/check-finish.png'
    return '/images/podium/check-finish.png'
  }

  // First chapter — green-start when done, blue-char-start when active
  if (isFirst) {
    if (completed) return '/images/podium/green-start.png'
    return '/images/podium/blue-char-start.png'
  }

  // Middle
  if (completed) return '/images/podium/green.png'
  if (locked)    return withChar ? '/images/podium/grey-lock-char.png' : '/images/podium/grey-lock.png'
  return withChar ? '/images/podium/blue-char.png' : '/images/podium/blue.png'
}

export function ChapterPlatform({
  chapter, isFirst, isLast, hasCharacter, onClick,
}: Props) {
  const src = assetFor(chapter, isFirst, isLast, hasCharacter)
  const interactive = !!onClick && (chapter.isInProgress || chapter.isCompleted || isFirst)

  // Anchoring problem this solves:
  //   The podium PNGs share a 342px width but their HEIGHTS vary wildly
  //   (grey-lock 183 → blue-char 399) because some bake a standing character
  //   or a flag ABOVE the slab. Centring the whole image on the path point
  //   therefore parks the path in the middle of a character's torso for tall
  //   art and at the slab for short art — so the snake never reads as passing
  //   through the pedestals.
  //
  // Fix: a fixed-aspect "slab anchor box". The image is bottom-aligned inside
  // it and free to overflow UPWARD (the character/flag rises out of the box),
  // while the box itself — whose centre SnakePath pins to the path point — is a
  // constant fraction of the width tall. Result: the dashed path always crosses
  // the pedestal slab, identically for every variant, no per-asset tuning.
  return (
    <div className="relative" style={{ width: '100%' }}>
      <div style={{ position: 'relative', width: '100%', aspectRatio: `1 / ${SLAB_BOX_RATIO}` }}>
        <motion.button
          type="button"
          onClick={interactive ? onClick : undefined}
          disabled={!interactive}
          aria-label={chapter.name}
          className={interactive ? 'cursor-pointer' : 'cursor-default'}
          style={{
            position: 'absolute', bottom: 0, left: 0, width: '100%',
            display: 'block', background: 'transparent', border: 'none', padding: 0,
          }}
          whileHover={interactive ? { y: -4 } : undefined}
          whileTap={interactive ? { scale: 0.97 } : undefined}
        >
          <img
            src={src}
            alt=""
            draggable={false}
            className="block w-full select-none"
            style={{ height: 'auto' }}
          />
        </motion.button>
      </div>

      {/* Label — absolutely-positioned just below the slab box so it sits
          under the pedestal and never inflates the anchored bounding box. */}
      <div
        className="font-body text-center"
        style={{
          position: 'absolute',
          top: '100%', left: '50%', transform: 'translateX(-50%)',
          marginTop: 8,
          width: 'max-content', maxWidth: 124,
          fontSize: 13, fontWeight: 700, lineHeight: '17px',
          overflowWrap: 'break-word', wordBreak: 'break-word', hyphens: 'auto',
          color: chapter.isCompleted ? '#22D3A0'
               : chapter.isInProgress ? '#00167A'
               : '#989CA5',
          pointerEvents: 'none',
        }}
      >
        {chapter.name}
      </div>
    </div>
  )
}
