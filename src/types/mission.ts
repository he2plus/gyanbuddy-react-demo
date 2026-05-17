/**
 * Mission types — mirror lib/models/mission_model.dart.
 *
 * API allows the `subject` field to come back as either a nested object OR a
 * string ID (with sibling `subject_name`, `subject_color`, etc). We normalize
 * both shapes into a single Subject ref.
 */
import { parseQuestion, type Question, type QuestionDTO } from './question'

export type MissionStatusLiteral = 'not_started' | 'in_progress' | 'completed'

export type MissionDTO = {
  id?: string
  title?: string
  description?: string
  mission_date?: string
  questions?: Array<string | QuestionDTO | { id?: string; question?: QuestionDTO; order?: number }>
  status?: string
  user_completed?: boolean
  user_started?: boolean

  // Subject can be a nested object OR a string ID with sibling fields.
  subject?: string | { id?: string; name?: string; logo?: string; color?: string }
  subject_name?: string
  subject_logo?: string
  subject_color?: string
}

export type Mission = {
  id: string
  title: string
  description: string
  /** ISO date (yyyy-mm-dd) */
  missionDate: string
  status: MissionStatusLiteral
  userCompleted: boolean
  userStarted: boolean
  questionCount: number
  questions: Question[]
  subject: {
    id: string | null
    name: string | null
    logo: string | null
    color: string | null
  }
}

const asStatus = (v: unknown): MissionStatusLiteral => {
  const s = String(v ?? 'not_started')
  if (s === 'in_progress' || s === 'completed') return s
  return 'not_started'
}

export function parseMission(dto: MissionDTO): Mission {
  let subjectId: string | null = null
  let subjectName: string | null = null
  let subjectLogo: string | null = null
  let subjectColor: string | null = null

  if (dto.subject && typeof dto.subject === 'object') {
    subjectId = dto.subject.id ?? null
    subjectName = dto.subject.name ?? null
    subjectLogo = dto.subject.logo ?? null
    subjectColor = dto.subject.color ?? null
  } else if (typeof dto.subject === 'string') {
    subjectId = dto.subject
  }
  subjectName = subjectName ?? dto.subject_name ?? null
  subjectLogo = subjectLogo ?? dto.subject_logo ?? null
  subjectColor = subjectColor ?? dto.subject_color ?? null

  const rawQuestions = dto.questions ?? []
  const questions: Question[] = rawQuestions
    .map((q) => {
      if (typeof q === 'string') return null  // bare ID — wait for separate fetch
      if ('question' in q && q.question) return parseQuestion(q.question)
      return parseQuestion(q as QuestionDTO)
    })
    .filter((q): q is Question => q !== null)

  return {
    id: String(dto.id ?? ''),
    title: dto.title ?? '',
    description: dto.description ?? '',
    missionDate: dto.mission_date ?? new Date().toISOString().slice(0, 10),
    status: asStatus(dto.status),
    userCompleted: dto.user_completed ?? false,
    userStarted: dto.user_started ?? false,
    questionCount: rawQuestions.length,
    questions,
    subject: {
      id: subjectId,
      name: subjectName,
      logo: subjectLogo,
      color: subjectColor,
    },
  }
}
