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

  // The wrapper's HEIGHT must equal the platform image's height (no label
  // contributing to the layout box) — that way SnakePath's
  // `transform: translate(-50%, -50%)` puts the IMAGE's centre on the
  // path point, and the dashed snake actually appears to pass through
  // the pedestal. The name label is absolutely-positioned below the
  // image, so it floats outside the centred hit area and never pulls
  // the geometric centre upward.
  return (
    <div className="relative" style={{ width: '100%' }}>
      <motion.button
        type="button"
        onClick={interactive ? onClick : undefined}
        disabled={!interactive}
        aria-label={chapter.name}
        className={interactive ? 'cursor-pointer' : 'cursor-default'}
        style={{
          width: '100%', display: 'block',
          background: 'transparent', border: 'none', padding: 0,
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

      {/* Label — absolutely-positioned below the image so it doesn't
          inflate the parent's bounding box. */}
      <div
        className="font-body text-center"
        style={{
          position: 'absolute',
          top: '100%', left: '50%', transform: 'translateX(-50%)',
          marginTop: 6,
          width: 'max-content', maxWidth: 132,
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
