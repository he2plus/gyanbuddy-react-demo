/**
 * ProfilePage — restyled to match the new design language.
 * Shows: avatar hero card with full name and class info, stat tiles
 * (XP / Rewards / Level), action rows (Edit profile / Change password /
 * Notifications / Help / Logout).
 *
 * The Flutter screen also had sound + vibration toggles — those need
 * platform-specific web equivalents we haven't built yet, kept as TBD.
 */
import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import {
  ChevronRight, Flame, Gift, Pencil, KeyRound,
  Bell, HelpCircle, LogOut, Trophy,
} from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import { useAuthStore } from '../../state/auth'
import { getCurrentUser } from '../../api/users'

const NAVY = '#00167A'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

export function ProfilePage() {
  const me = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)
  const navigate = useNavigate()

  const { data: fresh } = useQuery({
    queryKey: ['users', 'me'],
    queryFn: getCurrentUser,
    staleTime: 0,
    refetchOnMount: true,
  })

  useEffect(() => {
    if (fresh) useAuthStore.setState({ user: fresh })
  }, [fresh])

  const user = fresh ?? me
  if (!user) return null

  const initial = (user.firstName?.[0] ?? user.username?.[0] ?? 'U').toUpperCase()
  const onLogout = async () => {
    await logout()
    navigate('/login', { replace: true })
  }

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Profile" />

      <main
        className="mx-auto flex flex-col"
        style={{ maxWidth: 1100, padding: '50px 24px 60px', gap: 32 }}
      >
        {/* Hero card */}
        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
          className="bg-white flex items-center"
          style={{
            padding: 32, borderRadius: 34, gap: 28,
            border: '1px solid #E7E7E7',
            boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
          }}
        >
          {/* Avatar */}
          <div
            className="grid place-items-center shrink-0 relative"
            style={{
              width: 120, height: 120, borderRadius: 999,
              background: `radial-gradient(circle at 32% 28%, #1F3DB8 0%, ${NAVY} 65%, #000A4A 100%)`,
              boxShadow: '0 12px 28px rgba(0,22,122,0.28)',
            }}
          >
            <span
              className="font-body"
              style={{ fontSize: 64, fontWeight: 700, color: '#fff', lineHeight: 1 }}
            >
              {initial}
            </span>
          </div>

          <div className="flex-1 flex flex-col" style={{ gap: 6 }}>
            <h1
              className="font-body capitalize"
              style={{ fontSize: 32, fontWeight: 700, color: TXT_DARK, lineHeight: '42px', margin: 0 }}
            >
              {user.fullName || user.username}
            </h1>
            <span
              className="font-body"
              style={{ fontSize: 16, fontWeight: 500, color: TXT_MID, lineHeight: '22px' }}
            >
              {user.schoolName || 'GyanBuddy Student'} · Admission #{user.admissionNumber || '—'}
            </span>
            {user.email && (
              <span
                className="font-body"
                style={{ fontSize: 14, fontWeight: 400, color: TXT_MUTED, lineHeight: '20px' }}
              >
                {user.email}
              </span>
            )}
          </div>

          <button
            type="button"
            onClick={() => navigate('/profile/edit')}
            className="grid place-items-center font-body"
            style={{
              background: NAVY, color: '#fff', borderRadius: 999,
              padding: '12px 20px', height: 48, gap: 8,
            }}
          >
            <span className="flex items-center" style={{ gap: 8 }}>
              <Pencil className="w-4 h-4" strokeWidth={2.5} />
              Edit
            </span>
          </button>
        </motion.section>

        {/* Stat tiles */}
        <div className="grid grid-cols-3" style={{ gap: 24 }}>
          <StatCard
            icon={<Trophy className="w-7 h-7" style={{ color: '#fff' }} strokeWidth={2.2} />}
            label="Total XP"
            value={user.totalExp.toLocaleString()}
          />
          <StatCard
            icon={<Gift className="w-7 h-7" style={{ color: '#fff' }} strokeWidth={2.2} />}
            label="Rewards"
            value={(user.rewards ?? 0).toLocaleString()}
          />
          <StatCard
            icon={<Flame className="w-7 h-7" style={{ color: '#fff' }} strokeWidth={2.2} />}
            label="Level"
            value={user.level ? `${user.level.name}` : '1'}
          />
        </div>

        {/* Action rows */}
        <section
          className="bg-white overflow-hidden"
          style={{
            borderRadius: 34, border: '1px solid #E7E7E7',
            boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
          }}
        >
          <ActionRow
            icon={<Pencil className="w-5 h-5" style={{ color: NAVY }} strokeWidth={2.2} />}
            label="Edit profile"
            sublabel="Update your name, school, contact info"
            onClick={() => navigate('/profile/edit')}
          />
          <Divider />
          <ActionRow
            icon={<KeyRound className="w-5 h-5" style={{ color: NAVY }} strokeWidth={2.2} />}
            label="Change password"
            sublabel="Pick a new password"
            onClick={() => navigate('/profile/change-password')}
          />
          <Divider />
          <ActionRow
            icon={<Bell className="w-5 h-5" style={{ color: NAVY }} strokeWidth={2.2} />}
            label="Notifications"
            sublabel="See your recent activity"
            onClick={() => navigate('/notifications')}
          />
          <Divider />
          <ActionRow
            icon={<HelpCircle className="w-5 h-5" style={{ color: NAVY }} strokeWidth={2.2} />}
            label="Help & Support"
            sublabel="Reach out if you're stuck"
            onClick={() => window.open('mailto:dptmywork@gmail.com')}
          />
          <Divider />
          <ActionRow
            icon={<LogOut className="w-5 h-5" style={{ color: '#FF3131' }} strokeWidth={2.2} />}
            label="Log out"
            sublabel="Sign out of this device"
            danger
            onClick={onLogout}
          />
        </section>
      </main>
    </div>
  )
}

