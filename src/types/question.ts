/**
 * Question + QuestionOption types — mirror lib/models/question_model.dart
 * and lib/models/question_option_model.dart.
 *
 * API quirks preserved:
 *   - `question_text` (snake_case) → `text` (camelCase)
 *   - `question_type` literal: mcq_single | mcq_multiple | short_answer | rearrange
 *   - `is_correct` on options is included only in dev/mock; real backend may
 *     omit it so the server can validate. We DO NOT expose it to the user
 *     directly — the quiz UI calls POST /questions/{id}/check/ when the real
 *     backend is wired (Tier 4 polish).
 */

export type QuestionTypeLiteral = 'mcq_single' | 'mcq_multiple' | 'short_answer' | 'rearrange'

export type DifficultyLiteral = 'easy' | 'medium' | 'hard'

export type QuestionOptionDTO = {
  id?: string | number
  question?: string | number
  option_text?: string
  is_correct?: boolean
  order?: number
}

export type QuestionOption = {
  id: string
  optionText: string
  /** Present in mock data; absent on real-backend responses (server-side check). */
  isCorrect: boolean
  order: number
}

export type QuestionDTO = {
  id?: string | number
  question_text?: string
  image?: string | null
  question_type?: string
  exp_points?: number
  difficulty_level?: string
  explanation?: string | null
  hint?: string | null
  is_active?: boolean
  is_hots?: boolean
  level?: number
  options?: QuestionOptionDTO[]
}

export type Question = {
  id: string
  text: string
  image: string | null
  type: QuestionTypeLiteral
  expPoints: number
  difficulty: DifficultyLiteral
  explanation: string | null
  hint: string | null
  isHots: boolean
  level: number
  options: QuestionOption[]
}

const asType = (v: unknown): QuestionTypeLiteral => {
  const s = String(v ?? 'mcq_single')
  if (s === 'mcq_multiple' || s === 'short_answer' || s === 'rearrange') return s
  return 'mcq_single'
}

const asDifficulty = (v: unknown): DifficultyLiteral => {
  const s = String(v ?? 'medium')
  if (s === 'easy' || s === 'hard') return s
  return 'medium'
}

export function parseOption(dto: QuestionOptionDTO): QuestionOption {
  return {
    id: String(dto.id ?? ''),
    optionText: dto.option_text ?? '',
    isCorrect: dto.is_correct ?? false,
    order: dto.order ?? 0,
  }
}

export function parseQuestion(dto: QuestionDTO): Question {
  return {
    id: String(dto.id ?? ''),
    text: dto.question_text ?? '',
    image: dto.image ?? null,
    type: asType(dto.question_type),
    expPoints: dto.exp_points ?? 10,
    difficulty: asDifficulty(dto.difficulty_level),
    explanation: dto.explanation ?? null,
    hint: dto.hint ?? null,
    isHots: dto.is_hots ?? false,
    level: dto.level ?? 1,
    options: (dto.options ?? []).map(parseOption).sort((a, b) => a.order - b.order),
  }
}
