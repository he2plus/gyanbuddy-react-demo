/**
 * Button — primary / secondary / ghost.
 * Colors come from the design tokens (lib/theme/app_theme.dart).
 */
import { type ButtonHTMLAttributes, forwardRef } from 'react'
import { cn } from '../lib/cn'

type Variant = 'primary' | 'secondary' | 'ghost'

type Props = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: Variant
  loading?: boolean
  fullWidth?: boolean
}

const base =
  'inline-flex items-center justify-center gap-2 rounded-[var(--radius-base)] text-base font-semibold transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] focus-visible:ring-offset-2 disabled:cursor-not-allowed'

const variants: Record<Variant, string> = {
  primary:
    'bg-[var(--color-button)] text-[var(--color-button-text)] shadow-md shadow-[color:var(--color-primary)]/20 hover:bg-[var(--color-primary-dark)] active:scale-[0.98] disabled:bg-[var(--color-button-disabled)] disabled:text-[var(--color-text-light)] disabled:shadow-none',
  secondary:
    'border border-[var(--color-input-border)] bg-white text-[var(--color-text-primary)] hover:bg-[var(--color-input-fill)] disabled:bg-[var(--color-input-fill)] disabled:text-[var(--color-text-light)]',
  ghost:
    'text-[var(--color-primary)] hover:bg-[var(--color-primary)]/10 disabled:text-[var(--color-text-light)]',
}

export const Button = forwardRef<HTMLButtonElement, Props>(function Button(
  {
    variant = 'primary',
    loading = false,
    fullWidth = false,
    disabled,
    className,
    children,
    type = 'button',
    ...rest
  },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      className={cn(
        base,
        variants[variant],
        'h-12 px-5',
        fullWidth && 'w-full',
        className,
      )}
      {...rest}
    >
      {loading ? (
        <Spinner />
      ) : (
        children
      )}
    </button>
  )
})

function Spinner() {
  return (
    <svg
      className="h-5 w-5 animate-spin"
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <circle
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="3"
        strokeOpacity="0.25"
      />
      <path
        d="M22 12a10 10 0 0 1-10 10"
        stroke="currentColor"
        strokeWidth="3"
        strokeLinecap="round"
      />
    </svg>
  )
}
