/**
 * Leaderboard API — mirrors lib/services/user_api_service.dart `getLeaderboard`.
 *
 * Endpoint: GET /users/leaderboard/?page&limit&period&grade
 *
 * Response shape is permissive (Dart code handles 4 different layouts in case
 * the backend evolves). We mirror the same defensive parsing so a backend
 * change doesn't crash the page.
 */
import { api } from './client'
import { parseUser, type User, type UserDTO } from '../types/user'
import type { ApiEnvelope } from '../types/api'
import { isMockSessionActive } from './modules'

export type LeaderboardPeriod = 'daily' | 'weekly' | 'monthly' | 'all-time'

export type LeaderboardQuery = {
  page?: number
  limit?: number
  period?: LeaderboardPeriod
  grade?: string
}

export type LeaderboardResult = {
  users: User[]
  className: string | null
  gradeName: string | null
}

type WireResponse = Partial<ApiEnvelope<unknown>> & {
  class_name?: string
  grade_name?: string
  users?: unknown
}

function isUserList(v: unknown): v is UserDTO[] {
  return Array.isArray(v)
}

function pickUsersArray(envelope: WireResponse): UserDTO[] {
  // Case 1: top-level `users` array
  if (isUserList(envelope.users)) return envelope.users
  const data = envelope.data
  // Case 2: `data` is itself the array
  if (isUserList(data)) return data
  if (data && typeof data === 'object') {
    const d = data as Record<string, unknown>
    // Case 3: `data.results`
    if (isUserList(d.results)) return d.results
    // Case 4: `data.users`
    if (isUserList(d.users)) return d.users
  }
  return []
}

function pickScopeName(envelope: WireResponse, key: 'class_name' | 'grade_name'): string | null {
  if (typeof envelope[key] === 'string' && envelope[key]) return envelope[key] as string
  const data = envelope.data
  if (data && typeof data === 'object') {
    const d = data as Record<string, unknown>
    if (typeof d[key] === 'string' && d[key]) return d[key] as string
  }
  return null
}

export async function getLeaderboard(q: LeaderboardQuery = {}): Promise<LeaderboardResult> {
  if (isMockSessionActive()) return mockLeaderboard()

  const params: Record<string, string | number> = {}
  if (q.page != null) params.page = q.page
  if (q.limit != null) params.limit = q.limit
  if (q.period) params.period = q.period
  if (q.grade) params.grade = q.grade

  const { data: envelope } = await api.get<WireResponse>('/users/leaderboard/', { params })

  // Treat explicit success:false as failure; absence of `success` is treated as OK
  // (mirrors Dart user_api_service.dart:387-394).
  if (envelope?.success === false) {
    throw new Error(envelope.message || 'Failed to load leaderboard')
  }

  const dtos = pickUsersArray(envelope)
  const users = dtos
    .map((dto, i) => {
      try {
        return parseUser(dto)
      } catch (e) {
        // Mirror Dart: skip parse failures, don't crash the whole list
        if (import.meta.env.DEV) {
          console.warn(`Failed to parse leaderboard user at index ${i}:`, e)
        }
        return null
      }
    })
    .filter((u): u is User => u !== null)

  return {
    users,
    className: pickScopeName(envelope, 'class_name'),
    gradeName: pickScopeName(envelope, 'grade_name'),
  }
}

// ---------------------------------------------------------------------------
// Mock leaderboard data — exercises the You-highlight + top-3 medal coloring
// ---------------------------------------------------------------------------

function mockLeaderboard(): LeaderboardResult {
  const now = new Date().toISOString()
  const seed = (
    rank: number,
    id: string,
    first: string,
    last: string,
    username: string,
    exp: number,
    rewards: number,
  ): UserDTO => ({
    id,
    username,
    first_name: first,
    last_name: last,
    email: `${username}@gyanbuddy.local`,
    user_type: 'student',
    admission_number: 1000 + rank,
    roll_number: rank,
    total_exp: exp,
    rewards,
    level: { id: '3', name: 3, min_exp: 200, max_exp: 1999 },
    is_active: true,
    logged_in_once: true,
    school: 'mock-school',
    school_name: 'GyanBuddy Demo School',
    created_at: now,
    updated_at: now,
  })

  const dtos: UserDTO[] = [
    seed(1, 'lb-1', 'Aanya', 'Verma', 'aanya_v', 2180, 420),
    seed(2, 'lb-2', 'Rohan', 'Mehta', 'rohan_m', 1890, 380),
    seed(3, 'mock-user-1', 'Demo', 'Student', 'demo_student', 1544, 320),
    seed(4, 'lb-4', 'Priya', 'Singh', 'priya_s', 1410, 290),
    seed(5, 'lb-5', 'Arjun', 'Kapoor', 'arjun_k', 1276, 260),
    seed(6, 'lb-6', 'Sneha', 'Rao', 'sneha_r', 1120, 230),
    seed(7, 'lb-7', 'Vikram', 'Joshi', 'vikram_j', 980, 200),
    seed(8, 'lb-8', 'Diya', 'Kumar', 'diya_k', 870, 180),
  ]

  return {
    users: dtos.map(parseUser),
    className: '10-C',
    gradeName: 'Class 10',
  }
}
