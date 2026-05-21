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
  /** Legacy / mock layout — top-level status. Real backend nests it under `progress`. */
  status?: string
  user_completed?: boolean
  user_started?: boolean

  /**
   * Real backend layout: progress is a nested object carrying status +
   * percentage + score + counts. The presence of this object is the
   * authoritative signal of how the user is doing on the mission.
   */
  progress?: {
    status?: string
    percentage?: number
    score?: number
    total_questions?: number
    questions_attempted?: number
    correct_answers?: number
    wrong_answers?: number
    exp_earned?: number
    accuracy?: number
  } | null

  question_count?: number

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
  // Normalise hex: backend ships "2196F3" without the leading "#" — add it
  // so style attributes can use the value directly.
  if (subjectColor && !subjectColor.startsWith('#')) {
    subjectColor = `#${subjectColor}`
  }

  const rawQuestions = dto.questions ?? []
  const questions: Question[] = rawQuestions
    .map((q) => {
      if (typeof q === 'string') return null  // bare ID — wait for separate fetch
      if ('question' in q && q.question) return parseQuestion(q.question)
      return parseQuestion(q as QuestionDTO)
    })
    .filter((q): q is Question => q !== null)

  // Prefer the nested progress.status (real backend) over the top-level
  // status (mock fixtures). user_completed / user_started likewise come from
  // progress when present.
  const progressStatus = dto.progress?.status
  const finalStatus = asStatus(progressStatus ?? dto.status)
  const userCompleted = dto.user_completed ?? (progressStatus === 'completed')
  const userStarted =
    dto.user_started ??
    (progressStatus != null && progressStatus !== 'not_started')

  return {
    id: String(dto.id ?? ''),
    title: dto.title ?? '',
    description: dto.description ?? '',
    missionDate: dto.mission_date ?? new Date().toISOString().slice(0, 10),
    status: finalStatus,
    userCompleted,
    userStarted,
    questionCount: rawQuestions.length || (dto.question_count ?? 0),
    questions,
    subject: {
      id: subjectId,
      name: subjectName,
      logo: subjectLogo,
      color: subjectColor,
    },
  }
}
