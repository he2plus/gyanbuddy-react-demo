/**
 * Podium — top-3 visualisation. 2nd ─ 1st ─ 3rd ordering with pedestal heights
 * 1 > 2 > 3, medal-coloured rank chips. Avoids the generic AI-template feel:
 *   - No gradient washes, no glassmorphism, no decorative SVG balloons.
 *   - Uses the project's flat palette (brand navy, primary, medal yellow/silver/bronze).
 *   - Pedestal height is fixed in CSS so it doesn't drift with content; avatar
 *     sizes are uniform, and the "You" highlight reuses the same primary-tint
 *     ring that the rest of the app uses for the active-row callout.
 *
 * If fewer than 3 entries are available the missing slots are rendered as
 * faded "—" placeholders so the layout stays symmetric.
 */
import { motion } from 'framer-motion'
import { Crown } from 'lucide-react'

const MEDAL: Record<1 | 2 | 3, string> = {
  1: '#F5B400',
  2: '#9CA3AF',
  3: '#B45309',
}

const PEDESTAL_HEIGHT: Record<1 | 2 | 3, number> = {
  1: 132,
  2: 96,
  3: 72,
}

export type PodiumEntry = {
  id: string
  fullName: string
  username: string
  firstName?: string
  totalExp: number
  profilePicture?: string | null
}

type Props = {
  entries: PodiumEntry[]
  meId?: string
  onClick?: (entry: PodiumEntry) => void
}

export function Podium({ entries, meId, onClick }: Props) {
  const first = entries[0]
  const second = entries[1]
  const third = entries[2]

  return (
    <div
      className="rounded-2xl border bg-white px-5 pt-6 pb-0 shadow-sm sm:px-8 sm:pt-8"
      style={{ borderColor: '#E0E0E0' }}
    >
      <div className="mx-auto flex max-w-md items-end justify-center gap-4 sm:gap-6">
        <Column rank={2} entry={second} meId={meId} onClick={onClick} delay={0.08} />
        <Column rank={1} entry={first} meId={meId} onClick={onClick} delay={0} />
        <Column rank={3} entry={third} meId={meId} onClick={onClick} delay={0.16} />
      </div>
    </div>
  )
}

function Column({
  rank,
  entry,
  meId,
  onClick,
  delay,
}: {
  rank: 1 | 2 | 3
  entry?: PodiumEntry
  meId?: string
  onClick?: (entry: PodiumEntry) => void
  delay: number
}) {
  const isMe = !!entry && entry.id === meId
  const medal = MEDAL[rank]
  const height = PEDESTAL_HEIGHT[rank]

  const avatarSize = rank === 1 ? 76 : 60
  const initials = (entry?.firstName?.[0] ?? entry?.username?.[0] ?? '·').toUpperCase()

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.35, ease: 'easeOut' }}
      className="flex flex-1 flex-col items-center"
    >
      {/* Crown above #1 */}
      {rank === 1 && (
        <Crown
          className="mb-1 h-5 w-5"
          style={{ color: medal }}
          strokeWidth={2.5}
          aria-hidden="true"
        />
      )}

      {/* Avatar */}
      <button
        type="button"
        onClick={entry && onClick ? () => onClick(entry) : undefined}
        disabled={!entry}
        aria-label={entry ? `${entry.fullName || entry.username}, rank ${rank}` : `Rank ${rank} unfilled`}
        className="group relative grid shrink-0 place-items-center rounded-full font-extrabold text-white shadow-sm transition-transform disabled:cursor-default"
        style={{
          width: avatarSize,
          height: avatarSize,
          background: entry ? medal : '#EEEEEE',
          outline: isMe ? '3px solid #365DEA' : 'none',
          outlineOffset: 2,
        }}
      >
        {entry?.profilePicture ? (
          <img
            src={entry.profilePicture}
            alt=""
            className="h-full w-full rounded-full object-cover"
          />
        ) : (
          <span
            style={{
              fontSize: rank === 1 ? 28 : 22,
              color: entry ? '#FFFFFF' : '#BDBDBD',
            }}
          >
            {initials}
          </span>
        )}
      </button>

      {/* Name + XP */}
      <div className="mt-2 min-h-[2.5rem] w-full max-w-[120px] text-center">
        <div
          className={`truncate text-[13px] font-bold ${entry ? 'text-[#222]' : 'text-[#BBB]'}`}
        >
          {entry?.fullName || entry?.username || '—'}
        </div>
        {entry && (
          <div className="text-[11px] font-semibold text-[#666] tabular-nums">
            {entry.totalExp.toLocaleString()} XP
          </div>
        )}
      </div>

      {/* Pedestal */}
      <div
        className="mt-2 flex w-full max-w-[120px] items-start justify-center rounded-t-lg pt-2 text-base font-extrabold text-white"
        style={{
          height,
          background: medal,
          boxShadow: 'inset 0 -10px 0 rgba(0,0,0,0.08)',
        }}
      >
        {rank}
      </div>
    </motion.div>
  )
}
