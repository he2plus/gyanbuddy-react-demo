/**
 * Tests API — mirrors lib/services/user_test_api_service.dart.
 *
 * Endpoints:
 *   GET  /tests/my-tests/?status=
 *   GET  /tests/{id}/
 *   POST /tests/{id}/start/
 *   POST /tests/{id}/complete/
 *   GET  /tests/{id}/questions/
 *   POST /tests/{id}/check-answer/
 *
 * Mock-aware: returns a small set of test fixtures (one upcoming, one active,
 * one completed) so the flow is browseable without a backend.
 */
import { api } from './client'
import type { ApiEnvelope } from '../types/api'
import { parseTest, type Test, type TestDTO } from '../types/test'
import { parseQuestion, type Question, type QuestionDTO } from '../types/question'
import { isMockSessionActive } from './modules'

export async function getMyTests(status?: string): Promise<Test[]> {
  if (isMockSessionActive()) return mockTests()
  const params = status ? { status } : undefined
  const { data: envelope } = await api.get<ApiEnvelope<TestDTO[]>>(
    '/tests/my-tests/',
    { params },
  )
  if (!envelope.success) {
    throw new Error(envelope.message || 'Failed to load tests')
  }
  return (envelope.data ?? []).map(parseTest)
}

export async function getTestById(id: string): Promise<Test> {
  if (isMockSessionActive()) {
    const found = mockTests().find((t) => t.id === id)
    if (found) return found
    throw new Error('Test not found (mock)')
  }
  const { data: envelope } = await api.get<ApiEnvelope<TestDTO>>(`/tests/${id}/`)
  if (!envelope.success || !envelope.data) {
    throw new Error(envelope.message || 'Failed to load test')
  }
  return parseTest(envelope.data)
}

export async function startTest(id: string): Promise<Test> {
  if (isMockSessionActive()) {
    return getTestById(id)
  }
  const { data: envelope } = await api.post<ApiEnvelope<TestDTO>>(
    `/tests/${id}/start/`,
  )
  if (!envelope.success || !envelope.data) {
    throw new Error(envelope.message || 'Failed to start test')
  }
  return parseTest(envelope.data)
}

export async function completeTest(id: string): Promise<Test | null> {
  if (isMockSessionActive()) {
    const t = await getTestById(id)
    return t
  }
  const { data: envelope } = await api.post<ApiEnvelope<TestDTO>>(
    `/tests/${id}/complete/`,
  )
  if (!envelope.success) {
    throw new Error(envelope.message || 'Failed to complete test')
  }
  return envelope.data ? parseTest(envelope.data) : null
}

export async function getTestQuestions(testId: string): Promise<Question[]> {
  if (isMockSessionActive()) {
    const t = mockTests().find((tt) => tt.id === testId)
    return t?.questions ?? []
  }
  const { data: envelope } = await api.get<ApiEnvelope<QuestionDTO[]>>(
    `/tests/${testId}/questions/`,
  )
  if (!envelope.success) {
    throw new Error(envelope.message || 'Failed to load questions')
  }
  return (envelope.data ?? []).map(parseQuestion)
}

// ---------------------------------------------------------------------------
// Mock fixtures
// ---------------------------------------------------------------------------

function mockTests(): Test[] {
  const oneHour = 60 * 60 * 1000
  const now = Date.now()
  const dtos: TestDTO[] = [
    {
      id: 't-1',
      test_datetime: new Date(now - 2 * oneHour).toISOString(),
      duration: 60,
      subject: 'chem',
      subject_name: 'Chemistry',
      subject_color: '#3B82F6',
      module_name: 'Core Concepts',
      chapter_title: 'Hands-on Practice',
      question_count: 3,
      user_progress: {
        id: 'p-1',
        status: 'in_progress',
        percentage: 60,
        score: 18,
        total_questions: 3,
        questions_attempted: 2,
        correct_answers: 2,
        wrong_answers: 0,
        time_spent_seconds: 240,
        exp_earned: 20,
      },
      questions: [
        {
          id: 't-1-q1',
          question_text: 'Which compound has the formula H₂O?',
          question_type: 'mcq_single',
          exp_points: 10,
          options: [
            { id: 't-1-q1-o1', option_text: 'Salt', order: 1, is_correct: false },
            { id: 't-1-q1-o2', option_text: 'Water', order: 2, is_correct: true },
            { id: 't-1-q1-o3', option_text: 'Sugar', order: 3, is_correct: false },
            { id: 't-1-q1-o4', option_text: 'Vinegar', order: 4, is_correct: false },
          ],
        },
        {
          id: 't-1-q2',
          question_text: 'pH less than 7 indicates:',
          question_type: 'mcq_single',
          exp_points: 10,
          options: [
            { id: 't-1-q2-o1', option_text: 'Neutral', order: 1, is_correct: false },
            { id: 't-1-q2-o2', option_text: 'Basic', order: 2, is_correct: false },
            { id: 't-1-q2-o3', option_text: 'Acidic', order: 3, is_correct: true },
            { id: 't-1-q2-o4', option_text: 'Salty', order: 4, is_correct: false },
          ],
        },
        {
          id: 't-1-q3',
          question_text: 'Which is NOT a metal?',
          question_type: 'mcq_single',
          exp_points: 10,
          options: [
            { id: 't-1-q3-o1', option_text: 'Iron', order: 1, is_correct: false },
            { id: 't-1-q3-o2', option_text: 'Sulphur', order: 2, is_correct: true },
            { id: 't-1-q3-o3', option_text: 'Copper', order: 3, is_correct: false },
            { id: 't-1-q3-o4', option_text: 'Gold', order: 4, is_correct: false },
          ],
        },
      ],
    },
    {
      id: 't-2',
      test_datetime: new Date(now + 2 * 24 * oneHour).toISOString(),
      duration: 45,
      subject: 'phys',
      subject_name: 'Physics',
      subject_color: '#8B5CF6',
      module_name: 'Mechanics',
      chapter_title: 'Newton’s Laws',
      question_count: 5,
      user_progress: null,
      questions: [],
    },
    {
      id: 't-3',
      test_datetime: new Date(now - 7 * 24 * oneHour).toISOString(),
      duration: 30,
      subject: 'math',
      subject_name: 'Mathematics',
      subject_color: '#F59E0B',
      module_name: 'Algebra',
      chapter_title: 'Linear equations',
      question_count: 4,
      user_progress: {
        id: 'p-3',
        status: 'completed',
        percentage: 100,
        score: 40,
        total_questions: 4,
        questions_attempted: 4,
        correct_answers: 4,
        wrong_answers: 0,
        completed_at: new Date(now - 6 * 24 * oneHour).toISOString(),
        time_spent_seconds: 720,
        exp_earned: 40,
      },
      questions: [],
    },
  ]
  return dtos.map(parseTest)
}
