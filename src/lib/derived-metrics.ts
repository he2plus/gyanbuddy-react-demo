/**
 * derived-metrics — client-side fillers for fields the backend hasn't shipped
 * yet (streak, weekly XP delta, today's goal percentage, test score).
 *
 * Every value is a deterministic function of the user id, so the same user
 * sees the same number across page navigations / reloads — no random
 * flickering. When the backend ships the real fields we delete this whole
 * module and read from the response shape.
 */

/** Tiny string hash — stable, 32-bit, sufficient for "give me a number". */
function hash(s: string): number {
  let h = 0
  for (let i = 0; i < s.length; i++) {
    h = (h << 5) - h + s.charCodeAt(i)
    h |= 0
  }
  return Math.abs(h)
}

/** A "days streak" between 1 and 28 (deterministic per user). */
export function deriveStreak(userId: string): number {
  return (hash(userId + ':streak') % 28) + 1
}

/**
 * Weekly XP delta. ~60% of users went up, ~25% went down, ~15% stayed flat.
 * Magnitudes feel realistic for the seed data range (highest user ~1300 XP).
 */
export function deriveWeeklyDelta(userId: string): number {
  const h = hash(userId + ':week')
  const bucket = h % 100
  if (bucket < 60) {
    // up: +5 to +180
    return ((h >> 4) % 175) + 5
  }
  if (bucket < 85) {
    // down: −1 to −25
    return -(((h >> 4) % 25) + 1)
  }
  return 0
}

/**
 * Day-streak for the CURRENT user — the same number we show on the home
 * "Day Streak!" metric tile. Uses the streak derivation.
 */
export function deriveDayStreak(userId: string): number {
  return deriveStreak(userId)
}

/**
 * Today's goal — a percentage 0..100 of the user's level progress.
 * If the level math is available we use it; otherwise a stable hash value.
 */
export function deriveTodayGoal(opts: {
  userId: string
  totalExp: number
  level: { minExp: number; maxExp: number } | null
}): number {
  const { userId, totalExp, level } = opts
  if (level && level.maxExp > level.minExp) {
    const inLevel = Math.max(0, totalExp - level.minExp)
    const range = level.maxExp - level.minExp
    return Math.min(100, Math.round((inLevel / range) * 100))
  }
  return hash(userId + ':goal') % 80 + 10  // 10..89
}

/**
 * Average test score — derived from XP + a per-user salt so it varies.
 * Returns 0..100.
 */
export function deriveTestScore(opts: { userId: string; totalExp: number }): number {
  // Higher XP nudges the score up, but a per-user salt keeps it non-trivial.
  const base = 55 + (hash(opts.userId + ':test') % 35)  // 55..89
  const xpBoost = Math.min(10, Math.floor(opts.totalExp / 500))
  return Math.min(99, base + xpBoost)
}

/** Formats a delta the way the Figma row label reads. */
export function formatDelta(delta: number): {
  text: string
  tone: 'up' | 'down' | 'flat'
} {
  if (delta > 0) return { text: `+${delta} this week`, tone: 'up' }
  if (delta < 0) return { text: `${delta} this week`,  tone: 'down' }
  return { text: 'No change', tone: 'flat' }
}
