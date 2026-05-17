/**
 * TextField — labeled input with optional left icon, error message, and
 * password-visibility toggle. Mirrors the look of the Flutter login fields:
 * filled fill color, rounded, focus ring in brand primary.
 */
import { type InputHTMLAttributes, type ReactNode, forwardRef, useId, useState } from 'react'
import { Eye, EyeOff } from 'lucide-react'
import { cn } from '../lib/cn'

type Props = Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> & {
  label?: string
  leftIcon?: ReactNode
  error?: string
  /** Set to "password" to enable the visibility toggle. */
  type?: InputHTMLAttributes<HTMLInputElement>['type']
}

export const TextField = forwardRef<HTMLInputElement, Props>(function TextField(
  { label, leftIcon, error, type = 'text', className, id, ...rest },
  ref,
) {
  const reactId = useId()
  const inputId = id ?? reactId
  const [revealed, setRevealed] = useState(false)
  const isPassword = type === 'password'
  const effectiveType = isPassword && revealed ? 'text' : type

  return (
    <div className="w-full">
      {label && (
        <label
          htmlFor={inputId}
          className="mb-1.5 block text-sm font-medium text-[var(--color-text-primary)]"
        >
          {label}
        </label>
      )}
      <div
        className={cn(
          'relative flex items-center rounded-[10px] border bg-[var(--color-input-fill)] transition-colors focus-within:border-[var(--color-input-focus)] focus-within:bg-white',
          error
            ? 'border-[var(--color-error)]'
            : 'border-[var(--color-input-border)]',
        )}
      >
        {leftIcon && (
          <span
            className="pointer-events-none absolute left-3 text-[var(--color-text-light)]"
            aria-hidden="true"
          >
            {leftIcon}
          </span>
        )}
        <input
          ref={ref}
          id={inputId}
          type={effectiveType}
          aria-invalid={Boolean(error) || undefined}
          aria-describedby={error ? `${inputId}-error` : undefined}
          className={cn(
            'h-12 w-full rounded-[10px] bg-transparent px-3.5 text-sm text-[var(--color-text-primary)] placeholder-[var(--color-text-light)] outline-none',
            leftIcon && 'pl-10',
            isPassword && 'pr-10',
            className,
          )}
          {...rest}
        />
        {isPassword && (
          <button
            type="button"
            onClick={() => setRevealed((r) => !r)}
            aria-label={revealed ? 'Hide password' : 'Show password'}
            className="absolute right-2 grid h-9 w-9 place-items-center text-[var(--color-text-light)] hover:text-[var(--color-text-secondary)]"
          >
            {revealed ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
          </button>
        )}
      </div>
      {error && (
        <p
          id={`${inputId}-error`}
          className="mt-1.5 text-xs text-[var(--color-error)]"
          role="alert"
        >
          {error}
        </p>
      )}
    </div>
  )
})
