/**
 * Responsive shell. Sidebar width depends on the persisted collapsed state
 * from useUIStore.
 */
import { Outlet, useLocation } from 'react-router-dom'

import { BottomTabs } from './BottomTabs'
import { SideNav } from './SideNav'
import { useUIStore } from '../state/ui'

// Pages with their own Figma-faithful top bar render the chrome themselves;
// the persistent SideNav would steal width and break pixel-exact layouts.
// Exact paths or prefix patterns (anything starting with these) are hidden.
const HIDE_CHROME_EXACT = new Set([
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/onboarding',
  '/confirmation',
  '/home',
  '/subjects',
  '/missions',
  '/leaderboard',
  '/tests',
  '/notifications',
  '/profile',
  '/credits',
])
// Anything under these prefixes also runs chrome-less (Journey page, etc.)
const HIDE_CHROME_PREFIX = ['/subjects/', '/missions/', '/tests/', '/profile/']

function isChromeless(path: string): boolean {
  if (HIDE_CHROME_EXACT.has(path)) return true
  return HIDE_CHROME_PREFIX.some((p) => path.startsWith(p))
}

export function AppShell() {
  const { pathname } = useLocation()
  const showChrome = !isChromeless(pathname)
  const collapsed = useUIStore((s) => s.sidenavCollapsed)

  const sidebarWidth = collapsed ? 64 : 240

  return (
    <div className="min-h-screen w-full bg-white">
      <div className="mx-auto flex w-full max-w-[1920px]">
        {showChrome && (
          <aside
            className="hidden shrink-0 transition-[width] duration-200 ease-out lg:block"
            style={{ width: sidebarWidth }}
          >
            <SideNav />
          </aside>
        )}

        <main className="relative min-h-screen flex-1">
          <Outlet />

          {showChrome && (
            <div className="lg:hidden">
              <BottomTabs />
            </div>
          )}
        </main>
      </div>
    </div>
  )
}
