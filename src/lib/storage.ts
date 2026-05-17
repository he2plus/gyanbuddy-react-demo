/**
 * Token storage — mirrors lib/services/token_storage_service.dart.
 *
 * Keeps the SAME localStorage keys the Flutter web build uses (see context.txt
 * §5) so users in mid-transition can keep a session across the Flutter→React
 * cutover without re-logging in.
 */

const KEYS = {
  access: 'access_token',
  refresh: 'refresh_token',
  accessExpires: 'access_token_expires',
  refreshExpires: 'refresh_token_expires',
} as const

export type TokenSet = {
  accessToken: string
  refreshToken: string
  accessTokenExpires: string  // ISO
  refreshTokenExpires: string // ISO
}

export const tokenStorage = {
  read(): TokenSet | null {
    if (typeof window === 'undefined') return null
    const accessToken = localStorage.getItem(KEYS.access)
    const refreshToken = localStorage.getItem(KEYS.refresh)
    const accessTokenExpires = localStorage.getItem(KEYS.accessExpires)
    const refreshTokenExpires = localStorage.getItem(KEYS.refreshExpires)
    if (!accessToken || !refreshToken || !accessTokenExpires || !refreshTokenExpires) {
      return null
    }
    return { accessToken, refreshToken, accessTokenExpires, refreshTokenExpires }
  },

  write(t: TokenSet) {
    localStorage.setItem(KEYS.access, t.accessToken)
    localStorage.setItem(KEYS.refresh, t.refreshToken)
    localStorage.setItem(KEYS.accessExpires, t.accessTokenExpires)
    localStorage.setItem(KEYS.refreshExpires, t.refreshTokenExpires)
  },

  clear() {
    localStorage.removeItem(KEYS.access)
    localStorage.removeItem(KEYS.refresh)
    localStorage.removeItem(KEYS.accessExpires)
    localStorage.removeItem(KEYS.refreshExpires)
  },

  isAccessExpired(): boolean {
    const t = this.read()
    if (!t) return true
    return new Date(t.accessTokenExpires).getTime() <= Date.now()
  },
}
