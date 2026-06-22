/**
 * TopBar — the universal page header. Verified pixel-faithful against
 * Figma Frame 134 (1920 × 117, white bg, hairline bottom #f3f3f3).
 *
 * Used by every "redesigned" page (Home, Subject, Journey, Missions,
 * Leaderboard, Tests). The AppShell hides its persistent SideNav on those
 * routes so this bar is the only chrome.
 *
 * Props:
 *   pageTitle  — large 32px navy/black title shown next to the G logo
 *   xp         — current user XP, rendered in the right-side pill
 *   testCount  — small badge on the Tests button (number of pending tests)
 *
 * Auth + nav side-effects live here so individual pages don't reimplement
 * the same logout / Tests / notification handlers six times.
 */
import { useCallback, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Bell, ClipboardList, LogOut, Menu, Sparkles } from 'lucide-react'

import { useAuthStore } from '../state/auth'
import { NavDrawer } from './NavDrawer'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'

export function TopBar({
  pageTitle,
  testCount = 0,
  onBack,
}: {
  /** Large title shown next to the G logo. Omit to render the logo alone
      (the Home page does this for a cleaner, slimmer bar). */
  pageTitle?: string
  testCount?: number
  /** When provided, a back arrow is shown after the menu button. */
  onBack?: () => void
}) {
  const me = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)
  const navigate = useNavigate()
  const xp = me?.totalExp ?? 0
  const [drawerOpen, setDrawerOpen] = useState(false)

  // useCallback so NavDrawer's effect deps stay stable (defence in depth —
  // the real fix lives inside NavDrawer, but a stable handle never hurts).
  const closeDrawer = useCallback(() => setDrawerOpen(false), [])

  return (
    <>
    <NavDrawer open={drawerOpen} onClose={closeDrawer} />
    <header
      className="w-full bg-white border-b"
      style={{ height: 'clamp(54px, 7vw, 76px)', borderColor: '#F3F3F3' }}
    >
      <div
        className="mx-auto flex items-center"
        style={{ maxWidth: 1920, padding: 'clamp(8px, 1.2vw, 14px) clamp(16px, 4vw, 120px)', gap: 'clamp(10px, 2vw, 34px)', height: '100%' }}
      >
        {/* Left lockup: burger + [back] + G + title/subtitle */}
        <div className="flex items-center min-w-0" style={{ gap: 'clamp(8px, 1.5vw, 16px)' }}>
          <button
            type="button"
            aria-label="Open menu"
            onClick={() => setDrawerOpen(true)}
            className="grid place-items-center"
            style={{
              width: 40, height: 40, borderRadius: 12, color: TXT_MID,
              background: 'transparent',
              transition: 'background 0.15s ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.background = '#F1F1F1')}
            onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
          >
            <Menu className="w-7 h-7" strokeWidth={2.5} />
          </button>
          {onBack && (
            <button
              type="button"
              aria-label="Go back"
              onClick={onBack}
              className="grid place-items-center shrink-0"
              style={{
                width: 40, height: 40, borderRadius: 12, color: TXT_MID,
                background: 'transparent', transition: 'background 0.15s ease',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.background = '#F1F1F1')}
              onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
            >
              <ArrowLeft className="w-6 h-6" strokeWidth={2.5} />
            </button>
          )}
          <div
            className="grid place-items-center bg-white shadow-sm shrink-0"
            style={{ width: 'clamp(38px, 4vw, 52px)', height: 'clamp(38px, 4vw, 52px)', borderRadius: 12 }}
          >
            <div
              className="font-display"
              style={{ fontSize: 'clamp(22px, 2.6vw, 30px)', fontWeight: 800, color: NAVY, lineHeight: 1 }}
            >
              G
            </div>
          </div>
          {/* Page title only — the "Gyanbuddy" subtitle was dropped so the bar
              stays slim and uncluttered. Home omits the title entirely. */}
          {pageTitle && (
            <div className="flex flex-col leading-none min-w-0">
              <div
                className="font-body truncate"
                style={{ fontSize: 'clamp(18px, 3.2vw, 30px)', fontWeight: 600, color: '#000', lineHeight: 1.18 }}
              >
                {pageTitle}
              </div>
            </div>
          )}
        </div>

        <div className="flex-1" />

        {/* Right cluster: XP pill / bell / Tests / Logout */}
        <div className="flex items-center shrink-0" style={{ gap: 'clamp(6px, 1.4vw, 24px)' }}>
          <div
            className="flex items-center bg-white shrink-0"
            style={{ height: 'clamp(40px, 5vw, 58px)', borderRadius: 50, padding: '0 clamp(12px, 2vw, 26px)', gap: 8 }}
          >
            <Sparkles className="w-7 h-7" style={{ color: CYAN }} strokeWidth={2.2} />
            <span
              className="font-body tabular-nums"
              style={{
                fontSize: 'clamp(14px, 2vw, 24px)', fontWeight: 600, color: TXT_MUTED, lineHeight: 1,
              }}
            >
              {xp}<span className="hidden sm:inline"> XP</span>
            </span>
          </div>

          <button
            type="button"
            aria-label="Notifications"
            onClick={() => navigate('/notifications')}
            className="relative grid place-items-center bg-white shrink-0"
            style={{ width: 'clamp(44px, 5vw, 62px)', height: 'clamp(40px, 5vw, 58px)', borderRadius: 50 }}
          >
            <Bell className="w-7 h-7" style={{ color: TXT_MID }} strokeWidth={2} />
            <span
              className="absolute"
              style={{
                top: 8, right: 14,
                width: 10, height: 10, borderRadius: 99,
                background: CYAN,
              }}
            />
          </button>

          <button
            type="button"
            onClick={() => navigate('/tests')}
            className="flex items-center bg-white shrink-0"
            style={{ height: 'clamp(40px, 5vw, 58px)', borderRadius: 50, padding: '0 clamp(12px, 2vw, 26px)', gap: 8 }}
          >
            <ClipboardList
              className="w-6 h-6" style={{ color: CYAN }} strokeWidth={2.2}
            />
            <span
              className="font-body hidden md:inline"
              style={{
                fontSize: 'clamp(16px, 2vw, 24px)', fontWeight: 600, color: NAVY, lineHeight: 1,
              }}
            >
              Tests
            </span>
            {testCount > 0 && (
              <span
                className="grid place-items-center"
                style={{
                  width: 24, height: 24, borderRadius: 99,
                  background: CYAN, color: '#fff',
                  fontFamily: 'var(--font-body)',
                  fontSize: 16, fontWeight: 600,
                }}
              >
                {testCount}
              </span>
            )}
          </button>

          <button
            type="button"
            onClick={async () => {
              await logout()
              navigate('/login', { replace: true })
            }}
            className="flex items-center shrink-0"
            style={{ gap: 10 }}
          >
            <LogOut className="w-6 h-6" style={{ color: TXT_MID }} strokeWidth={2} />
            <span
              className="font-body hidden md:inline"
              style={{
                fontSize: 'clamp(16px, 2vw, 24px)', fontWeight: 600, color: TXT_MID, lineHeight: 1,
              }}
            >
              Logout
            </span>
          </button>
        </div>
      </div>
    </header>
    </>
  )
}
