/**
 * Auth store — replaces the BLoC `UserBloc` from the Flutter app.
 *
 * Lifecycle (mirrors lib/blocs/user/user_bloc.dart `_onLoadCurrentUser`):
 *   1. App boot calls `bootstrap()`
 *   2. If a non-expired token exists in localStorage, fetch /users/me
 *   3. On success: status = 'authenticated', user populated
 *   4. On failure or no token: clear tokens, status = 'unauthenticated'
 *
 * 401 from any subsequent call triggers `forceLogout()` via the axios
 * interceptor (registered in main.tsx).
 */
import { create } from 'zustand'
import { tokenStorage, type TokenSet } from '../lib/storage'
import type { User } from '../types/user'
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
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  status: 'idle',
  message: null,

  bootstrap: async () => {
    if (get().status === 'bootstrapping') return
    set({ status: 'bootstrapping', message: null })

    const tokens = tokenStorage.read()
    if (!tokens || tokenStorage.isAccessExpired()) {
      tokenStorage.clear()
      set({ user: null, status: 'unauthenticated' })
      return
    }

    try {
      const user = await getCurrentUser()
      set({ user, status: 'authenticated' })
    } catch {
      tokenStorage.clear()
      set({ user: null, status: 'unauthenticated' })
    }
  },

  setSession: (user, tokens) => {
    tokenStorage.write(tokens)
    set({ user, status: 'authenticated', message: null })
  },

  logout: async () => {
    await apiLogout()
    tokenStorage.clear()
    set({ user: null, status: 'unauthenticated', message: null })
  },

  forceLogout: (message) => {
    tokenStorage.clear()
    set({
      user: null,
      status: 'unauthenticated',
      message: message ?? 'Session expired. Please log in again.',
    })
  },
}))
