/**
 * HomePage — composed from the same elements as the live Flutter screen, but
 * adapted to use the available screen width at every viewport.
 *
 * Brand discipline:
 *   - Primary `#365DEA` is the ONLY blue used in net-new chrome
 *   - Deep navy `#00167A` only on the trophy banner (faithful to Flutter)
 *   - No invented pastel/indigo/violet gradients — uses solid brand colors
 *     and the subject's own `color` field when one is present
 *   - Avatars carry the brand primary or the per-rank medal color, NOT a
 *     generated purple sweep
 *
 * Layout:
 *   - <lg     : single column
 *   - lg-xl   : 12-col grid → leaderboard (5) + active subject card (7)
 *   - 2xl+    : 12-col grid → leaderboard (4) + active subject (5) + subject rail (3)
 *               so a TV-sized screen actually shows three columns instead of
 *               leaving 30 % of the page blank
 */
import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  Bell,
  ClipboardList,
  TrendingUp,
  ArrowRight,
  Atom,
  FlaskConical,
  Globe,
  Leaf,
  Layers,
  Dna,
  Castle,
  Scroll,
  BookOpen,
  CheckCircle2,
  Clock,
  LogOut,
  type LucideIcon,
} from 'lucide-react'

import { PageContainer } from '../../components/PageContainer'
import { useAuthStore } from '../../state/auth'
import { useLeaderboard } from '../leaderboard/useLeaderboard'
import { useSubjects } from '../subject/useSubjects'
import { useSubjectModules, useModuleChapters } from '../module/useModuleChapters'
import type { Subject } from '../../types/subject'

const BRAND_PRIMARY = '#365DEA'
const BRAND_NAVY = '#00167A'
const BRAND_SURFACE = '#F8F9FA'
const BRAND_BORDER = '#E0E0E0'

const SUBJECT_ICON: Record<string, LucideIcon> = {
  CHEM: FlaskConical,
  PHY: Atom,
  GEO: Globe,
  BIO: Leaf,
  MATH: Layers,
  GEN: Dna,
  HIS: Castle,
  SAN: Scroll,
}

const iconFor = (s: Subject): LucideIcon =>
  SUBJECT_ICON[(s.code || '').toUpperCase()] ?? BookOpen

const RANK_AVATAR_COLOR: Record<number, string> = {
  1: '#FACC15', // gold
  2: '#9CA3AF', // silver
  3: '#92400E', // bronze
}

