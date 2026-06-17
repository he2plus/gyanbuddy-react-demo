/**
 * MissionDetailPage — mirrors lib/screens/mission/mission_detail_screen.dart
 * (the preview portion). Start hands off to the shared QuizFlow.
 *
 * Flat hero on solid subject color (was a 135deg gradient). No `Target` icon
 * prefixing the subject pill. Status pills are bordered text labels.
 */
import { useMemo } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { motion } from 'framer-motion'
import { AlertTriangle, ArrowRight, CheckCircle2, PlayCircle } from 'lucide-react'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import { Button } from '../../components/Button'
import { useMissions } from './useMissions'

const BRAND_PRIMARY = '#365DEA'
const BRAND_BORDER = '#E0E0E0'

export function MissionDetailPage() {
  const navigate = useNavigate()
  const { missionId = '' } = useParams<{ missionId: string }>()
  const missionsQ = useMissions()

  const mission = useMemo(
    () => missionsQ.data?.find((m) => m.id === missionId),
    [missionsQ.data, missionId],
  )

  if (missionsQ.isLoading) {
    return (
      <div className="min-h-screen bg-white">
        <ScreenHeader title="Mission" />
        <PageContainer variant="medium" className="py-10">
          <div className="grid place-items-center py-20">
            <div
              className="h-8 w-8 animate-spin rounded-full border-4 border-t-transparent"
              style={{
                borderColor: `${BRAND_PRIMARY} transparent ${BRAND_PRIMARY} ${BRAND_PRIMARY}`,
              }}
            />
          </div>
        </PageContainer>
      </div>
    )
  }

  if (missionsQ.isError || !mission) {
    return (
      <div className="min-h-screen bg-white">
        <ScreenHeader title="Mission" />
        <PageContainer variant="medium" className="py-10">
          <div className="grid place-items-center px-6 py-16 text-center">
            <AlertTriangle className="h-10 w-10 text-[#999]" />
            <h2 className="mt-3 text-base font-bold text-[#444]">
              {missionsQ.isError ? "Couldn't load mission" : 'Mission not found'}
            </h2>
            <div className="mt-5">
              <Button onClick={() => navigate('/missions')}>
                Back to missions
              </Button>
            </div>
          </div>
        </PageContainer>
      </div>
    )
  }

  const accent = mission.subject.color || BRAND_PRIMARY
  const completed = mission.userCompleted || mission.status === 'completed'
  const xpAvailable = mission.questions.reduce((sum, q) => sum + q.expPoints, 0)

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader
        title={mission.subject.name ? `${mission.subject.name} mission` : 'Mission'}
        onBack={() => navigate('/missions')}
      />

      <PageContainer variant="medium" className="pb-12 pt-2">
        {/* Hero — flat color, no gradient */}
        <motion.section
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
          className="rounded-xl p-6 text-white sm:p-8"
          style={{ background: accent }}
        >
          <div className="flex items-start justify-between gap-3">
            {mission.subject.name && (
              <div className="text-[11px] font-bold uppercase tracking-widest text-white/80">
                {mission.subject.name}
              </div>
            )}
            {completed ? (
              <span className="rounded-md border border-white/40 bg-white/15 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-white backdrop-blur">
                <CheckCircle2 className="mr-1 inline h-3 w-3" />
                Completed
              </span>
            ) : mission.userStarted ? (
              <span className="rounded-md border border-white/40 bg-white/15 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-white backdrop-blur">
                <PlayCircle className="mr-1 inline h-3 w-3" />
                Started
              </span>
            ) : null}
          </div>
          <h1 className="mt-2 text-2xl font-extrabold leading-tight tracking-tight sm:text-3xl">
            {mission.title}
          </h1>
          {mission.description && (
            <p className="mt-2 max-w-2xl text-sm text-white/90">
              {mission.description}
            </p>
          )}
          <div className="mt-5 flex flex-wrap gap-x-6 gap-y-2">
            <Stat label="Questions" value={mission.questionCount} />
            {xpAvailable > 0 && <Stat label="XP available" value={xpAvailable} />}
            <Stat label="Date" value={mission.missionDate} />
          </div>
        </motion.section>

        {/* CTA */}
        <section
          className="mt-5 flex flex-col items-center gap-3 rounded-xl border bg-white p-5 sm:flex-row sm:justify-between sm:p-6"
          style={{ borderColor: BRAND_BORDER }}
        >
          <div>
            <div className="text-sm text-[#666]">
              {completed
                ? 'You already finished this mission.'
                : mission.userStarted
                  ? 'Pick up where you left off.'
                  : 'Ready when you are.'}
            </div>
            <div className="text-base font-bold text-[#222]">
              {completed ? 'Review the questions' : 'Start the mission'}
            </div>
          </div>
          <Button
            onClick={() => navigate(`/missions/${mission.id}/quiz`)}
            className="px-6"
          >
            {completed ? 'Review' : 'Start'}
            <ArrowRight className="h-4 w-4" />
          </Button>
        </section>

        {/* Question titles only */}
        {mission.questions.length > 0 && (
          <section
            className="mt-5 rounded-xl border bg-white p-5 sm:p-6"
            style={{ borderColor: BRAND_BORDER }}
          >
            <h2 className="text-sm font-bold uppercase tracking-widest text-[#666]">
              What's inside
            </h2>
            <ol className="mt-3 space-y-2">
              {mission.questions.map((q, i) => (
                <li
                  key={q.id}
                  className="flex items-start gap-3 rounded-lg bg-[#F8F9FA] p-3"
                >
                  <span
                    className="grid h-6 w-6 shrink-0 place-items-center rounded text-[11px] font-bold text-white"
                    style={{ background: accent }}
                  >
                    {i + 1}
                  </span>
                  <span className="text-sm text-[#333]">{q.text}</span>
                </li>
              ))}
            </ol>
          </section>
        )}
      </PageContainer>
    </div>
  )
}

function Stat({ label, value }: { label: string; value: number | string }) {
  return (
    <div className="flex items-baseline gap-1.5">
      <span className="text-lg font-bold tabular-nums">{value}</span>
      <span className="text-xs uppercase tracking-widest text-white/80">
        {label}
      </span>
    </div>
  )
}
