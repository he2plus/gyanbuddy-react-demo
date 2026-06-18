/**
 * LeaderboardPage — the flat, real-time "standings" view.
 *
 * Where this is reached from:
 *   - End of any chapter quiz → "Done" button navigates here so the
 *     student immediately sees how their attempt moved them in the class.
 *   - Direct URL `/leaderboard`.
 *
 * Where the visual podium screen lives instead:
 *   - `/podium` → PodiumPage.tsx (linked from the sidebar/drawer as
 *     "Leaderboard" in the UI label).
 *
 * Layout:
 *   - Compact header with class pill + period tabs.
 *   - Full-width ranked list. Each row: rank → avatar → name +
 *     streak subtitle → XP + weekly delta pill. Current user's row gets
 *     a cyan highlight so they can find themselves in a long list.
 *   - "Just updated" timestamp at the top so it reads as live.
 *   - Optional "View podium" outbound link → /podium.
 *
 * Responsiveness:
 *   - Single column. Card max-width clamps to readable width on huge
 *     screens, fills the viewport on laptops. Works 320px → 1920px
 *     without any fixed pixel breakpoints needed beyond the typography
 *     scale.
 */
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ChevronDown, Trophy, ArrowUpRight, Check,
  RefreshCw,
} from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import { useLeaderboard } from './useLeaderboard'
import { useAuthStore } from '../../state/auth'
import type { LeaderboardPeriod } from '../../api/leaderboard'
import type { User } from '../../types/user'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

const AVATAR_COLOURS = ['#3A6FF8', '#FB923C', '#F5B400', '#22C55E', '#7C3AED', '#06B6D4', '#A855F7', '#FF3131']

