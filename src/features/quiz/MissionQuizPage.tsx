/**
 * MissionQuizPage — quiz route for the daily-mission flow.
 * Route: /missions/:missionId/quiz
 */
import { useNavigate, useParams } from 'react-router-dom'

import { useMissions } from '../mission/useMissions'
import { FlutterQuizScreen } from '../quiz/FlutterQuizScreen'
import { QuizErrorState } from '../quiz/QuizFlow'

export function MissionQuizPage() {
  const navigate = useNavigate()
  const { missionId = '' } = useParams<{ missionId: string }>()
  const missionsQ = useMissions()
  const mission = missionsQ.data?.find((m) => m.id === missionId)

  // Original Flutter flow: finishing the mission quiz pops straight back to the
  // mission detail screen (Navigator.pop(context, mission.id)) — not the
  // leaderboard. Exiting mid-quiz returns to the same place.
  const back = () => navigate(`/missions/${missionId}`)

  if (missionsQ.isLoading) {
    return (
      <div className="min-h-screen bg-white grid place-items-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-[var(--color-primary)] border-t-transparent" />
      </div>
    )
  }

  if (missionsQ.isError || !mission) {
    return (
      <div className="min-h-screen bg-white p-6">
        <QuizErrorState
          message={missionsQ.error instanceof Error ? missionsQ.error.message : 'Mission not found'}
          onRetry={() => missionsQ.refetch()}
          onExit={back}
        />
      </div>
    )
  }

  return (
    <FlutterQuizScreen
      questions={mission.questions}
      onExit={back}
      onComplete={back}
    />
  )
}
