/**
 * Quiz API — wraps:
 *   GET  /module_chapters/{chapterId}/module_questions/   → list of Questions
 *   POST /questions/{questionId}/check/                   → verify an answer
 *
 * Plus a mission-quiz path that re-uses the embedded questions on the Mission
 * object (no extra round-trip).
 *
 * In mock mode we answer-check client-side using the `is_correct` flag on
 * options. Real backend will return server-validated correctness.
 */
import { api } from './client'
import type { ApiEnvelope } from '../types/api'
import { parseQuestion, type Question, type QuestionDTO } from '../types/question'
import { isMockSessionActive } from './modules'
import { getUserMissions } from './missions'
import { getModuleChapters } from './modules'

export async function getChapterQuestions(chapterId: string): Promise<Question[]> {
  if (isMockSessionActive()) {
    // Mock path: synthesize a small quiz per chapter so the flow works offline.
    return mockQuestionsForChapter(chapterId)
  }
  const { data: envelope } = await api.get<ApiEnvelope<QuestionDTO[]>>(
    `/module_chapters/${chapterId}/module_questions/`,
  )
  if (!envelope.success) {
    throw new Error(envelope.message || 'Failed to load questions')
  }
  return (envelope.data ?? []).map(parseQuestion)
}

export async function getMissionQuestions(missionId: string): Promise<Question[]> {
  const missions = await getUserMissions()
  const m = missions.find((mm) => mm.id === missionId)
  return m?.questions ?? []
}

export type CheckResult = {
  isCorrect: boolean
  expAwarded: number
  explanation?: string
}

/**
 * Validate an answer. In mock mode this is purely client-side.
 *
 * Inputs:
 *   - question      → the Question being answered
 *   - optionIds     → user's selected option IDs (MCQ)
 *   - shortAnswer   → user's text answer (short_answer type)
 *   - tries         → 1 on first attempt, 2 on second. Backend's check_answer
 *                     uses this to compute XP (2 / 1 / 0 per docx #16).
 */
export async function checkAnswer(
  question: Question,
  optionIds: string[],
  shortAnswer?: string,
  tries: number = 1,
): Promise<CheckResult> {
  if (isMockSessionActive()) {
    return mockCheck(question, optionIds, shortAnswer, tries)
  }
  try {
    const body: Record<string, unknown> = { tries }
    if (optionIds && optionIds.length > 1) body.answer_ids = optionIds
    else if (optionIds && optionIds.length === 1) body.answer_id = optionIds[0]
    if (shortAnswer) body.answer_text = shortAnswer
    const { data: envelope } = await api.patch<ApiEnvelope<{
      is_correct?: boolean
      exp_awarded?: number
      exp_earned?: number
      explanation?: string
    }>>(`/questions/${question.id}/check/`, body)
    if (!envelope.success || !envelope.data) {
      throw new Error(envelope.message || 'Could not check answer')
    }
    const isCorrect = !!envelope.data.is_correct
    // Backend may name the field exp_awarded OR exp_earned depending on
    // version; fall back to the docx-prescribed 2/1/0 formula if neither.
    const expFromBackend =
      typeof envelope.data.exp_awarded === 'number' ? envelope.data.exp_awarded :
      typeof envelope.data.exp_earned === 'number'  ? envelope.data.exp_earned :
      null
    const expAwarded = expFromBackend ?? (isCorrect ? (tries === 1 ? 2 : 1) : 0)
    return {
      isCorrect,
      expAwarded,
      explanation: envelope.data.explanation,
    }
  } catch {
    return mockCheck(question, optionIds, shortAnswer, tries)
  }
}

function mockCheck(
  question: Question,
  optionIds: string[],
  shortAnswer: string | undefined,
  tries: number,
): CheckResult {
  let isCorrect: boolean
  if (question.type === 'short_answer') {
    const target = question.options.find((o) => o.isCorrect)?.optionText?.trim().toLowerCase() ?? ''
    isCorrect = !!shortAnswer && shortAnswer.trim().toLowerCase() === target
  } else {
    const correctIds = new Set(question.options.filter((o) => o.isCorrect).map((o) => o.id))
    const selected = new Set(optionIds)
    isCorrect = correctIds.size === selected.size && [...correctIds].every((id) => selected.has(id))
  }
  const expAwarded = isCorrect ? (tries === 1 ? 2 : tries === 2 ? 1 : 0) : 0
  return { isCorrect, expAwarded, explanation: question.explanation ?? undefined }
}

// ---------------------------------------------------------------------------
// Mock chapter questions — small per-chapter quiz so /quiz works offline
// ---------------------------------------------------------------------------

function mockQuestionsForChapter(chapterId: string): Question[] {
  const make = (i: number, text: string, opts: Array<{ t: string; c?: boolean }>): QuestionDTO => ({
    id: `${chapterId}-q${i}`,
    question_text: text,
    question_type: 'mcq_single',
    exp_points: 10,
    difficulty_level: 'medium',
    is_active: true,
    is_hots: false,
    level: 1,
    options: opts.map((o, idx) => ({
      id: `${chapterId}-q${i}-o${idx + 1}`,
      option_text: o.t,
      is_correct: o.c === true,
      order: idx + 1,
    })),
  })

  return [
    make(1, 'Which of the following best describes the topic of this chapter?', [
      { t: 'A core idea you just learned', c: true },
      { t: 'A topic from the next chapter' },
      { t: 'A topic from an unrelated subject' },
      { t: 'A topic that does not exist' },
    ]),
    make(2, 'Which statement is TRUE?', [
      { t: 'The theory section covered no examples' },
      { t: 'The theory section covered guided examples', c: true },
      { t: 'There is no quiz after the theory' },
      { t: 'You cannot revisit previous chapters' },
    ]),
    make(3, 'What should you do if you get a question wrong?', [
      { t: 'Skip the chapter' },
      { t: 'Stop using the app' },
      { t: 'Read the explanation and try again', c: true },
      { t: 'Restart the entire module' },
    ]),
  ].map(parseQuestion)
}

// Re-export for symmetry with other features
export { getModuleChapters }
