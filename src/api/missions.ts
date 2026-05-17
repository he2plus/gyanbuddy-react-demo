/**
 * Missions API — mirrors lib/services/mission_api_service.dart usage and the
 * `getUserMissions` call in lib/services/user_api_service.dart.
 *
 * Endpoint: GET /missions/   →   { success, message, data: Mission[] }
 *
 * Mock-aware: returns fixtures so /missions and the detail flow are
 * browseable without a backend.
 */
import { api } from './client'
import type { ApiEnvelope } from '../types/api'
import { parseMission, type Mission, type MissionDTO } from '../types/mission'
import type { QuestionDTO } from '../types/question'
import { isMockSessionActive } from './modules'

export async function getUserMissions(): Promise<Mission[]> {
  if (isMockSessionActive()) return mockMissions()

  const { data: envelope } = await api.get<ApiEnvelope<MissionDTO[]>>('/missions/')
  // Dart accepts either { success: true } or { status: 'success' }
  const ok =
    envelope.success === true ||
    (envelope as unknown as { status?: string }).status === 'success'
  if (!ok) {
    throw new Error(envelope.message || 'Failed to load missions')
  }
  return (envelope.data ?? []).map(parseMission)
}

// ---------------------------------------------------------------------------
// Mock fixtures — 7 missions spread across the current week + past + future
// ---------------------------------------------------------------------------

function dayOffset(days: number): string {
  const d = new Date()
  d.setDate(d.getDate() + days)
  return d.toISOString().slice(0, 10)
}

function mockOption(id: string, text: string, correct: boolean, order: number): QuestionDTO['options'] extends (infer T)[] | undefined ? T : never {
  return {
    id,
    option_text: text,
    is_correct: correct,
    order,
  } as never
}

function mockQuestion(opts: {
  id: string
  text: string
  options: Array<{ text: string; correct?: boolean }>
  expPoints?: number
  hint?: string
  explanation?: string
}): QuestionDTO {
  return {
    id: opts.id,
    question_text: opts.text,
    question_type: 'mcq_single',
    exp_points: opts.expPoints ?? 10,
    difficulty_level: 'medium',
    is_active: true,
    is_hots: false,
    level: 1,
    hint: opts.hint,
    explanation: opts.explanation,
    options: opts.options.map((o, i) =>
      mockOption(`${opts.id}-o${i + 1}`, o.text, o.correct === true, i + 1),
    ),
  }
}

function mockMissions(): Mission[] {
  const dtos: MissionDTO[] = [
    {
      id: 'm-1',
      title: 'Daily Chemistry Challenge',
      description:
        'Five questions on chemical reactions to keep your streak going.',
      mission_date: dayOffset(0),
      status: 'in_progress',
      user_completed: false,
      user_started: true,
      subject: { id: 'chem', name: 'Chemistry', color: '#3B82F6' },
      questions: [
        mockQuestion({
          id: 'm-1-q1',
          text: 'Which of the following is a chemical change?',
          options: [
            { text: 'Melting of ice' },
            { text: 'Burning of paper', correct: true },
            { text: 'Boiling of water' },
            { text: 'Crushing a can' },
          ],
          explanation:
            'Burning irreversibly produces new substances — that is a chemical change.',
        }),
        mockQuestion({
          id: 'm-1-q2',
          text: 'The pH of a neutral solution at 25°C is:',
          options: [
            { text: '0' },
            { text: '7', correct: true },
            { text: '14' },
            { text: '1' },
          ],
        }),
        mockQuestion({
          id: 'm-1-q3',
          text: 'Which gas is produced when an acid reacts with a metal?',
          options: [
            { text: 'Oxygen' },
            { text: 'Carbon dioxide' },
            { text: 'Hydrogen', correct: true },
            { text: 'Nitrogen' },
          ],
        }),
      ],
    },
    {
      id: 'm-2',
      title: 'Physics Speed Round',
      description: 'Quick concepts from motion + forces.',
      mission_date: dayOffset(0),
      status: 'not_started',
      user_completed: false,
      user_started: false,
      subject: { id: 'phys', name: 'Physics', color: '#8B5CF6' },
      questions: [
        mockQuestion({
          id: 'm-2-q1',
          text: 'SI unit of force is:',
          options: [
            { text: 'Joule' },
            { text: 'Newton', correct: true },
            { text: 'Watt' },
            { text: 'Pascal' },
          ],
        }),
        mockQuestion({
          id: 'm-2-q2',
          text: 'Acceleration due to gravity on Earth is approximately:',
          options: [
            { text: '9.8 m/s²', correct: true },
            { text: '8.9 m/s²' },
            { text: '10.8 m/s²' },
            { text: '6.5 m/s²' },
          ],
        }),
      ],
    },
    {
      id: 'm-3',
      title: 'Biology Recap',
      description: 'Cells and tissues quickfire.',
      mission_date: dayOffset(-1),
      status: 'completed',
      user_completed: true,
      user_started: true,
      subject: { id: 'bio', name: 'Biology', color: '#10B981' },
      questions: [
        mockQuestion({
          id: 'm-3-q1',
          text: 'The basic unit of life is:',
          options: [
            { text: 'Tissue' },
            { text: 'Organ' },
            { text: 'Cell', correct: true },
            { text: 'Organ system' },
          ],
        }),
      ],
    },
    {
      id: 'm-4',
      title: 'Math Warmup',
      description: 'Algebraic identities + linear equations.',
      mission_date: dayOffset(-2),
      status: 'completed',
      user_completed: true,
      user_started: true,
      subject: { id: 'math', name: 'Mathematics', color: '#F59E0B' },
      questions: [
        mockQuestion({
          id: 'm-4-q1',
          text: '(a + b)² is equal to:',
          options: [
            { text: 'a² + b²' },
            { text: 'a² + 2ab + b²', correct: true },
            { text: 'a² − 2ab + b²' },
            { text: 'a² + ab + b²' },
          ],
        }),
      ],
    },
    {
      id: 'm-5',
      title: 'Geography Mini',
      description: 'Continents and capitals.',
      mission_date: dayOffset(1),
      status: 'not_started',
      user_completed: false,
      user_started: false,
      subject: { id: 'geo', name: 'Geography', color: '#06B6D4' },
      questions: [
        mockQuestion({
          id: 'm-5-q1',
          text: 'Which continent has the most countries?',
          options: [
            { text: 'Asia' },
            { text: 'Europe' },
            { text: 'Africa', correct: true },
            { text: 'South America' },
          ],
        }),
      ],
    },
    {
      id: 'm-6',
      title: 'History Snapshot',
      description: 'Indian independence movement essentials.',
      mission_date: dayOffset(2),
      status: 'not_started',
      user_completed: false,
      user_started: false,
      subject: { id: 'hist', name: 'History', color: '#A855F7' },
      questions: [
        mockQuestion({
          id: 'm-6-q1',
          text: 'India gained independence in which year?',
          options: [
            { text: '1945' },
            { text: '1947', correct: true },
            { text: '1950' },
            { text: '1942' },
          ],
        }),
      ],
    },
  ]
  return dtos.map(parseMission)
}
