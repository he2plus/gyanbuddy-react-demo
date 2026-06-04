/**
 * Auth endpoints — mirrors lib/services/user_api_service.dart login/register/etc.
 *
 * Login wire format (verified against Dart):
 *   request:  { username, password, fcm_token? }
 *             (the field is "username" but the user enters their admission number)
 *   response: { success: true, message, data: { user, tokens: { access, refresh,
 *               access_token_expires, refresh_token_expires } } }
 *             on failure: { success: false, message, errors? }
 *
 * Dev-mock mode: when VITE_DEV_MOCK_AUTH=true, login accepts any non-empty
 * credentials and returns a fake authenticated session. Lets you exercise
 * every screen without a real backend or test creds.
 */
import { api } from './client'
import { parseUser, type User, type UserDTO } from '../types/user'
import type { ApiEnvelope, LoginResponseData } from '../types/api'

// Mock only ever runs in local `vite dev` (import.meta.env.DEV is hard-false in
// production builds), so the live Vercel demo always uses the real backend.
const MOCK_AUTH =
  import.meta.env.DEV && import.meta.env.VITE_DEV_MOCK_AUTH === 'true'

export type LoginInput = {
  username: string  // admission number
  password: string
  fcm_token?: string
}

export type LoginSuccess = {
  user: User
  tokens: {
    accessToken: string
    refreshToken: string
    accessTokenExpires: string
    refreshTokenExpires: string
  }
}

export class LoginFailedError extends Error {
  readonly errors: Record<string, string[] | string> | undefined
  constructor(message: string, errors?: Record<string, string[] | string>) {
    super(message)
    this.name = 'LoginFailedError'
    this.errors = errors
  }
}

function formatBackendErrors(
  errors: Record<string, string[] | string> | undefined,
  fallback: string,
): string {
  if (!errors) return fallback
  const messages: string[] = []
  for (const [field, val] of Object.entries(errors)) {
    if (Array.isArray(val)) {
      for (const m of val) {
        if (typeof m === 'string' && m.length) {
          const stripped = m.toLowerCase().startsWith(field.toLowerCase())
            ? m.slice(field.length).replace(/^[:\s]+/, '')
            : m
          messages.push(stripped)
        }
      }
    } else if (typeof val === 'string' && val.length) {
      messages.push(val)
    }
  }
  if (!messages.length) return fallback
  if (messages.length === 1) return messages[0]
  return messages.join('. ')
}

function mockLogin(input: LoginInput): LoginSuccess {
  const username = input.username.trim() || 'demo_student'
  const userDto: UserDTO = {
    id: 'mock-user-1',
    username,
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
  const now = Date.now()
  const oneHour = 60 * 60 * 1000
  return {
    user: parseUser(userDto),
    tokens: {
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      accessTokenExpires: new Date(now + 8 * oneHour).toISOString(),
      refreshTokenExpires: new Date(now + 30 * 24 * oneHour).toISOString(),
    },
  }
}

export async function login(input: LoginInput): Promise<LoginSuccess> {
  if (MOCK_AUTH) {
    if (!input.username.trim() || !input.password) {
      throw new LoginFailedError('Enter any admission number and password.')
    }
    // Tiny artificial delay so the spinner is visible
    await new Promise((r) => setTimeout(r, 350))
    return mockLogin(input)
  }

  // The backend returns HTTP 400 with `{success: false, errors: {...}}` on
  // bad credentials, which axios throws on. Catch the throw, peel the
  // response body, and re-throw as a LoginFailedError carrying the
  // human-readable message ("Invalid credentials") instead of axios's
  // cryptic "Request failed with status code 400".
  let envelope: ApiEnvelope<LoginResponseData>
  try {
    const resp = await api.post<ApiEnvelope<LoginResponseData>>(
      '/auth/login/',
      input,
    )
    envelope = resp.data
  } catch (err) {
    const axiosErr = err as { response?: { data?: ApiEnvelope<LoginResponseData> } }
    const body = axiosErr.response?.data
    if (body && body.success === false) {
      throw new LoginFailedError(
        formatBackendErrors(body.errors, body.message || 'Login failed.'),
        body.errors,
      )
    }
    // No structured body — fall through with a generic message.
    throw new LoginFailedError(
      err instanceof Error && err.message ? err.message : 'Login failed.',
    )
  }

  if (!envelope.success || !envelope.data) {
    throw new LoginFailedError(
      formatBackendErrors(envelope.errors, envelope.message || 'Login failed.'),
      envelope.errors,
    )
  }

  const { user: userDto, tokens } = envelope.data
  return {
    user: parseUser(userDto),
    tokens: {
      accessToken: tokens.access,
      refreshToken: tokens.refresh,
      accessTokenExpires: tokens.access_token_expires,
      refreshTokenExpires: tokens.refresh_token_expires,
    },
  }
}

// ---------------------------------------------------------------------------
// Register / Forgot password / Reset password
// ---------------------------------------------------------------------------

export type RegisterInput = {
  username: string         // admission number
  password: string
  first_name: string
  last_name: string
  email: string
  user_type?: 'student' | 'teacher' | 'admin'
  admission_number: number
  roll_number?: number
  school: string
  phone_number?: string
  date_of_birth?: string  // ISO date
}

export async function register(input: RegisterInput): Promise<LoginSuccess> {
  if (MOCK_AUTH) {
    await new Promise((r) => setTimeout(r, 400))
    return mockLogin({ username: input.username, password: input.password })
  }
  const { data: envelope } = await api.post<ApiEnvelope<LoginResponseData>>(
    '/auth/register',
    input,
  )
  if (!envelope.success || !envelope.data) {
    throw new LoginFailedError(
      formatBackendErrors(envelope.errors, envelope.message || 'Registration failed.'),
      envelope.errors,
    )
  }
  const { user: userDto, tokens } = envelope.data
  return {
    user: parseUser(userDto),
    tokens: {
      accessToken: tokens.access,
      refreshToken: tokens.refresh,
      accessTokenExpires: tokens.access_token_expires,
      refreshTokenExpires: tokens.refresh_token_expires,
    },
  }
}

export async function forgotPassword(email: string): Promise<{ message: string }> {
  if (MOCK_AUTH) {
    await new Promise((r) => setTimeout(r, 350))
    return { message: `If an account exists for ${email}, a reset link has been sent.` }
  }
  const { data: envelope } = await api.post<ApiEnvelope<unknown>>(
    '/auth/forgot-password',
    { email },
  )
  if (!envelope.success) {
    throw new LoginFailedError(
      formatBackendErrors(envelope.errors, envelope.message || 'Could not start reset.'),
      envelope.errors,
    )
  }
  return { message: envelope.message }
}

export type ResetPasswordInput = {
  token: string
  password: string
  password_confirmation: string
}

export async function resetPassword(input: ResetPasswordInput): Promise<{ message: string }> {
  if (MOCK_AUTH) {
    await new Promise((r) => setTimeout(r, 350))
    if (input.password !== input.password_confirmation) {
      throw new LoginFailedError('Passwords do not match.')
    }
    return { message: 'Password reset successfully. You can now log in.' }
  }
  const { data: envelope } = await api.post<ApiEnvelope<unknown>>(
    '/auth/reset-password',
    input,
  )
  if (!envelope.success) {
    throw new LoginFailedError(
      formatBackendErrors(envelope.errors, envelope.message || 'Password reset failed.'),
      envelope.errors,
    )
  }
  return { message: envelope.message }
}
