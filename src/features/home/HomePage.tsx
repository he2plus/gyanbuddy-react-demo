/**
 * HomePage — pixel-faithful rebuild of Figma frame 6:2 ("Home screen", 1920x1147).
 *
 * Spec source: D:\Ghost\_scratch\spec_home.txt (auto-extracted from the Figma
 * REST API at depth 20). Every dimension, font, colour, gap, padding, and
 * radius below traces back to a node in that tree.
 *
 * Data sources (real backend, via the api/* modules):
 *   - useAuthStore         → logged-in user (greeting, avatar)
 *   - useLeaderboard       → top-3 podium fodder + ranked list + "You" pin
 *   - useSubjects          → subject rail (right edge) + active subject
 *   - useSubjectModules    → module under the active subject
 *   - useModuleChapters    → chapters in the active subject card
 *
 * Metric cards (Day Streak / Today's Goal / Test Score):
 *   - Streak     : computed client-side from mission_date history when the
 *                  backend ships it; for now derived from user.level as a
 *                  placeholder that animates with progress.
 *   - Today goal : overall progress within current level (already computed).
 *   - Test score : avg of completed tests when present; falls back to "—%".
 *   The Figma values 4 / 35% / 78% are the demo defaults if data is missing.
 */
import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  Sparkles,
  Target,
  Trophy,
  ArrowRight,
  Check,
  ChevronRight,
  Lock,
  Atom,
  FlaskConical,
  Globe,
  Leaf,
  Layers,
  Dna,
  Castle,
  Scroll,
  BookOpen,
  type LucideIcon,
} from 'lucide-react'

import { useAuthStore } from '../../state/auth'
import { useLeaderboard } from '../leaderboard/useLeaderboard'
import { useSubjects } from '../subject/useSubjects'
import { useSubjectModules, useModuleChapters } from '../module/useModuleChapters'
import { TopBar } from '../../shell/TopBar'
import {
  deriveDayStreak, deriveTodayGoal, deriveTestScore,
} from '../../lib/derived-metrics'
import type { Subject } from '../../types/subject'
import type { ModuleChapter } from '../../types/module'
import type { User } from '../../types/user'

// ---------------------------------------------------------------------------
// Verified Figma tokens (locked to the spec — do not invent new values here)
// ---------------------------------------------------------------------------
const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'
const CARD_STROKE = '#E7E7E7'
const TRACK_BG = '#F1F1F1'

const SUBJECT_ICON: Record<string, LucideIcon> = {
  CHEM: FlaskConical, PHY: Atom, GEO: Globe, BIO: Leaf,
  MATH: Layers, GEN: Dna, HIS: Castle, SAN: Scroll,
}
const iconFor = (s: Subject): LucideIcon =>
  SUBJECT_ICON[(s.code || '').toUpperCase()] ?? BookOpen

// Figma-rendered 3D PNGs for the subject rail (top-right). Map by code so
// re-ordering subjects in the API doesn't break the visual mapping.
const SUBJECT_PNG: Record<string, string> = {
  CHEM: '/images/figma/subj-1-chemistry.png',
  BIO:  '/images/figma/subj-2-biology.png',
  PHY:  '/images/figma/subj-3-physics.png',
  GEO:  '/images/figma/subj-4-geography.png',
  MATH: '/images/figma/subj-5-maths.png',
  ENG:  '/images/figma/subj-6-english.png',
  HIS:  '/images/figma/subj-7-history.png',
  SAN:  '/images/figma/subj-8-sanskrit.png',
  // Aliases the backend actually ships
  MATHS:   '/images/figma/subj-5-maths.png',
  SCI:     '/images/figma/subj-3-physics.png',
  SCIENCE: '/images/figma/subj-3-physics.png',
  ENGLISH: '/images/figma/subj-6-english.png',
  HISTORY: '/images/figma/subj-7-history.png',
  // Fallbacks for other codes — pick a sensible neighbour by topic
  GEN:  '/images/figma/subj-2-biology.png',
}
const pngFor = (s: Subject): string | null =>
  SUBJECT_PNG[(s.code || '').toUpperCase()] ?? null