function StatCard({
  icon, label, value,
}: {
  icon: React.ReactNode; label: string; value: string
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="flex flex-col items-center relative overflow-hidden"
      style={{
        background: NAVY, color: '#fff', borderRadius: 24,
        padding: '32px 24px', gap: 12,
      }}
    >
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: 'radial-gradient(circle at 25% 0%, rgba(26,188,254,0.18), transparent 55%)',
        }}
      />
      <div className="relative">{icon}</div>
      <div
        className="relative font-body tabular-nums"
        style={{
          fontFamily: 'var(--font-numeric)',
          fontSize: 40, fontWeight: 900, color: '#fff', lineHeight: 1,
        }}
      >
        {value}
      </div>
      <div
        className="relative font-body"
        style={{
          fontSize: 14, fontWeight: 700, color: '#fff', lineHeight: '20px',
          letterSpacing: '0.06em', textTransform: 'uppercase',
        }}
      >
        {label}
      </div>
    </motion.div>
  )
}

function ActionRow({
  icon, label, sublabel, onClick, danger = false,
}: {
  icon: React.ReactNode
  label: string
  sublabel?: string
  onClick: () => void
  danger?: boolean
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex items-center w-full text-left"
      style={{
        padding: '20px 28px', gap: 18,
        background: 'transparent',
      }}
      onMouseEnter={(e) => (e.currentTarget.style.background = '#F8FAFC')}
      onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
    >
      <div
        className="grid place-items-center shrink-0"
        style={{
          width: 44, height: 44, borderRadius: 14,
          background: danger ? '#FFE2E2' : '#F0F4FF',
        }}
      >
        {icon}
      </div>
      <div className="flex-1 flex flex-col" style={{ gap: 2 }}>
        <span
          className="font-body"
          style={{
            fontSize: 16, fontWeight: 700,
            color: danger ? '#B91C1C' : TXT_DARK,
            lineHeight: '22px',
          }}
        >
          {label}
        </span>
        {sublabel && (
          <span
            className="font-body"
            style={{ fontSize: 14, fontWeight: 400, color: TXT_MUTED, lineHeight: '20px' }}
          >
            {sublabel}
          </span>
        )}
      </div>
      <ChevronRight className="w-5 h-5 shrink-0" style={{ color: TXT_MUTED }} strokeWidth={2.5} />
    </button>
  )
}

function Divider() {
  return <div style={{ height: 1, background: '#F1F1F1' }} />
}
