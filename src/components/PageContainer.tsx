/**
 * PageContainer — common page-width wrapper. Sizes chosen so the app feels
 * good from a 320 px phone up to a 4K TV without ever locking content into a
 * tiny center column.
 *
 * Variants:
 *   narrow  → max-w-2xl   (forms, single-column reads: edit pages, recovery)
 *   medium  → max-w-5xl   (lists, leaderboard, quizzes)
 *   wide    → max-w-[1760px]  (the home composition, journey, subject grid)
 *   fluid   → no cap     (full-bleed pages like Onboarding, Confirmation)
 *
 * Padding scales with breakpoint so phones aren't cramped and big monitors
 * don't feel empty against the edges.
 */
import { type HTMLAttributes, type ReactNode } from 'react'
import { cn } from '../lib/cn'

type Variant = 'narrow' | 'medium' | 'wide' | 'fluid'

const variants: Record<Variant, string> = {
  narrow: 'max-w-2xl',
  medium: 'max-w-5xl',
  wide: 'max-w-[1760px]',
  fluid: 'max-w-none',
}

type Props = HTMLAttributes<HTMLDivElement> & {
  variant?: Variant
  children: ReactNode
}

export function PageContainer({
  variant = 'medium',
  className,
  children,
  ...rest
}: Props) {
  return (
    <div
      className={cn(
        'mx-auto w-full px-4 sm:px-6 lg:px-8 xl:px-10 2xl:px-12',
        variants[variant],
        className,
      )}
      {...rest}
    >
      {children}
    </div>
  )
}
