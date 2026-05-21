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
import { motion, AnimatePresence } from 'framer-motion'
import {
  ChevronDown, Flame, TrendingUp, TrendingDown, Minus, Sparkles, Check,
} from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import { useLeaderboard } from './useLeaderboard'
import { useAuthStore } from '../../state/auth'
import { Podium, type PodiumEntry } from './Podium'
import {
  deriveStreak, deriveWeeklyDelta, formatDelta,
} from '../../lib/derived-metrics'
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

          {/* CENTER — podium + ranked list */}
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

          {/* RIGHT — Most Active This Week */}
          <MostActiveWidget users={users} meId={me.id} />
        </div>
      </main>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Backend only returns the student's own class today; the dropdown is a
// UI affordance with a few sibling-class names available. When the API
// ships a real list we read from there.
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
          height: 49, borderRadius: 50, padding: '12px 34px', gap: 8,
          border: `1px solid ${open ? CYAN : '#EAEAEA'}`,
          transition: 'border-color 0.18s ease',
        }}
      >
        <span
          className="font-body"
          style={{ fontSize: 18, fontWeight: 600, color: TXT_DARK, lineHeight: '25px' }}
        >
          {selected}
        </span>
        <ChevronDown
          className="w-6 h-6 transition-transform"
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
              top: 56, left: 0, minWidth: 200,
              borderRadius: 18, padding: 6,
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
                    padding: '10px 14px', gap: 10, borderRadius: 12,
                    background: isActive ? '#F0F4FF' : 'transparent',
                    color: isActive ? NAVY : TXT_DARK,
                    fontFamily: 'var(--font-body)', fontSize: 16, fontWeight: 600,
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
  const streak = deriveStreak(user.id)
  const delta = formatDelta(deriveWeeklyDelta(user.id))

  const onTone = isMe
    ? { color: '#fff', subColor: 'rgba(255,255,255,0.8)' }
    : { color: TXT_DARK, subColor: TXT_MID }

  return (
    <motion.li
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25 }}
      className="flex items-center"
      style={{
        minHeight: 76, borderRadius: 24, padding: '12px 24px', gap: 18,
        background: isMe ? CYAN : 'transparent',
        border: `1px solid ${isMe ? CYAN : CARD_STROKE}`,
      }}
    >
      <span
        className="font-body tabular-nums text-center shrink-0"
        style={{
          width: 28, fontSize: 20, fontWeight: 700, lineHeight: '28px',
          color: onTone.color,
        }}
      >
        {rank}
      </span>
      <div
        className="grid place-items-center shrink-0"
        style={{
          width: 44, height: 44, borderRadius: 999,
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
      <div className="flex flex-col flex-1 min-w-0 leading-tight">
        <div className="flex items-center" style={{ gap: 8 }}>
          <span
            className="font-body truncate"
            style={{
              fontSize: 18, fontWeight: 600, lineHeight: '24px', color: onTone.color,
            }}
          >
            {user.fullName || user.username}
          </span>
          {isMe && (
            <span
              className="grid place-items-center shrink-0"
              style={{
                height: 24, borderRadius: 999, padding: '2px 10px',
                background: NAVY, color: '#fff',
                fontFamily: 'var(--font-body)', fontSize: 12, fontWeight: 700,
                letterSpacing: '0.04em', textTransform: 'uppercase',
              }}
            >
              You
            </span>
          )}
        </div>
        <span
          className="font-body"
          style={{
            fontSize: 13, fontWeight: 500, lineHeight: '18px',
            color: onTone.subColor,
          }}
        >
          {streak} day{streak === 1 ? '' : 's'} streak
        </span>
      </div>
      <div className="flex flex-col items-end leading-none shrink-0">
        <span
          className="font-body tabular-nums"
          style={{
            fontSize: 20, fontWeight: 700, lineHeight: '28px', color: onTone.color,
          }}
        >
          {user.totalExp.toLocaleString()} <span style={{ fontSize: 13, fontWeight: 500, color: onTone.subColor }}>XP</span>
        </span>
        <DeltaPill tone={delta.tone} text={delta.text} onCyan={isMe} />
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
        up:   { bg: 'rgba(255,255,255,0.20)', fg: '#fff' },
        down: { bg: 'rgba(255,255,255,0.20)', fg: '#fff' },
        flat: { bg: 'rgba(255,255,255,0.16)', fg: 'rgba(255,255,255,0.85)' },
      }
    : {
        up:   { bg: '#DCFCE7', fg: '#15803D' },
        down: { bg: '#FFE2E2', fg: '#B91C1C' },
        flat: { bg: '#F1F5F9', fg: TXT_MID },
      }
  const Icon = tone === 'up' ? TrendingUp : tone === 'down' ? TrendingDown : Minus
  const c = palette[tone]
  return (
    <span
      className="inline-flex items-center"
      style={{
        marginTop: 4, padding: '2px 8px', borderRadius: 999, gap: 4,
        background: c.bg, color: c.fg,
        fontFamily: 'var(--font-body)', fontSize: 12, fontWeight: 700,
        lineHeight: '16px',
      }}
    >
      <Icon className="w-3 h-3" strokeWidth={2.5} />
      {text}
    </span>
  )
}

