/**
 * Responsive shell. Sidebar width depends on the persisted collapsed state
 * from useUIStore.
 */
import { Outlet, useLocation } from 'react-router-dom'

import { BottomTabs } from './BottomTabs'
import { SideNav } from './SideNav'
import { useUIStore } from '../state/ui'

const HIDE_CHROME_ON = new Set([
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/onboarding',
  '/confirmation',
])

export function AppShell() {
  const { pathname } = useLocation()
  const showChrome = !HIDE_CHROME_ON.has(pathname)
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
