import { useQuery } from '@tanstack/react-query'
import { getChapterQuestions, getMissionQuestions } from '../../api/quiz'

export function useChapterQuiz(chapterId: string | undefined) {
  return useQuery({
    queryKey: ['quiz', 'chapter', chapterId],
    queryFn: () => getChapterQuestions(chapterId!),
    enabled: !!chapterId,
    staleTime: 30_000,
  })
}

export function useMissionQuiz(missionId: string | undefined) {
  return useQuery({
    queryKey: ['quiz', 'mission', missionId],
    queryFn: () => getMissionQuestions(missionId!),
    enabled: !!missionId,
    staleTime: 30_000,
  })
}
