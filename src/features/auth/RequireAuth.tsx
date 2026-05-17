/**
 * RequireAuth — wrap any route that needs an authenticated user.
 *
 * - status === 'bootstrapping' → render a minimal splash so the page doesn't
 *   flash to /login during the initial /users/me call.
 * - status === 'unauthenticated' AND onboarding not yet completed → /onboarding
 *   so first-time visitors see the welcome carousel instead of a raw login form.
 *   Onboarding's "Get started" flips the flag and sends them to /login.
 * - status === 'unauthenticated' AND onboarding completed → /login.
 * - status === 'authenticated' → render children.
 */
import { type ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuthStore } from '../../state/auth'
import { onboardingStore } from '../../lib/onboarding'

export function RequireAuth({ children }: { children: ReactNode }) {
  const status = useAuthStore((s) => s.status)
  const location = useLocation()

  if (status === 'idle' || status === 'bootstrapping') {
    return <BootstrapSplash />
  }

  if (status === 'unauthenticated') {
    const target = onboardingStore.isComplete() ? '/login' : '/onboarding'
    return <Navigate to={target} replace state={{ from: location.pathname }} />
  }

  return <>{children}</>
}

function BootstrapSplash() {
  return (
    <div className="grid min-h-screen place-items-center text-[var(--color-text-light)]">
      <div className="flex items-center gap-3 text-sm">
        <span className="inline-block h-2 w-2 animate-pulse rounded-full bg-[var(--color-primary)]" />
        Loading…
      </div>
    </div>
  )
}
