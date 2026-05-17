/**
 * Axios client — mirrors lib/services/api_service.dart and its _AuthInterceptor.
 *
 * Behaviors (verified against Dart source, NOT context.txt):
 *   - baseURL = `${VITE_BASE_URL_<mode>}${VITE_API_PREFIX}` where API_PREFIX = "/api"
 *     (Dart hard-codes /api in env.dart:68; the API_VERSION env var is dead code.)
 *   - When VITE_USE_PROXY=true, baseURL is empty so requests stay relative
 *     (`/api/...`) and the Vite dev server proxies them to the real backend.
 *     Bypasses browser CORS entirely — see vite.config.ts.
 *   - Request interceptor:
 *       • application/json content type + accept
 *       • Strip Authorization for the public endpoint allowlist (login, register,
 *         forgot-password, reset-password). Note: only /auth/login/ has a trailing slash.
 *       • Otherwise attach Bearer access token from localStorage if present and not expired.
 *   - Response interceptor:
 *       • On 401 / 403 (and request was NOT public): clear tokens, fire global
 *         logout callback, then reject. NO refresh-token retry — Dart doesn't do one.
 *       • All other errors propagate as-is.
 */
import axios, {
  AxiosError,
  type AxiosInstance,
  type InternalAxiosRequestConfig,
} from 'axios'
import { tokenStorage } from '../lib/storage'

type Mode = 'dev' | 'stage' | 'prod'

const MODE = (import.meta.env.VITE_BUILD_MODE ?? 'dev') as Mode

const baseUrlByMode: Record<Mode, string | undefined> = {
  dev: import.meta.env.VITE_BASE_URL_DEV,
  stage: import.meta.env.VITE_BASE_URL_STAGE,
  prod: import.meta.env.VITE_BASE_URL_PROD,
}

const API_PREFIX = import.meta.env.VITE_API_PREFIX ?? '/api'
const USE_PROXY = import.meta.env.VITE_USE_PROXY === 'true'

// When proxying through Vite, leave baseURL empty so requests stay
// same-origin (`/api/...`) and the dev server forwards them.
const baseURL = USE_PROXY ? API_PREFIX : `${baseUrlByMode[MODE] ?? ''}${API_PREFIX}`

/** Public endpoint allowlist — exact match against the Dart source. */
const PUBLIC_ENDPOINTS = [
  '/auth/login/',
  '/auth/register',
  '/auth/forgot-password',
  '/auth/reset-password',
] as const

const isPublicPath = (path: string | undefined) => {
  if (!path) return false
  return PUBLIC_ENDPOINTS.some((p) => path.includes(p))
}

/**
 * Global logout callback registry. The auth store registers itself on init so
 * the interceptor can clear app state without importing the store (which would
 * create a cycle).
 */
type LogoutHandler = () => void
let onUnauthorized: LogoutHandler | null = null
let isLoggingOut = false

export function registerUnauthorizedHandler(handler: LogoutHandler) {
  onUnauthorized = handler
}

export const api: AxiosInstance = axios.create({
  baseURL,
  timeout: Number(import.meta.env.VITE_RECEIVE_TIMEOUT ?? 30_000),
  headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
})

api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const path = config.url ?? ''
  if (isPublicPath(path)) {
    if (config.headers && 'Authorization' in config.headers) {
      delete (config.headers as Record<string, unknown>).Authorization
    }
    return config
  }
  const token = tokenStorage.read()
  if (token && !tokenStorage.isAccessExpired()) {
    config.headers.set('Authorization', `Bearer ${token.accessToken}`)
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const status = error.response?.status
    const path = error.config?.url
    const isPublic = isPublicPath(path)

    if ((status === 401 || status === 403) && !isPublic) {
      if (!isLoggingOut) {
        isLoggingOut = true
        try {
          tokenStorage.clear()
          onUnauthorized?.()
        } finally {
          isLoggingOut = false
        }
      }
    }
    return Promise.reject(error)
  },
)

if (import.meta.env.DEV) {
  // Surface what mode we're in so dev-mock vs. real backend is unambiguous.
  // eslint-disable-next-line no-console
  console.info(
    `[gyanbuddy] api baseURL=${baseURL || '(relative)'} ${USE_PROXY ? '[proxy:on]' : '[proxy:off]'} ${import.meta.env.VITE_DEV_MOCK_AUTH === 'true' ? '[mock-auth:on]' : ''}`,
  )
}