// ---------------------------------------------------------------------------
export function LeaderboardPage() {
  const me = useAuthStore((s) => s.user)
  const navigate = useNavigate()
  const [period, setPeriod] = useState<LeaderboardPeriod>('weekly')
  const lbQ = useLeaderboard({ period, limit: 100 })

  const users = lbQ.data?.users ?? []
  const className = lbQ.data?.className ?? '10-A'
  const myIndex = me ? users.findIndex((u) => u.id === me.id) : -1
  const myRank = myIndex >= 0 ? myIndex + 1 : 0

  const justNow = useMemo(() => new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }), [lbQ.dataUpdatedAt])

  if (!me) return null

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Leaderboard" />

      {/* Wrap content in a sensible reading width; px-* + max-w-* keep it
          comfortable on huge screens without ever overflowing narrow ones. */}
      <main className="mx-auto w-full px-4 sm:px-8 lg:px-12 pt-8 pb-16" style={{ maxWidth: 960 }}>
        {/* Header */}
        <header className="flex flex-col items-center text-center" style={{ gap: 14, marginBottom: 24 }}>
          <h1
            className="font-body"
            style={{
              fontSize: 36, fontWeight: 700, color: NAVY,
              lineHeight: '46px', letterSpacing: '-0.5px', margin: 0,
            }}
          >
            Leaderboard
          </h1>
          <p
            className="font-body flex items-center"
            style={{ fontSize: 14, fontWeight: 500, color: TXT_MID, gap: 6, margin: 0 }}
          >
            <RefreshCw className="w-3.5 h-3.5" strokeWidth={2.4} />
            Live · class standings updated {justNow}
          </p>
          <div className="flex items-center flex-wrap justify-center" style={{ gap: 12, marginTop: 4 }}>
            <ClassPill name={`Class ${className}`} />
            <PeriodTabs active={period} onChange={setPeriod} />
            <button
              type="button"
              onClick={() => navigate('/podium')}
              className="flex items-center bg-white"
              style={{
                height: 42, borderRadius: 999, padding: '10px 18px', gap: 8,
                border: '1px solid #EAEAEA', color: NAVY,
                fontFamily: 'var(--font-body)', fontSize: 14, fontWeight: 700,
              }}
            >
              <Trophy className="w-4 h-4" strokeWidth={2.4} />
              View podium
              <ArrowUpRight className="w-4 h-4" strokeWidth={2.4} />
            </button>
          </div>
        </header>

        {/* "You" summary chip */}
        {myRank > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
            className="flex items-center bg-white"
            style={{
              padding: '14px 20px', borderRadius: 18, gap: 14,
              border: `1px solid ${CYAN}40`,
              boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
              marginBottom: 20,
            }}
          >
            <div
              className="grid place-items-center shrink-0"
              style={{
                width: 48, height: 48, borderRadius: 999,
                background: `radial-gradient(circle at 32% 28%, #1F3DB8 0%, ${NAVY} 70%)`,
                color: '#fff', fontFamily: 'var(--font-body)', fontSize: 20, fontWeight: 700,
              }}
            >
              #{myRank}
            </div>
            <div className="flex flex-col flex-1 min-w-0 leading-tight">
              <span
                className="font-body"
                style={{ fontSize: 16, fontWeight: 700, color: TXT_DARK, lineHeight: '22px' }}
              >
                You're #{myRank} in Class {className}
              </span>
              <span
                className="font-body"
                style={{ fontSize: 13, fontWeight: 500, color: TXT_MID, lineHeight: '18px' }}
              >
                {(me.totalExp ?? 0).toLocaleString()} XP this {period === 'weekly' ? 'week' : period === 'monthly' ? 'month' : 'period'}
              </span>
            </div>
          </motion.div>
        )}

        {/* Flat ranked list */}
        <section
          className="bg-white"
          style={{
            borderRadius: 24,
            boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
            border: '1px solid #E7E7E7',
            overflow: 'hidden',
          }}
        >
          {lbQ.isLoading ? (
            <div className="flex flex-col" style={{ padding: 12, gap: 6 }}>
              {Array.from({ length: 6 }).map((_, i) => (
                <div
                  key={i}
                  className="animate-pulse"
                  style={{ height: 64, borderRadius: 14, background: '#F1F1F1' }}
                />
              ))}
            </div>
          ) : users.length === 0 ? (
            <div className="grid place-items-center text-center" style={{ padding: 60, color: TXT_MUTED, fontSize: 16 }}>
              No standings yet.
            </div>
          ) : (
            <ul className="flex flex-col">
              {users.map((u, i) => (
                <LeaderRow
                  key={u.id}
                  user={u}
                  rank={i + 1}
                  isMe={u.id === me.id}
                  isLast={i === users.length - 1}
                />
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  )
}

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
          style={{ color: TXT_DARK, transform: open ? 'rotate(180deg)' : 'none' }}
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
              top: 50, left: 0, minWidth: 180, borderRadius: 16, padding: 6,
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
      style={{ height: 42, borderRadius: 999, border: '1px solid #EAEAEA' }}
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
              height: 42, borderRadius: 999, padding: '8px 18px',
              background: isActive ? NAVY : 'transparent',
              color: isActive ? '#fff' : TXT_MUTED,
              fontFamily: 'var(--font-body)', fontSize: 14, fontWeight: 600,
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
function LeaderRow({
  user, rank, isMe, isLast,
}: {
  user: User; rank: number; isMe: boolean; isLast: boolean
}) {
  const initial = (user.firstName?.[0] ?? user.username?.[0] ?? 'U').toUpperCase()
  const avatarColour = AVATAR_COLOURS[(rank - 1) % AVATAR_COLOURS.length]

  return (
    <motion.li
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.22, delay: Math.min(rank, 10) * 0.02 }}
      className="flex items-center"
      style={{
        padding: '14px 20px', gap: 14,
        background: isMe ? 'rgba(26,188,254,0.08)' : 'transparent',
        borderBottom: isLast ? 'none' : '1px solid #F1F1F1',
      }}
    >
      <span
        className="font-body tabular-nums text-center shrink-0"
        style={{
          width: 32, fontSize: 18, fontWeight: 700, lineHeight: '24px',
          color: rank <= 3 ? NAVY : TXT_MID,
        }}
      >
        {rank}
      </span>
      <div
        className="grid place-items-center shrink-0"
        style={{ width: 42, height: 42, borderRadius: 999, background: avatarColour }}
      >
        <span
          className="font-body"
          style={{ fontSize: 16, fontWeight: 700, color: '#fff', lineHeight: '22px' }}
        >
          {initial}
        </span>
      </div>
      <div className="flex flex-col flex-1 min-w-0 leading-tight">
        <div className="flex items-center" style={{ gap: 8 }}>
          <span
            className="font-body truncate"
            style={{ fontSize: 16, fontWeight: 700, color: TXT_DARK, lineHeight: '22px' }}
          >
            {user.fullName || user.username}
          </span>
          {isMe && (
            <span
              className="grid place-items-center shrink-0"
              style={{
                height: 22, borderRadius: 999, padding: '2px 10px',
                background: CYAN, color: '#fff',
                fontFamily: 'var(--font-body)', fontSize: 11, fontWeight: 700,
                letterSpacing: '0.04em', textTransform: 'uppercase',
              }}
            >
              You
            </span>
          )}
        </div>
      </div>
      <div className="flex flex-col items-end leading-tight shrink-0">
        <span
          className="font-body tabular-nums"
          style={{ fontSize: 20, fontWeight: 800, color: TXT_DARK, lineHeight: '26px' }}
        >
          {user.totalExp.toLocaleString()}{' '}
          <span style={{ fontSize: 13, fontWeight: 600, color: TXT_MID }}>XP</span>
        </span>
      </div>
    </motion.li>
  )
}

