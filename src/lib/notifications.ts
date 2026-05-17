/**
 * Local notification storage — mirrors NotificationService persistence.
 * Flutter app uses SharedPreferences; web uses localStorage with the same
 * shape so a future native ↔ web sync can converge if needed.
 */
import type { NotificationItem, NotificationType } from '../types/notification'

const KEY = 'stored_notifications'

function readRaw(): NotificationItem[] {
  if (typeof window === 'undefined') return []
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw) as unknown
    if (!Array.isArray(parsed)) return []
    return parsed.filter(
      (n): n is NotificationItem =>
        !!n &&
        typeof n === 'object' &&
        typeof (n as NotificationItem).id === 'string',
    )
  } catch {
    return []
  }
}

function writeRaw(items: NotificationItem[]) {
  localStorage.setItem(KEY, JSON.stringify(items))
}

export const notificationStore = {
  getAll(): NotificationItem[] {
    return readRaw().sort(
      (a, b) =>
        new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
    )
  },
  markRead(id: string) {
    const items = readRaw().map((n) => (n.id === id ? { ...n, isRead: true } : n))
    writeRaw(items)
    return items
  },
  remove(id: string) {
    writeRaw(readRaw().filter((n) => n.id !== id))
  },
  clear() {
    writeRaw([])
  },
  /** Used during Tier 5 FCM wiring + for dev seeding. */
  add(input: Omit<NotificationItem, 'id' | 'timestamp' | 'isRead'> & {
    id?: string
    timestamp?: string
    isRead?: boolean
  }) {
    const item: NotificationItem = {
      id: input.id ?? crypto.randomUUID(),
      title: input.title,
      body: input.body,
      type: input.type,
      timestamp: input.timestamp ?? new Date().toISOString(),
      isRead: input.isRead ?? false,
      data: input.data,
    }
    writeRaw([item, ...readRaw()])
    return item
  },
}

/** Color + icon mapping for the notification UI, mirroring Dart switch. */
export function notificationColor(type: NotificationType): string {
  switch (type) {
    case 'quiz':
      return '#10b981' // green
    case 'achievement':
      return '#f59e0b' // orange
    case 'reminder':
      return '#4A90E2' // blue (matches Dart _baseColor)
    case 'update':
      return '#a855f7' // purple
    default:
      return '#6b7280' // gray
  }
}

export function formatRelative(ts: string): string {
  const then = new Date(ts).getTime()
  if (Number.isNaN(then)) return ''
  const diffMs = Date.now() - then
  const minutes = Math.floor(diffMs / 60_000)
  if (minutes < 1) return 'Just now'
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  return `${days}d ago`
}
