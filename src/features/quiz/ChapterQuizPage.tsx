/**
 * ChapterQuizPage — quiz route for chapter-Start-Quiz flow.
 * Route: /subjects/:subjectId/modules/:moduleId/chapters/:chapterId/quiz
 */
import { useQuery } from '@tanstack/react-query'
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

  const chapter = chaptersQ.data?.find((c) => c.id === chapterId) ?? null
  const chapters = chaptersQ.data ?? []
  // Fire the celebratory splash when the LAST chapter of the module's quiz
  // is completed — per docx #13 (last topic → chapter-completed animation).
  const isLastChapter =
    chapters.length > 0 &&
    chapter?.id === chapters[chapters.length - 1]?.id
  void subjectQ.data

  const back = () =>
    navigate(`/subjects/${subjectId}/modules/${moduleId}/chapters/${chapterId}`)
  // After the splash, go back to the journey page (not the chapter detail)
  // so the user can see the whole path marked completed.
  const backToJourney = () =>
    navigate(`/subjects/${subjectId}/modules/${moduleId}/chapters`)

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
            onExit={isLastChapter ? backToJourney : back}
            celebration={
              isLastChapter && chapter
                ? {
                    chapterName: chapter.name,
                    moduleName: 'this module',
                    enabled: true,
                  }
                : undefined
            }
          />
        )}
      </PageContainer>
    </div>
  )
}
