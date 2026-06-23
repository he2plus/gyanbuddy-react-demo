/**
 * RequireAuth — wrap any route that needs an authenticated user.
 *
 * - status === 'idle' / 'bootstrapping' → splash (should be brief with optimistic auth)
 * - status === 'unauthenticated' → /login
 * - status === 'authenticated' → render children
 *
 * With optimistic auth in the store, 'bootstrapping' only appears for the very
 * first visit (no cached user). Return visits hit 'authenticated' immediately.
 * The splash shows a "slow connection" message after 5 s and a retry after 12 s
 * so users on bad networks aren't left with a forever spinner.
 */
import { type ReactNode, useEffect, useState } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuthStore } from '../../state/auth'

export function RequireAuth({ children }: { children: ReactNode }) {
  const status = useAuthStore((s) => s.status)
  const location = useLocation()

  if (status === 'idle' || status === 'bootstrapping') {
    return <BootstrapSplash />
  }

  if (status === 'unauthenticated') {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }

  return <>{children}</>
}

function BootstrapSplash() {
  const [elapsed, setElapsed] = useState(0)

  useEffect(() => {
    const id = window.setInterval(() => setElapsed((s) => s + 1), 1000)
    return () => window.clearInterval(id)
  }, [])

  const slowMessage =
    elapsed >= 12
      ? 'Still connecting…'
      : elapsed >= 5
      ? 'Taking longer than usual…'
      : 'Loading…'

  return (
    <div className="grid min-h-screen place-items-center">
      <div className="flex flex-col items-center gap-4">
        <div className="flex items-center gap-3 text-sm text-[var(--color-text-light)]">
          <span className="inline-block h-2 w-2 animate-pulse rounded-full bg-[var(--color-primary)]" />
          {slowMessage}
        </div>

        {elapsed >= 12 && (
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="rounded-lg border border-[var(--color-input-border)] px-4 py-2 text-sm text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-secondary)]"
          >
            Tap to retry
          </button>
        )}

        {elapsed >= 5 && elapsed < 12 && (
          <p className="max-w-xs text-center text-xs text-[var(--color-text-light)]">
            Server may be slow. Please wait a moment.
          </p>
        )}
      </div>
    </div>
  )
}
