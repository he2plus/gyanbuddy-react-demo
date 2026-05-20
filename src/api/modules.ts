/**
 * Modules + chapters API — mirrors lib/services/subject_api_service.dart and
 * lib/services/module_content_api_service.dart.
 *
 * Endpoints (preserved exactly from Dart):
 *   GET /subjects/{id}/modules                       → list of Module
 *   GET /modules/{moduleId}/module_chapters/         → list of ModuleChapter
 *   GET /module_chapters/{chapterId}/module_content  → Tier 3 next screen
 *
 * Mock-aware: when VITE_DEV_MOCK_AUTH=true AND the caller has the mock token,
 * we return generated fixtures so the user can navigate the whole tree
 * (subjects → modules → chapters → journey page) without a real backend.
 */
import { api } from './client'
import { tokenStorage } from '../lib/storage'
import type { ApiEnvelope } from '../types/api'
import {
  parseModule,
  parseChapter,
  type Module,
  type ModuleChapter,
  type ModuleDTO,
  type ModuleChapterDTO,
} from '../types/module'

const MOCK_AUTH = import.meta.env.VITE_DEV_MOCK_AUTH === 'true'
const isMockSession = () =>
  MOCK_AUTH && tokenStorage.read()?.accessToken === 'mock_access_token'

// ---------------------------------------------------------------------------
// Real API
// ---------------------------------------------------------------------------

export async function getSubjectModules(subjectId: string): Promise<Module[]> {
  if (isMockSession()) return mockModulesFor(subjectId)
  const { data: envelope } = await api.get<ApiEnvelope<ModuleDTO[]>>(
    `/subjects/${subjectId}/modules/`,
  )
  if (!envelope.success) {
    throw new Error(envelope.message || 'Failed to load modules')
  }
  return (envelope.data ?? []).map(parseModule)
}

export async function getModuleChapters(moduleId: string): Promise<ModuleChapter[]> {
  if (isMockSession()) return mockChaptersFor(moduleId)
  const { data: envelope } = await api.get<ApiEnvelope<ModuleChapterDTO[]>>(
    `/modules/${moduleId}/module_chapters/`,
  )
  if (!envelope.success) {
    throw new Error(envelope.message || 'Failed to load chapters')
  }
  return (envelope.data ?? []).map((c) => parseChapter(c, moduleId))
}

// ---------------------------------------------------------------------------
// Mock data — only used when running with VITE_DEV_MOCK_AUTH=true.
// Designed to exercise every visual branch of the journey page:
//   - completed (regular + important + last)
//   - in_progress (regular + important)  ← the "boy standing on platform"
//   - not_started (regular + important + last)
// ---------------------------------------------------------------------------

function mockModulesFor(subjectId: string): Module[] {
  const now = new Date().toISOString()
  const base = (overrides: Partial<ModuleDTO>): ModuleDTO => ({
    subject: subjectId,
    is_enabled: true,
    chapter_count: 6,
    question_count: 24,
    status: 'in_progress',
    user_status: 'in_progress',
    user_percentage: 40,
    created_at: now,
    updated_at: now,
    ...overrides,
  })
  return [
    parseModule(base({ id: `${subjectId}-m1`, name: 'Foundations', order: 1, status: 'completed', user_status: 'completed', user_percentage: 100 })),
    parseModule(base({ id: `${subjectId}-m2`, name: 'Core Concepts', order: 2, status: 'in_progress', user_status: 'in_progress', user_percentage: 45 })),
    parseModule(base({ id: `${subjectId}-m3`, name: 'Applications', order: 3, status: 'not_started', user_status: 'not_started', user_percentage: 0, due_date: new Date(Date.now() + 7 * 86_400_000).toISOString() })),
    parseModule(base({ id: `${subjectId}-m4`, name: 'Advanced Topics', order: 4, status: 'not_started', user_status: 'not_started', user_percentage: 0 })),
  ]
}

function mockChaptersFor(moduleId: string): ModuleChapter[] {
  const now = new Date().toISOString()
  const c = (overrides: Partial<ModuleChapterDTO> & { title: string }): ModuleChapterDTO => ({
    is_enabled: true,
    is_important: false,
    has_hots: false,
    content_count: 5,
    status: 'not_started',
    created_at: now,
    updated_at: now,
    ...overrides,
  })
  const theory = (chapter: string) =>
    `Welcome to **${chapter}**. In this chapter you'll learn the core ideas, work through guided examples, and try a short quiz at the end. ` +
    `Take your time on the key principles below — they show up again in later chapters and on the assessment. ` +
    `If anything is unclear, you can revisit the previous chapters using the path on the left.`
  const dtos: ModuleChapterDTO[] = [
    c({ id: `${moduleId}-c1`, title: 'Introduction', order: 1, status: 'completed', theory: theory('Introduction') }),
    c({ id: `${moduleId}-c2`, title: 'Building Blocks', order: 2, status: 'completed', theory: theory('Building Blocks') }),
    c({ id: `${moduleId}-c3`, title: 'Key Principles', order: 3, status: 'completed', is_important: true, theory: theory('Key Principles') }),
    c({ id: `${moduleId}-c4`, title: 'Hands-on Practice', order: 4, status: 'in_progress', is_important: true, theory: theory('Hands-on Practice') }),
    c({ id: `${moduleId}-c5`, title: 'Deeper Dive', order: 5, status: 'not_started', theory: theory('Deeper Dive') }),
    c({ id: `${moduleId}-c6`, title: 'Real-world Applications', order: 6, status: 'not_started', is_important: true, theory: theory('Real-world Applications') }),
    c({ id: `${moduleId}-c7`, title: 'Final Project', order: 7, status: 'not_started', theory: theory('Final Project') }),
  ]
  return dtos.map((dto) => parseChapter(dto, moduleId))
}

// ---------------------------------------------------------------------------
// Mock subjects (used by api/subjects.ts when mock session is active).
// Lives here to keep all mock fixtures in one place.
// ---------------------------------------------------------------------------

import type { SubjectDTO } from '../types/subject'

export function mockSubjects(): SubjectDTO[] {
  const now = new Date().toISOString()
  return [
    { id: 'chem', name: 'Chemistry', code: 'CHEM', color: '#3B82F6', logo: '', is_active: true, module_count: 4, has_due_module: true, created_at: now, updated_at: now },
    { id: 'phys', name: 'Physics', code: 'PHY', color: '#8B5CF6', logo: '', is_active: true, module_count: 5, has_due_module: false, created_at: now, updated_at: now },
    { id: 'bio', name: 'Biology', code: 'BIO', color: '#10B981', logo: '', is_active: true, module_count: 6, has_due_module: false, created_at: now, updated_at: now },
    { id: 'math', name: 'Mathematics', code: 'MATH', color: '#F59E0B', logo: '', is_active: true, module_count: 7, has_due_module: true, created_at: now, updated_at: now },
    { id: 'geo', name: 'Geography', code: 'GEO', color: '#06B6D4', logo: '', is_active: true, module_count: 3, has_due_module: false, created_at: now, updated_at: now },
    { id: 'hist', name: 'History', code: 'HIS', color: '#A855F7', logo: '', is_active: true, module_count: 4, has_due_module: false, created_at: now, updated_at: now },
  ]
}

export function isMockSessionActive(): boolean {
  return isMockSession()
}
