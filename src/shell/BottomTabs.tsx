/**
 * Mobile bottom tab bar. Tier 3: 5 destinations — Home / Subjects / Missions /
 * Leaderboard / Profile. Notifications + Credits live in the desktop side nav.
 */
import { NavLink } from 'react-router-dom'
import { Home, BookOpen, Target, Trophy, User } from 'lucide-react'

const tabs = [
  { to: '/home', label: 'Home', icon: Home },
  { to: '/subjects', label: 'Subjects', icon: BookOpen },
  { to: '/missions', label: 'Missions', icon: Target },
  { to: '/leaderboard', label: 'Ranks', icon: Trophy },
  { to: '/profile', label: 'You', icon: User },
] as const

export function BottomTabs() {
  return (
    <nav
      className="sticky bottom-0 left-0 right-0 z-10 flex items-stretch justify-around border-t border-[var(--color-input-border)] bg-[var(--color-bg)] pb-[env(safe-area-inset-bottom)]"
      aria-label="Primary"
    >
      {tabs.map(({ to, label, icon: Icon }) => (
        <NavLink
          key={label}
          to={to}
          end
          className={({ isActive }) =>
            `flex flex-1 flex-col items-center gap-0.5 py-2 text-[11px] font-medium transition-colors ${
              isActive
                ? 'text-[var(--color-primary)]'
                : 'text-[var(--color-text-light)]'
            }`
          }
        >
          <Icon className="h-5 w-5" />
          <span>{label}</span>
        </NavLink>
      ))}
    </nav>
  )
}
