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
import { useLocation, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ChevronDown, Check,
  ArrowRight,
} from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import { useLeaderboard } from './useLeaderboard'
import { useAuthStore } from '../../state/auth'
import type { User } from '../../types/user'

const NAVY = '#00167A'
const NAVY_DEEP = '#001B7A' // podium card body
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

// Avatar colours for podium-list rows (cycled deterministically by rank).
// Matches the Figma colour swatches at ranks 1..5.
const AVATAR_COLOURS = ['#3A6FF8', '#FB923C', '#F5B400', '#22C55E', '#7C3AED']

// ---------------------------------------------------------------------------
export function PodiumPage() {
  const me = useAuthStore((s) => s.user)
  const lbQ = useLeaderboard({ period: 'weekly', limit: 100 })
  const navigate = useNavigate()
  const location = useLocation()
  // When the student lands here straight after finishing a quiz, the quiz page
  // passes the journey URL so we can offer a "Continue learning" button that
  // drops them back on the journey path — now sitting on the next podium.
  const returnTo = (location.state as { returnTo?: string } | null)?.returnTo ?? null

  const users = lbQ.data?.users ?? []
  const className = lbQ.data?.className ?? '10-A'

  if (!me) return null

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Leaderboard" />

      <main
        className="mx-auto w-full"
        style={{
          maxWidth: 1680,
          padding: 'clamp(20px, 3vw, 32px) clamp(16px, 4vw, 64px) clamp(40px, 5vw, 60px)',
        }}
      >
        {/* Post-quiz banner — return to the journey on the next podium. */}
        {returnTo && (
          <motion.button
            type="button"
            onClick={() => navigate(returnTo)}
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            whileTap={{ scale: 0.98 }}
            className="flex items-center justify-center w-full font-body"
            style={{
              gap: 10, marginBottom: 20, padding: '14px 24px', borderRadius: 999,
              background: NAVY, color: '#fff', fontSize: 16, fontWeight: 700,
              boxShadow: '0 8px 22px rgba(0,22,122,0.22)',
            }}
          >
            Continue learning — next topic
            <ArrowRight className="w-5 h-5" strokeWidth={2.5} />
          </motion.button>
        )}

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
          <ClassPill name={`Class ${className}`} />
        </div>

        {/* Podium + ranked list, centred — matches the original leaderboard. */}
        <div className="mx-auto min-w-0" style={{ maxWidth: 1100 }}>
          <PodiumCard users={users} myId={me.id} loading={lbQ.isLoading} />
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
// PodiumCard — ONE unified container. Navy backdrop, hero illustration on
// top half, floating white rank-list panel overlapping the bottom half.
// ---------------------------------------------------------------------------
function PodiumCard({
  users, myId, loading,
}: {
  users: User[]; myId: string; loading: boolean
}) {
  const ranked = users  // show the whole class, not just the top 5
  return (
    <motion.section
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
      className="relative overflow-hidden w-full mx-auto"
      style={{
        maxWidth: 1040,
        minWidth: 0,
        borderRadius: 24,
        background: NAVY_DEEP,
        boxShadow: '0 18px 36px rgba(0,22,122,0.18)',
      }}
    >
      {/* Hero podium — DYNAMICALLY rendered from the live top-3 so the
          names above each pedestal always match the ranked list below.
          (Previously we used a static PNG with names baked in — Tanishq /
          Naman / Girish — which clashed with the actual data.) */}
      <PodiumHero
        first={users[0] ?? null}
        second={users[1] ?? null}
        third={users[2] ?? null}
      />

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
        ) : ranked.length === 0 ? (
          <div
            className="grid place-items-center"
            style={{ minHeight: 100, color: TXT_MUTED }}
          >
            No ranks yet.
          </div>
        ) : (
          <ul
            className="flex flex-col"
            style={{ gap: 4, maxHeight: 'min(60vh, 460px)', overflowY: 'auto' }}
          >
            {ranked.map((u, i) => (
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

// ---------------------------------------------------------------------------
// PodiumHero — top-3 visualisation, fully driven by live data.
//
// Layout (left→right): #2 silver, #1 gold (taller, with floating trophy),
// #3 bronze. Pedestals are cream-coloured with cyan rank numbers — matches
// the Figma art direction without baking student names into a PNG.
// ---------------------------------------------------------------------------
function PodiumHero({
  first, second, third,
}: {
  first: User | null; second: User | null; third: User | null
}) {
  return (
    <div
      className="relative w-full overflow-hidden"
      style={{
        padding: '28px 16px 0',
        // Subtle radial "spotlight" so the navy backdrop has depth
        background:
          'radial-gradient(circle at 50% 0%, rgba(255,255,255,0.10), transparent 55%)',
      }}
    >
      <div
        className="relative grid items-end mx-auto"
        style={{
          maxWidth: 480,
          gridTemplateColumns: '1fr 1.2fr 1fr',
          gap: 8,
          minHeight: 280,
        }}
      >
        <PodiumColumn rank={2} user={second} />
        <PodiumColumn rank={1} user={first} />
        <PodiumColumn rank={3} user={third} />
      </div>
    </div>
  )
}

const PEDESTAL_HEIGHTS: Record<1 | 2 | 3, number> = { 1: 140, 2: 100, 3: 76 }
const PEDESTAL_GRADIENT = 'linear-gradient(180deg, #E8E5DC 0%, #BFBAB0 100%)'
const PEDESTAL_FACE = 'linear-gradient(180deg, #F2EFE7 0%, #CFCAC0 100%)'
const RANK_NUMBER_COLOUR = '#5FD4FF'

function PodiumColumn({ rank, user }: { rank: 1 | 2 | 3; user: User | null }) {
  const initial = (user?.firstName?.[0] ?? user?.username?.[0] ?? '·').toUpperCase()
  const isLeader = rank === 1
  const pedestalH = PEDESTAL_HEIGHTS[rank]
  const avatarSize = isLeader ? 64 : 52
  return (
    <div className="flex flex-col items-center" style={{ gap: 8 }}>
      {/* Trophy floats above #1 */}
      {isLeader && (
        <motion.div
          animate={{ y: [0, -3, 0] }}
          transition={{ duration: 3.2, repeat: Infinity, ease: 'easeInOut' }}
          aria-hidden="true"
        >
          <svg width="68" height="64" viewBox="0 0 68 64" fill="none">
            {/* Cup body */}
            <path
              d="M18 8 H50 V28 C50 38 42 46 34 46 C26 46 18 38 18 28 Z"
              fill="#F5B400"
              stroke="#B97A00"
              strokeWidth="2"
            />
            {/* Highlight on the cup */}
            <path d="M22 12 H30 V22 C30 22 28 26 24 26 C20 26 22 14 22 12 Z" fill="#FFD24A" opacity="0.6" />
            {/* Left handle */}
            <path d="M18 14 C10 14 10 28 18 28" stroke="#B97A00" strokeWidth="4" fill="none" strokeLinecap="round" />
            {/* Right handle */}
            <path d="M50 14 C58 14 58 28 50 28" stroke="#B97A00" strokeWidth="4" fill="none" strokeLinecap="round" />
            {/* Stem */}
            <rect x="32" y="46" width="4" height="8" fill="#B97A00" />
            {/* Base */}
            <rect x="22" y="54" width="24" height="6" rx="1" fill="#B97A00" />
          </svg>
        </motion.div>
      )}

      {/* Spacer so #2 and #3 align nicely under the trophy zone */}
      {!isLeader && <div aria-hidden style={{ height: 28 }} />}

      {/* Name (above pedestal) */}
      <span
        className="font-body text-center"
        style={{
          fontSize: isLeader ? 14 : 13,
          fontWeight: 700,
          color: '#fff',
          lineHeight: '18px',
          minHeight: 36,
          maxWidth: '100%',
          padding: '0 4px',
        }}
      >
        {user
          ? (user.fullName || user.username).split(' ').slice(0, 2).join(' ')
          : '—'}
      </span>

      {/* Avatar */}
      <div
        className="grid place-items-center"
        style={{
          width: avatarSize, height: avatarSize, borderRadius: 999,
          background: '#fff',
          border: '3px solid rgba(255,255,255,0.4)',
          marginBottom: 4,
          color: NAVY,
          fontFamily: 'var(--font-body)',
          fontSize: isLeader ? 24 : 20, fontWeight: 800,
          boxShadow: '0 6px 14px rgba(0,0,0,0.25)',
        }}
      >
        {user?.profilePicture ? (
          <img
            src={user.profilePicture}
            alt=""
            className="w-full h-full rounded-full object-cover"
          />
        ) : (
          initial
        )}
      </div>

      {/* Pedestal — cream block with big cyan rank number */}
      <div
        className="relative w-full grid place-items-start justify-center"
        style={{
          height: pedestalH,
          background: PEDESTAL_GRADIENT,
          borderTopLeftRadius: 10, borderTopRightRadius: 10,
          paddingTop: 12,
          boxShadow:
            'inset 0 -12px 0 rgba(0,0,0,0.10), inset 6px 0 0 rgba(255,255,255,0.20)',
          backgroundImage: PEDESTAL_FACE,
        }}
      >
        <span
          style={{
            fontFamily: 'var(--font-numeric)',
            fontSize: isLeader ? 56 : 44,
            fontWeight: 900,
            color: RANK_NUMBER_COLOUR,
            lineHeight: 1,
            textShadow: '0 2px 4px rgba(0,0,0,0.18)',
          }}
        >
          {rank}
        </span>
      </div>
    </div>
  )
}

function PodiumRow({
  user, rank, isMe, isLeader,
}: {
  user: User; rank: number; isMe: boolean; isLeader: boolean
}) {
  const initial = (user.firstName?.[0] ?? user.username?.[0] ?? 'U').toUpperCase()
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
      </div>
      <div className="flex flex-col items-end leading-tight shrink-0">
        <span
          className="font-body tabular-nums"
          style={{
            fontSize: 19, fontWeight: 800, lineHeight: '25px',
            color: highlight ? '#fff' : TXT_DARK,
          }}
        >
          {user.totalExp.toLocaleString()}{' '}
          <span
            style={{
              fontSize: 13, fontWeight: 600,
              color: highlight ? 'rgba(255,255,255,0.85)' : TXT_MID,
            }}
          >
            XP
          </span>
        </span>
      </div>
    </motion.li>
  )
}


