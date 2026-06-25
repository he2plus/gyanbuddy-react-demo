/**
 * Module + ModuleChapter types — mirror lib/models/module_model.dart and
 * lib/models/module_chapter_model.dart.
 *
 * Quirks to preserve:
 *   - API sends chapter `title`, NOT `name`
 *   - API sends `content_count`, NOT `question_count`
 *   - Module status is a string literal union; user status is a separate enum
 *     (notStarted | inProgress | due | completed)
 */

export const MODULE_STATUS = ['not_started', 'in_progress', 'completed', 'locked'] as const
export type ModuleStatusString = (typeof MODULE_STATUS)[number]

export const USER_MODULE_STATUS = ['not_started', 'in_progress', 'due', 'completed'] as const
export type UserModuleStatus = (typeof USER_MODULE_STATUS)[number]

export type ModuleDTO = {
  id?: string | number
  name?: string
  description?: string | null
  subject?: string | null
  subject_name?: string | null
  order?: number
  is_enabled?: boolean
  is_active?: boolean
  logo?: string | null
  question_count?: number
  chapter_count?: number
  status?: string
  due_date?: string | null
  user_status?: string
  user_percentage?: number
  started_at?: string | null
  last_accessed?: string | null
  created_at?: string
  updated_at?: string
}

export type Module = {
  id: string
  name: string
  description: string | null
  subjectId: string
  subjectName: string | null
  order: number
  isEnabled: boolean
  logo: string | null
  questionCount: number
  chapterCount: number
  status: ModuleStatusString
  dueDate: string | null
  userStatus: UserModuleStatus
  userPercentage: number
  startedAt: string | null
  lastAccessed: string | null
  createdAt: string
  updatedAt: string
}

const safeInt = (v: unknown): number => {
  if (typeof v === 'number') return Math.trunc(v)
  if (typeof v === 'string') {
    const n = Number.parseInt(v, 10)
    return Number.isFinite(n) ? n : 0
  }
  return 0
}

const asModuleStatus = (v: unknown): ModuleStatusString => {
  const s = String(v ?? 'not_started')
  return (MODULE_STATUS as readonly string[]).includes(s)
    ? (s as ModuleStatusString)
    : 'not_started'
}

const asUserModuleStatus = (v: unknown): UserModuleStatus => {
  const s = String(v ?? 'not_started')
  return (USER_MODULE_STATUS as readonly string[]).includes(s)
    ? (s as UserModuleStatus)
    : 'not_started'
}

export function parseModule(dto: ModuleDTO): Module {
  const now = new Date().toISOString()
  return {
    id: String(dto.id ?? ''),
    name: dto.name ?? '',
    description: dto.description ?? null,
    subjectId: dto.subject ? String(dto.subject) : '',
    subjectName: dto.subject_name ?? null,
    order: safeInt(dto.order),
    isEnabled: dto.is_enabled ?? dto.is_active ?? true,
    logo: dto.logo ?? null,
    questionCount: safeInt(dto.question_count),
    chapterCount: safeInt(dto.chapter_count),
    status: asModuleStatus(dto.status),
    dueDate: dto.due_date ?? null,
    userStatus: asUserModuleStatus(dto.user_status),
    userPercentage: typeof dto.user_percentage === 'number' ? dto.user_percentage : 0,
    startedAt: dto.started_at ?? null,
    lastAccessed: dto.last_accessed ?? null,
    createdAt: dto.created_at ?? now,
    updatedAt: dto.updated_at ?? now,
  }
}

// ---------------------------------------------------------------------------
// ModuleChapter
// ---------------------------------------------------------------------------

export const CHAPTER_STATUS = ['not_started', 'in_progress', 'completed', 'locked', 'due'] as const
export type ChapterStatusString = (typeof CHAPTER_STATUS)[number]

export type ModuleChapterDTO = {
  id?: string | number
  /** API sends `title`, NOT `name` */
  title?: string
  description?: string | null
  theory?: string | null
  order?: number
  logo?: string | null
  /** API sends `content_count`, NOT `question_count` */
  content_count?: number
  status?: string
  is_enabled?: boolean
  is_important?: boolean
  has_hots?: boolean
  /** Deadline assigned by the teacher (date-only). Null when no due date. */
  due_date?: string | null
  /** Backend flag: this chapter is assigned with an active due date. */
  is_due?: boolean
  current_question_id?: string | number | null
  created_at?: string
  updated_at?: string
}

export type ModuleChapter = {
  id: string
  /** Domain `name` ← wire `title` */
  name: string
  description: string | null
  theory: string | null
  moduleId: string
  order: number
  logo: string | null
  /** Domain `questionCount` ← wire `content_count` */
  questionCount: number
  status: ChapterStatusString
  isEnabled: boolean
  isImportant: boolean
  hasHots: boolean
  currentQuestionId: string | null
  /** Deadline (date-only ISO) or null. */
  dueDate: string | null
  createdAt: string
  updatedAt: string
  // Derived helpers
  isNotStarted: boolean
  isInProgress: boolean
  isCompleted: boolean
  isLocked: boolean
  /** Assigned with an active due date and not yet completed. */
  isDue: boolean
  /** Due date has already passed (and chapter isn't completed). */
  isOverdue: boolean
}

const asChapterStatus = (v: unknown): ChapterStatusString => {
  const s = String(v ?? 'not_started')
  return (CHAPTER_STATUS as readonly string[]).includes(s)
    ? (s as ChapterStatusString)
    : 'not_started'
}

export function parseChapter(dto: ModuleChapterDTO, moduleId = ''): ModuleChapter {
  const now = new Date().toISOString()
  const status = asChapterStatus(dto.status)
  const dueDate = dto.due_date ?? null
  const isCompleted = status === 'completed'
  // The backend sends a progress `status` (not_started | in_progress | completed)
  // PLUS a separate `is_due` flag + `due_date` — it never sends status='due'.
  // A chapter counts as "due" (assigned, actionable) when it has an active
  // deadline and isn't completed yet.
  const hasDeadline = dto.is_due === true || status === 'due' || dueDate != null
  const isDue = hasDeadline && !isCompleted
  const startOfToday = new Date()
  startOfToday.setHours(0, 0, 0, 0)
  const isOverdue =
    isDue && dueDate != null && Date.parse(dueDate) < startOfToday.getTime()
  return {
    id: String(dto.id ?? ''),
    name: dto.title ?? '',
    description: dto.description ?? null,
    theory: dto.theory ?? null,
    moduleId,
    order: safeInt(dto.order),
    logo: dto.logo ?? null,
    questionCount: safeInt(dto.content_count),
    status,
    isEnabled: dto.is_enabled ?? true,
    isImportant: dto.is_important ?? false,
    hasHots: dto.has_hots ?? false,
    currentQuestionId:
      dto.current_question_id != null ? String(dto.current_question_id) : null,
    dueDate,
    createdAt: dto.created_at ?? now,
    updatedAt: dto.updated_at ?? now,
    isNotStarted: status === 'not_started',
    isInProgress: status === 'in_progress',
    isCompleted,
    isLocked: status === 'locked',
    isDue,
    isOverdue,
  }
}
