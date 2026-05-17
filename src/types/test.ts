/**
 * Test types — mirror lib/models/user_test_model.dart.
 *
 * Tests are scheduled quizzes with an active window:
 *   - testDatetime + duration minutes = the window during which a student can attempt
 *   - Status enum: upcoming | active | skipped | completed
 */
import { parseQuestion, type Question, type QuestionDTO } from './question'

export type TestStatusLiteral = 'upcoming' | 'active' | 'skipped' | 'completed'

export type UserTestProgressDTO = {
  id?: string
  status?: string
  percentage?: number
  score?: number
  total_questions?: number
  questions_attempted?: number
  correct_answers?: number
  wrong_answers?: number
  started_at?: string | null
  completed_at?: string | null
  last_accessed?: string | null
  time_spent_seconds?: number
  exp_earned?: number
  current_question_id?: string | null
  current_question_text?: string | null
}

export type UserTestProgress = {
  id: string
  status: 'not_started' | 'in_progress' | 'completed'
  percentage: number
  score: number
  totalQuestions: number
  questionsAttempted: number
  correctAnswers: number
  wrongAnswers: number
  startedAt: string | null
  completedAt: string | null
  timeSpentSeconds: number
  expEarned: number
}

export type TestDTO = {
  id?: string
  test_datetime?: string
  duration?: number | null
  class_group?: string
  class_group_name?: string
  subject?: string
  subject_name?: string
  subject_color?: string
  subject_logo?: string | null
  module?: string
  module_name?: string
  module_chapter?: string
  chapter_title?: string
  question_count?: number
  user_progress?: UserTestProgressDTO | null
  questions?: QuestionDTO[]
}

export type Test = {
  id: string
  testDatetime: string
  durationMinutes: number
  classGroupName: string | null
  subjectId: string | null
  subjectName: string | null
  subjectColor: string | null
  subjectLogo: string | null
  moduleName: string | null
  chapterTitle: string | null
  questionCount: number
  progress: UserTestProgress | null
  questions: Question[]
  // Derived
  title: string
  testEndTime: string  // ISO
  status: TestStatusLiteral
}

function parseProgress(dto: UserTestProgressDTO | null | undefined): UserTestProgress | null {
  if (!dto) return null
  const status = dto.status === 'in_progress' || dto.status === 'completed' ? dto.status : 'not_started'
  return {
    id: String(dto.id ?? ''),
    status,
    percentage: dto.percentage ?? 0,
    score: dto.score ?? 0,
    totalQuestions: dto.total_questions ?? 0,
    questionsAttempted: dto.questions_attempted ?? 0,
    correctAnswers: dto.correct_answers ?? 0,
    wrongAnswers: dto.wrong_answers ?? 0,
    startedAt: dto.started_at ?? null,
    completedAt: dto.completed_at ?? null,
    timeSpentSeconds: dto.time_spent_seconds ?? 0,
    expEarned: dto.exp_earned ?? 0,
  }
}

function deriveStatus(testDatetime: string, durationMin: number, progress: UserTestProgress | null): TestStatusLiteral {
  if (progress?.status === 'completed') return 'completed'
  const now = Date.now()
  const start = new Date(testDatetime).getTime()
  const end = start + durationMin * 60_000
  if (now < start) return 'upcoming'
  if (now >= end) return 'skipped'
  return 'active'
}

export function parseTest(dto: TestDTO): Test {
  const duration = dto.duration ?? 60
  const testDatetime = dto.test_datetime ?? new Date().toISOString()
  const progress = parseProgress(dto.user_progress)
  const endIso = new Date(new Date(testDatetime).getTime() + duration * 60_000).toISOString()
  return {
    id: String(dto.id ?? ''),
    testDatetime,
    durationMinutes: duration,
    classGroupName: dto.class_group_name ?? null,
    subjectId: dto.subject ? String(dto.subject) : null,
    subjectName: dto.subject_name ?? null,
    subjectColor: dto.subject_color ?? null,
    subjectLogo: dto.subject_logo ?? null,
    moduleName: dto.module_name ?? null,
    chapterTitle: dto.chapter_title ?? null,
    questionCount: dto.question_count ?? 0,
    progress,
    questions: (dto.questions ?? []).map(parseQuestion),
    title: dto.chapter_title ?? dto.module_name ?? 'Test',
    testEndTime: endIso,
    status: deriveStatus(testDatetime, duration, progress),
  }
}
