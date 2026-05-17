/**
 * Card — surface container with the standard 12px radius and soft shadow.
 * Optional accented title header (used by Credits screen).
 */
import { type HTMLAttributes, type ReactNode } from 'react'
import { cn } from '../lib/cn'

type Props = HTMLAttributes<HTMLDivElement> & {
  title?: string
  /** Header background tint and title color */
  accent?: 'green' | 'blue' | 'neutral'
  children: ReactNode
}

const accents = {
  green: { bg: 'bg-emerald-50', text: 'text-emerald-700' },
  blue: { bg: 'bg-blue-50', text: 'text-[var(--color-primary)]' },
  neutral: { bg: 'bg-[var(--color-input-fill)]', text: 'text-[var(--color-text-primary)]' },
} as const

export function Card({ title, accent = 'neutral', className, children, ...rest }: Props) {
  const a = accents[accent]
  return (
    <section
      className={cn(
        'overflow-hidden rounded-[var(--radius-base)] border border-[var(--color-input-border)] bg-white shadow-sm',
        className,
      )}
      {...rest}
    >
      {title && (
        <header className={cn('px-5 py-4 text-base font-bold', a.bg, a.text)}>
          {title}
        </header>
      )}
      {children}
    </section>
  )
}
