/**
 * PodiumPage — the visual top-3 trophy/pedestal screen accessed from the
 * sidebar (labelled "Leaderboard" in the UI). Was the original
 * LeaderboardPage built against Figma frame 49:2. The flat ranked-list
 * version that the quiz lands on now lives in LeaderboardPage.tsx.
 *
 * Layout (matches the Figma frame container hierarchy):
 *
 *   <TopBar hideBack />                           // no back arrow on this frame
 *   <main>
 *     <h1>Leaderboard</h1>                        // compact, centred
 *     <Filters>                                   // class pill + period tabs
 *
 *     <BodyRow>
 *       <MeCard />                                // left, ~366px
 *       <PodiumCard>                              // centre, single navy card
 *         <img src="leaderboard-podium.png" />   // hero illustration
 *         <FloatingRankList />                    // white panel overlapping
 *       </PodiumCard>
 *       <MostActiveWidget />                      // right, ~330px
 *     </BodyRow>
 *   </main>
 *
 * Notes on intentional differences from the previous build:
 *  - Podium + ranked list are ONE unified card (Figma had them merged).
 *  - The hero podium illustration is the Figma asset itself — names baked in.
 *  - "TOP OF THE CLASS" pill header is removed (not in Figma).
 *  - Me card no longer shows the user's name above the class subtitle.
 *  - Top-right of each side card has an outbound-arrow "open" affordance.
 */
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ChevronDown, Flame, TrendingUp, TrendingDown, Minus, ArrowUpRight, Check,
} from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import { useLeaderboard } from './useLeaderboard'
import { useAuthStore } from '../../state/auth'
import {
  deriveStreak, deriveWeeklyDelta, formatDelta,
} from '../../lib/derived-metrics'
import type { LeaderboardPeriod } from '../../api/leaderboard'
import type { User } from '../../types/user'

const NAVY = '#00167A'
const NAVY_DEEP = '#001B7A' // podium card body
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const CARD_STROKE = '#E7E7E7'
const SURFACE_BG = '#FAFAFA'

// Avatar colours for podium-list rows (cycled deterministically by rank).
// Matches the Figma colour swatches at ranks 1..5.
const AVATAR_COLOURS = ['#3A6FF8', '#FB923C', '#F5B400', '#22C55E', '#7C3AED']