export function HomePage() {
  const me = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)
  const navigate = useNavigate()

  const lbQ = useLeaderboard({ period: 'all-time', limit: 8 })
  const subjectsQ = useSubjects()

  const activeSubject = useMemo(() => {
    const data = subjectsQ.data ?? []
    return data.find((s) => s.hasDueModule) ?? data[0] ?? null
  }, [subjectsQ.data])

  const modulesQ = useSubjectModules(activeSubject?.id)
  const activeModule = useMemo(() => {
    const list = modulesQ.data ?? []
    return list.find((m) => m.status === 'in_progress') ?? list[0] ?? null
  }, [modulesQ.data])
  const chaptersQ = useModuleChapters(activeModule?.id)

  const overallProgress = useMemo(() => {
    if (!me) return 0
    if (me.level && me.level.maxExp > 0) {
      const inLevel = Math.max(0, me.totalExp - me.level.minExp)
      const range = Math.max(1, me.level.maxExp - me.level.minExp)
      return Math.round(Math.min(100, (inLevel / range) * 100))
    }
    return Math.min(100, me.totalExp % 100)
  }, [me])

  const onLogout = async () => {
    await logout()
    navigate('/login', { replace: true })
  }

  if (!me) return null

  return (
    <PageContainer variant="wide" className="py-5 pb-12 sm:py-6">
      {/* ----- Top strip: greeting + actions ----- */}
      <section className="mb-6 flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex items-center gap-4">
          <div
            className="grid h-14 w-14 shrink-0 place-items-center rounded-full text-xl font-bold text-white shadow-md sm:h-16 sm:w-16 sm:text-2xl"
            style={{ background: BRAND_PRIMARY }}
            aria-hidden="true"
          >
            {(me.firstName?.[0] ?? me.username?.[0] ?? 'U').toUpperCase()}
          </div>
          <div className="min-w-0">
            <h1 className="text-2xl font-bold text-[#333] sm:text-3xl">
              Hello, <span className="capitalize">{me.firstName || me.username}</span>
            </h1>
            <div className="mt-2 flex flex-wrap items-center gap-2 text-sm text-[#666]">
              <TrendingUp className="h-4 w-4" style={{ color: BRAND_PRIMARY }} />
              <span>
                Progress:{' '}
                <span className="font-semibold text-[#333]">{overallProgress}%</span>
              </span>
              <div
                className="ml-1 h-1.5 w-28 overflow-hidden rounded-full sm:w-36"
                style={{ background: BRAND_BORDER }}
                role="progressbar"
                aria-valuenow={overallProgress}
                aria-valuemin={0}
                aria-valuemax={100}
              >
                <motion.div
                  className="h-full rounded-full"
                  style={{ background: BRAND_PRIMARY }}
                  initial={{ width: 0 }}
                  animate={{ width: `${overallProgress}%` }}
                  transition={{ duration: 0.9, ease: 'easeOut' }}
                />
              </div>
            </div>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2 sm:gap-3">
          <div
            className="flex items-center gap-2 rounded-full border bg-white px-3.5 py-2 shadow-sm"
            style={{ borderColor: BRAND_BORDER }}
          >
            <span className="text-xs font-bold" style={{ color: BRAND_PRIMARY }}>
              XP
            </span>
            <XPCounter value={me.totalExp} />
          </div>
          <button
            type="button"
            aria-label="Notifications"
            onClick={() => navigate('/notifications')}
            className="grid h-10 w-10 place-items-center rounded-full border bg-white text-[#666] shadow-sm transition-colors hover:bg-[#F8F9FA]"
            style={{ borderColor: BRAND_BORDER }}
          >
            <Bell className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={() => navigate('/tests')}
            className="flex items-center gap-2 rounded-full border bg-white px-3.5 py-2 text-sm font-medium text-[#333] shadow-sm transition-colors hover:bg-[#F8F9FA]"
            style={{ borderColor: BRAND_BORDER }}
          >
            <ClipboardList className="h-4 w-4" style={{ color: BRAND_PRIMARY }} />
            Tests
          </button>
          <button
            type="button"
            onClick={onLogout}
            className="hidden items-center gap-1.5 text-sm font-medium text-[#666] hover:text-[#E74C3C] sm:inline-flex"
          >
            <LogOut className="h-4 w-4" />
            Log out
          </button>
        </div>
      </section>

      {/* ----- Main grid — adapts from 1 col → 12-col (2 spans) → 12-col (3 spans) ----- */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-12 lg:gap-6">
        {/* LEFT: trophy banner + leaderboard */}
        <div className="space-y-5 lg:col-span-5 2xl:col-span-4 lg:space-y-6">
          <TrophyBanner me={me} />
          <LeaderboardWidget
            entries={(lbQ.data?.users ?? []).slice(0, 5)}
            scope={lbQ.data?.className ?? lbQ.data?.gradeName ?? 'Class'}
            meId={me.id}
            loading={lbQ.isLoading}
            onSeeAll={() => navigate('/leaderboard')}
          />
        </div>

        {/* CENTER: active subject + chapters */}
        <div className="space-y-5 lg:col-span-7 2xl:col-span-5 lg:space-y-6">
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

        {/* RIGHT (≥2xl only): subject rail moved into its own column on wide displays */}
        <div className="lg:col-span-12 2xl:col-span-3">
          <SubjectRail
            subjects={subjectsQ.data ?? []}
            activeId={activeSubject?.id ?? null}
            onPick={(id) => navigate(`/subjects/${id}`)}
            loading={subjectsQ.isLoading}
          />
        </div>
      </div>
    </PageContainer>
  )
}

