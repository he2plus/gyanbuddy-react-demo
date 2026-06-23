/**
 * ChapterQuizPage — quiz route for chapter-Start-Quiz flow.
 * Route: /subjects/:subjectId/modules/:moduleId/chapters/:chapterId/quiz
 */
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useNavigate, useParams } from 'react-router-dom'

import { getSubjectById } from '../../api/subjects'
import { getHotsQuestions } from '../../api/quiz'
import { useChapterQuiz } from './useQuizQuestions'
import { useModuleChapters } from '../module/useModuleChapters'
import { FlutterQuizScreen } from './FlutterQuizScreen'
import { QuizErrorState } from './QuizFlow'
import type { Subject } from '../../types/subject'
import type { Question } from '../../types/question'

export function ChapterQuizPage() {
  const navigate = useNavigate()
  const { subjectId = '', moduleId = '', chapterId = '' } = useParams<{
    subjectId: string
    moduleId: string
    chapterId: string
  }>()

  const subjectQ = useQuery<Subject>({
    queryKey: ['subjects', subjectId, 'detail'],
    queryFn: () => getSubjectById(subjectId),
    enabled: !!subjectId,
    staleTime: 5 * 60_000,
  })
  const chaptersQ = useModuleChapters(moduleId)
  const quizQ = useChapterQuiz(chapterId)
  const queryClient = useQueryClient()

  const chapter = chaptersQ.data?.find((c) => c.id === chapterId) ?? null
  const subjectColor = subjectQ.data?.color ?? undefined

  // Fetch HOTS questions only when the chapter declares it has them
  // (mirrors Flutter's `if (widget.chapter.hasHots) _fetchHots()`)
  const hotsQ = useQuery<Question[]>({
    queryKey: ['chapters', chapterId, 'hots'],
    queryFn: () => getHotsQuestions(chapterId),
    enabled: !!chapterId && (chapter?.hasHots ?? false),
    staleTime: 10 * 60_000,
  })

  // Drop the cached progress so the journey, module and subject screens refetch
  // and the character advances to the newly-unlocked chapter.
  const refreshProgress = () => {
    queryClient.invalidateQueries({ queryKey: ['modules', moduleId, 'chapters'] })
    queryClient.invalidateQueries({ queryKey: ['subjects', subjectId, 'modules'] })
    queryClient.invalidateQueries({ queryKey: ['subjects'] })
  }

  const back = () => {
    refreshProgress()
    navigate(`/subjects/${subjectId}/modules/${moduleId}/chapters/${chapterId}`)
  }
  // After a quiz finishes, take the student to the live class standings (the
  // podium). The journey URL is passed as `returnTo` so the podium's "Continue
  // learning" button drops them back on the journey — now advanced one chapter.
  const toStandings = () => {
    refreshProgress()
    navigate('/podium', {
      state: { returnTo: `/subjects/${subjectId}/modules/${moduleId}/chapters` },
    })
  }

  if (quizQ.isLoading) {
    return (
      <div className="min-h-screen bg-white grid place-items-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-[var(--color-primary)] border-t-transparent" />
      </div>
    )
  }

  if (quizQ.isError) {
    return (
      <div className="min-h-screen bg-white p-6">
        <QuizErrorState
          message={quizQ.error instanceof Error ? quizQ.error.message : 'Failed to load quiz'}
          onRetry={() => quizQ.refetch()}
          onExit={back}
        />
      </div>
    )
  }

  return (
    <FlutterQuizScreen
      questions={quizQ.data ?? []}
      subjectColor={subjectColor}
      hotsQuestions={hotsQ.data ?? []}
      onExit={back}
      onEmpty={back}
      onComplete={toStandings}
    />
  )
}