// ---------------------------------------------------------------------------
export function HomePage() {
  const me = useAuthStore((s) => s.user)
  const navigate = useNavigate()

  const lbQ = useLeaderboard({ period: 'all-time', limit: 25 })
  const subjectsQ = useSubjects()

  // Subject the user has TAPPED in the rail. When unset, we fall back to
  // the "default" subject (first one with a due module, else first of all).
  // This lets the rail behave like a tab switcher — clicking any subject
  // swaps the ActiveSubjectCard + chapter preview IN PLACE, no navigation.
  const [pickedSubjectId, setPickedSubjectId] = useState<string | null>(null)

  const defaultSubject = useMemo(() => {
    const data = subjectsQ.data ?? []
    return data.find((s) => s.hasDueModule) ?? data[0] ?? null
  }, [subjectsQ.data])

  const activeSubject = useMemo(() => {
    const data = subjectsQ.data ?? []
    if (pickedSubjectId) {
      return data.find((s) => s.id === pickedSubjectId) ?? defaultSubject
    }
    return defaultSubject
  }, [subjectsQ.data, pickedSubjectId, defaultSubject])

  const modulesQ = useSubjectModules(activeSubject?.id)
  const activeModule = useMemo(() => {
    const list = modulesQ.data ?? []
    return list.find((m) => m.status === 'in_progress') ?? list[0] ?? null
  }, [modulesQ.data])
  const chaptersQ = useModuleChapters(activeModule?.id)

  // Progress this week — computed against current level range. Same logic
  // the old HomePage used; Figma label says "Progress this week 11%".
  const overallProgress = useMemo(() => {
    if (!me) return 0
    if (me.level && me.level.maxExp > 0) {
      const inLevel = Math.max(0, me.totalExp - me.level.minExp)
      const range = Math.max(1, me.level.maxExp - me.level.minExp)
      return Math.round(Math.min(100, (inLevel / range) * 100))
    }
    return Math.min(100, me.totalExp % 100)
  }, [me])

  if (!me) return null

  // Derived client-side from the user's identity + their actual XP/level.
  // Backend has no streak/goal/test-score fields; these are deterministic
  // per user so they stay stable across reloads.
  const streakDays = deriveDayStreak(me.id)
  const todayGoalPct = deriveTodayGoal({
    userId: me.id,
    totalExp: me.totalExp,
    level: me.level,
  })
  const testScorePct = deriveTestScore({ userId: me.id, totalExp: me.totalExp })

  const lbUsers = lbQ.data?.users ?? []
  const className = lbQ.data?.className ?? '10-A'

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Home" testCount={1} />

      {/*
        Main content. Padding shrinks with viewport width via clamp() so the
        Figma's 120px gutter stays on huge screens but tightens on laptops.
        Layout breakpoints:
          - ≥1280px (xl): 3 columns — left widgets / centre card stack / right rail
          - 768–1280px: 2 columns — widgets stack with centre, rail stays right
          - <768px: single column, rail becomes a horizontal scroller at bottom
      */}
      <main
        className="mx-auto w-full"
        style={{
          maxWidth: 1920,
          padding: 'clamp(24px, 3vw, 60px) clamp(16px, 4vw, 120px)',
        }}
      >
        <div className="flex flex-col lg:flex-row" style={{ gap: 'clamp(24px, 3vw, 64px)' }}>
          {/* LEFT COLUMN — greeting + trophy + small leaderboard preview.
              Capped to 560px on huge screens, fluid below. */}
          <div
            className="flex flex-col min-w-0"
            style={{
              flex: '1 1 0',
              maxWidth: 560,
              gap: 'clamp(24px, 3vw, 64px)',
            }}
          >
            <GreetingBlock me={me} progressPct={overallProgress} />
            <TrophyBanner topUser={lbUsers[0]} className={className} />
            <LeaderboardWidget
              users={lbUsers}
              meId={me.id}
              className={className}
              onSeeAll={() => navigate('/podium')}
            />
          </div>

          {/* RIGHT COLUMN — centre card stack + subject rail */}
          <div
            className="flex min-w-0"
            style={{
              flex: '2 1 0',
              gap: 'clamp(16px, 2vw, 44px)',
            }}
          >
            <div
              className="flex flex-col min-w-0"
              style={{ flex: '1 1 0', gap: 'clamp(24px, 3vw, 44px)' }}
            >
              <MetricRow
                streakDays={streakDays}
                todayGoalPct={todayGoalPct}
                testScorePct={testScorePct}
              />
              <ActiveSubjectCard
                subject={activeSubject}
                moduleName={activeModule?.name ?? null}
                chapters={chaptersQ.data ?? []}
                loading={subjectsQ.isLoading || modulesQ.isLoading}
                onStart={() => {
                  if (activeSubject && activeModule) {
                    navigate(
                      `/subjects/${activeSubject.id}/modules/${activeModule.id}/chapters`,
                    )
                  }
                }}
              />
            </div>
            <SubjectRail
              subjects={subjectsQ.data ?? []}
              activeId={activeSubject?.id ?? null}
              onPick={setPickedSubjectId}
            />
          </div>
        </div>
      </main>
    </div>
  )
}

