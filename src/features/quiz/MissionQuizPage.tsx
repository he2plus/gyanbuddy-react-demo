/**
 * MissionQuizPage — quiz route for the daily-mission flow.
 * Route: /missions/:missionId/quiz
 */
import { useNavigate, useParams } from 'react-router-dom'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import { useMissions } from '../mission/useMissions'
import { QuizFlow, QuizErrorState } from './QuizFlow'

export function MissionQuizPage() {
  const navigate = useNavigate()
  const { missionId = '' } = useParams<{ missionId: string }>()
  const missionsQ = useMissions()
  const mission = missionsQ.data?.find((m) => m.id === missionId)

  const back = () => navigate(`/missions/${missionId}`)

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader
        title={mission ? `Mission · ${mission.title}` : 'Mission Quiz'}
        onBack={back}
      />
      <PageContainer variant="medium" className="pb-12 pt-2">
        {missionsQ.isLoading ? (
          <div className="grid place-items-center py-20">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-[var(--color-primary)] border-t-transparent" />
          </div>
        ) : missionsQ.isError || !mission ? (
          <QuizErrorState
            message={
              missionsQ.error instanceof Error
                ? missionsQ.error.message
                : 'Mission not found'
            }
            onRetry={() => missionsQ.refetch()}
            onExit={back}
          />
        ) : (
          <QuizFlow
            questions={mission.questions}
            onExit={back}
          />
        )}
      </PageContainer>
    </div>
  )
}
