/**
 * Top app bar — minimal Phase 0 placeholder.
 * Tier 2 will add page title from route, back button, and trailing actions.
 */
export function AppBar() {
  return (
    <header
      className="sticky top-0 z-10 flex h-14 items-center justify-between border-b border-[var(--color-input-border)] bg-[var(--color-bg)] px-4"
    >
      <div className="text-base font-semibold text-[var(--color-text-primary)]">
        Gyaan Buddy
      </div>
      {/* trailing slot reserved for notifications bell, profile, etc. */}
      <div aria-hidden="true" />
    </header>
  )
}
