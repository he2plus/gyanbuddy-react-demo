/**
 * NotificationsPage — lists recent app events from /api/notifications/.
 * Each notification is classified by its `type` (test / mission / chapter /
 * leaderboard / achievement / system) and rendered with the matching icon
 * and palette.
 */
import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import {
  Bell, BellOff, Trophy, Flame, BookOpen, Sparkles, Target, Check, AlertCircle,
  type LucideIcon,
} from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import {
  getNotifications, markAllNotificationsRead,
  type Notification, type NotificationKind,
} from '../../api/notifications'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

const KIND_META: Record<NotificationKind, { icon: LucideIcon; bg: string; fg: string }> = {
  achievement: { icon: Trophy,    bg: '#FFF4D6', fg: '#B45309' },
  mission:     { icon: Target,    bg: '#FFE7D7', fg: '#C05127' },
  leaderboard: { icon: Sparkles,  bg: '#CFF1FF', fg: CYAN },
  chapter:     { icon: BookOpen,  bg: '#E0E7FF', fg: NAVY },
  test:        { icon: Flame,     bg: '#FFE2E2', fg: '#FF3131' },
  system:      { icon: Bell,      bg: '#F1F5F9', fg: TXT_MID },
}

export function NotificationsPage() {
  const navigate = useNavigate()
  const query = useQuery({
    queryKey: ['notifications'],
    queryFn: getNotifications,
    staleTime: 30_000,
  })

  const [items, setItems] = useState<Notification[]>([])
  useEffect(() => {
    if (query.data) setItems(query.data)
  }, [query.data])

  const unread = useMemo(() => items.filter((n) => !n.read).length, [items])
  const markAllRead = () => {
    setItems((arr) => arr.map((n) => ({ ...n, read: true })))
    void markAllNotificationsRead()
  }

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Notifications" testCount={1} />

      <main
        className="mx-auto flex flex-col"
        style={{ maxWidth: 900, padding: '50px 24px 60px', gap: 24 }}
      >
        <div className="flex items-center" style={{ gap: 18 }}>
          <div
            className="grid place-items-center shrink-0"
            style={{
              width: 56, height: 56, borderRadius: 18,
              background: NAVY, color: '#fff',
            }}
          >
            <Bell className="w-7 h-7" strokeWidth={2.2} />
          </div>
          <div className="flex-1 flex flex-col" style={{ gap: 2 }}>
            <h1
              className="font-body"
              style={{ fontSize: 28, fontWeight: 700, color: TXT_DARK, lineHeight: '36px', margin: 0 }}
            >
              Notifications
            </h1>
            <span
              className="font-body"
              style={{ fontSize: 16, fontWeight: 500, color: TXT_MID, lineHeight: '22px' }}
            >
              {unread > 0 ? `${unread} unread • ${items.length} total` : `${items.length} total`}
            </span>
          </div>
          {unread > 0 && (
            <button
              type="button"
              onClick={markAllRead}
              className="font-body"
              style={{
                padding: '10px 18px', borderRadius: 999,
                background: '#fff', border: '1px solid #E7E7E7', color: NAVY,
                fontSize: 14, fontWeight: 700,
              }}
            >
              <span className="flex items-center" style={{ gap: 6 }}>
                <Check className="w-4 h-4" strokeWidth={2.5} />
                Mark all read
              </span>
            </button>
          )}
        </div>

        {query.isLoading ? (
          <LoadingState />
        ) : query.isError ? (
          <ErrorState message={(query.error as Error)?.message || 'Failed to load notifications'} onRetry={() => query.refetch()} />
        ) : items.length === 0 ? (
          <EmptyState />
        ) : (
          <section
            className="bg-white overflow-hidden"
            style={{
              borderRadius: 34, border: '1px solid #E7E7E7',
              boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
            }}
          >
            {items.map((n, i) => (
              <NotificationRow key={n.id} item={n} index={i} isLast={i === items.length - 1} />
            ))}
          </section>
        )}

        {items.length > 0 && (
          <div className="text-center">
            <button
              type="button"
              onClick={() => navigate('/home')}
              className="font-body"
              style={{ color: NAVY, fontWeight: 700, fontSize: 16, background: 'transparent' }}
            >
              ← Back to home
            </button>
          </div>
        )}
      </main>
    </div>
  )
}

