/**
 * TestQuizPage — mirrors lib/screens/test/test_quiz_screen.dart.
 *
 * Wraps the shared <QuizFlow/> with a countdown timer that's specific to
 * tests (the test must be completed within `durationMinutes` of `testDatetime`).
 * Calls `startTest` on mount and `completeTest` when the user finishes or
 * the timer hits zero.
 */
import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Clock, AlertTriangle } from 'lucide-react'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import { Button } from '../../components/Button'
import { FlutterQuizScreen } from '../quiz/FlutterQuizScreen'
import { QuizErrorState } from '../quiz/QuizFlow'
import { useTest, useTestQuestions } from './useTests'
import { startTest, completeTest } from '../../api/tests'

export function TestQuizPage() {
  const navigate = useNavigate()
  const { testId = '' } = useParams<{ testId: string }>()

  const testQ = useTest(testId)
  const questionsQ = useTestQuestions(testId)

  const startCalledRef = useRef(false)
  useEffect(() => {
    if (testQ.data && testQ.data.status === 'active' && !startCalledRef.current) {
      startCalledRef.current = true
      // Fire-and-forget; failure shouldn't block the UI.
      void startTest(testId).catch(() => undefined)
    }
  }, [testQ.data, testId])

  const back = () => navigate('/tests')

  const test = testQ.data
  const accent = test?.subjectColor || '#FF9800'
  const totalSeconds = useMemo(() => {
    if (!test) return 0
    const end = new Date(test.testEndTime).getTime()
    return Math.max(0, Math.floor((end - Date.now()) / 1000))
  }, [test])

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader title={test ? test.title : 'Test'} onBack={back} />

      <PageContainer variant="medium" className="pb-12 pt-2">
        {testQ.isLoading || questionsQ.isLoading ? (
          <div className="grid place-items-center py-20">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-[var(--color-primary)] border-t-transparent" />
          </div>
        ) : testQ.isError || questionsQ.isError || !test ? (
          <QuizErrorState
            message={
              testQ.error instanceof Error
                ? testQ.error.message
                : questionsQ.error instanceof Error
                  ? questionsQ.error.message
                  : 'Failed to load test'
            }
            onRetry={() => {
              testQ.refetch()
              questionsQ.refetch()
            }}
            onExit={back}
          />
        ) : test.status === 'upcoming' ? (
          <UpcomingState test={test} onExit={back} />
        ) : test.status === 'skipped' ? (
          <SkippedState onExit={back} />
        ) : test.status === 'completed' ? (
          <CompletedState test={test} onExit={back} />
        ) : (
          <div className="flex flex-col" style={{ height: 'calc(100vh - 56px)', overflow: 'hidden' }}>
            <TimerBar totalSeconds={totalSeconds} accent={accent} onExpire={() => void completeTest(testId).catch(() => undefined)} />
            <div className="flex-1 overflow-hidden">
              <FlutterQuizScreen
                questions={questionsQ.data ?? test.questions ?? []}
                subjectColor={accent}
                onExit={async () => {
                  await completeTest(testId).catch(() => undefined)
                  navigate('/tests')
                }}
                onComplete={async () => {
                  await completeTest(testId).catch(() => undefined)
                  navigate('/tests')
                }}
              />
            </div>
          </div>
        )}
      </PageContainer>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Timer banner — counts down to the test's `testEndTime`
// ---------------------------------------------------------------------------
function TimerBar({
  totalSeconds,
  accent,
  onExpire,
}: {
  totalSeconds: number
  accent: string
  onExpire: () => void
}) {
  const [remaining, setRemaining] = useState(totalSeconds)
  useEffect(() => setRemaining(totalSeconds), [totalSeconds])
  useEffect(() => {
    const id = window.setInterval(() => {
      setRemaining((s) => {
        if (s <= 1) {
          window.clearInterval(id)
          onExpire()
          return 0
        }
        return s - 1
      })
    }, 1000)
    return () => window.clearInterval(id)
  }, [onExpire])

  const minutes = Math.floor(remaining / 60)
  const seconds = remaining % 60
  const isLow = remaining < 60

  return (
    <motion.div
      initial={{ opacity: 0, y: -8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className={`sticky top-14 z-20 mb-4 flex items-center justify-between gap-3 rounded-xl border px-4 py-2.5 shadow-sm backdrop-blur ${
        isLow
          ? 'border-red-300 bg-red-50/90 text-red-700'
          : 'border-[var(--color-input-border)] bg-white/95 text-[var(--color-text-primary)]'
      }`}
    >
      <div className="flex items-center gap-2 text-sm">
        <Clock className="h-4 w-4" />
        <span className="font-semibold">Time remaining</span>
      </div>
      <div
        className="font-mono text-lg font-bold tabular-nums"
        style={!isLow ? { color: accent } : undefined}
      >
        {String(minutes).padStart(2, '0')}:{String(seconds).padStart(2, '0')}
      </div>
    </motion.div>
  )
}

function UpcomingState({ test, onExit }: { test: { testDatetime: string }; onExit: () => void }) {
  const t = new Date(test.testDatetime)
  return (
    <div className="grid place-items-center rounded-2xl border border-amber-200 bg-amber-50 px-6 py-12 text-center">
      <Clock className="h-12 w-12 text-amber-600" />
      <h2 className="mt-4 text-lg font-bold text-amber-900">Not yet available</h2>
      <p className="mt-1 text-sm text-amber-700">
        This test opens at{' '}
        {t.toLocaleString(undefined, {
          weekday: 'long',
          month: 'long',
          day: 'numeric',
          hour: 'numeric',
          minute: '2-digit',
        })}.
      </p>
      <div className="mt-6">
        <Button variant="secondary" onClick={onExit}>
          Back to tests
        </Button>
      </div>
    </div>
  )
}

function SkippedState({ onExit }: { onExit: () => void }) {
  return (
    <div className="grid place-items-center rounded-2xl border border-red-200 bg-red-50 px-6 py-12 text-center">
      <AlertTriangle className="h-12 w-12 text-red-600" />
      <h2 className="mt-4 text-lg font-bold text-red-900">Window has closed</h2>
      <p className="mt-1 text-sm text-red-700">
        This test is no longer available. Speak to your teacher if you need a make-up slot.
      </p>
      <div className="mt-6">
        <Button variant="secondary" onClick={onExit}>
          Back to tests
        </Button>
      </div>
    </div>
  )
}

function CompletedState({
  test,
  onExit,
}: {
  test: { progress: { score: number; correctAnswers: number; totalQuestions: number; expEarned: number; percentage: number } | null }
  onExit: () => void
}) {
  const p = test.progress
  return (
    <div className="grid place-items-center rounded-2xl border border-emerald-200 bg-emerald-50 px-6 py-12 text-center">
      <div className="text-4xl">🏆</div>
      <h2 className="mt-3 text-xl font-bold text-emerald-900">Test complete</h2>
      {p && (
        <p className="mt-2 text-sm text-emerald-800">
          You scored <span className="font-bold">{p.score}</span> ({p.correctAnswers}/{p.totalQuestions}{' '}
          correct · {p.percentage}%) and earned <span className="font-bold">{p.expEarned} XP</span>.
        </p>
      )}
      <div className="mt-6">
        <Button onClick={onExit}>Back to tests</Button>
      </div>
    </div>
  )
}
