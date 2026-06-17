/**
 * User types — mirror lib/models/user_model.dart.
 *
 * Two shapes:
 *   - UserDTO: snake_case wire format, exactly as Django sends it.
 *   - User:    camelCase domain object used inside React.
 *
 * `parseUser(dto)` converts wire → domain. Defaults match the Dart factory.
 */

export type UserType = 'student' | 'teacher' | 'admin'

export type LevelDTO = {
  id?: string | number
  name?: number
  min_exp?: number
  max_exp?: number
}

export type Level = {
  id: string
  name: number
  minExp: number
  maxExp: number
}

export type SubjectProgressDTO = {
  // Loose for now; refined when subject screens land.
  [key: string]: unknown
}

/** Parsed per-subject progress (the real backend metrics from /users/me). */
export type SubjectProgress = {
  subjectId: string
  subjectName: string
  chaptersCompleted: number
  totalChapters: number
  /** 0..100 chapter-completion percentage for the subject. */
  completionRate: number
}

export type UserDTO = {
  id: string | number
  username?: string
  first_name?: string
  last_name?: string
  email?: string
  user_type?: string
  admission_number?: number | string
  roll_number?: number | string | null
  total_exp?: number | string
  rewards?: number | string
  level?: LevelDTO | number | null
  phone_number?: string | null
  date_of_birth?: string | null
  profile_picture?: string | null
  bio?: string | null
  is_active?: boolean
  logged_in_once?: boolean
  school?: string | number | null
  school_name?: string | null
  created_at?: string
  date_joined?: string
  updated_at?: string
  subject_progress?: SubjectProgressDTO[]
}

export type User = {
  id: string
  username: string
  firstName: string
  lastName: string
  fullName: string
  email: string
  userType: UserType
  admissionNumber: number
  rollNumber: number | null
  totalExp: number
  rewards: number
  level: Level | null
  phoneNumber: string | null
  dateOfBirth: string | null
  profilePicture: string | null
  bio: string | null
  isActive: boolean
  loggedInOnce: boolean
  schoolId: string | null
  schoolName: string | null
  createdAt: string
  updatedAt: string
  /** Real per-subject progress from the backend (empty if not shipped). */
  subjectProgress: SubjectProgress[]
}

const safeInt = (v: unknown): number => {
  if (typeof v === 'number') return Math.trunc(v)
  if (typeof v === 'string') {
    const n = Number.parseInt(v, 10)
    return Number.isFinite(n) ? n : 0
  }
  return 0
}

const safeUserType = (v: unknown): UserType => {
  const s = String(v ?? '').toLowerCase()
  if (s === 'teacher') return 'teacher'
  if (s === 'admin') return 'admin'
  return 'student'
}

const parseLevel = (v: LevelDTO | number | null | undefined): Level | null => {
  if (v == null) return null
  if (typeof v === 'number') {
    const minExp = (v - 1) * 100
    const maxExp = v * 100 - 1
    return { id: String(v), name: v, minExp, maxExp }
  }
  if (typeof v === 'object') {
    const name = safeInt(v.name)
    return {
      id: String(v.id ?? name),
      name,
      minExp: safeInt(v.min_exp),
      maxExp: safeInt(v.max_exp),
    }
  }
  return null
}

const parseSubjectProgress = (
  list: SubjectProgressDTO[] | undefined,
): SubjectProgress[] => {
  if (!Array.isArray(list)) return []
  return list.map((s) => {
    const done = safeInt(s.chapters_completed)
    const total = safeInt(s.total_chapters_in_attempted_modules)
    const rateRaw = s.chapter_completion_rate
    const rate =
      typeof rateRaw === 'number'
        ? rateRaw
        : total > 0
          ? (done / total) * 100
          : 0
    return {
      subjectId: String(s.subject_id ?? ''),
      subjectName: String(s.subject_name ?? ''),
      chaptersCompleted: done,
      totalChapters: total,
      completionRate: Math.round(rate),
    }
  })
}

export function parseUser(dto: UserDTO): User {
  const firstName = dto.first_name ?? ''
  const lastName = dto.last_name ?? ''
  return {
    id: String(dto.id ?? ''),
    username: dto.username ?? '',
    firstName,
    lastName,
    fullName: `${firstName} ${lastName}`.trim(),
    email: dto.email ?? '',
    userType: safeUserType(dto.user_type),
    admissionNumber: safeInt(dto.admission_number),
    rollNumber:
      dto.roll_number === null || dto.roll_number === undefined
        ? null
        : safeInt(dto.roll_number),
    totalExp: safeInt(dto.total_exp),
    rewards: safeInt(dto.rewards),
    level: parseLevel(dto.level),
    phoneNumber: dto.phone_number ?? null,
    dateOfBirth: dto.date_of_birth ?? null,
    profilePicture: dto.profile_picture ?? null,
    bio: dto.bio ?? null,
    isActive: dto.is_active ?? true,
    loggedInOnce: dto.logged_in_once ?? false,
    schoolId: dto.school != null ? String(dto.school) : null,
    schoolName: dto.school_name ?? null,
    createdAt: dto.created_at ?? dto.date_joined ?? new Date().toISOString(),
    updatedAt: dto.updated_at ?? new Date().toISOString(),
    subjectProgress: parseSubjectProgress(dto.subject_progress),
  }
}
