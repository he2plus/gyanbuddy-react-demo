import { cn } from '../lib/cn'

type Props = {
  initial: string
  color?: string
  size?: 'sm' | 'md' | 'lg' | 'xl'
  className?: string
}

const sizes: Record<NonNullable<Props['size']>, string> = {
  sm: 'h-8 w-8 text-sm',
  md: 'h-10 w-10 text-base',
  lg: 'h-12 w-12 text-lg',
  xl: 'h-20 w-20 text-3xl',
}

export function Avatar({ initial, color = '#8B5CF6', size = 'md', className }: Props) {
  return (
    <div
      className={cn(
        'grid place-items-center rounded-full font-bold text-white shadow-sm',
        sizes[size],
        className,
      )}
      style={{ background: color }}
      aria-hidden="true"
    >
      {initial}
    </div>
  )
}
