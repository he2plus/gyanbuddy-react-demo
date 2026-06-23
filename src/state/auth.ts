/**
 * Auth store — replaces the BLoC `UserBloc` from the Flutter app.
 *
 * Optimistic auth: if a valid (non-expired) token + cached user profile exist in
 * localStorage, the app is shown INSTANTLY — no blocking API call on page load.
 * /users/me is then validated silently in the background:
 *   - 200 OK  → update the user profile in state (no visual change)
 *   - 401/403 → session expired: forceLogout (redirect to login)
 *   - network error / timeout → keep the user logged in (backend is down, NOT
 *     session invalid). The app works with cached state until backend is back.
 *
 * This pattern eliminates the "pulsing dot for 10-30 seconds" UX problem caused
 * by slow Django cold-starts on the Vercel-proxied gyanbuddy.ai backend.
 *
 * 401 from any subsequent call still triggers forceLogout() via the axios
 * interceptor (registered in main.tsx).
 */
import { create } from 'zustand'
import { tokenStorage, type TokenSet } from '../lib/storage'
import { parseUser, type User } from '../types/user'
import { getCurrentUser, logout as apiLogout } from '../api/users'

export type AuthStatus = 'idle' | 'bootstrapping' | 'authenticated' | 'unauthenticated'

type AuthState = {
  user: User | null
  status: AuthStatus
  /** Last error from a bootstrap or session expiry, if any. */
  message: string | null

  bootstrap: () => Promise<void>
  setSession: (user: User, tokens: TokenSet) => void
  /** Network logout — calls API then clears state. */
  logout: () => Promise<void>
  /** Local-only logout — used by 401 interceptor. */
  forceLogout: (message?: string) => void
  /** Silently refresh the cached user profile (called after profile edit). */
  refreshUser: () => Promise<void>
}

/** Background /users/me validation timeout — 8 s is generous for a health-check. */
const VALIDATE_TIMEOUT_MS = 8_000

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  status: 'idle',
  message: null,

  bootstrap: async () => {
    if (get().status !== 'idle') return
    set({ status: 'bootstrapping', message: null })

    const tokens = tokenStorage.read()
    if (!tokens || tokenStorage.isAccessExpired()) {
      tokenStorage.clear()
      tokenStorage.clearUser()
      set({ user: null, status: 'unauthenticated' })
      return
    }

    // ── Optimistic path: serve from cache instantly ──────────────────────────
    const cached = tokenStorage.readUser<User>()
    if (cached) {
      // Immediately unblock the UI with the cached profile.
      set({ user: cached, status: 'authenticated' })
      // Background-validate so the profile stays fresh.
      void validateInBackground()
      return
    }

    // ── Cold start: no cache yet — must await the first /users/me ────────────
    // (Only on the very first login after cache is cleared.)
    try {
      const user = await withTimeout(getCurrentUser(), VALIDATE_TIMEOUT_MS)
      tokenStorage.writeUser(user)
      set({ user, status: 'authenticated' })
    } catch (err) {
      if (isUnauthorized(err)) {
        tokenStorage.clear()
        tokenStorage.clearUser()
        set({ user: null, status: 'unauthenticated' })
      } else {
        // Network error on first load with no cache — can't do much. Kick to login
        // so the user can explicitly retry.
        tokenStorage.clear()
        tokenStorage.clearUser()
        set({ user: null, status: 'unauthenticated' })
      }
    }
  },

  setSession: (user, tokens) => {
    tokenStorage.write(tokens)
    tokenStorage.writeUser(user)
    set({ user, status: 'authenticated', message: null })
  },

  logout: async () => {
    await apiLogout().catch(() => undefined) // fire-and-forget; don't block local clear
    tokenStorage.clear()
    tokenStorage.clearUser()
    set({ user: null, status: 'unauthenticated', message: null })
  },

  forceLogout: (message) => {
    tokenStorage.clear()
    tokenStorage.clearUser()
    set({
      user: null,
      status: 'unauthenticated',
      message: message ?? 'Session expired. Please log in again.',
    })
  },

  refreshUser: async () => {
    try {
      const user = await withTimeout(getCurrentUser(), VALIDATE_TIMEOUT_MS)
      tokenStorage.writeUser(user)
      set({ user })
    } catch {
      // Silently ignore — keep stale profile if backend is down
    }
  },
}))

// ── helpers ───────────────────────────────────────────────────────────────────

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    promise,
    new Promise<never>((_, reject) =>
      window.setTimeout(() => reject(new Error('timeout')), ms),
    ),
  ])
}

function isUnauthorized(err: unknown): boolean {
  if (!err || typeof err !== 'object') return false
  const e = err as { response?: { status?: number } }
  return e.response?.status === 401 || e.response?.status === 403
}

// Runs after the UI is already shown (cached user served). Updates profile
// silently; only force-logout on a true 401 (NOT on network errors/timeouts).
async function validateInBackground() {
  try {
    const user = await withTimeout(getCurrentUser(), VALIDATE_TIMEOUT_MS)
    tokenStorage.writeUser(user)
    useAuthStore.setState({ user })
  } catch (err) {
    if (isUnauthorized(err)) {
      // Genuine session expiry — clear everything and redirect to login.
      tokenStorage.clear()
      tokenStorage.clearUser()
      useAuthStore.setState({
        user: null,
        status: 'unauthenticated',
        message: 'Session expired. Please log in again.',
      })
    }
    // Network error / timeout → keep the user in the app with cached state.
  }
}

// Expose parseUser for places that need to re-hydrate the cached user object
// (the JSON round-trip loses any class methods, but User is a plain record so
// this is safe — parseUser is idempotent on already-parsed objects).
export { parseUser }
