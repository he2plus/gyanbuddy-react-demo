/**
 * Subjects API — mirrors lib/services/subject_api_service.dart.
 *
 * Endpoints:
 *   GET /subjects/                      → list all subjects
 *   GET /subjects/{id}                  → single subject
 *   GET /subjects/{id}/modules          → modules for a subject (see api/modules.ts)
 *
 * Mock-aware: returns fixtures when running with VITE_DEV_MOCK_AUTH=true.
 */
import { api } from './client'
import type { ApiEnvelope } from '../types/api'
import {
  parseSubject,
  type Subject,
  type SubjectDTO,
} from '../types/subject'
import { isMockSessionActive, mockSubjects } from './modules'

export async function getAllSubjects(): Promise<Subject[]> {
  if (isMockSessionActive()) return mockSubjects().map(parseSubject)
  const { data: envelope } = await api.get<ApiEnvelope<SubjectDTO[]>>('/subjects/')
  if (!envelope.success) {
    throw new Error(envelope.message || 'Failed to load subjects')
  }
  const list = Array.isArray(envelope.data) ? envelope.data : []
  return list.map(parseSubject)
}

export async function getSubjectById(id: string): Promise<Subject> {
  if (isMockSessionActive()) {
    const found = mockSubjects().find((s) => s.id === id)
    if (found) return parseSubject(found)
    throw new Error('Subject not found (mock)')
  }
  const { data: envelope } = await api.get<ApiEnvelope<SubjectDTO>>(`/subjects/${id}/`)
  if (!envelope.success || !envelope.data) {
    throw new Error(envelope.message || 'Failed to load subject')
  }
  return parseSubject(envelope.data)
}
