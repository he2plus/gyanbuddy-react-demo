/**
 * Shared placeholder shown by every Phase 0 route until its real screen lands.
 * Lets us verify routing, breakpoints, and shell behavior without committing
 * to any screen UI yet.
 */
type Props = {
  title: string
  source?: string // Flutter source path this screen will mirror
}

export function PlaceholderPage({ title, source }: Props) {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-2 px-4 text-center">
      <div className="text-xs font-medium uppercase tracking-widest text-[var(--color-text-light)]">
        Phase 0 placeholder
      </div>
      <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
        {title}
      </h1>
      {source && (
        <p className="text-sm text-[var(--color-text-secondary)]">
          Will mirror{' '}
          <code className="rounded bg-[var(--color-input-fill)] px-1.5 py-0.5 text-xs">
            {source}
          </code>
        </p>
      )}
    </div>
  )
}
