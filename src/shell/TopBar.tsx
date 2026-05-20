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
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Bell, ClipboardList, LogOut, Menu, Sparkles } from 'lucide-react'

import { useAuthStore } from '../state/auth'
import { NavDrawer } from './NavDrawer'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'

export function TopBar({
  pageTitle,
  testCount = 0,
}: {
  pageTitle: string
  testCount?: number
}) {
  const me = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)
  const navigate = useNavigate()
  const xp = me?.totalExp ?? 0
  const [drawerOpen, setDrawerOpen] = useState(false)

  return (
    <>
    <NavDrawer open={drawerOpen} onClose={() => setDrawerOpen(false)} />
    <header
      className="w-full bg-white border-b"
      style={{ height: 117, borderColor: '#F3F3F3' }}
    >
      <div
        className="mx-auto flex items-center"
        style={{ maxWidth: 1920, padding: '24px 120px', gap: 34, height: '100%' }}
      >
        {/* Left lockup: burger + G + title/subtitle */}
        <div className="flex items-center" style={{ gap: 24 }}>
          <button
            type="button"
            aria-label="Open menu"
            onClick={() => setDrawerOpen(true)}
            className="grid place-items-center"
            style={{ width: 34, height: 34, color: TXT_MID }}
          >
            <Menu className="w-8 h-8" strokeWidth={2.5} />
          </button>
          <div
            className="grid place-items-center bg-white shadow-sm"
            style={{ width: 65, height: 68, borderRadius: 14 }}
          >
            <div
              className="font-display"
              style={{ fontSize: 36, fontWeight: 800, color: NAVY, lineHeight: 1 }}
            >
              G
            </div>
          </div>
          <div className="flex flex-col leading-none">
            <div
              className="font-body"
              style={{ fontSize: 32, fontWeight: 600, color: '#000', lineHeight: '38px' }}
            >
              {pageTitle}
            </div>
            <div
              className="font-body"
              style={{
                fontSize: 22, fontWeight: 600, color: TXT_MUTED,
                lineHeight: '30px', marginTop: 0,
              }}
            >
              Gyanbuddy
            </div>
          </div>
        </div>

        <div className="flex-1" />

        {/* Right cluster: XP pill / bell / Tests / Logout */}
        <div className="flex items-center" style={{ gap: 24 }}>
          <div
            className="flex items-center bg-white"
            style={{ height: 58, borderRadius: 50, padding: '12px 26px', gap: 10 }}
          >
            <Sparkles className="w-7 h-7" style={{ color: CYAN }} strokeWidth={2.2} />
            <span
              className="font-body tabular-nums"
              style={{
                fontSize: 24, fontWeight: 600, color: TXT_MUTED, lineHeight: '33px',
              }}
            >
              {xp} XP
            </span>
          </div>

          <button
            type="button"
            aria-label="Notifications"
            onClick={() => navigate('/notifications')}
            className="relative grid place-items-center bg-white"
            style={{ width: 62, height: 58, borderRadius: 50 }}
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
            className="flex items-center bg-white"
            style={{ height: 58, borderRadius: 50, padding: '12px 26px', gap: 10 }}
          >
            <ClipboardList
              className="w-6 h-6" style={{ color: CYAN }} strokeWidth={2.2}
            />
            <span
              className="font-body"
              style={{
                fontSize: 24, fontWeight: 600, color: NAVY, lineHeight: '33px',
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
            className="flex items-center"
            style={{ gap: 10 }}
          >
            <LogOut className="w-6 h-6" style={{ color: TXT_MID }} strokeWidth={2} />
            <span
              className="font-body"
              style={{
                fontSize: 24, fontWeight: 600, color: TXT_MID, lineHeight: '33px',
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
