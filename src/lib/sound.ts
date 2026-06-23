/**
 * Tiny sound helper — mirrors the Flutter app's SoundService for the events
 * that matter on web. Uses the original audio files (copied to /sounds). Each
 * play uses a fresh Audio element so rapid repeats overlap cleanly. Failures
 * (autoplay policy before first interaction) are swallowed.
 */
// Safari does not support OGG. MP3 is universally supported.
// OGG files exist in /sounds/ for future use but we use MP3 fallbacks here.
const FILES = {
  correct: '/sounds/correct_answer.mp3',
  incorrect: '/sounds/incorrect_answer.mp3',
  select: '/sounds/button_click.mp3',   // answer-select.ogg — no MP3 variant; use click
  click: '/sounds/button_click.mp3',
  success: '/sounds/success.mp3',
  hint: '/sounds/button_click.mp3',     // hint-usage.ogg — no MP3 variant; use click
  whoosh: '/sounds/button_click.mp3',   // question-whoosh.ogg — no MP3 variant; use click
} as const

export type SoundName = keyof typeof FILES

let enabled = true
export function setSoundEnabled(on: boolean) {
  enabled = on
}

export function playSound(name: SoundName, volume = 0.6) {
  if (!enabled || typeof Audio === 'undefined') return
  try {
    const a = new Audio(FILES[name])
    a.volume = volume
    void a.play().catch(() => {})
  } catch {
    /* ignore */
  }
}
