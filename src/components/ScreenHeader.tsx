/**
 * ScreenHeader — page-owned top bar with optional back button and trailing slot.
 * Used by Credits, Notifications, etc. Replaces the global AppShell AppBar
 * on screens that need their own title and actions.
 */
import { type ReactNode } from 'react'
import { ArrowLeft } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

type Props = {
  title: string
  showBack?: boolean
  /** Override the default `navigate(-1)` behavior. */
  onBack?: () => void
  trailing?: ReactNode
}

export function ScreenHeader({ title, showBack = true, onBack, trailing }: Props) {
  const navigate = useNavigate()
  return (
    <header className="sticky top-0 z-10 flex h-14 items-center bg-white/95 px-4 backdrop-blur">
      {showBack && (
        <button
          type="button"
          onClick={() => (onBack ? onBack() : navigate(-1))}
          aria-label="Go back"
          className="grid h-10 w-10 place-items-center rounded-full text-[var(--color-text-primary)] hover:bg-[var(--color-input-fill)]"
        >
          <ArrowLeft className="h-5 w-5" />
        </button>
      )}
      <h1 className="ml-2 flex-1 text-lg font-bold text-[var(--color-text-primary)]">
        {title}
      </h1>
      {trailing}
    </header>
  )
}
