/**
 * LeaderboardPage — pixel-faithful rebuild of Figma frame 49:2
 * ("Leaderboard 1", 1920 × 1201).
 *
 * Per the docx leaderboard section:
 *   - Current user gets a hero card with rank + XP + streak.
 *   - Period tabs: This Week / This Month (+ All Time, kept).
 *   - Class list sorted descending by XP; the current user row stays
 *     highlighted in cyan no matter where it falls.
 *
 * Layout:
 *   - Header (1680 × 135): big "Leaderboard" title, class pill, period tabs.
 *   - Body (1680, 2-col, gap 44):
 *       LEFT  (516): "Me" card — avatar + name + 3 stat tiles
 *                    (rank / XP / streak) + "X XP to go" to next rank.
 *       RIGHT (1104): podium for top 3 + ranked class list below.
 */
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ChevronDown, Flame } from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import { useLeaderboard } from './useLeaderboard'
import { useAuthStore } from '../../state/auth'
import { Podium, type PodiumEntry } from './Podium'
import type { LeaderboardPeriod } from '../../api/leaderboard'
import type { User } from '../../types/user'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const CARD_STROKE = '#E7E7E7'
const SURFACE_BG = '#FAFAFA'

// ---------------------------------------------------------------------------
export function LeaderboardPage() {
  const me = useAuthStore((s) => s.user)
  const [period, setPeriod] = useState<LeaderboardPeriod>('weekly')
  const lbQ = useLeaderboard({ period, limit: 100 })
  const navigate = useNavigate()

  const users = lbQ.data?.users ?? []
  const className = lbQ.data?.className ?? '10-A'

  // Find current user's rank + the user just above them
  const myIndex = users.findIndex((u) => u.id === me?.id)
  const myRank = myIndex >= 0 ? myIndex + 1 : 0
  const myXp = me?.totalExp ?? 0
  // Demo streak — backend doesn't ship a streak field; mock until it does.
  const myStreak = 1

  const aboveMe = myIndex > 0 ? users[myIndex - 1] : null
  const xpToNext = aboveMe ? Math.max(0, aboveMe.totalExp - myXp) : 0
  const nextRankPct = aboveMe && aboveMe.totalExp > 0
    ? Math.round((myXp / aboveMe.totalExp) * 100)
    : 100

  const top3: PodiumEntry[] = users.slice(0, 3).map((u) => ({
    id: u.id, fullName: u.fullName, username: u.username,
    firstName: u.firstName, totalExp: u.totalExp,
  }))

  if (!me) return null

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Leaderboard" testCount={1} />

      <main className="mx-auto" style={{ maxWidth: 1920, padding: '50px 120px 60px' }}>
        {/* Header */}
        <div className="flex flex-col items-center" style={{ gap: 24, marginBottom: 44 }}>
          <h1
            className="font-body"
            style={{
              fontSize: 44, fontWeight: 700, color: NAVY,
              lineHeight: '61px', letterSpacing: '-0.5px', margin: 0,
            }}
          >
            Leaderboard
          </h1>
          <div className="flex items-center" style={{ gap: 24 }}>
            <ClassPill name={`Class ${className}`} />
            <PeriodTabs active={period} onChange={setPeriod} />
          </div>
        </div>

        {/* Body */}
        <div className="flex" style={{ gap: 44 }}>
          {/* LEFT — me stats */}
          <MeCard
            user={me}
            rank={myRank}
            xp={myXp}
            streak={myStreak}
            xpToNext={xpToNext}
            nextRankPct={nextRankPct}
            aboveMe={aboveMe}
            className={className}
          />

          {/* RIGHT — podium + ranked list */}
          <section className="flex-1 flex flex-col" style={{ gap: 44 }}>
            <Podium
              entries={top3}
              meId={me.id}
              onClick={(e) => {
                if (e.id === me.id) navigate('/profile')
              }}
            />
            <RankedList
              users={users}
              myId={me.id}
              loading={lbQ.isLoading}
            />
          </section>
        </div>
      </main>
    </div>
  )
}

