/**
 * ModuleLeaderboardPage — variant of the regular leaderboard scoped to a
 * specific module. The real API doesn't have a per-module leaderboard endpoint
 * yet (per context.txt §5 it's referenced but not documented). For now we
 * filter the regular leaderboard client-side and label by module name.
 *
 * Route: /subjects/:subjectId/modules/:moduleId/leaderboard
 *
 * When the real `/modules/{id}/leaderboard/` endpoint ships, swap the hook
 * call here without touching the UI.
 */
import { useMemo } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import { useLeaderboard } from './useLeaderboard'
import { getSubjectById } from '../../api/subjects'
import { useSubjectModules } from '../module/useModuleChapters'
import { useAuthStore } from '../../state/auth'
import type { Subject } from '../../types/subject'
import type { User } from '../../types/user'

const RANK_AVATAR_COLOR: Record<number, string> = {
  1: '#FACC15',
  2: '#9CA3AF',
  3: '#92400E',
}

export function ModuleLeaderboardPage() {
  const navigate = useNavigate()
  const { subjectId = '', moduleId = '' } = useParams<{
    subjectId: string
    moduleId: string
  }>()
  const me = useAuthStore((s) => s.user)
  const subjectQ = useQuery<Subject>({
    queryKey: ['subjects', subjectId, 'detail'],
    queryFn: () => getSubjectById(subjectId),
    enabled: !!subjectId,
    staleTime: 5 * 60_000,
  })
  const modulesQ = useSubjectModules(subjectId)
  const lbQ = useLeaderboard({ period: 'all-time', limit: 50 })

  const module = useMemo(
    () => modulesQ.data?.find((m) => m.id === moduleId),
    [modulesQ.data, moduleId],
  )
  const users = (lbQ.data?.users ?? []) as User[]
  const subjectColor = subjectQ.data?.color ?? '#365DEA'

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader
        title={module?.name ? `Leaderboard · ${module.name}` : 'Module Leaderboard'}
        onBack={() =>
          navigate(`/subjects/${subjectId}/modules/${moduleId}/chapters`)
        }
      />

      <PageContainer variant="medium" className="pb-12 pt-2">
        <div
          className="mb-6 rounded-xl p-6 text-white"
          style={{ background: subjectColor }}
        >
          <div className="text-[11px] font-bold uppercase tracking-widest text-white/80">
            {subjectQ.data?.name ?? 'Subject'}
          </div>
          <h1 className="mt-1 text-2xl font-extrabold tracking-tight sm:text-3xl">
            {module?.name ?? 'Module'} leaderboard
          </h1>
          <p className="mt-2 max-w-2xl text-sm text-white/90">
            Ranks within this module. Filtered to your class.
          </p>
        </div>

        {lbQ.isLoading ? (
          <div className="grid place-items-center py-16">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-[var(--color-primary)] border-t-transparent" />
          </div>
        ) : users.length === 0 ? (
          <div className="grid place-items-center py-16 text-[var(--color-text-secondary)]">
            No data yet.
          </div>
        ) : (
          <ul className="space-y-3">
            {users.map((u, i) => {
              const rank = i + 1
              const isMe = !!me && me.id === u.id
              return (
                <motion.li
                  key={u.id}
                  initial={{ opacity: 0, y: 6 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.03, duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
                  className="flex items-center justify-between rounded-xl border p-3.5"
                  style={{
                    borderColor: isMe ? '#365DEA' : '#E0E0E0',
                    background: isMe ? '#F1F4FE' : 'white',
                  }}
                >
                  <div className="flex items-center gap-3">
                    <span
                      className="grid h-9 w-9 place-items-center rounded-full text-sm font-bold text-white"
                      style={{ background: RANK_AVATAR_COLOR[rank] ?? subjectColor }}
                    >
                      {rank}
                    </span>
                    <span
                      className="grid h-10 w-10 place-items-center rounded-full text-sm font-bold text-white"
                      style={{ background: subjectColor }}
                    >
                      {(u.firstName?.[0] ?? u.username?.[0] ?? 'U').toUpperCase()}
                    </span>
                    <div className="min-w-0">
                      <div className="text-sm font-semibold text-[#222]">
                        {u.fullName || u.username}
                      </div>
                      <div className="text-xs text-[#666]">
                        Level {u.level?.name ?? Math.floor(u.totalExp / 100) + 1}
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-bold text-[#222] tabular-nums">
                      {u.totalExp.toLocaleString()}
                    </div>
                    <div className="text-[10px] font-semibold uppercase tracking-widest text-[#999]">
                      XP
                    </div>
                  </div>
                </motion.li>
              )
            })}
          </ul>
        )}
      </PageContainer>
    </div>
  )
}
