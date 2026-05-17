import { useQuery } from '@tanstack/react-query'
import { getLeaderboard, type LeaderboardQuery } from '../../api/leaderboard'

export function useLeaderboard(q: LeaderboardQuery) {
  return useQuery({
    queryKey: ['leaderboard', q],
    queryFn: () => getLeaderboard(q),
    staleTime: 30_000,
  })
}
