/**
 * ProfilePage (view-only) — Tier 2 cut of lib/screens/profile/profile_screen.dart.
 *
 * Skipped for now (Tier 5):
 *   - Sound + vibration toggles (need SoundService / VibrationService web equivalents)
 *   - Profile picture tap action
 *   - Detailed subject progress charts (subject_progress is loose-typed for now)
 *   - Animated counters (the underlying _demo/AnimatedCounter is salvageable
 *     but not wired here yet — keep it tight for view-only)
 *
 * Included:
 *   - Avatar + full name header (green initial circle, like Flutter)
 *   - Stats card: XP / Rewards / Level
 *   - Settings + Support placeholders (rows that will become real Tier 5)
 *   - Logout
 *   - Version footer
 */
import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { LogOut, Volume2, Vibrate, HelpCircle, Mail, ChevronRight, Pencil, KeyRound } from 'lucide-react'

import { ScreenHeader } from '../../components/ScreenHeader'
import { Card } from '../../components/Card'
import { PageContainer } from '../../components/PageContainer'
import { useAuthStore } from '../../state/auth'
import { getCurrentUser } from '../../api/users'
import { useQuery } from '@tanstack/react-query'

export function ProfilePage() {
  const me = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)
  const navigate = useNavigate()

  // Mirror Flutter behavior: force-refresh /users/me when this screen opens.
  const { data: fresh } = useQuery({
    queryKey: ['users', 'me'],
    queryFn: getCurrentUser,
    staleTime: 0,
    refetchOnMount: true,
  })

  useEffect(() => {
    if (fresh) {
      // Update store with the fresh copy without disturbing tokens
      useAuthStore.setState({ user: fresh })
    }
  }, [fresh])

  const user = fresh ?? me

  if (!user) return null

  const initial = user.firstName?.[0]?.toUpperCase() ?? 'U'

  const onLogout = async () => {
    await logout()
    navigate('/login', { replace: true })
  }

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader title="Profile" showBack={false} />

      <PageContainer variant="narrow" className="pb-24">
        {/* Header */}
        <div className="flex items-center gap-5 pt-1 pb-6">
          <div
            className="grid h-20 w-20 shrink-0 place-items-center rounded-full text-3xl font-bold text-white shadow-[0_4px_8px_rgba(16,185,129,0.3)]"
            style={{ background: '#10B981' }}
            aria-hidden="true"
          >
            {initial}
          </div>
          <div className="min-w-0">
            <div className="truncate text-2xl font-bold text-[var(--color-text-primary)]">
              {user.fullName || user.username}
            </div>
            <div className="text-sm text-[var(--color-text-secondary)]">
              Admission #{user.admissionNumber}
            </div>
          </div>
        </div>

        {/* Stats */}
        <Card className="mb-5">
          <div className="grid grid-cols-3 gap-2 px-4 py-5 text-center">
            <Stat label="XP" value={user.totalExp} color="var(--color-primary)" />
            <Stat label="Rewards" value={user.rewards} color="#F59E0B" />
            <Stat label="Level" value={user.level?.name ?? Math.floor(user.totalExp / 100) + 1} color="#10B981" />
          </div>
        </Card>

        {/* Account */}
        <Card title="Account" accent="neutral" className="mb-5">
          <ul className="divide-y divide-[var(--color-input-border)]">
            <Row icon={Pencil} label="Edit profile" onClick={() => navigate('/profile/edit')} />
            <Row icon={KeyRound} label="Change password" onClick={() => navigate('/profile/change-password')} />
          </ul>
        </Card>

        {/* Settings — Tier 5 will wire toggles */}
        <Card title="Settings" accent="neutral" className="mb-5">
          <ul className="divide-y divide-[var(--color-input-border)]">
            <Row icon={Volume2} label="Sound" hint="On" disabled />
            <Row icon={Vibrate} label="Vibration" hint="On" disabled />
          </ul>
        </Card>

        {/* Support */}
        <Card title="Support" accent="neutral" className="mb-5">
          <ul className="divide-y divide-[var(--color-input-border)]">
            <Row icon={HelpCircle} label="Help" />
            <Row icon={Mail} label="Contact us" />
          </ul>
        </Card>

        {/* Logout */}
        <button
          type="button"
          onClick={onLogout}
          className="flex w-full items-center gap-3 rounded-[12px] border border-[var(--color-error)]/30 bg-white p-4 text-[var(--color-error)] shadow-sm transition-colors hover:bg-[var(--color-error)]/5"
        >
          <LogOut className="h-5 w-5" />
          <span className="font-semibold">Log out</span>
        </button>

        <p className="mt-6 text-center text-xs text-[var(--color-text-light)]">
          Build Version 1.0.0 (web)
        </p>
      </PageContainer>
    </div>
  )
}

function Stat({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div>
      <div className="text-xs text-[var(--color-text-light)]">{label}</div>
      <div className="mt-1 text-xl font-bold" style={{ color }}>
        {value.toLocaleString()}
      </div>
    </div>
  )
}

function Row({
  icon: Icon,
  label,
  hint,
  disabled,
  onClick,
}: {
  icon: typeof LogOut
  label: string
  hint?: string
  disabled?: boolean
  onClick?: () => void
}) {
  const inner = (
    <>
      <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-[var(--color-input-fill)] text-[var(--color-text-secondary)]">
        <Icon className="h-4 w-4" />
      </span>
      <span className="flex-1 font-medium text-[var(--color-text-primary)]">{label}</span>
      {hint && <span className="text-sm text-[var(--color-text-light)]">{hint}</span>}
      {!disabled && <ChevronRight className="h-4 w-4 text-[var(--color-text-light)]" />}
    </>
  )
  if (onClick && !disabled) {
    return (
      <li>
        <button
          type="button"
          onClick={onClick}
          className="flex w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-[var(--color-input-fill)]"
        >
          {inner}
        </button>
      </li>
    )
  }
  return (
    <li className={`flex items-center gap-3 px-4 py-3 ${disabled ? 'opacity-60' : ''}`}>
      {inner}
    </li>
  )
}
