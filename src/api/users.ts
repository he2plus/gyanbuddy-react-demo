/**
 * User endpoints — mirrors lib/services/user_api_service.dart.
 *
 * Mock-aware: when VITE_DEV_MOCK_AUTH=true and a mock token is present, we
 * return the cached mock user instead of hitting the backend, so the post-
 * login bootstrap and Profile force-refresh work without a real API.
 */
import { api } from './client'
import { parseUser, type User, type UserDTO } from '../types/user'
import { tokenStorage } from '../lib/storage'
import type { ApiEnvelope } from '../types/api'

const MOCK_AUTH = import.meta.env.VITE_DEV_MOCK_AUTH === 'true'

function mockMe(): User {
  // Same DTO as mockLogin() — kept in sync here intentionally.
  const userDto: UserDTO = {
    id: 'mock-user-1',
    username: 'demo_student',
    first_name: 'Demo',
    last_name: 'Student',
    email: 'demo@gyanbuddy.local',
    user_type: 'student',
    admission_number: 1234,
    roll_number: 7,
    total_exp: 1544,
    rewards: 320,
    level: { id: '3', name: 3, min_exp: 200, max_exp: 1999 },
    is_active: true,
    logged_in_once: true,
    school: 'mock-school',
    school_name: 'GyanBuddy Demo School',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }
  return parseUser(userDto)
}

export async function getCurrentUser(): Promise<User> {
  if (MOCK_AUTH && tokenStorage.read()?.accessToken === 'mock_access_token') {
    return mockMe()
  }
  const { data: envelope } = await api.get<ApiEnvelope<UserDTO>>('/users/me/')
  if (!envelope.success || !envelope.data) {
    throw new Error(envelope.message || 'Failed to load user')
  }
  return parseUser(envelope.data)
}

export async function logout(): Promise<void> {
  if (MOCK_AUTH && tokenStorage.read()?.accessToken === 'mock_access_token') {
    return
  }
  try {
    await api.post('/auth/logout/')
  } catch {
    // swallow: caller will clear local state regardless.
  }
}

// ---------------------------------------------------------------------------
// Profile update + change password
// ---------------------------------------------------------------------------

export type UpdateProfileInput = {
  name?: string                // backend accepts `name` per the Dart wrapper
  first_name?: string
  last_name?: string
  email?: string
  phone_number?: string
  date_of_birth?: string
  bio?: string
  profile_image?: string
}

export async function updateProfile(input: UpdateProfileInput): Promise<User> {
  if (MOCK_AUTH && tokenStorage.read()?.accessToken === 'mock_access_token') {
    const current = mockMe()
    return parseUser({
      ...{
        id: current.id,
        username: current.username,
        admission_number: current.admissionNumber,
        user_type: current.userType,
        total_exp: current.totalExp,
        rewards: current.rewards,
        level: current.level
          ? { id: current.level.id, name: current.level.name, min_exp: current.level.minExp, max_exp: current.level.maxExp }
          : null,
      } as UserDTO,
      first_name: input.first_name ?? current.firstName,
      last_name: input.last_name ?? current.lastName,
      email: input.email ?? current.email,
      phone_number: input.phone_number ?? current.phoneNumber ?? undefined,
      date_of_birth: input.date_of_birth ?? current.dateOfBirth ?? undefined,
      bio: input.bio ?? current.bio ?? undefined,
      profile_picture: input.profile_image ?? current.profilePicture ?? undefined,
    } as UserDTO)
  }
  const { data: envelope } = await api.put<ApiEnvelope<UserDTO>>('/users/me/', input)
  if (!envelope.success || !envelope.data) {
    throw new Error(envelope.message || 'Failed to update profile')
  }
  return parseUser(envelope.data)
}

export type ChangePasswordInput = {
  current_password: string
  new_password: string
  new_password_confirmation: string
}

export async function changePassword(input: ChangePasswordInput): Promise<{ message: string }> {
  if (MOCK_AUTH && tokenStorage.read()?.accessToken === 'mock_access_token') {
    if (input.new_password !== input.new_password_confirmation) {
      throw new Error('New passwords do not match.')
    }
    if (input.new_password.length < 6) {
      throw new Error('Password must be at least 6 characters.')
    }
    return { message: 'Password changed successfully.' }
  }
  // Backend exposes this as POST /api/users/change_password/ (DRF @action
   // default url_path keeps underscores). Method is POST, not PUT.
   const { data: envelope } = await api.post<ApiEnvelope<unknown>>(
    '/users/change_password/',
    input,
  )
  if (!envelope.success) {
    throw new Error(envelope.message || 'Failed to change password')
  }
  return { message: envelope.message }
}
