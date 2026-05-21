/**
 * Podium — top-3 visualisation. Reads as a 3D-ish stage: gold trophy crown
 * floats above #1, pedestals have radial shading and an inset shadow so
 * they don't look like flat blocks, and the medal palette (gold/silver/
 * bronze) lines up with the rest of the app.
 *
 * Why not the Figma PNG: the exported leaderboard-podium.png has the demo
 * names + avatars baked in, so it can't drive live data. This stays as a
 * data-driven component and just leans into the same visual language.
 */
import { motion } from 'framer-motion'
import { Crown } from 'lucide-react'

const MEDAL: Record<1 | 2 | 3, { base: string; light: string; dark: string }> = {
  1: { base: '#F5B400', light: '#FFD24A', dark: '#B97A00' },
  2: { base: '#9CA3AF', light: '#CBD5E1', dark: '#64748B' },
  3: { base: '#B45309', light: '#D97706', dark: '#7C2D12' },
}

const PEDESTAL_HEIGHT: Record<1 | 2 | 3, number> = {
  1: 156,
  2: 116,
  3: 88,
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
      className="relative overflow-hidden bg-white"
      style={{
        borderRadius: 24, padding: '40px 32px 0',
        border: '1px solid #E7E7E7',
        boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
      }}
    >
      {/* Soft radial backdrop that hints at a stage spotlight */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: 'radial-gradient(circle at 50% 0%, rgba(26,188,254,0.10), transparent 60%)',
        }}
      />

      <div
        className="relative mx-auto flex items-end justify-center"
        style={{ maxWidth: 540, gap: 32 }}
      >
        <Column rank={2} entry={second} meId={meId} onClick={onClick} delay={0.08} />
        <Column rank={1} entry={first}  meId={meId} onClick={onClick} delay={0} />
        <Column rank={3} entry={third}  meId={meId} onClick={onClick} delay={0.16} />
      </div>
    </div>
  )
}

function Column({
  rank, entry, meId, onClick, delay,
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

  const avatarSize = rank === 1 ? 84 : 64
  const initials = (entry?.firstName?.[0] ?? entry?.username?.[0] ?? '·').toUpperCase()

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
      className="flex flex-1 flex-col items-center"
    >
      {/* Crown sits above #1, gently bobs */}
      {rank === 1 && entry && (
        <motion.div
          animate={{ y: [0, -3, 0], rotate: [0, 3, 0, -3, 0] }}
          transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
          className="mb-1 grid place-items-center"
          style={{
            width: 44, height: 36, borderRadius: 8,
            color: medal.base,
            filter: `drop-shadow(0 4px 10px ${medal.base}66)`,
          }}
        >
          <Crown className="w-9 h-9" strokeWidth={2.4} fill={medal.light} />
        </motion.div>
      )}

      {/* Avatar with depth */}
      <button
        type="button"
        onClick={entry && onClick ? () => onClick(entry) : undefined}
        disabled={!entry}
        aria-label={entry ? `${entry.fullName || entry.username}, rank ${rank}` : `Rank ${rank} unfilled`}
        className="group relative grid shrink-0 place-items-center rounded-full font-extrabold text-white disabled:cursor-default"
        style={{
          width: avatarSize,
          height: avatarSize,
          background: entry
            ? `radial-gradient(circle at 32% 28%, ${medal.light} 0%, ${medal.base} 55%, ${medal.dark} 100%)`
            : 'radial-gradient(circle at 50% 30%, #F1F5F9 0%, #E2E8F0 70%)',
          outline: isMe ? '3px solid #00167A' : 'none',
          outlineOffset: 2,
          boxShadow: entry
            ? `0 10px 22px ${medal.base}55, inset 0 -6px 10px rgba(0,0,0,0.18), inset 0 4px 10px rgba(255,255,255,0.30)`
            : 'inset 0 -4px 8px rgba(0,0,0,0.06), inset 0 2px 4px rgba(255,255,255,0.5)',
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
              fontSize: rank === 1 ? 32 : 24,
              color: entry ? '#FFFFFF' : '#BDBDBD',
              textShadow: entry ? '0 1px 2px rgba(0,0,0,0.22)' : 'none',
            }}
          >
            {initials}
          </span>
        )}
      </button>

      {/* Name + XP — fixed height so columns line up */}
      <div className="mt-3 min-h-[2.75rem] w-full max-w-[140px] text-center">
        <div
          className={`truncate font-body ${entry ? '' : 'opacity-50'}`}
          style={{
            fontSize: rank === 1 ? 15 : 13,
            fontWeight: 700,
            color: '#121212',
            lineHeight: '20px',
          }}
        >
          {entry?.fullName || entry?.username || '—'}
        </div>
        {entry && (
          <div
            className="font-body tabular-nums"
            style={{
              fontSize: 12, fontWeight: 600, color: '#545454', lineHeight: '16px',
              marginTop: 1,
            }}
          >
            {entry.totalExp.toLocaleString()} XP
          </div>
        )}
      </div>

      {/* 3D-looking pedestal — gradient body + inset darkening at the bottom +
          a lighter top edge to read as the front face of a block. */}
      <div
        className="relative mt-2 w-full max-w-[140px] flex items-start justify-center text-base font-extrabold text-white"
        style={{
          height,
          paddingTop: 8,
          borderRadius: '14px 14px 4px 4px',
          background: `linear-gradient(180deg, ${medal.light} 0%, ${medal.base} 45%, ${medal.dark} 100%)`,
          boxShadow: `
            inset 0 -16px 0 rgba(0,0,0,0.14),
            inset 0 6px 0 rgba(255,255,255,0.32),
            0 12px 24px rgba(0,0,0,0.10)
          `,
        }}
      >
        <span
          className="font-body"
          style={{
            fontFamily: 'var(--font-numeric)',
            fontSize: rank === 1 ? 40 : 32,
            fontWeight: 900, color: '#fff',
            lineHeight: 1,
            textShadow: '0 2px 4px rgba(0,0,0,0.25)',
          }}
        >
          {rank}
        </span>

        {/* Tiny shine highlight */}
        <span
          className="absolute pointer-events-none"
          style={{
            top: 6, left: 10, width: 18, height: 6, borderRadius: 99,
            background: 'rgba(255,255,255,0.35)',
            filter: 'blur(2px)',
          }}
        />
      </div>
    </motion.div>
  )
}
