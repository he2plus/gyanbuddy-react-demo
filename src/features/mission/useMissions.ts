import { useQuery } from '@tanstack/react-query'
import { getUserMissions } from '../../api/missions'

export function useMissions() {
  return useQuery({
    queryKey: ['missions'],
    queryFn: getUserMissions,
    staleTime: 60_000,
  })
}
