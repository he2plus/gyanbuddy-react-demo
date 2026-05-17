/**
 * NotificationItem — mirrors lib/models/notification_item.dart structure.
 * Stored locally (NOT fetched from backend in the Flutter app either —
 * NotificationService persists to SharedPreferences).
 */
export type NotificationType = 'quiz' | 'achievement' | 'reminder' | 'update' | 'general'

export type NotificationItem = {
  id: string
  title: string
  body: string
  type: NotificationType
  /** ISO timestamp */
  timestamp: string
  isRead: boolean
  data?: Record<string, unknown>
}
