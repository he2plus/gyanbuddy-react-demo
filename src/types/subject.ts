/**
 * Subject types — mirror lib/models/subject_model.dart.
 */
export type SubjectDTO = {
  id?: string
  name?: string
  code?: string
  description?: string | null
  logo?: string | null
  color?: string | null
  is_active?: boolean
  created_by?: string | null
  created_at?: string
  updated_at?: string
  teacher_count?: number
  class_count?: number
  module_count?: number
  has_due_module?: boolean
}

export type Subject = {
  id: string
  name: string
  code: string
  description: string | null
  logo: string
  color: string | null
  isActive: boolean
  createdBy: string | null
  createdAt: string
  updatedAt: string
  teacherCount: number
  classCount: number
  moduleCount: number
  hasDueModule: boolean
}

export function parseSubject(dto: SubjectDTO): Subject {
  return {
    id: dto.id ?? '',
    name: dto.name ?? '',
    code: dto.code ?? '',
    description: dto.description ?? null,
    logo: dto.logo ?? '',
    color: dto.color ?? null,
    isActive: dto.is_active ?? true,
    createdBy: dto.created_by ?? null,
    createdAt: dto.created_at ?? new Date().toISOString(),
    updatedAt: dto.updated_at ?? new Date().toISOString(),
    teacherCount: dto.teacher_count ?? 0,
    classCount: dto.class_count ?? 0,
    moduleCount: dto.module_count ?? 0,
    hasDueModule: dto.has_due_module ?? false,
  }
}
