import { useQuery } from '@tanstack/react-query'
import { getAllSubjects } from '../../api/subjects'

export function useSubjects() {
  return useQuery({
    queryKey: ['subjects'],
    queryFn: getAllSubjects,
    staleTime: 5 * 60_000,
  })
}
