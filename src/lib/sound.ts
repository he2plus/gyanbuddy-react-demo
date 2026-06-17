/**
 * Tiny sound helper — mirrors the Flutter app's SoundService for the events
 * that matter on web. Uses the original audio files (copied to /sounds). Each
 * play uses a fresh Audio element so rapid repeats overlap cleanly. Failures
 * (autoplay policy before first interaction) are swallowed.
 */
const FILES = {
  correct: '/sounds/correct_answer.mp3',
  incorrect: '/sounds/incorrect_answer.mp3',
  select: '/sounds/answer-select.ogg',
  click: '/sounds/button_click.mp3',
  success: '/sounds/success.mp3',
  hint: '/sounds/hint-usage.ogg',
  whoosh: '/sounds/question-whoosh.ogg',
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
