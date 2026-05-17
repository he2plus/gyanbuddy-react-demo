import { useQuery } from '@tanstack/react-query'
import { getMyTests, getTestById, getTestQuestions } from '../../api/tests'

export function useMyTests() {
  return useQuery({
    queryKey: ['tests'],
    queryFn: () => getMyTests(),
    staleTime: 30_000,
  })
}

export function useTest(id: string | undefined) {
  return useQuery({
    queryKey: ['tests', id],
    queryFn: () => getTestById(id!),
    enabled: !!id,
    staleTime: 30_000,
  })
}

export function useTestQuestions(id: string | undefined) {
  return useQuery({
    queryKey: ['tests', id, 'questions'],
    queryFn: () => getTestQuestions(id!),
    enabled: !!id,
    staleTime: 30_000,
  })
}
