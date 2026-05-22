/**
 * NavDrawer — left-side slide-in drawer triggered by the TopBar burger.
 * Uses framer-motion for the slide + a backdrop click to close.
 */
import { useEffect } from 'react'
import { NavLink } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Home, BookOpen, Target, ClipboardList, Trophy, Bell, User, CreditCard,
  LogOut, X,
} from 'lucide-react'

import { useAuthStore } from '../state/auth'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'

const ITEMS = [
  { to: '/home',          label: 'Home',          icon: Home },
  { to: '/subjects',      label: 'Subjects',      icon: BookOpen },
  { to: '/missions',      label: 'Missions',      icon: Target },
  { to: '/tests',         label: 'Tests',         icon: ClipboardList },
  { to: '/podium',        label: 'Leaderboard',   icon: Trophy },
  { to: '/notifications', label: 'Notifications', icon: Bell },
  { to: '/profile',       label: 'Profile',       icon: User },
  { to: '/credits',       label: 'Credits',       icon: CreditCard },
] as const

export function NavDrawer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const logout = useAuthStore((s) => s.logout)
  const me = useAuthStore((s) => s.user)

  // Note: route-change-closes-drawer is handled by NavLink onClick below,
  // NOT by a useEffect on location.pathname. The previous useEffect had
  // `onClose` in its deps, which is a fresh function each parent render —
  // the effect re-fired and slammed the drawer shut the same frame it opened.

  // Close on Escape
  useEffect(() => {
    if (!open) return
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [open, onClose])

  // Lock body scroll while open
  useEffect(() => {
    if (!open) return
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => { document.body.style.overflow = prev }
  }, [open])

  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            key="backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={onClose}
            className="fixed inset-0 z-40"
            style={{ background: 'rgba(15,23,42,0.45)', backdropFilter: 'blur(2px)' }}
          />

          {/* Drawer */}
          <motion.aside
            key="drawer"
            initial={{ x: '-100%' }}
            animate={{ x: 0 }}
            exit={{ x: '-100%' }}
            transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
            className="fixed top-0 left-0 bottom-0 z-50 flex flex-col bg-white"
            style={{
              width: 320, padding: 0,
              boxShadow: '6px 0 30px rgba(0,0,0,0.16)',
            }}
            role="dialog"
            aria-label="Primary navigation"
          >
            {/* Header */}
            <div
              className="flex items-center"
              style={{ padding: '24px 24px 16px', gap: 14 }}
            >
              <div
                className="grid place-items-center bg-white shadow"
                style={{ width: 52, height: 54, borderRadius: 14, border: '1px solid #E7E7E7' }}
              >
                <span
                  className="font-display"
                  style={{ fontSize: 28, fontWeight: 800, color: NAVY, lineHeight: 1 }}
                >
                  G
                </span>
              </div>
              <div className="flex flex-col flex-1 leading-tight">
                <span
                  className="font-body"
                  style={{ fontSize: 20, fontWeight: 700, color: NAVY }}
                >
                  GyanBuddy
                </span>
                <span
                  className="font-body"
                  style={{ fontSize: 13, fontWeight: 500, color: TXT_MID }}
                >
                  A smarter way to learn
                </span>
              </div>
              <button
                type="button"
                onClick={onClose}
                aria-label="Close menu"
                className="grid place-items-center"
                style={{
                  width: 40, height: 40, borderRadius: 12,
                  background: '#F1F1F1', color: TXT_MID,
                }}
              >
                <X className="w-5 h-5" strokeWidth={2.5} />
              </button>
            </div>

            {/* User badge */}
            {me && (
              <div
                className="flex items-center"
                style={{ padding: '16px 24px', gap: 14, borderTop: '1px solid #F1F1F1', borderBottom: '1px solid #F1F1F1' }}
              >
                <div
                  className="grid place-items-center shrink-0"
                  style={{
                    width: 48, height: 48, borderRadius: 999,
                    background: `radial-gradient(circle at 32% 28%, #1F3DB8 0%, ${NAVY} 100%)`,
                  }}
                >
                  <span
                    className="font-body"
                    style={{ fontSize: 22, fontWeight: 700, color: '#fff' }}
                  >
                    {(me.firstName?.[0] ?? me.username?.[0] ?? 'U').toUpperCase()}
                  </span>
                </div>
                <div className="flex-1 flex flex-col" style={{ gap: 2 }}>
                  <span
                    className="font-body capitalize"
                    style={{ fontSize: 16, fontWeight: 700, color: TXT_DARK, lineHeight: '22px' }}
                  >
                    {me.firstName || me.username}
                  </span>
                  <span
                    className="font-body"
                    style={{ fontSize: 13, fontWeight: 500, color: TXT_MID, lineHeight: '18px' }}
                  >
                    {me.totalExp.toLocaleString()} XP · Level {me.level?.name ?? 1}
                  </span>
                </div>
              </div>
            )}

            {/* Nav items */}
            <nav
              className="flex flex-col flex-1 overflow-y-auto"
              style={{ padding: 12, gap: 4 }}
            >
              {ITEMS.map(({ to, label, icon: Icon }) => (
                <NavLink
                  key={to}
                  to={to}
                  end
                  onClick={onClose}
                  className={({ isActive }) =>
                    `flex items-center w-full text-left ${isActive ? '' : ''}`
                  }
                  style={({ isActive }) => ({
                    padding: '12px 16px', gap: 14, borderRadius: 14,
                    background: isActive ? '#F0F4FF' : 'transparent',
                    color: isActive ? NAVY : TXT_DARK,
                    fontFamily: 'var(--font-body)',
                    fontSize: 16, fontWeight: isActive ? 700 : 500,
                    textDecoration: 'none',
                  })}
                >
                  {({ isActive }) => (
                    <>
                      <span
                        className="grid place-items-center shrink-0"
                        style={{
                          width: 36, height: 36, borderRadius: 10,
                          background: isActive ? NAVY : '#F1F1F1',
                          color: isActive ? '#fff' : TXT_MID,
                        }}
                      >
                        <Icon className="w-4 h-4" strokeWidth={2.2} />
                      </span>
                      {label}
                      {isActive && (
                        <span
                          className="ml-auto"
                          style={{
                            width: 8, height: 8, borderRadius: 999, background: CYAN,
                          }}
                        />
                      )}
                    </>
                  )}
                </NavLink>
              ))}
            </nav>

            {/* Logout */}
            <button
              type="button"
              onClick={async () => {
                await logout()
                onClose()
              }}
              className="flex items-center font-body w-full"
              style={{
                padding: '20px 28px', gap: 14,
                borderTop: '1px solid #F1F1F1',
                color: '#B91C1C',
                fontSize: 16, fontWeight: 700,
              }}
            >
              <span
                className="grid place-items-center shrink-0"
                style={{
                  width: 36, height: 36, borderRadius: 10,
                  background: '#FFE2E2',
                }}
              >
                <LogOut className="w-4 h-4" strokeWidth={2.5} />
              </span>
              Log out
            </button>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  )
}
