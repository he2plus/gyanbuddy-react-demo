/**
 * App-wide providers. Phase 0 wires QueryClient + Toaster only.
 * Tier 1 will add AuthProvider (token bootstrap) and PostHog.
 */
import { type ReactNode, useState } from 'react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'react-hot-toast'

type Props = { children: ReactNode }

export function AppProviders({ children }: Props) {
  // One client per app instance. Stable across re-renders.
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60_000,
            refetchOnWindowFocus: false,
            retry: 1,
          },
        },
      }),
  )

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <Toaster
        position="top-center"
        toastOptions={{
          duration: 3500,
          style: {
            borderRadius: 'var(--radius-base)',
            fontFamily: 'var(--font-sans)',
          },
        }}
      />
    </QueryClientProvider>
  )
}
