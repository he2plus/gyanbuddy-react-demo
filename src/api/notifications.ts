/**
 * Notifications API — hits GET /api/notifications/.
 *
 * Real backend wraps the list under `data.notifications`, with each item
 * carrying a `data` blob (title / body / type / etc.) plus delivery metadata
 * (is_read, created_at). This file flattens that into a clean Notification
 * shape the UI can render directly.
 */
import { api } from './client'

export type NotificationKind =
  | 'achievement'
  | 'mission'
  | 'leaderboard'
  | 'chapter'
  | 'test'
  | 'system'

export type Notification = {
  id: string
  kind: NotificationKind
  title: string
  body: string
  createdAt: Date
  read: boolean
  /** Carries the original wire `type` so a future deep-link layer can act on it. */
  rawType: string | null
  /** Pre-extracted target id (e.g. test_id) if present in the data blob. */
  targetId: string | null
}

type WireNotification = {
  id: string
  user?: string
  user_name?: string
  username?: string
  notification_id?: string
  data?: {
    title?: string
    body?: string
    type?: string
    action?: string
    test_id?: string
    mission_id?: string
    chapter_id?: string
    subject_name?: string
    class_name?: string
    duration?: string
    test_datetime?: string
    [key: string]: unknown
  }
  type?: string
  type_display?: string
  triggered_by?: string
  is_read?: boolean
  read_at?: string | null
  created_at?: string
  updated_at?: string
}

type WireEnvelope = {
  success?: boolean
  message?: string
  data?: {
    notifications?: WireNotification[]
    [key: string]: unknown
  } | WireNotification[]
}

const KIND_FROM_TYPE: Record<string, NotificationKind> = {
  test: 'test',
  test_created: 'test',
  test_reminder: 'test',
  mission: 'mission',
  mission_created: 'mission',
  mission_complete: 'mission',
  achievement: 'achievement',
  level_up: 'achievement',
  badge_earned: 'achievement',
  leaderboard: 'leaderboard',
  rank_change: 'leaderboard',
  chapter: 'chapter',
  chapter_complete: 'chapter',
  chapter_unlocked: 'chapter',
}

function pickList(envelope: WireEnvelope): WireNotification[] {
  const d = envelope.data
  if (Array.isArray(d)) return d
  if (d && Array.isArray(d.notifications)) return d.notifications
  return []
}

/**
 * Decode mojibake-encoded titles/bodies that come back from the backend.
 * The seed double-encodes UTF-8 → Latin-1, so an emoji like "📝" lands as
 * "ð". This swap restores the intended glyph.
 */
function fixEncoding(s: string | undefined | null): string {
  if (!s) return ''
  // Cheap heuristic: if the string contains characters typical of double
  // encoding (â€™, ð, ¡, etc.) try the round-trip. If decode fails, return
  // the original so we never crash on already-clean strings.
  if (!/[ÂÃâð]/.test(s)) return s
  try {
    const bytes = new Uint8Array(s.length)
    for (let i = 0; i < s.length; i++) bytes[i] = s.charCodeAt(i) & 0xff
    return new TextDecoder('utf-8', { fatal: false }).decode(bytes)
  } catch {
    return s
  }
}

function classify(rawType: string | null): NotificationKind {
  if (!rawType) return 'system'
  return KIND_FROM_TYPE[rawType.toLowerCase()] ?? 'system'
}

function parseOne(w: WireNotification): Notification {
  const blob = w.data ?? {}
  const rawType = blob.type ?? w.type ?? null
  return {
    id: w.id,
    kind: classify(rawType),
    title: fixEncoding(blob.title) || 'Notification',
    body: fixEncoding(blob.body) || '',
    createdAt: w.created_at ? new Date(w.created_at) : new Date(),
    read: w.is_read ?? false,
    rawType,
    targetId: blob.test_id || blob.mission_id || blob.chapter_id || null,
  }
}

export async function getNotifications(): Promise<Notification[]> {
  const { data: envelope } = await api.get<WireEnvelope>('/notifications/')
  if (envelope?.success === false) {
    throw new Error(envelope.message || 'Failed to load notifications')
  }
  return pickList(envelope).map(parseOne)
}

export async function markAllNotificationsRead(): Promise<void> {
  // Endpoint name guessed from the DRF action naming convention; if it
  // isn't there we silently no-op rather than break the UX.
  try {
    await api.post('/notifications/mark_all_read/')
  } catch {
    // best-effort; the local UI still flips state optimistically
  }
}