function NotificationRow({
  item, index, isLast,
}: {
  item: Notification; index: number; isLast: boolean
}) {
  const meta = KIND_META[item.kind]
  const Icon = meta.icon
  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.04, duration: 0.3 }}
      className="flex items-start"
      style={{
        padding: '20px 28px', gap: 18,
        background: item.read ? 'transparent' : 'rgba(26,188,254,0.05)',
        borderBottom: isLast ? 'none' : '1px solid #F1F1F1',
      }}
    >
      <div
        className="grid place-items-center shrink-0"
        style={{
          width: 44, height: 44, borderRadius: 14,
          background: meta.bg, color: meta.fg,
        }}
      >
        <Icon className="w-5 h-5" strokeWidth={2.2} />
      </div>
      <div className="flex-1 flex flex-col" style={{ gap: 4 }}>
        <div className="flex items-center" style={{ gap: 8 }}>
          <span
            className="font-body"
            style={{ fontSize: 16, fontWeight: 700, color: TXT_DARK, lineHeight: '22px' }}
          >
            {item.title}
          </span>
          {!item.read && (
            <span style={{ width: 8, height: 8, borderRadius: 999, background: CYAN }} />
          )}
        </div>
        <span
          className="font-body"
          style={{ fontSize: 14, fontWeight: 400, color: TXT_MID, lineHeight: '20px' }}
        >
          {item.body}
        </span>
        <span
          className="font-body"
          style={{ fontSize: 12, fontWeight: 500, color: TXT_MUTED, lineHeight: '16px' }}
        >
          {formatRelative(item.createdAt)}
        </span>
      </div>
    </motion.div>
  )
}

function LoadingState() {
  return (
    <section
      className="bg-white"
      style={{ borderRadius: 34, border: '1px solid #E7E7E7', boxShadow: '0 4px 18px rgba(0,0,0,0.04)' }}
    >
      {Array.from({ length: 4 }).map((_, i) => (
        <div
          key={i}
          className="flex items-start animate-pulse"
          style={{
            padding: '20px 28px', gap: 18,
            borderBottom: i === 3 ? 'none' : '1px solid #F1F1F1',
          }}
        >
          <div style={{ width: 44, height: 44, borderRadius: 14, background: '#F1F1F1' }} />
          <div className="flex-1 flex flex-col" style={{ gap: 8 }}>
            <div style={{ height: 16, width: '60%', borderRadius: 6, background: '#F1F1F1' }} />
            <div style={{ height: 14, width: '85%', borderRadius: 6, background: '#F4F4F4' }} />
          </div>
        </div>
      ))}
    </section>
  )
}

function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div
      className="bg-white grid place-items-center text-center"
      style={{
        padding: 48, borderRadius: 34, border: '1px solid #E7E7E7',
        boxShadow: '0 4px 18px rgba(0,0,0,0.04)', gap: 14,
      }}
    >
      <AlertCircle className="w-9 h-9" style={{ color: '#FF3131' }} strokeWidth={2} />
      <span
        className="font-body"
        style={{ fontSize: 16, fontWeight: 600, color: TXT_DARK }}
      >
        {message}
      </span>
      <button
        type="button"
        onClick={onRetry}
        className="font-body"
        style={{
          marginTop: 8, padding: '10px 22px', borderRadius: 999,
          background: NAVY, color: '#fff', fontSize: 14, fontWeight: 700,
        }}
      >
        Retry
      </button>
    </div>
  )
}

function EmptyState() {
  return (
    <div
      className="bg-white grid place-items-center text-center"
      style={{
        padding: 60, borderRadius: 34, border: '1px solid #E7E7E7',
        boxShadow: '0 4px 18px rgba(0,0,0,0.04)', gap: 16,
      }}
    >
      <div
        className="grid place-items-center"
        style={{
          width: 88, height: 88, borderRadius: 999,
          background: '#F8FAFC', border: '1px solid #EAEAEA',
        }}
      >
        <BellOff className="w-9 h-9" style={{ color: TXT_MUTED }} strokeWidth={2} />
      </div>
      <div className="flex flex-col items-center" style={{ gap: 4 }}>
        <span
          className="font-body"
          style={{ fontSize: 20, fontWeight: 700, color: TXT_DARK, lineHeight: '28px' }}
        >
          You're all caught up
        </span>
        <span
          className="font-body"
          style={{ fontSize: 14, fontWeight: 400, color: TXT_MUTED, lineHeight: '20px' }}
        >
          New notifications will show up here.
        </span>
      </div>
    </div>
  )
}

function formatRelative(d: Date): string {
  const diff = (Date.now() - d.getTime()) / 1000
  if (diff < 60) return 'just now'
  if (diff < 3600) return `${Math.floor(diff / 60)} min ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)} hr ago`
  if (diff < 604800) return `${Math.floor(diff / 86400)} d ago`
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}
