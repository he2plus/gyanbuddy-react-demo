/**
 * LeaderboardPage — class-wide leaderboard.
 *
 * Flat brand palette. Class chip is solid primary (was a gradient). Dropped
 * the floating decorative circles + fade bands.
 */
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { AlertTriangle } from 'lucide-react'

import { ScreenHeader } from '../../components/ScreenHeader'
import { Button } from '../../components/Button'
import { PageContainer } from '../../components/PageContainer'
import { useLeaderboard } from './useLeaderboard'
import { useAuthStore } from '../../state/auth'
import type { LeaderboardPeriod } from '../../api/leaderboard'
import type { User } from '../../types/user'

const BRAND_PRIMARY = '#365DEA'
const BRAND_BORDER = '#E0E0E0'

const PERIODS: LeaderboardPeriod[] = ['daily', 'weekly', 'monthly', 'all-time']

export function LeaderboardPage() {
  const [period, setPeriod] = useState<LeaderboardPeriod>('all-time')
  const [page, setPage] = useState(1)
  const me = useAuthStore((s) => s.user)

  const limit = 20
  const { data, isLoading, isError, error, refetch, isFetching } =
    useLeaderboard({ period, page, limit })

  const users = data?.users ?? []

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader title="Leaderboard" showBack={false} />

      <PageContainer variant="medium" className="pb-10 pt-4">
        {/* Class + period */}
        <div className="mb-4 flex flex-wrap items-center gap-3">
          {(data?.className || data?.gradeName) && (
            <span
              className="rounded-md px-3 py-1.5 text-sm font-semibold text-white"
              style={{ background: BRAND_PRIMARY }}
            >
              {data.className ?? data.gradeName}
            </span>
          )}
          <PeriodPills
            value={period}
            onChange={(p) => {
              setPeriod(p)
              setPage(1)
            }}
          />
        </div>

        {isLoading && <LoadingState />}
        {isError && (
          <ErrorState
            message={
              error instanceof Error ? error.message : 'Error loading leaderboard'
            }
            onRetry={() => refetch()}
          />
        )}
        {!isLoading && !isError && users.length === 0 && <EmptyState />}
        {!isLoading && !isError && users.length > 0 && (
          <ul className="space-y-2.5 pt-2">
            <AnimatePresence initial={false}>
              {users.map((u, i) => (
                <LeaderboardRow
                  key={u.id || i}
                  user={u}
                  rank={(page - 1) * limit + i + 1}
                  isMe={!!me && me.id === u.id}
                />
              ))}
            </AnimatePresence>
          </ul>
        )}

        {!isLoading && !isError && users.length >= limit && (
          <div className="mt-6 flex justify-center">
            <Button
              variant="secondary"
              onClick={() => setPage((p) => p + 1)}
              disabled={isFetching}
              loading={isFetching}
            >
              Load more
            </Button>
          </div>
        )}
      </PageContainer>
    </div>
  )
}

function PeriodPills({
  value,
  onChange,
}: {
  value: LeaderboardPeriod
  onChange: (p: LeaderboardPeriod) => void
}) {
  return (
    <div
      className="inline-flex overflow-hidden rounded-md border"
      role="tablist"
      style={{ borderColor: BRAND_BORDER }}
    >
      {PERIODS.map((p, i) => {
        const active = p === value
        return (
          <button
            key={p}
            type="button"
            role="tab"
            aria-selected={active}
            onClick={() => onChange(p)}
            className={`px-3 py-1.5 text-[11px] font-bold uppercase tracking-widest transition-colors ${
              i > 0 ? 'border-l' : ''
            } ${active ? 'text-white' : 'text-[#666] hover:bg-[#F5F5F5]'}`}
            style={{
              borderColor: BRAND_BORDER,
              background: active ? BRAND_PRIMARY : 'transparent',
            }}
          >
            {p}
          </button>
        )
      })}
    </div>
  )
}

function rankColor(rank: number): string {
  if (rank === 1) return '#FACC15'
  if (rank === 2) return '#9CA3AF'
  if (rank === 3) return '#92400E'
  return BRAND_PRIMARY
}

function LeaderboardRow({
  user,
  rank,
  isMe,
}: {
  user: User
  rank: number
  isMe: boolean
}) {
  const initials = (user.firstName?.[0] ?? user.username?.[0] ?? 'U').toUpperCase()
  return (
    <motion.li
      layout
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
      className="flex items-center gap-4 rounded-xl border bg-white p-3.5"
      style={{
        borderColor: isMe ? BRAND_PRIMARY : BRAND_BORDER,
        background: isMe ? '#F1F4FE' : 'white',
      }}
    >
      <span
        className="grid h-9 w-9 shrink-0 place-items-center rounded-full text-sm font-bold text-white"
        style={{ background: rankColor(rank) }}
      >
        {rank}
      </span>

      {user.profilePicture ? (
        <img
          src={user.profilePicture}
          alt=""
          className="h-10 w-10 rounded-full object-cover"
        />
      ) : (
        <span
          className="grid h-10 w-10 shrink-0 place-items-center rounded-full text-sm font-bold text-white"
          style={{ background: BRAND_PRIMARY }}
          aria-hidden="true"
        >
          {initials}
        </span>
      )}

      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <span className="truncate text-sm font-semibold text-[#222]">
            {user.fullName || user.username || 'User'}
          </span>
          {isMe && (
            <span
              className="rounded-md px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-widest text-white"
              style={{ background: BRAND_PRIMARY }}
            >
              You
            </span>
          )}
        </div>
        <div className="text-xs text-[#666]">
          Level {user.level?.name ?? Math.floor(user.totalExp / 100) + 1}
        </div>
      </div>

      <div className="shrink-0 text-right">
        <div className="text-sm font-bold text-[#222] tabular-nums">
          {user.totalExp.toLocaleString()}
        </div>
        <div className="text-[10px] font-semibold uppercase tracking-widest text-[#999]">
          XP
        </div>
      </div>
    </motion.li>
  )
}

function LoadingState() {
  return (
    <ul className="space-y-2.5 pt-2">
      {Array.from({ length: 5 }).map((_, i) => (
        <li
          key={i}
          className="h-16 animate-pulse rounded-xl border bg-white"
          style={{ borderColor: BRAND_BORDER }}
        />
      ))}
    </ul>
  )
}

function EmptyState() {
  return (
    <div className="grid place-items-center py-20 text-[#666]">
      No users found
    </div>
  )
}

function ErrorState({
  message,
  onRetry,
}: {
  message: string
  onRetry: () => void
}) {
  return (
    <div className="grid place-items-center px-6 py-16 text-center">
      <AlertTriangle className="h-10 w-10 text-[#999]" />
      <h2 className="mt-3 text-base font-bold text-[#444]">
        Couldn't load leaderboard
      </h2>
      <p className="mt-1 text-sm text-[#888]">{message}</p>
      <div className="mt-5">
        <Button onClick={onRetry}>Retry</Button>
      </div>
    </div>
  )
}