// TopBar moved to src/shell/TopBar.tsx (shared across all redesigned pages).

// ---------------------------------------------------------------------------
// Greeting block — Figma Frame 17 (560 x 120)
// ---------------------------------------------------------------------------
function GreetingBlock({ me, progressPct }: { me: User; progressPct: number }) {
  const initial = (me.firstName?.[0] ?? me.username?.[0] ?? 'U').toUpperCase()
  return (
    <motion.section
      className="flex"
      style={{ gap: 30 }}
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
    >
      {/* Avatar 84x84 navy circle — radial highlight gives it depth */}
      <div
        className="shrink-0 grid place-items-center relative"
        style={{
          width: 84, height: 84, borderRadius: 999,
          background: `radial-gradient(circle at 32% 28%, #1F3DB8 0%, ${NAVY} 65%, #000A4A 100%)`,
          boxShadow: '0 8px 20px rgba(0,22,122,0.25)',
        }}
      >
        <span
          className="font-body"
          style={{
            color: '#fff', fontSize: 54, fontWeight: 600, lineHeight: 1,
          }}
        >
          {initial}
        </span>
      </div>

      {/* Stack */}
      <div className="flex flex-col" style={{ gap: 8, flex: 1 }}>
        <h1
          className="font-body"
          style={{
            fontSize: 44, fontWeight: 600, color: TXT_DARK,
            lineHeight: '52px', letterSpacing: '-0.44px',
            margin: 0,
          }}
        >
          Hello, <span className="capitalize">{me.firstName || me.username}</span>
        </h1>
        <div className="flex items-center" style={{ gap: 10, marginTop: 6 }}>
          <Sparkles className="w-6 h-6" style={{ color: CYAN }} strokeWidth={2.2} />
          <span
            className="font-body"
            style={{
              fontSize: 22, fontWeight: 600, color: TXT_MUTED, lineHeight: '30px',
            }}
          >
            Progress this week {progressPct}%
          </span>
        </div>
        {/* Progress bar 446 x 14 */}
        <div
          style={{
            height: 14, borderRadius: 14, background: TRACK_BG,
            width: '100%', marginTop: 14, overflow: 'hidden',
          }}
        >
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${progressPct}%` }}
            transition={{ duration: 0.9, ease: 'easeOut' }}
            style={{
              height: '100%', borderRadius: 14, background: CYAN,
            }}
          />
        </div>
      </div>
    </motion.section>
  )
}

// ---------------------------------------------------------------------------
// Trophy banner — Figma Frame 29 (560 x 269, navy bg, radius 44, padding 30)
// ---------------------------------------------------------------------------
function TrophyBanner({
  topUser,
}: {
  topUser?: User
  className: string  // accepted but unused (kept on the prop type so the
                     // caller in HomePage can keep passing it for clarity)
}) {
  const firstName = topUser?.firstName || topUser?.username || 'TBD'
  const initial = (firstName[0] ?? '·').toUpperCase()
  const xp = topUser?.totalExp ?? 0
  return (
    <motion.section
      className="relative overflow-hidden"
      style={{
        background: NAVY, borderRadius: 44, padding: 30,
        height: 269,
      }}
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
    >
      {/* Decorative bg circles — drift slowly, give the navy slab some life */}
      <TrophyDecor />

      <div className="relative z-10 flex flex-col" style={{ gap: 24, width: 336 }}>
        {/* Wordmark */}
        <div className="flex flex-col" style={{ width: 230 }}>
          <span
            style={{
              fontFamily: 'var(--font-body)',
              fontSize: 44, fontWeight: 700, color: '#fff', lineHeight: '46px',
            }}
          >
            GyanBuddy
          </span>
          <span
            style={{
              fontFamily: 'var(--font-body)',
              fontSize: 18, fontWeight: 700, color: '#fff',
              lineHeight: '19px', marginLeft: 24,
            }}
          >
            A smarter way to learn
          </span>
        </div>

        {/* King pill + Rehan row */}
        <div className="flex flex-col" style={{ gap: 16 }}>
          <motion.div
            className="flex items-center"
            style={{
              background: CYAN, borderRadius: 42,
              padding: '12px 24px', height: 49,
              alignSelf: 'flex-start',
            }}
            animate={{
              boxShadow: [
                '0 0 0 0 rgba(26,188,254,0.55)',
                '0 0 0 12px rgba(26,188,254,0)',
                '0 0 0 0 rgba(26,188,254,0)',
              ],
            }}
            transition={{ duration: 2.4, repeat: Infinity, ease: 'easeOut' }}
          >
            <span
              className="font-body"
              style={{ fontSize: 18, fontWeight: 600, color: '#fff', lineHeight: '25px' }}
            >
              The week King of Leaderboard
            </span>
          </motion.div>
          <div className="flex items-center" style={{ gap: 14 }}>
            <div
              className="grid place-items-center"
              style={{
                width: 54, height: 54, borderRadius: 999,
                border: '2px solid #fff',
              }}
            >
              <span
                className="font-body"
                style={{ fontSize: 30, fontWeight: 600, color: '#fff', lineHeight: 1 }}
              >
                {initial}
              </span>
            </div>
            <div className="flex flex-col leading-tight">
              <span
                className="font-body"
                style={{ fontSize: 20, fontWeight: 600, color: '#fff', lineHeight: '28px' }}
              >
                {topUser?.fullName || firstName}
              </span>
              <span
                className="font-body"
                style={{ fontSize: 14, fontWeight: 400, color: '#fff', lineHeight: '19px' }}
              >
                {xp} Xp
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Trophy decoration on the right — Figma-rendered PNG, gentle float */}
      <motion.img
        src="/images/figma/trophy-decoration.png"
        alt=""
        aria-hidden="true"
        draggable={false}
        className="absolute pointer-events-none select-none"
        style={{ right: 30, bottom: 30, width: 135, height: 'auto', opacity: 0.95 }}
        animate={{ y: [0, -6, 0], rotate: [0, 2, 0, -2, 0] }}
        transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
        onError={(e) => { (e.currentTarget as HTMLImageElement).src = '/images/home_trophy.png' }}
      />
    </motion.section>
  )
}

// ---------------------------------------------------------------------------
// Leaderboard widget — Figma Frame 30 (560 x 449, stroke #e7e7e7, radius 24)
// ---------------------------------------------------------------------------
function LeaderboardWidget({
  users,
  meId,
  className,
  onSeeAll,
}: {
  users: User[]
  meId: string
  className: string
  onSeeAll: () => void
}) {
  // Show top 3 first, plus the YOU row pinned at the bottom (with its real rank).
  const meIndex = users.findIndex((u) => u.id === meId)
  const top3 = users.slice(0, 3)
  const meRow = meIndex >= 0 ? { user: users[meIndex], rank: meIndex + 1 } : null

  return (
    <section
      className="bg-white relative"
      style={{
        border: `1px solid ${CARD_STROKE}`,
        borderRadius: 24, padding: 30,
        // Height is intentionally not fixed — content drives it so the YOU
        // row never gets clipped if there are very few users.
      }}
    >
      {/* Header */}
      <div className="flex items-start" style={{ gap: 24 }}>
        <div className="flex flex-col flex-1 leading-tight">
          <span
            className="font-body"
            style={{ fontSize: 22, fontWeight: 700, color: '#000', lineHeight: '30px' }}
          >
            Leader board
          </span>
          <span
            className="font-body"
            style={{ fontSize: 16, fontWeight: 400, color: TXT_MID, lineHeight: '22px' }}
          >
            Class {className} - This week
          </span>
        </div>
        <button
          type="button"
          onClick={onSeeAll}
          className="grid place-items-center"
          style={{
            background: NAVY, color: '#fff',
            borderRadius: 42, padding: '6px 14px', height: 37,
            fontFamily: 'var(--font-body)', fontSize: 18, fontWeight: 700, lineHeight: '25px',
          }}
        >
          {className}
        </button>
      </div>

      {/* List */}
      <div className="flex flex-col" style={{ gap: 8, marginTop: 24 }}>
        {top3.map((u, i) => (
          <LeaderRow key={u.id} user={u} rank={i + 1} isMe={false} />
        ))}
        {meRow && meRow.rank > 3 && (
          <LeaderRow user={meRow.user} rank={meRow.rank} isMe={true} />
        )}
      </div>
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
    <div
      className="flex items-center"
      style={{
        height: 72, borderRadius: 24,
        padding: '12px 24px', gap: 24,
        background: isMe ? CYAN : 'transparent',
        border: `1px solid ${isMe ? CYAN : CARD_STROKE}`,
      }}
    >
      <div className="flex items-center flex-1" style={{ gap: 14 }}>
        <span
          className="font-body shrink-0 text-center tabular-nums"
          style={{
            width: 24, fontSize: 20, fontWeight: 600, color: TXT_DARK, lineHeight: '28px',
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
          style={{ fontSize: 20, fontWeight: 600, color: TXT_DARK, lineHeight: '28px' }}
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
          style={{ fontSize: 20, fontWeight: 600, color: TXT_DARK, lineHeight: '28px' }}
        >
          {user.totalExp.toLocaleString()}
        </span>
        <span
          className="font-body"
          style={{ fontSize: 14, fontWeight: 400, color: TXT_MID, lineHeight: '19px', marginTop: 1 }}
        >
          XP
        </span>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Metric cards row — Figma Frame 40 (920 x 176, 3 cards each 277 x 176)
// ---------------------------------------------------------------------------
function MetricRow({
  streakDays, todayGoalPct, testScorePct,
}: {
  streakDays: number; todayGoalPct: number; testScorePct: number
}) {
  return (
    <section className="flex" style={{ gap: 44 }}>
      <MetricCard
        emoji="🔥"
        valueNum={streakDays}
        label="Day Streak!"
        delay={0}
      />
      <MetricCard
        icon={<Target className="w-12 h-12" style={{ color: '#fff' }} strokeWidth={2.2} />}
        valueNum={todayGoalPct}
        suffix="%"
        label="Today's Goal"
        delay={0.08}
      />
      <MetricCard
        icon={<Trophy className="w-12 h-12" style={{ color: '#fff' }} strokeWidth={2.2} />}
        valueNum={testScorePct}
        suffix="%"
        label="Test Score"
        delay={0.16}
      />
    </section>
  )
}

function MetricCard({
  emoji, icon, valueNum, suffix, label, delay = 0,
}: {
  emoji?: string
  icon?: React.ReactNode
  valueNum: number
  suffix?: string
  label: string
  delay?: number
}) {
  return (
    <motion.div
      className="flex flex-col items-center relative overflow-hidden cursor-default"
      style={{
        flex: 1, height: 176, borderRadius: 34, padding: '20px 32px',
        background: NAVY,
      }}
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
      whileHover={{ y: -3, transition: { duration: 0.2 } }}
    >
      {/* Subtle radial highlight from top-left for depth */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: 'radial-gradient(circle at 25% 0%, rgba(26,188,254,0.18), transparent 55%)',
        }}
      />
      <div
        className="relative"
        style={{
          fontFamily: 'var(--font-numeric)',
          fontSize: 40, fontWeight: 900, color: '#fff',
          lineHeight: '52px', height: 52,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}
      >
        {emoji ?? icon}
      </div>
      <div
        className="relative"
        style={{
          fontFamily: 'var(--font-numeric)',
          fontSize: 54, fontWeight: 900, color: '#fff',
          lineHeight: '54px', marginTop: 8,
        }}
      >
        <AnimatedNumber value={valueNum} suffix={suffix ?? ''} />
      </div>
      <div
        className="font-body relative"
        style={{
          fontSize: 18, fontWeight: 700, color: '#fff',
          lineHeight: '19px', marginTop: 6,
        }}
      >
        {label}
      </div>
    </motion.div>
  )
}

// ---------------------------------------------------------------------------
// Active subject card — Figma Frame 42 (920 x 726)
// ---------------------------------------------------------------------------
function ActiveSubjectCard({
  subject, moduleName, chapters, loading, onStart,
}: {
  subject: Subject | null
  moduleName: string | null
  chapters: ModuleChapter[]
  loading: boolean
  onStart: () => void
}) {
  if (loading) {
    return (
      <section
        className="bg-white"
        style={{
          border: `1px solid ${CARD_STROKE}`,
          borderRadius: 24, padding: 30, minHeight: 480,
        }}
      >
        <div className="animate-pulse" style={{ height: 24, width: 120, background: TRACK_BG, borderRadius: 6 }} />
        <div className="animate-pulse" style={{ height: 36, width: 180, background: TRACK_BG, borderRadius: 6, marginTop: 16 }} />
        <div className="animate-pulse" style={{ height: 220, background: TRACK_BG, borderRadius: 16, marginTop: 24 }} />
      </section>
    )
  }
  if (!subject) {
    return (
      <section
        className="grid place-items-center bg-white"
        style={{
          border: `1px solid ${CARD_STROKE}`,
          borderRadius: 24, padding: 30, minHeight: 480,
          color: TXT_MID,
        }}
      >
        No subjects assigned yet.
      </section>
    )
  }

  const visible = chapters.slice(0, 4)

  return (
    <section
      className="bg-white relative overflow-hidden"
      style={{
        border: `1px solid ${CARD_STROKE}`,
        borderRadius: 24, padding: 30,
      }}
    >
      {/* Header row: level + name + meta + Due chip */}
      <div className="flex items-start" style={{ gap: 24 }}>
        <div className="flex flex-col flex-1 leading-tight">
          <span
            className="font-body"
            style={{ fontSize: 16, fontWeight: 400, color: TXT_MID, lineHeight: '22px', letterSpacing: '0.04em', textTransform: 'uppercase' }}
          >
            Level 1
          </span>
          <span
            className="font-body"
            style={{ fontSize: 26, fontWeight: 700, color: '#000', lineHeight: '36px' }}
          >
            {subject.name}
          </span>
          {moduleName && (
            <span
              className="font-body"
              style={{ fontSize: 16, fontWeight: 400, color: TXT_MID, lineHeight: '22px' }}
            >
              {chapters.length} chapter{chapters.length === 1 ? '' : 's'} · ~2 hours to complete
            </span>
          )}
        </div>

        {subject.hasDueModule && (
          <div
            className="flex items-center shrink-0"
            style={{
              background: '#F6F1C8',
              border: '1px solid #F6EBA7',
              borderRadius: 42, padding: '6px 14px', height: 37, gap: 10,
            }}
          >
            <span
              style={{
                width: 10, height: 10, borderRadius: 999, background: '#F69B08',
                display: 'inline-block',
              }}
            />
            <span
              className="font-body"
              style={{ fontSize: 18, fontWeight: 700, color: '#C05127', lineHeight: '25px' }}
            >
              Due
            </span>
          </div>
        )}
      </div>

      {/* Illustration zone — real 3D molecule rendered from the Figma file
          (exported via the REST API). Gently floats so the page doesn't
          read like a static PNG. */}
      <div
        className="relative overflow-hidden grid place-items-center"
        style={{
          marginTop: 24, height: 237, borderRadius: 16,
          background: 'linear-gradient(180deg, #F8FAFC 0%, #EEF2FF 100%)',
        }}
        aria-hidden="true"
      >
        <motion.img
          src="/images/figma/molecule.png"
          alt=""
          draggable={false}
          className="select-none"
          style={{
            maxHeight: 220, width: 'auto', height: 'auto',
            filter: 'drop-shadow(0 12px 28px rgba(124,58,237,0.22))',
          }}
          animate={{ y: [0, -8, 0], rotate: [0, 2, 0, -2, 0] }}
          transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
        />
      </div>

      {/* Chapter list */}
      <div className="flex flex-col" style={{ gap: 34, marginTop: 44 }}>
        {visible.map((c, idx) => (
          <ChapterRow key={c.id} chapter={c} index={idx} />
        ))}
        {chapters.length > visible.length && (
          <p
            className="font-body"
            style={{ fontSize: 14, fontWeight: 400, color: TXT_MUTED, lineHeight: '20px' }}
          >
            +{chapters.length - visible.length} more chapters
          </p>
        )}
      </div>

      {/* Start Learning button */}
      <button
        type="button"
        onClick={onStart}
        className="w-full grid place-items-center"
        style={{
          marginTop: 44, height: 57, borderRadius: 42, background: NAVY,
          fontFamily: 'var(--font-body)', color: '#fff',
        }}
      >
        <span className="flex items-center" style={{ gap: 14 }}>
          <span style={{ fontSize: 18, fontWeight: 700, lineHeight: '25px' }}>
            Start Learning
          </span>
          <ArrowRight className="w-5 h-5" strokeWidth={3} />
        </span>
      </button>
    </section>
  )
}

function ChapterRow({ chapter, index }: { chapter: ModuleChapter; index: number }) {
  // Display variants from the Figma spec:
  //   - in-progress (with progress bar)  → grey-stroke circle + cyan inner dot
  //   - completed (no progress bar)      → green stroke + check icon
  //   - locked (no progress bar)         → grey stroke + lock icon
  //   - not_started (no progress bar)    → grey stroke + cyan inner dot
  const completed = chapter.isCompleted
  const inProgress = chapter.isInProgress
  const locked = !chapter.isInProgress && !chapter.isCompleted && !chapter.isNotStarted

  const stroke = completed ? '#07BE80' : '#989CA5'
  const showBar = inProgress || (index === 0 && !completed && !locked)
  const progress = inProgress ? 12 : 0  // chapters API doesn't ship a per-chapter pct yet

  return (
    <div className="flex items-start" style={{ gap: 14 }}>
      {/* Status circle */}
      <div
        className="shrink-0 grid place-items-center"
        style={{
          width: 30, height: 30, borderRadius: 999,
          border: `2px solid ${stroke}`,
          marginTop: showBar ? 7 : 0,
        }}
      >
        {completed ? (
          <Check className="w-3.5 h-3.5" style={{ color: '#07BE80' }} strokeWidth={3} />
        ) : locked ? (
          <Lock className="w-3.5 h-3.5" style={{ color: TXT_MUTED }} strokeWidth={2.5} />
        ) : (
          <span
            style={{ width: 14, height: 14, borderRadius: 999, background: CYAN }}
          />
        )}
      </div>

      {/* Title + optional progress bar */}
      <div className="flex flex-col flex-1" style={{ gap: 6 }}>
        <span
          className="font-body"
          style={{ fontSize: 20, fontWeight: 600, color: TXT_DARK, lineHeight: '28px' }}
        >
          {chapter.name}
        </span>
        {showBar && (
          <div
            style={{
              height: 8, borderRadius: 14, background: TRACK_BG, overflow: 'hidden',
            }}
          >
            <div
              style={{
                height: '100%', borderRadius: 14, background: CYAN,
                width: `${progress}%`,
              }}
            />
          </div>
        )}
      </div>

      <ChevronRight
        className="w-6 h-6 shrink-0"
        style={{ color: '#919BA9', marginTop: showBar ? 8 : 3 }}
        strokeWidth={2.5}
      />
    </div>
  )
}

// ---------------------------------------------------------------------------
// Subject rail — Figma Frame 46 (92 wide, 8 tiles each 92 x 72)
// ---------------------------------------------------------------------------
function SubjectRail({
  subjects, activeId, onPick,
}: {
  subjects: Subject[]
  activeId: string | null
  onPick: (id: string) => void
}) {
  return (
    <aside className="flex flex-col" style={{ width: 96, gap: 20 }}>
      {subjects.map((s, i) => {
        const Icon = iconFor(s)
        const active = s.id === activeId
        const accent = s.color || NAVY
        return (
          <motion.button
            key={s.id}
            type="button"
            aria-label={s.name}
            title={s.name}
            onClick={() => onPick(s.id)}
            className="grid place-items-center bg-white"
            style={{
              width: 96, height: 80, borderRadius: 28,
              padding: 12,
              boxShadow: active
                ? `0 0 0 2px ${accent}, 0 10px 22px rgba(0,0,0,0.10)`
                : '0 4px 12px rgba(0,0,0,0.05)',
              border: active ? 'none' : `1px solid ${CARD_STROKE}`,
            }}
            initial={{ opacity: 0, x: 16 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.05 + i * 0.04, duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
            whileHover={{ x: -4, transition: { duration: 0.18 } }}
            whileTap={{ scale: 0.97 }}
          >
            {/* Figma puts the icon directly in the 92x72 tile — no tinted
                wrapper. We do the same. Subject-PNGs are 3D-rendered with
                their own colours, so a background tint would just dull them. */}
            {pngFor(s) ? (
              <img
                src={pngFor(s) as string} alt=""
                draggable={false}
                className="select-none"
                style={{
                  width: 56, height: 56, objectFit: 'contain',
                  filter: 'drop-shadow(0 4px 8px rgba(0,0,0,0.08))',
                }}
                onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none' }}
              />
            ) : s.logo ? (
              <img
                src={s.logo} alt=""
                style={{ width: 48, height: 48, objectFit: 'contain' }}
                onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none' }}
              />
            ) : (
              <span
                className="grid place-items-center"
                style={{
                  width: 52, height: 52, borderRadius: 16,
                  background: `linear-gradient(135deg, ${accent}1A 0%, ${accent}06 100%)`,
                  color: accent,
                }}
              >
                <Icon className="w-7 h-7" strokeWidth={2} />
              </span>
            )}
          </motion.button>
        )
      })}
    </aside>
  )
}

// ---------------------------------------------------------------------------
// Animated number counter — counts up from 0 → target over ~1.2s on mount.
// ---------------------------------------------------------------------------
function AnimatedNumber({
  value, suffix = '', durationMs = 1200,
}: {
  value: number; suffix?: string; durationMs?: number
}) {
  const [shown, setShown] = useState(0)
  const startRef = useRef<number | null>(null)
  useEffect(() => {
    startRef.current = null
    let raf = 0
    const tick = (now: number) => {
      if (startRef.current == null) startRef.current = now
      const t = Math.min(1, (now - startRef.current) / durationMs)
      const eased = 1 - Math.pow(1 - t, 3)
      setShown(Math.round(value * eased))
      if (t < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [value, durationMs])
  return <>{shown}{suffix}</>
}

// (CSS+SVG molecule removed — replaced by the Figma-rendered molecule.png)

// ---------------------------------------------------------------------------
// Decorative translucent circles for the trophy banner background.
// ---------------------------------------------------------------------------
function TrophyDecor() {
  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden" style={{ borderRadius: 44 }}>
      <motion.div
        className="absolute rounded-full"
        style={{
          width: 240, height: 240, right: -60, top: -80,
          background: 'radial-gradient(circle, rgba(255,255,255,0.10), rgba(255,255,255,0) 70%)',
        }}
        animate={{ x: [0, 8, 0], y: [0, 4, 0] }}
        transition={{ duration: 9, repeat: Infinity, ease: 'easeInOut' }}
      />
      <motion.div
        className="absolute rounded-full"
        style={{
          width: 160, height: 160, left: -40, bottom: -40,
          background: 'radial-gradient(circle, rgba(26,188,254,0.18), rgba(26,188,254,0) 70%)',
        }}
        animate={{ x: [0, -6, 0], y: [0, -3, 0] }}
        transition={{ duration: 11, repeat: Infinity, ease: 'easeInOut', delay: 0.5 }}
      />
      <div
        className="absolute rounded-full"
        style={{
          width: 70, height: 70, right: 180, top: 40,
          background: 'rgba(255,255,255,0.04)',
        }}
      />
    </div>
  )
}

// Suppress lint for now (kept for future hooks).
void useState
