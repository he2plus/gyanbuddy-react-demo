/**
 * Desktop side navigation. Collapsible — toggle button at top either expands
 * (showing labels) or collapses to icon-only at 64 px wide.
 *
 * Preference is persisted via useUIStore (localStorage).
 */
import { NavLink } from 'react-router-dom'
import {
  Home,
  BookOpen,
  Target,
  ClipboardList,
  Trophy,
  Bell,
  CreditCard,
  User,
  ChevronsLeft,
  ChevronsRight,
} from 'lucide-react'
import { useUIStore } from '../state/ui'

const items = [
  { to: '/home', label: 'Home', icon: Home, end: true },
  { to: '/subjects', label: 'Subjects', icon: BookOpen, end: true },
  { to: '/missions', label: 'Missions', icon: Target, end: true },
  { to: '/tests', label: 'Tests', icon: ClipboardList, end: true },
  { to: '/leaderboard', label: 'Leaderboard', icon: Trophy, end: true },
  { to: '/notifications', label: 'Notifications', icon: Bell, end: true },
  { to: '/profile', label: 'Profile', icon: User, end: true },
  { to: '/credits', label: 'Credits', icon: CreditCard, end: true },
] as const

export function SideNav() {
  const collapsed = useUIStore((s) => s.sidenavCollapsed)
  const toggle = useUIStore((s) => s.toggleSidenav)

  return (
    <nav
      aria-label="Primary"
      className="sticky top-0 flex h-screen flex-col border-r border-[#E0E0E0] bg-white"
    >
      {/* Brand + collapse toggle */}
      <div
        className={`flex items-center border-b border-[#F0F0F0] ${
          collapsed ? 'h-14 justify-center px-2' : 'h-14 justify-between px-4'
        }`}
      >
        {!collapsed && (
          <div className="text-base font-extrabold tracking-tight text-[#00167A]">
            Gyaan<span className="text-[#365DEA]">Buddy</span>
          </div>
        )}
        <button
          type="button"
          onClick={toggle}
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          title={collapsed ? 'Expand' : 'Collapse'}
          className="grid h-8 w-8 place-items-center rounded-md text-[#666] hover:bg-[#F5F5F5] hover:text-[#333]"
        >
          {collapsed ? (
            <ChevronsRight className="h-4 w-4" />
          ) : (
            <ChevronsLeft className="h-4 w-4" />
          )}
        </button>
      </div>

      {/* Items */}
      <div className="flex flex-col gap-0.5 overflow-y-auto p-2">
        {items.map(({ to, label, icon: Icon, end }) => (
          <NavLink
            key={label}
            to={to}
            end={end}
            title={collapsed ? label : undefined}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-md text-sm font-medium transition-colors ${
                collapsed ? 'h-10 justify-center' : 'h-10 px-3'
              } ${
                isActive
                  ? 'bg-[#365DEA] text-white'
                  : 'text-[#555] hover:bg-[#F5F5F5] hover:text-[#222]'
              }`
            }
          >
            <Icon className="h-[18px] w-[18px] shrink-0" />
            {!collapsed && <span className="truncate">{label}</span>}
          </NavLink>
        ))}
      </div>

      <div className="mt-auto border-t border-[#F0F0F0] px-3 py-3 text-[10px] text-[#999]">
        {!collapsed && (
          <div className="space-y-0.5">
            <div>© Gyaan Buddy</div>
            <div>
              Built by{' '}
              <a
                href="mailto:dptmywork@gmail.com"
                className="font-semibold text-[#365DEA] hover:underline"
                title="dptmywork@gmail.com"
              >
                Prakhar Tripathi
              </a>
            </div>
          </div>
        )}
      </div>
    </nav>
  )
}
