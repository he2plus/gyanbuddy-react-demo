/**
 * Generic API envelope used by every Gyaan Buddy backend endpoint.
 * Source of truth: lib/services/user_api_service.dart `ApiResponse<T>`.
 */
export type ApiEnvelope<T> = {
  success: boolean
  message: string
  data?: T
  /** Validation errors keyed by field. Present when success === false. */
  errors?: Record<string, string[] | string>
  status_code?: number
}

/** Token bundle as returned inside the login/register response. */
export type TokensFromBackend = {
  access: string
  refresh: string
  access_token_expires: string  // ISO
  refresh_token_expires: string // ISO
}

/** Login response payload (data field of the envelope). */
export type LoginResponseData = {
  user: import('./user').UserDTO
  tokens: TokensFromBackend
}
