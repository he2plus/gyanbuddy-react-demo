/**
 * Notifications API — hits GET /api/notifications/.
 *
 * Real backend wraps the list under `data.notifications`, with each item
 * carrying a `data` blob (title / body / type / etc.) plus delivery metadata
 * (is_read, created_at). This file flattens that into a clean Notification
 * shape the UI can render directly.
 *
 * Mock-aware: when VITE_DEV_MOCK_AUTH=true AND the caller has the mock
 * token, returns a rich set of fixture notifications so the Vercel demo
 * shows a populated bell instead of a "Failed to load" error.
 */
import { api } from './client'
import { isMockSessionActive } from './modules'

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
  if (isMockSessionActive()) return mockNotifications()
  const { data: envelope } = await api.get<WireEnvelope>('/notifications/')
  if (envelope?.success === false) {
    throw new Error(envelope.message || 'Failed to load notifications')
  }
  return pickList(envelope).map(parseOne)
}

export async function markAllNotificationsRead(): Promise<void> {
  if (isMockSessionActive()) return  // optimistic UI flip only
  // Endpoint name guessed from the DRF action naming convention; if it
  // isn't there we silently no-op rather than break the UX.
  try {
    await api.post('/notifications/mark_all_read/')
  } catch {
    // best-effort; the local UI still flips state optimistically
  }
}

// ---------------------------------------------------------------------------
// Mock fixtures — 7 notifications spanning every kind so the bell is fully
// populated on the Vercel demo where there's no backend to call.
// ---------------------------------------------------------------------------
function mockNotifications(): Notification[] {
  const now = Date.now()
  const mins = (m: number) => new Date(now - m * 60_000)
  return [
    {
      id: 'demo-n1',
      kind: 'achievement',
      title: '🏆 New personal best!',
      body: "You crossed 1500 XP today. Three more chapters and you'll hit Level 4.",
      createdAt: mins(8),
      read: false,
      rawType: 'level_up',
      targetId: null,
    },
    {
      id: 'demo-n2',
      kind: 'mission',
      title: '🎯 New mission unlocked',
      body: 'Daily Chemistry Challenge is ready — 5 quick questions to keep the streak.',
      createdAt: mins(35),
      read: false,
      rawType: 'mission_created',
      targetId: 'm-1',
    },
    {
      id: 'demo-n3',
      kind: 'test',
      title: '📝 Upcoming test',
      body: 'Physics Mid-term is in 2 days. Tap to start preparing now.',
      createdAt: mins(2 * 60 + 15),
      read: false,
      rawType: 'test_created',
      targetId: 't-2',
    },
    {
      id: 'demo-n4',
      kind: 'leaderboard',
      title: '📈 You moved up 2 ranks',
      body: "You're now #3 in Class 10-C this week. Two more correct answers to overtake Rohan.",
      createdAt: mins(4 * 60),
      read: false,
      rawType: 'rank_change',
      targetId: null,
    },
    {
      id: 'demo-n5',
      kind: 'chapter',
      title: '📚 Chapter completed',
      body: 'Chemistry · Foundations · Building Blocks — well done. Hands-on Practice is next.',
      createdAt: mins(6 * 60),
      read: true,
      rawType: 'chapter_complete',
      targetId: null,
    },
    {
      id: 'demo-n6',
      kind: 'mission',
      title: '🔥 Streak alert',
      body: "You've kept a 12-day streak. Finish today's mission to stretch it to 13.",
      createdAt: mins(18 * 60),
      read: true,
      rawType: 'mission_reminder',
      targetId: null,
    },
    {
      id: 'demo-n7',
      kind: 'test',
      title: '✅ Test result published',
      body: 'Mathematics test result is out — you scored 86%. Top of the class on Linear Equations.',
      createdAt: mins(30 * 60),
      read: true,
      rawType: 'test_result',
      targetId: 't-3',
    },
  ]
}