// ---------------------------------------------------------------------------
// XP counter (counts up from 0 → value)
// ---------------------------------------------------------------------------
function XPCounter({ value }: { value: number }) {
  const [shown, setShown] = useState(0)
  useEffect(() => {
    const start = performance.now()
    const duration = 900
    let raf = 0
    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / duration)
      const eased = 1 - Math.pow(1 - t, 3)
      setShown(Math.round(value * eased))
      if (t < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [value])
  return <span className="text-sm font-semibold text-[#333]">{shown.toLocaleString()}</span>
}

// ---------------------------------------------------------------------------
// Trophy banner — faithful navy from Flutter (`_primaryBlue: 0xFF00167A`)
// ---------------------------------------------------------------------------
function TrophyBanner({ me }: { me: { firstName: string; username: string; totalExp: number } }) {
  return (
    <div
      className="relative overflow-hidden rounded-2xl p-6 sm:p-7"
      style={{ background: BRAND_NAVY }}
    >
      <div className="relative z-10 max-w-[62%]">
        <div className="text-xl font-extrabold tracking-tight text-white sm:text-2xl">
          Gyan<span style={{ color: '#00D4FF' }}>Buddy</span>
        </div>
        <div className="mt-0.5 text-[10px] font-medium uppercase tracking-widest text-white/70">
          A smarter way to learn
        </div>
        <div className="mt-5 inline-flex rounded-full bg-white/15 px-3.5 py-1.5 text-xs font-medium text-white backdrop-blur sm:px-4 sm:py-2 sm:text-sm">
          The week King of Leaderboard
        </div>
        <div className="mt-4 flex items-center gap-3">
          <div
            className="grid h-10 w-10 place-items-center rounded-full text-base font-bold text-white"
            style={{ background: '#FACC15' }}
          >
            {(me.firstName?.[0] ?? me.username?.[0] ?? 'U').toUpperCase()}
          </div>
          <div>
            <div className="text-base font-bold text-white sm:text-lg">
              {me.firstName || me.username}
            </div>
            <div className="text-sm text-white/80">{me.totalExp.toLocaleString()} XP</div>
          </div>
        </div>
      </div>

      <div className="pointer-events-none absolute right-0 top-1/2 hidden -translate-y-1/2 sm:block">
        <img
          src="/images/home_trophy.png"
          alt=""
          className="h-44 w-auto select-none opacity-95"
          draggable={false}
          onError={(e) => {
            ;(e.currentTarget as HTMLImageElement).style.display = 'none'
          }}
        />
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Leaderboard widget — top 5 with You highlight
// ---------------------------------------------------------------------------
function LeaderboardWidget({
  entries,
  scope,
  meId,
  loading,
  onSeeAll,
}: {
  entries: Array<{ id: string; firstName: string; lastName: string; fullName: string; totalExp: number; username: string }>
  scope: string
  meId: string
  loading: boolean
  onSeeAll: () => void
}) {
  return (
    <div
      className="rounded-2xl border bg-white p-5 shadow-sm sm:p-6"
      style={{ borderColor: BRAND_BORDER }}
    >
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-bold text-[#333]">Leaderboard</h3>
        <button
          type="button"
          onClick={onSeeAll}
          className="flex items-center gap-1 text-sm font-medium hover:underline"
          style={{ color: BRAND_PRIMARY }}
        >
          See all <ArrowRight className="h-4 w-4" />
        </button>
      </div>

      <div className="mt-3 flex justify-center">
        <span
          className="inline-flex min-w-[200px] items-center justify-center rounded-full px-6 py-1.5 text-sm font-semibold text-white shadow-sm"
          style={{ background: BRAND_PRIMARY }}
        >
          {scope}
        </span>
      </div>

      {loading ? (
        <ul className="mt-4 space-y-2">
          {Array.from({ length: 3 }).map((_, i) => (
            <li key={i} className="h-14 animate-pulse rounded-xl" style={{ background: BRAND_SURFACE }} />
          ))}
        </ul>
      ) : entries.length === 0 ? (
        <p className="mt-6 text-center text-sm text-[#999]">
          No leaderboard data yet.
        </p>
      ) : (
        <ul className="mt-4 space-y-2.5">
          {entries.map((u, i) => {
            const rank = i + 1
            const isMe = u.id === meId
            return (
              <motion.li
                key={u.id}
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.05, duration: 0.3, ease: 'easeOut' }}
                className="flex items-center justify-between rounded-xl border px-3 py-2.5 transition-all hover:-translate-y-0.5 hover:shadow-md"
                style={{
                  borderColor: isMe ? BRAND_PRIMARY : BRAND_BORDER,
                  background: isMe ? '#F1F4FE' : 'white',
                }}
              >
                <div className="flex items-center gap-3">
                  <span className="w-5 text-center text-sm font-bold text-[#666]">
                    {rank}.
                  </span>
                  <span
                    className="grid h-9 w-9 place-items-center rounded-full text-sm font-bold text-white"
                    style={{ background: RANK_AVATAR_COLOR[rank] ?? BRAND_PRIMARY }}
                  >
                    {(u.firstName?.[0] ?? u.username?.[0] ?? 'U').toUpperCase()}
                  </span>
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-[#333]">
                      {u.fullName || u.username}
                    </span>
                    {isMe && (
                      <span
                        className="rounded-full px-2 py-0.5 text-[10px] font-bold text-white"
                        style={{ background: BRAND_PRIMARY }}
                      >
                        You
                      </span>
                    )}
                  </div>
                </div>
                <span className="text-sm font-semibold text-[#666]">
                  {u.totalExp.toLocaleString()} XP
                </span>
              </motion.li>
            )
          })}
        </ul>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Active subject card — now shows actual chapter list (denser, more useful)
// ---------------------------------------------------------------------------
function ActiveSubjectCard({
  subject,
  moduleName,
  chapters,
  loading,
  onStart,
}: {
  subject: Subject | null
  moduleName: string | null
  chapters: Array<{ id: string; name: string; status: string; isInProgress: boolean; isCompleted: boolean }>
  loading: boolean
  onStart: () => void
}) {
  if (loading) {
    return (
      <div
        className="rounded-2xl border bg-white p-6 shadow-sm"
        style={{ borderColor: BRAND_BORDER }}
      >
        <div className="h-7 w-32 animate-pulse rounded" style={{ background: BRAND_SURFACE }} />
        <div className="mt-3 h-3 w-20 animate-pulse rounded" style={{ background: BRAND_SURFACE }} />
        <div className="mt-6 h-24 w-full animate-pulse rounded" style={{ background: BRAND_SURFACE }} />
        <div className="mt-6 h-12 w-full animate-pulse rounded" style={{ background: BRAND_SURFACE }} />
      </div>
    )
  }

  if (!subject) {
    return (
      <div
        className="rounded-2xl border bg-white p-6 text-center text-[#666] shadow-sm"
        style={{ borderColor: BRAND_BORDER }}
      >
        No subjects assigned yet.
      </div>
    )
  }

  const accent = subject.color || BRAND_PRIMARY
  const Icon = iconFor(subject)
  const visibleChapters = chapters.slice(0, 3)
  const remaining = Math.max(0, chapters.length - visibleChapters.length)

  return (
    <div
      className="rounded-2xl border bg-white p-6 shadow-sm sm:p-7"
      style={{ borderColor: BRAND_BORDER }}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <h2 className="text-2xl font-bold text-[#333] sm:text-3xl">{subject.name}</h2>
          {moduleName && (
            <div className="mt-1 text-xs font-semibold uppercase tracking-widest text-[#999]">
              {moduleName}
            </div>
          )}
        </div>
        {subject.hasDueModule && (
          <span
            className="inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-bold uppercase tracking-widest text-white"
            style={{ background: '#F39C12' }}
          >
            <Clock className="h-3 w-3" />
            Due
          </span>
        )}
      </div>

      {/* Subject illustration — flat surface bg, no gradient */}
      <div
        className="my-5 grid place-items-center rounded-xl py-8"
        style={{ background: BRAND_SURFACE }}
      >
        {subject.logo ? (
          <img
            src={subject.logo}
            alt=""
            className="h-24 w-auto object-contain"
            onError={(e) => {
              ;(e.currentTarget as HTMLImageElement).style.display = 'none'
            }}
          />
        ) : (
          <Icon className="h-20 w-20" style={{ color: accent }} />
        )}
      </div>

      {/* Chapter list (denser content density — matches Flutter home behaviour) */}
      {visibleChapters.length > 0 && (
        <div>
          <h3 className="text-sm font-semibold text-[#666]">Chapters</h3>
          <ul className="mt-3 space-y-2">
            {visibleChapters.map((c) => (
              <li
                key={c.id}
                className="flex items-center justify-between rounded-xl px-3 py-2.5"
                style={{ background: BRAND_SURFACE }}
              >
                <div className="flex min-w-0 items-center gap-3">
                  <span
                    className="grid h-8 w-8 shrink-0 place-items-center rounded-lg text-xs font-bold text-white"
                    style={{ background: accent }}
                  >
                    <Icon className="h-4 w-4" />
                  </span>
                  <span className="truncate text-sm font-medium text-[#333]">
                    {c.name}
                  </span>
                </div>
                <ChapterStatusIcon
                  isCompleted={c.isCompleted}
                  isInProgress={c.isInProgress}
                />
              </li>
            ))}
          </ul>
          {remaining > 0 && (
            <p className="mt-3 text-xs text-[#999]">+{remaining} more chapters</p>
          )}
        </div>
      )}

      {/* Start button — brand primary, NOT subject color (faithful to Flutter) */}
      <motion.button
        type="button"
        whileTap={{ scale: 0.98 }}
        whileHover={{ y: -1 }}
        onClick={onStart}
        className="mt-5 flex w-full items-center justify-center gap-2 rounded-xl py-3.5 text-base font-semibold text-white shadow-sm transition-colors"
        style={{ background: BRAND_PRIMARY }}
      >
        Start
        <ArrowRight className="h-4 w-4" />
      </motion.button>
    </div>
  )
}

function ChapterStatusIcon({
  isCompleted,
  isInProgress,
}: {
  isCompleted: boolean
  isInProgress: boolean
}) {
  if (isCompleted) {
    return (
      <span className="grid h-6 w-6 place-items-center rounded-full bg-emerald-500 text-white">
        <CheckCircle2 className="h-3.5 w-3.5" strokeWidth={3} />
      </span>
    )
  }
  if (isInProgress) {
    return (
      <span className="grid h-6 w-6 place-items-center rounded-full" style={{ background: '#FFF6E5', color: '#F39C12' }}>
        <Clock className="h-3.5 w-3.5" />
      </span>
    )
  }
  return null
}

// ---------------------------------------------------------------------------
// Subject rail — sized to fill its column at 2xl, scrolls on smaller screens
// ---------------------------------------------------------------------------
function SubjectRail({
  subjects,
  activeId,
  onPick,
  loading,
}: {
  subjects: Subject[]
  activeId: string | null
  onPick: (id: string) => void
  loading: boolean
}) {
  if (loading) {
    return (
      <div className="-mx-2 overflow-x-auto px-2">
        <ul className="flex items-center gap-3 pb-2">
          {Array.from({ length: 6 }).map((_, i) => (
            <li
              key={i}
              className="h-14 w-14 shrink-0 animate-pulse rounded-2xl sm:h-16 sm:w-16"
              style={{ background: BRAND_SURFACE }}
            />
          ))}
        </ul>
      </div>
    )
  }

  if (!subjects.length) return null

  return (
    <div
      className="rounded-2xl border bg-white p-4 shadow-sm sm:p-5"
      style={{ borderColor: BRAND_BORDER }}
    >
      <h3 className="mb-3 text-sm font-semibold text-[#666]">All subjects</h3>
      <ul className="-mx-1 grid grid-flow-col auto-cols-max gap-2 overflow-x-auto px-1 pb-1 2xl:grid-flow-row 2xl:auto-cols-auto 2xl:grid-cols-2 2xl:gap-3 2xl:overflow-visible">
        {subjects.map((s, i) => {
          const isActive = s.id === activeId
          const Icon = iconFor(s)
          const accent = s.color || BRAND_PRIMARY
          return (
            <motion.li
              key={s.id}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: i * 0.03, duration: 0.25, ease: 'easeOut' }}
            >
              <button
                type="button"
                onClick={() => onPick(s.id)}
                aria-label={s.name}
                title={s.name}
                className="flex w-full items-center gap-2.5 rounded-xl border px-2.5 py-2 text-left transition-all hover:-translate-y-0.5 hover:shadow-md 2xl:gap-3 2xl:px-3 2xl:py-2.5"
                style={{
                  borderColor: isActive ? accent : BRAND_BORDER,
                  background: isActive ? `${accent}10` : 'white',
                }}
              >
                <span
                  className="grid h-9 w-9 shrink-0 place-items-center rounded-lg 2xl:h-10 2xl:w-10"
                  style={{ background: `${accent}15`, color: accent }}
                >
                  {s.logo ? (
                    <img
                      src={s.logo}
                      alt=""
                      className="h-6 w-6 object-contain"
                      onError={(e) => {
                        ;(e.currentTarget as HTMLImageElement).style.display = 'none'
                      }}
                    />
                  ) : (
                    <Icon className="h-5 w-5" />
                  )}
                </span>
                <span className="hidden truncate text-sm font-medium text-[#333] 2xl:inline">
                  {s.name}
                </span>
              </button>
            </motion.li>
          )
        })}
      </ul>
    </div>
  )
}