// ---------------------------------------------------------------------------
// Most Active This Week — Figma right-column widget. Sorts by weekly delta
// descending, takes the top 4. Highlights the leader with a "Rising fast 🔥".
// ---------------------------------------------------------------------------
function MostActiveWidget({ users, meId }: { users: User[]; meId: string }) {
  // Score each non-podium user by their derived weekly gain, take top 4
  const scored = users
    .slice(3)
    .map((u, i) => ({
      user: u,
      rank: i + 4,
      delta: deriveWeeklyDelta(u.id),
      streak: deriveStreak(u.id),
    }))
    .filter((x) => x.delta > 0)
    .sort((a, b) => b.delta - a.delta)
    .slice(0, 4)

  if (scored.length === 0) return null

  return (
    <aside
      className="bg-white flex flex-col shrink-0"
      style={{
        width: 320, borderRadius: 24, padding: '24px 20px', gap: 18,
        border: `1px solid ${CARD_STROKE}`,
        boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
        alignSelf: 'flex-start',
      }}
    >
      <div className="flex items-center justify-between">
        <h3
          className="font-body"
          style={{ fontSize: 18, fontWeight: 700, color: TXT_DARK, lineHeight: '24px', margin: 0 }}
        >
          Most Active This Week
        </h3>
        <Sparkles className="w-5 h-5" style={{ color: CYAN }} strokeWidth={2.2} />
      </div>
      <ul className="flex flex-col" style={{ gap: 8 }}>
        {scored.map((entry, i) => {
          const isLeader = i === 0
          const isMe = entry.user.id === meId
          const initial = (entry.user.firstName?.[0] ?? entry.user.username?.[0] ?? 'U').toUpperCase()
          return (
            <li
              key={entry.user.id}
              className="flex items-center"
              style={{
                gap: 12, padding: '10px 12px', borderRadius: 18,
                background: isLeader ? '#E0F2FE' : 'transparent',
                border: isLeader ? `1px solid ${CYAN}40` : '1px solid transparent',
              }}
            >
              <span
                className="font-body tabular-nums shrink-0 text-center"
                style={{
                  width: 18, fontSize: 14, fontWeight: 700, color: TXT_MID,
                }}
              >
                {entry.rank}
              </span>
              <div
                className="grid place-items-center shrink-0"
                style={{
                  width: 36, height: 36, borderRadius: 999, background: NAVY,
                }}
              >
                <span
                  className="font-body"
                  style={{ fontSize: 14, fontWeight: 700, color: '#fff' }}
                >
                  {initial}
                </span>
              </div>
              <div className="flex flex-col flex-1 min-w-0 leading-tight">
                <span
                  className="font-body truncate"
                  style={{
                    fontSize: 14, fontWeight: 700, color: TXT_DARK, lineHeight: '20px',
                  }}
                >
                  {entry.user.fullName || entry.user.username}{isMe ? ' (You)' : ''}
                </span>
                <span
                  className="font-body"
                  style={{ fontSize: 12, fontWeight: 500, color: TXT_MID, lineHeight: '16px' }}
                >
                  {isLeader ? 'Rising fast 🔥' : `${entry.streak} day streak`}
                </span>
              </div>
              <span
                className="font-body tabular-nums shrink-0"
                style={{
                  fontSize: 14, fontWeight: 700, color: '#15803D',
                  letterSpacing: '0.02em',
                }}
              >
                +{entry.delta} XP
              </span>
            </li>
          )
        })}
      </ul>
    </aside>
  )
}

// Suppress unused-import lint
void AnimatePresence; void Check
