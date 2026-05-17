/**
 * Onboarding completion flag — mirrors lib/services/onboarding_service.dart.
 * Stored locally; the Dart app uses SharedPreferences with the same key shape.
 */
const KEY = 'onboarding_completed'

export const onboardingStore = {
  isComplete(): boolean {
    if (typeof window === 'undefined') return true
    return localStorage.getItem(KEY) === 'true'
  },
  complete() {
    localStorage.setItem(KEY, 'true')
  },
  reset() {
    localStorage.removeItem(KEY)
  },
}
