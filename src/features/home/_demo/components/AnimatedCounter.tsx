import { useEffect, useState } from 'react'

type Props = {
  value: number
  duration?: number
  className?: string
}

export function AnimatedCounter({ value, duration = 900, className }: Props) {
  const [displayed, setDisplayed] = useState(0)

  useEffect(() => {
    const start = performance.now()
    let raf = 0
    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / duration)
      const eased = 1 - Math.pow(1 - t, 3)
      setDisplayed(Math.round(value * eased))
      if (t < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [value, duration])

  return <span className={className}>{displayed.toLocaleString()}</span>
}
