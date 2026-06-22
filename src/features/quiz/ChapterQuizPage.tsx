/**
 * ChapterQuizPage — quiz route for chapter-Start-Quiz flow.
 * Route: /subjects/:subjectId/modules/:moduleId/chapters/:chapterId/quiz
 */
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useNavigate, useParams } from 'react-router-dom'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import { getSubjectById } from '../../api/subjects'
import { useChapterQuiz } from './useQuizQuestions'
import { useModuleChapters } from '../module/useModuleChapters'
import { QuizFlow, QuizErrorState } from './QuizFlow'
import type { Subject } from '../../types/subject'

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
  void subjectQ.data

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

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader
        title={chapter ? `Quiz · ${chapter.name}` : 'Quiz'}
        onBack={back}
      />
      <PageContainer variant="medium" className="pb-12 pt-2">
        {quizQ.isLoading ? (
          <div className="grid place-items-center py-20">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-[var(--color-primary)] border-t-transparent" />
          </div>
        ) : quizQ.isError ? (
          <QuizErrorState
            message={quizQ.error instanceof Error ? quizQ.error.message : 'Failed to load quiz'}
            onRetry={() => quizQ.refetch()}
            onExit={back}
          />
        ) : (
          <QuizFlow
            questions={quizQ.data ?? []}
            onExit={back}
            onEmpty={back}
            // Original Flutter flow: finishing the last question pushes the
            // student straight to the class standings/podium (no results card).
            onComplete={toStandings}
          />
        )}
      </PageContainer>
    </div>
  )
}
