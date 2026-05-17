/**
 * NotificationsPage — mirrors lib/screens/notifications/notification_screen.dart.
 *
 * Flutter app stores notifications LOCALLY (NotificationService uses
 * SharedPreferences). We do the same with localStorage so this screen has
 * zero backend dependency. FCM-pushed notifications will write into the
 * same store in Tier 5.
 *
 * Dropped: the four floating colored "decorative" circles the Flutter
 * version draws. They translate badly to web and read as filler.
 */
import { useEffect, useMemo, useState } from 'react'
import {
  Bell,
  MoreVertical,
  Trash2,
  Award,
  HelpCircle,
  Clock,
  RefreshCcw,
  AlertCircle,
} from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import {
  notificationStore,
  notificationColor,
  formatRelative,
} from '../../lib/notifications'
import type {
  NotificationItem,
  NotificationType,
} from '../../types/notification'

const BRAND_PRIMARY = '#365DEA'
const BRAND_BORDER = '#E0E0E0'

function iconForType(type: NotificationType) {
  switch (type) {
    case 'quiz':
      return HelpCircle
    case 'achievement':
      return Award
    case 'reminder':
      return Clock
    case 'update':
      return RefreshCcw
    default:
      return AlertCircle
  }
}

export function NotificationsPage() {
  const [items, setItems] = useState<NotificationItem[] | null>(null)
  const [showMenu, setShowMenu] = useState(false)

  const load = () => {
    setItems(notificationStore.getAll())
  }

  useEffect(() => {
    load()
  }, [])

  const isLoading = items === null
  const isEmpty = !isLoading && items.length === 0

  const trailing = useMemo(
    () =>
      !isLoading && items.length > 0 ? (
        <div className="relative">
          <button
            type="button"
            onClick={() => setShowMenu((s) => !s)}
            aria-label="More actions"
            aria-haspopup="menu"
            aria-expanded={showMenu}
            className="grid h-10 w-10 place-items-center rounded-full hover:bg-[#F5F5F5]"
          >
            <MoreVertical className="h-5 w-5 text-[#333]" />
          </button>
          {showMenu && (
            <div
              role="menu"
              className="absolute right-0 top-12 w-44 rounded-md border bg-white py-1 shadow-lg"
              style={{ borderColor: BRAND_BORDER }}
            >
              <button
                type="button"
                role="menuitem"
                onClick={() => {
                  if (window.confirm('Clear all notifications?')) {
                    notificationStore.clear()
                    setItems([])
                  }
                  setShowMenu(false)
                }}
                className="flex w-full items-center gap-2 px-3 py-2 text-sm text-[#E74C3C] hover:bg-[#F5F5F5]"
              >
                <Trash2 className="h-4 w-4" />
                Clear all
              </button>
            </div>
          )}
        </div>
      ) : null,
    [items, isLoading, showMenu],
  )

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader title="Notifications" trailing={trailing} />

      <PageContainer variant="medium" className="pb-10 pt-2">
        {isLoading && (
          <div className="grid place-items-center py-20 text-[#999]">
            Loading…
          </div>
        )}

        {isEmpty && (
          <div className="grid place-items-center px-6 py-20 text-center">
            <Bell className="h-10 w-10 text-[#CCC]" strokeWidth={1.5} />
            <h2 className="mt-3 text-base font-semibold text-[#666]">
              No notifications
            </h2>
            <button
              type="button"
              onClick={load}
              className="mt-5 inline-flex items-center gap-1.5 text-sm font-medium hover:underline"
              style={{ color: BRAND_PRIMARY }}
            >
              <RefreshCcw className="h-3.5 w-3.5" /> Refresh
            </button>
          </div>
        )}

        {!isLoading && !isEmpty && (
          <ul className="grid grid-cols-1 gap-3 md:grid-cols-2">
            <AnimatePresence initial={false}>
              {items!.map((n) => (
                <NotificationCard
                  key={n.id}
                  item={n}
                  onMarkRead={() => setItems(notificationStore.markRead(n.id))}
                  onDelete={() => {
                    notificationStore.remove(n.id)
                    setItems(notificationStore.getAll())
                  }}
                />
              ))}
            </AnimatePresence>
          </ul>
        )}
      </PageContainer>
    </div>
  )
}

function NotificationCard({
  item,
  onMarkRead,
  onDelete,
}: {
  item: NotificationItem
  onMarkRead: () => void
  onDelete: () => void
}) {
  const Icon = iconForType(item.type)
  const color = notificationColor(item.type)

  return (
    <motion.li
      layout
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -16 }}
      transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
      className="rounded-xl border bg-white p-4 transition-shadow hover:shadow-sm"
      style={{
        borderColor: item.isRead ? BRAND_BORDER : BRAND_PRIMARY,
      }}
    >
      <div className="flex items-start gap-3">
        <span
          className="grid h-9 w-9 shrink-0 place-items-center rounded-md"
          style={{ background: `${color}15`, color }}
          aria-hidden="true"
        >
          <Icon className="h-4 w-4" />
        </span>

        <div className="min-w-0 flex-1">
          <div
            className={`text-sm ${item.isRead ? 'font-medium text-[#444]' : 'font-bold text-[#222]'}`}
          >
            {item.title}
          </div>
          <p className="mt-0.5 line-clamp-2 text-sm text-[#666]">{item.body}</p>
          <div className="mt-2 flex items-center justify-between gap-2">
            <span className="text-xs text-[#999]">
              {formatRelative(item.timestamp)}
            </span>
            <div className="flex items-center gap-1">
              {!item.isRead && (
                <button
                  type="button"
                  onClick={onMarkRead}
                  className="rounded px-2 py-1 text-xs font-medium hover:bg-[#F5F5F5]"
                  style={{ color: BRAND_PRIMARY }}
                >
                  Mark as read
                </button>
              )}
              <button
                type="button"
                onClick={onDelete}
                aria-label="Delete notification"
                className="grid h-8 w-8 place-items-center rounded text-[#999] hover:bg-[#F5F5F5] hover:text-[#E74C3C]"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </motion.li>
  )
}