// ---------------------------------------------------------------------------
function ClassPill({ name }: { name: string }) {
  return (
    <div
      className="flex items-center bg-white"
      style={{
        height: 49, borderRadius: 50, padding: '12px 34px', gap: 8,
        border: '1px solid #EAEAEA',
      }}
    >
      <span
        className="font-body"
        style={{ fontSize: 18, fontWeight: 600, color: TXT_DARK, lineHeight: '25px' }}
      >
        {name}
      </span>
      <ChevronDown className="w-6 h-6" style={{ color: TXT_DARK }} strokeWidth={2.5} />
    </div>
  )
}

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
      style={{ height: 49, borderRadius: 52, padding: 0, border: '1px solid #EAEAEA' }}
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
              height: 49, borderRadius: 50, padding: '12px 34px',
              background: isActive ? NAVY : 'transparent',
              color: isActive ? '#fff' : TXT_MUTED,
              fontFamily: 'var(--font-body)', fontSize: 18, fontWeight: 600,
              lineHeight: '25px',
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
function MeCard({
  user, rank, xp, streak, xpToNext, nextRankPct, aboveMe, className,
}: {
  user: User
  rank: number
  xp: number
  streak: number
  xpToNext: number
  nextRankPct: number
  aboveMe: User | null
  className: string
}) {
  const initial = (user.firstName?.[0] ?? user.username?.[0] ?? 'U').toUpperCase()
  return (
    <motion.section
      className="bg-white flex flex-col"
      style={{
        width: 516, borderRadius: 24, padding: 30, gap: 24,
        boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
      }}
      initial={{ opacity: 0, x: -12 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
    >
      {/* Header: avatar + name */}
      <div className="flex items-center" style={{ gap: 14 }}>
        <div
          className="grid place-items-center shrink-0"
          style={{
            width: 84, height: 86, borderRadius: 999,
            background: `radial-gradient(circle at 32% 28%, #1F3DB8 0%, ${NAVY} 65%, #000A4A 100%)`,
            boxShadow: '0 8px 18px rgba(0,22,122,0.22)',
          }}
        >
          <span
            className="font-body"
            style={{ fontSize: 50, fontWeight: 600, color: '#fff', lineHeight: '54px' }}
          >
            {initial}
          </span>
        </div>
        <div className="flex flex-col" style={{ gap: 4 }}>
          <span
            className="font-body capitalize"
            style={{ fontSize: 26, fontWeight: 700, color: TXT_DARK, lineHeight: '36px' }}
          >
            {user.firstName || user.username}
          </span>
          <span
            className="font-body"
            style={{ fontSize: 16, fontWeight: 400, color: TXT_MID, lineHeight: '22px' }}
          >
            Class {className} · GyanBuddy Student
          </span>
        </div>
      </div>

      {/* 3 stat tiles */}
      <div className="grid grid-cols-3" style={{ gap: 24 }}>
        <StatTile label="Rank"   value={`#${rank}`} />
        <StatTile label="XP"     value={`${xp}`} />
        <StatTile label="Streak" value={`${streak}`} icon={<Flame className="w-4 h-4" style={{ color: '#F97316' }} strokeWidth={2.5} />} />
      </div>

      {/* Progress to next rank */}
      <div className="flex flex-col" style={{ gap: 4 }}>
        <div className="flex items-center" style={{ gap: 10 }}>
          <div
            className="flex-1"
            style={{ height: 8, borderRadius: 14, background: '#F1F1F1', overflow: 'hidden' }}
          >
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${nextRankPct}%` }}
              transition={{ duration: 0.9, ease: 'easeOut' }}
              style={{ height: '100%', borderRadius: 14, background: CYAN }}
            />
          </div>
          <span
            className="font-body tabular-nums"
            style={{ fontSize: 20, fontWeight: 700, color: TXT_DARK, lineHeight: '28px' }}
          >
            {xpToNext > 0 ? `${xpToNext} XP to go` : 'Top'}
          </span>
        </div>
        {aboveMe && (
          <span
            className="font-body"
            style={{ fontSize: 16, fontWeight: 400, color: TXT_MID, lineHeight: '22px' }}
          >
            Next rank: #{rank - 1} · {aboveMe.firstName || aboveMe.username} ({aboveMe.totalExp} XP)
          </span>
        )}
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
        height: 106, borderRadius: 24,
        border: `1px solid ${CARD_STROKE}`,
        padding: '12px 26px',
      }}
    >
      <div className="flex items-center" style={{ gap: 6 }}>
        {icon}
        <span
          className="font-body tabular-nums"
          style={{ fontSize: 44, fontWeight: 800, color: NAVY, lineHeight: '54px' }}
        >
          {value}
        </span>
      </div>
      <span
        className="font-body"
        style={{
          fontSize: 14, fontWeight: 600, color: TXT_MUTED, lineHeight: '20px',
          letterSpacing: '0.04em', textTransform: 'uppercase',
        }}
      >
        {label}
      </span>
    </div>
  )
}

// ---------------------------------------------------------------------------
function RankedList({
  users, myId, loading,
}: {
  users: User[]; myId: string; loading: boolean
}) {
  // Below-podium ranks (4+) — the podium covers 1-3
  const rest = users.slice(3)

  return (
    <section
      className="bg-white"
      style={{
        borderRadius: 24, padding: 30,
        border: `1px solid ${CARD_STROKE}`,
        boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
      }}
    >
      <div
        className="grid place-items-center"
        style={{
          background: NAVY, color: '#fff', borderRadius: 1000,
          padding: '12px 24px', height: 72, marginBottom: 24,
          fontFamily: 'var(--font-body)', fontSize: 18, fontWeight: 700, lineHeight: '25px',
          letterSpacing: '0.04em', textTransform: 'uppercase',
        }}
      >
        Top of the Class
      </div>
      {loading && (
        <div className="flex flex-col" style={{ gap: 8 }}>
          {Array.from({ length: 6 }).map((_, i) => (
            <div
              key={i}
              className="animate-pulse"
              style={{ height: 72, borderRadius: 24, background: '#F1F1F1' }}
            />
          ))}
        </div>
      )}
      {!loading && rest.length === 0 && (
        <div
          className="grid place-items-center"
          style={{ minHeight: 120, color: TXT_MUTED }}
        >
          No additional ranks yet.
        </div>
      )}
      {!loading && rest.length > 0 && (
        <ul className="flex flex-col" style={{ gap: 8 }}>
          {rest.map((u, i) => (
            <LeaderRow
              key={u.id}
              user={u}
              rank={i + 4}
              isMe={u.id === myId}
            />
          ))}
        </ul>
      )}
    </section>
  )
}

function LeaderRow({
  user, rank, isMe,
}: {
  user: User; rank: number; isMe: boolean
}) {
  const initial = (user.firstName?.[0] ?? user.username?.[0] ?? 'U').toUpperCase()
  return (
    <motion.li
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25 }}
      className="flex items-center"
      style={{
        height: 72, borderRadius: 24, padding: '12px 24px', gap: 24,
        background: isMe ? CYAN : 'transparent',
        border: `1px solid ${isMe ? CYAN : CARD_STROKE}`,
      }}
    >
      <div className="flex items-center flex-1" style={{ gap: 14 }}>
        <span
          className="font-body tabular-nums text-center shrink-0"
          style={{
            width: 32, fontSize: 20, fontWeight: 700, lineHeight: '28px',
            color: isMe ? '#fff' : TXT_DARK,
          }}
        >
          {rank}
        </span>
        <div
          className="grid place-items-center shrink-0"
          style={{
            width: 43, height: 44, borderRadius: 999,
            background: isMe ? '#fff' : NAVY,
          }}
        >
          <span
            className="font-body"
            style={{
              fontSize: 20, fontWeight: 700, lineHeight: '28px',
              color: isMe ? NAVY : '#fff',
            }}
          >
            {initial}
          </span>
        </div>
        <span
          className="font-body truncate"
          style={{
            fontSize: 20, fontWeight: 600, lineHeight: '28px',
            color: isMe ? '#fff' : TXT_DARK,
          }}
        >
          {user.fullName || user.username}
        </span>
        {isMe && (
          <span
            className="grid place-items-center shrink-0"
            style={{
              height: 30, borderRadius: 42, padding: '4px 12px',
              background: NAVY, color: '#fff',
              fontFamily: 'var(--font-body)', fontSize: 16, fontWeight: 700, lineHeight: '22px',
            }}
          >
            You
          </span>
        )}
      </div>
      <div className="flex flex-col items-end leading-none">
        <span
          className="font-body tabular-nums"
          style={{
            fontSize: 20, fontWeight: 600, lineHeight: '28px',
            color: isMe ? '#fff' : TXT_DARK,
          }}
        >
          {user.totalExp.toLocaleString()}
        </span>
        <span
          className="font-body"
          style={{
            fontSize: 14, fontWeight: 400, lineHeight: '19px', marginTop: 1,
            color: isMe ? 'rgba(255,255,255,0.8)' : TXT_MID,
          }}
        >
          XP
        </span>
      </div>
    </motion.li>
  )
}