// ---------------------------------------------------------------------------
export function PodiumPage() {
  const me = useAuthStore((s) => s.user)
  const [period, setPeriod] = useState<LeaderboardPeriod>('weekly')
  const lbQ = useLeaderboard({ period, limit: 100 })
  const navigate = useNavigate()

  const users = lbQ.data?.users ?? []
  const className = lbQ.data?.className ?? '10-A'

  const myIndex = users.findIndex((u) => u.id === me?.id)
  const myRank = myIndex >= 0 ? myIndex + 1 : 0
  const myXp = me?.totalExp ?? 0
  const myStreak = 1

  const aboveMe = myIndex > 0 ? users[myIndex - 1] : null
  const xpToNext = aboveMe ? Math.max(0, aboveMe.totalExp - myXp) : 0
  const nextRankPct = aboveMe && aboveMe.totalExp > 0
    ? Math.round((myXp / aboveMe.totalExp) * 100)
    : 100

  if (!me) return null

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Leaderboard" testCount={1} hideBack />

      <main
        className="mx-auto w-full"
        style={{
          maxWidth: 1680,
          padding: 'clamp(20px, 3vw, 32px) clamp(16px, 4vw, 64px) clamp(40px, 5vw, 60px)',
        }}
      >
        {/* Header — compact title + filters, tight spacing */}
        <div className="flex flex-col items-center" style={{ gap: 18, marginBottom: 28 }}>
          <h1
            className="font-body"
            style={{
              fontSize: 'clamp(28px, 3vw, 40px)', fontWeight: 700, color: NAVY,
              lineHeight: '1.2', letterSpacing: '-0.5px', margin: 0,
            }}
          >
            Leaderboard
          </h1>
          <div className="flex items-center flex-wrap justify-center" style={{ gap: 12 }}>
            <ClassPill name={`Class ${className}`} />
            <PeriodTabs active={period} onChange={setPeriod} />
          </div>
        </div>

        {/*
          Body — responsive layout:
            < 1024px : single column, Podium → Me → MostActive (stacked)
            >= 1024px: THREE columns side-by-side: Me | Podium | MostActive
                       (everything visible above the fold on a normal laptop)
          Each child is min-w-0 so children never force the parent wider
          than its grid cell.
        */}
        <div
          className="grid items-start mx-auto grid-cols-1 lg:grid-cols-[minmax(240px,1fr)_minmax(380px,1.6fr)_minmax(240px,1fr)]"
          style={{
            gap: 'clamp(16px, 1.6vw, 24px)',
            maxWidth: 1500,
          }}
        >
          {/* On wide screens, Me is in the left column. On narrow screens,
              the wrapper below the Podium hosts it. */}
          <div className="hidden lg:block min-w-0">
            <MeCard
              user={me}
              rank={myRank}
              xp={myXp}
              streak={myStreak}
              xpToNext={xpToNext}
              nextRankPct={nextRankPct}
              aboveMe={aboveMe}
              className={className}
              onOpen={() => navigate('/profile')}
            />
          </div>

          <div className="min-w-0">
            <PodiumCard
              users={users}
              myId={me.id}
              loading={lbQ.isLoading}
            />
          </div>

          <div className="hidden lg:block min-w-0">
            <MostActiveWidget users={users} meId={me.id} />
          </div>

          {/* Below-podium slot for narrow viewports only. */}
          <div
            className="lg:hidden grid"
            style={{
              gap: 'clamp(16px, 2vw, 24px)',
              gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
            }}
          >
            <MeCard
              user={me}
              rank={myRank}
              xp={myXp}
              streak={myStreak}
              xpToNext={xpToNext}
              nextRankPct={nextRankPct}
              aboveMe={aboveMe}
              className={className}
              onOpen={() => navigate('/profile')}
            />
            <MostActiveWidget users={users} meId={me.id} />
          </div>
        </div>
      </main>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Class pill — dropdown of sibling classes. Backend only exposes the
// student's own class today; UI affordance with mock options until the API
// catches up.
// ---------------------------------------------------------------------------
const CLASS_OPTIONS = ['10-A', '10-B', '10-C', '9-A', '9-B']

function ClassPill({ name }: { name: string }) {
  const [open, setOpen] = useState(false)
  const [selected, setSelected] = useState(name)
  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex items-center bg-white"
        style={{
          height: 42, borderRadius: 999, padding: '10px 22px', gap: 8,
          border: `1px solid ${open ? CYAN : '#EAEAEA'}`,
          transition: 'border-color 0.18s ease',
        }}
      >
        <span
          className="font-body"
          style={{ fontSize: 15, fontWeight: 600, color: TXT_DARK, lineHeight: '20px' }}
        >
          {selected}
        </span>
        <ChevronDown
          className="w-4 h-4 transition-transform"
          style={{
            color: TXT_DARK,
            transform: open ? 'rotate(180deg)' : 'none',
          }}
          strokeWidth={2.5}
        />
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: -4, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -4, scale: 0.98 }}
            transition={{ duration: 0.18, ease: 'easeOut' }}
            className="absolute z-20 bg-white"
            style={{
              top: 50, left: 0, minWidth: 180,
              borderRadius: 16, padding: 6,
              border: '1px solid #EAEAEA',
              boxShadow: '0 18px 40px rgba(0,0,0,0.12)',
            }}
            role="listbox"
          >
            {CLASS_OPTIONS.map((opt) => {
              const isActive = opt === selected
              return (
                <button
                  key={opt}
                  type="button"
                  onClick={() => { setSelected(opt); setOpen(false) }}
                  className="w-full flex items-center text-left"
                  style={{
                    padding: '8px 12px', gap: 10, borderRadius: 10,
                    background: isActive ? '#F0F4FF' : 'transparent',
                    color: isActive ? NAVY : TXT_DARK,
                    fontFamily: 'var(--font-body)', fontSize: 14, fontWeight: 600,
                  }}
                  onMouseEnter={(e) => {
                    if (!isActive) e.currentTarget.style.background = '#F8FAFC'
                  }}
                  onMouseLeave={(e) => {
                    if (!isActive) e.currentTarget.style.background = 'transparent'
                  }}
                >
                  <span className="flex-1">{opt}</span>
                  {isActive && <Check className="w-4 h-4" style={{ color: NAVY }} strokeWidth={2.5} />}
                </button>
              )
            })}
          </motion.div>
        )}
      </AnimatePresence>

      {open && (
        <div
          className="fixed inset-0 z-10"
          onClick={() => setOpen(false)}
          aria-hidden="true"
        />
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
const PERIODS: { id: LeaderboardPeriod; label: string }[] = [
  { id: 'weekly',   label: 'This Week' },
  { id: 'monthly',  label: 'This Month' },
  { id: 'all-time', label: 'All Time' },
]

function PeriodTabs({
  active, onChange,
}: {
  active: LeaderboardPeriod; onChange: (p: LeaderboardPeriod) => void
}) {
  return (
    <div
      className="flex bg-white"
      style={{ height: 42, borderRadius: 999, padding: 0, border: '1px solid #EAEAEA' }}
    >
      {PERIODS.map((p) => {
        const isActive = p.id === active
        return (
          <button
            key={p.id}
            type="button"
            onClick={() => onChange(p.id)}
            className="grid place-items-center"
            style={{
              height: 42, borderRadius: 999, padding: '8px 24px',
              background: isActive ? NAVY : 'transparent',
              color: isActive ? '#fff' : TXT_MUTED,
              fontFamily: 'var(--font-body)', fontSize: 15, fontWeight: 600,
              lineHeight: '20px',
              boxShadow: isActive ? '0 4px 12px rgba(0,22,122,0.18)' : 'none',
            }}
          >
            {p.label}
          </button>
        )
      })}
    </div>
  )
}

// ---------------------------------------------------------------------------
// MeCard — Figma left column. No big name above the class subtitle (the
// Figma frame doesn't render one); just avatar + class line + 3 stat tiles +
// progress to next rank, with a top-right "open" arrow affordance.
// ---------------------------------------------------------------------------
function MeCard({
  user, rank, xp, streak, xpToNext, nextRankPct, aboveMe, className, onOpen,
}: {
  user: User
  rank: number
  xp: number
  streak: number
  xpToNext: number
  nextRankPct: number
  aboveMe: User | null
  className: string
  onOpen: () => void
}) {
  const initial = (user.firstName?.[0] ?? user.username?.[0] ?? 'U').toUpperCase()
  return (
    <motion.section
      className="bg-white flex flex-col relative w-full"
      style={{
        borderRadius: 24, padding: 24, gap: 22,
        boxShadow: '0 6px 22px rgba(0,0,0,0.06)',
        minWidth: 0,
      }}
      initial={{ opacity: 0, x: -12 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
    >
      {/* Top-right open-arrow */}
      <button
        type="button"
        aria-label="Open profile"
        onClick={onOpen}
        className="absolute grid place-items-center"
        style={{
          top: 16, right: 16, width: 30, height: 30, borderRadius: 10,
          background: '#F4F6FB', color: NAVY,
        }}
      >
        <ArrowUpRight className="w-4 h-4" strokeWidth={2.4} />
      </button>

      {/* Avatar + class subtitle */}
      <div className="flex items-center" style={{ gap: 12 }}>
        <div
          className="grid place-items-center shrink-0"
          style={{
            width: 58, height: 58, borderRadius: 999,
            background: `radial-gradient(circle at 32% 28%, #1F3DB8 0%, ${NAVY} 65%, #000A4A 100%)`,
            boxShadow: '0 8px 18px rgba(0,22,122,0.22)',
          }}
        >
          <span
            className="font-body"
            style={{ fontSize: 28, fontWeight: 700, color: '#fff', lineHeight: '32px' }}
          >
            {initial}
          </span>
        </div>
        <div className="flex flex-col leading-tight" style={{ paddingRight: 36 }}>
          <span
            className="font-body"
            style={{ fontSize: 14, fontWeight: 500, color: TXT_MID, lineHeight: '20px' }}
          >
            Class {className} · GyanBuddy Student
          </span>
        </div>
      </div>

      {/* 3 stat tiles */}
      <div className="grid grid-cols-3" style={{ gap: 12 }}>
        <StatTile label="Rank"   value={`#${rank}`} />
        <StatTile label="XP"     value={`${xp}`} />
        <StatTile
          label="Streak"
          value={`${streak}`}
          icon={<Flame className="w-4 h-4" style={{ color: '#F97316' }} strokeWidth={2.5} />}
        />
      </div>

      {/* Progress to next rank */}
      <div className="flex flex-col" style={{ gap: 8 }}>
        <div
          style={{
            height: 8, borderRadius: 14, background: '#F1F1F1', overflow: 'hidden',
          }}
        >
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${nextRankPct}%` }}
            transition={{ duration: 0.9, ease: 'easeOut' }}
            style={{ height: '100%', borderRadius: 14, background: CYAN }}
          />
        </div>
        <div className="flex items-center justify-between">
          <span
            className="font-body"
            style={{ fontSize: 13, fontWeight: 500, color: TXT_MID, lineHeight: '18px' }}
          >
            {aboveMe
              ? `Next rank: #${rank - 1} · ${aboveMe.firstName || aboveMe.username} (${aboveMe.totalExp} XP)`
              : "You're at the top"}
          </span>
          {xpToNext > 0 && (
            <span
              className="font-body tabular-nums"
              style={{ fontSize: 14, fontWeight: 700, color: NAVY, lineHeight: '18px' }}
            >
              {xpToNext} XP to go
            </span>
          )}
        </div>
      </div>
    </motion.section>
  )
}

function StatTile({
  label, value, icon,
}: {
  label: string; value: string; icon?: React.ReactNode
}) {
  return (
    <div
      className="flex flex-col items-center justify-center bg-white"
      style={{
        minHeight: 86, borderRadius: 16,
        border: `1px solid ${CARD_STROKE}`,
        padding: '10px 12px',
      }}
    >
      <div className="flex items-center" style={{ gap: 4 }}>
        {icon}
        <span
          className="font-body tabular-nums"
          style={{ fontSize: 30, fontWeight: 800, color: NAVY, lineHeight: '36px' }}
        >
          {value}
        </span>
      </div>
      <span
        className="font-body"
        style={{
          fontSize: 11, fontWeight: 600, color: TXT_MUTED, lineHeight: '16px',
          letterSpacing: '0.06em', textTransform: 'uppercase',
        }}
      >
        {label}
      </span>
    </div>
  )
}

// ---------------------------------------------------------------------------
// PodiumCard — ONE unified container. Navy backdrop, hero illustration on
// top half, floating white rank-list panel overlapping the bottom half.
// ---------------------------------------------------------------------------
function PodiumCard({
  users, myId, loading,
}: {
  users: User[]; myId: string; loading: boolean
}) {
  const top5 = users.slice(0, 5)
  return (
    <motion.section
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
      className="relative overflow-hidden w-full mx-auto"
      style={{
        maxWidth: 720,
        minWidth: 0,
        borderRadius: 24,
        background: NAVY_DEEP,
        boxShadow: '0 18px 36px rgba(0,22,122,0.18)',
      }}
    >
      {/* Hero illustration — natural aspect ratio of the PNG (~600x400,
          all three pedestals + trophy + names visible). object-fit:
          contain inside a flexible-height container lets the image scale
          with the card width but never crop. */}
      <div className="relative w-full grid place-items-center" style={{ padding: '12px 12px 0' }}>
        <img
          src="/images/figma/leaderboard-podium.png"
          alt=""
          className="block w-full h-auto select-none"
          draggable={false}
          style={{ maxWidth: 540 }}
        />
      </div>

      {/* Ranked-list panel — sits BELOW the image (no negative margin
          overlap any more, that was hiding pedestals #2 and #3). */}
      <div
        className="relative bg-white"
        style={{
          margin: '12px 14px 14px',
          borderRadius: 18,
          padding: '12px 14px',
          boxShadow: '0 18px 40px rgba(0,0,0,0.10)',
        }}
      >
        {loading ? (
          <div className="flex flex-col" style={{ gap: 6 }}>
            {Array.from({ length: 5 }).map((_, i) => (
              <div
                key={i}
                className="animate-pulse"
                style={{ height: 62, borderRadius: 14, background: '#F1F1F1' }}
              />
            ))}
          </div>
        ) : top5.length === 0 ? (
          <div
            className="grid place-items-center"
            style={{ minHeight: 100, color: TXT_MUTED }}
          >
            No ranks yet.
          </div>
        ) : (
          <ul className="flex flex-col" style={{ gap: 4 }}>
            {top5.map((u, i) => (
              <PodiumRow
                key={u.id}
                user={u}
                rank={i + 1}
                isMe={u.id === myId}
                isLeader={i === 0}
              />
            ))}
          </ul>
        )}
      </div>
    </motion.section>
  )
}

function PodiumRow({
  user, rank, isMe, isLeader,
}: {
  user: User; rank: number; isMe: boolean; isLeader: boolean
}) {
  const initial = (user.firstName?.[0] ?? user.username?.[0] ?? 'U').toUpperCase()
  const streak = deriveStreak(user.id)
  const delta = formatDelta(deriveWeeklyDelta(user.id))
  const avatarColour = AVATAR_COLOURS[(rank - 1) % AVATAR_COLOURS.length]
  const highlight = isLeader || isMe

  return (
    <motion.li
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay: (rank - 1) * 0.04 }}
      className="flex items-center"
      style={{
        minHeight: 56, padding: '8px 12px', gap: 12,
        borderRadius: 12,
        background: highlight
          ? `linear-gradient(90deg, ${CYAN} 0%, #5FD4FF 100%)`
          : 'transparent',
      }}
    >
      <span
        className="font-body tabular-nums text-center shrink-0"
        style={{
          width: 22, fontSize: 16, fontWeight: 700, lineHeight: '22px',
          color: highlight ? '#fff' : TXT_MID,
        }}
      >
        {rank}
      </span>
      <div
        className="grid place-items-center shrink-0"
        style={{
          width: 38, height: 38, borderRadius: 999,
          background: highlight ? '#fff' : avatarColour,
        }}
      >
        <span
          className="font-body"
          style={{
            fontSize: 16, fontWeight: 700, lineHeight: '22px',
            color: highlight ? NAVY : '#fff',
          }}
        >
          {initial}
        </span>
      </div>
      <div className="flex flex-col flex-1 min-w-0 leading-tight">
        <span
          className="font-body truncate"
          style={{
            fontSize: 15, fontWeight: 700, lineHeight: '20px',
            color: highlight ? '#fff' : TXT_DARK,
          }}
        >
          {user.fullName || user.username}
        </span>
        <span
          className="font-body"
          style={{
            fontSize: 12, fontWeight: 500, lineHeight: '16px',
            color: highlight ? 'rgba(255,255,255,0.85)' : TXT_MID,
          }}
        >
          {streak} day{streak === 1 ? '' : 's'} streak
        </span>
      </div>
      <div className="flex flex-col items-end leading-tight shrink-0">
        <span
          className="font-body tabular-nums"
          style={{
            fontSize: 16, fontWeight: 800, lineHeight: '22px',
            color: highlight ? '#fff' : TXT_DARK,
          }}
        >
          {user.totalExp.toLocaleString()}{' '}
          <span
            style={{
              fontSize: 11, fontWeight: 600,
              color: highlight ? 'rgba(255,255,255,0.85)' : TXT_MID,
            }}
          >
            XP
          </span>
        </span>
        <DeltaPill tone={delta.tone} text={delta.text} onCyan={highlight} />
      </div>
    </motion.li>
  )
}

function DeltaPill({
  tone, text, onCyan,
}: {
  tone: 'up' | 'down' | 'flat'; text: string; onCyan: boolean
}) {
  const palette = onCyan
    ? {
        up:   { fg: '#fff', strong: '#fff' },
        down: { fg: '#fff', strong: '#FFD2D2' },
        flat: { fg: 'rgba(255,255,255,0.85)', strong: 'rgba(255,255,255,0.85)' },
      }
    : {
        up:   { fg: '#15803D', strong: '#15803D' },
        down: { fg: '#B91C1C', strong: '#B91C1C' },
        flat: { fg: TXT_MID,   strong: TXT_MID },
      }
  const Icon = tone === 'up' ? TrendingUp : tone === 'down' ? TrendingDown : Minus
  const c = palette[tone]
  return (
    <span
      className="inline-flex items-center"
      style={{
        marginTop: 2, gap: 3,
        color: c.fg,
        fontFamily: 'var(--font-body)', fontSize: 11, fontWeight: 700,
        lineHeight: '14px',
      }}
    >
      <Icon className="w-3 h-3" strokeWidth={3} style={{ color: c.strong }} />
      {text}
    </span>
  )
}

// ---------------------------------------------------------------------------
// MostActiveWidget — Figma right column. Top 4 by total XP from the
// leaderboard. Row 1 (leader) gets cyan highlight + "Rising fast" tag,
// rows 2-4 get derived weekly delta in green.
// ---------------------------------------------------------------------------
function MostActiveWidget({ users, meId }: { users: User[]; meId: string }) {
  const top4 = users.slice(0, 4)
  if (top4.length === 0) return null
  return (
    <motion.aside
      initial={{ opacity: 0, x: 12 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
      className="bg-white flex flex-col relative w-full"
      style={{
        minWidth: 0, borderRadius: 24, padding: '20px 18px', gap: 14,
        boxShadow: '0 6px 22px rgba(0,0,0,0.06)',
      }}
    >
      <button
        type="button"
        aria-label="Open full list"
        className="absolute grid place-items-center"
        style={{
          top: 16, right: 16, width: 30, height: 30, borderRadius: 10,
          background: '#F4F6FB', color: NAVY,
        }}
      >
        <ArrowUpRight className="w-4 h-4" strokeWidth={2.4} />
      </button>

      <h3
        className="font-body"
        style={{ fontSize: 16, fontWeight: 700, color: TXT_DARK, lineHeight: '22px', margin: 0, paddingRight: 36 }}
      >
        Most Active This Week
      </h3>

      <ul className="flex flex-col" style={{ gap: 6 }}>
        {top4.map((u, i) => {
          const rank = i + 1
          const isLeader = i === 0
          const isMe = u.id === meId
          const initial = (u.firstName?.[0] ?? u.username?.[0] ?? 'U').toUpperCase()
          const streak = deriveStreak(u.id)
          const delta = deriveWeeklyDelta(u.id)
          const avatarColour = AVATAR_COLOURS[(rank - 1) % AVATAR_COLOURS.length]
          return (
            <li
              key={u.id}
              className="flex items-center"
              style={{
                gap: 10, padding: '8px 10px', borderRadius: 14,
                background: isLeader
                  ? `linear-gradient(90deg, ${CYAN} 0%, #5FD4FF 100%)`
                  : 'transparent',
              }}
            >
              <span
                className="font-body tabular-nums text-center shrink-0"
                style={{
                  width: 18, fontSize: 13, fontWeight: 700,
                  color: isLeader ? '#fff' : TXT_MID,
                }}
              >
                {rank}
              </span>
              <div
                className="grid place-items-center shrink-0"
                style={{
                  width: 32, height: 32, borderRadius: 999,
                  background: isLeader ? '#fff' : avatarColour,
                }}
              >
                <span
                  className="font-body"
                  style={{
                    fontSize: 13, fontWeight: 700,
                    color: isLeader ? NAVY : '#fff',
                  }}
                >
                  {initial}
                </span>
              </div>
              <div className="flex flex-col flex-1 min-w-0 leading-tight">
                <span
                  className="font-body truncate"
                  style={{
                    fontSize: 13, fontWeight: 700,
                    color: isLeader ? '#fff' : TXT_DARK, lineHeight: '18px',
                  }}
                >
                  {u.fullName || u.username}{isMe ? ' (You)' : ''}
                </span>
                <span
                  className="font-body"
                  style={{
                    fontSize: 11, fontWeight: 500,
                    color: isLeader ? 'rgba(255,255,255,0.85)' : TXT_MID,
                    lineHeight: '15px',
                  }}
                >
                  {isLeader ? 'Rising fast 🔥' : `${streak} day streak`}
                </span>
              </div>
              {!isLeader && delta > 0 && (
                <span
                  className="font-body tabular-nums shrink-0"
                  style={{
                    fontSize: 13, fontWeight: 700, color: '#15803D',
                  }}
                >
                  +{delta} XP
                </span>
              )}
            </li>
          )
        })}
      </ul>
    </motion.aside>
  )
}
