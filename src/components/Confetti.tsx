/**
 * Confetti — faithful port of the Flutter app's ConfettiCelebration
 * (lib/widgets/confetti_celebration.dart). 50 particles explode from the
 * centre with gravity, fade and rotation; four shapes; the original's nine
 * celebration colours. Renders to a fixed, full-viewport, pointer-events-none
 * canvas and plays once whenever `play` flips true.
 */
import { useEffect, useRef } from 'react'

const COLORS = [
  '#26de81', '#fd79a8', '#fdcb6e', '#74b9ff', '#a29bfe',
  '#ff7675', '#55efc4', '#ffeaa7', '#e17055',
]
type Shape = 'circle' | 'square' | 'star' | 'triangle'
const SHAPES: Shape[] = ['circle', 'square', 'star', 'triangle']

type Particle = {
  color: string
  angle: number
  speed: number
  size: number
  rotationSpeed: number
  shape: Shape
}

const DURATION = 1500
const PARTICLE_COUNT = 50

function drawStar(ctx: CanvasRenderingContext2D, size: number) {
  const half = size / 2
  ctx.beginPath()
  for (let i = 0; i < 5; i++) {
    const a = (i * 4 * Math.PI) / 5 - Math.PI / 2
    const x = Math.cos(a) * half
    const y = Math.sin(a) * half
    if (i === 0) ctx.moveTo(x, y)
    else ctx.lineTo(x, y)
  }
  ctx.closePath()
  ctx.fill()
}

function drawTriangle(ctx: CanvasRenderingContext2D, size: number) {
  const half = size / 2
  ctx.beginPath()
  ctx.moveTo(0, -half)
  ctx.lineTo(-half, half)
  ctx.lineTo(half, half)
  ctx.closePath()
  ctx.fill()
}

export function Confetti({ play }: { play: boolean }) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const rafRef = useRef<number>(0)
  const startedRef = useRef(false)

  useEffect(() => {
    // Wipe the canvas whenever the effect tears down or play is off, so a frame
    // left mid-flight (e.g. the student taps Next before the 1500ms is up) can
    // never freeze on screen.
    const wipe = () => {
      const c = canvasRef.current
      const cx = c?.getContext('2d')
      if (c && cx) cx.clearRect(0, 0, c.width, c.height)
    }
    if (!play) {
      startedRef.current = false
      wipe()
      return
    }
    if (startedRef.current) return
    startedRef.current = true

    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const dpr = window.devicePixelRatio || 1
    const w = window.innerWidth
    const h = window.innerHeight
    canvas.width = w * dpr
    canvas.height = h * dpr
    ctx.scale(dpr, dpr)

    const particles: Particle[] = Array.from({ length: PARTICLE_COUNT }, () => ({
      color: COLORS[Math.floor(Math.random() * COLORS.length)],
      angle: Math.random() * 2 * Math.PI,
      speed: 200 + Math.random() * 300,
      size: 6 + Math.random() * 10,
      rotationSpeed: (Math.random() - 0.5) * 10,
      shape: SHAPES[Math.floor(Math.random() * SHAPES.length)],
    }))

    const cx = w / 2
    const cy = h / 2
    const start = performance.now()

    const frame = (now: number) => {
      const progress = Math.min(1, (now - start) / DURATION)
      ctx.clearRect(0, 0, w, h)
      const gravity = 400 * progress * progress
      for (const p of particles) {
        const dx = Math.cos(p.angle) * p.speed * progress
        const dy = Math.sin(p.angle) * p.speed * progress + gravity
        const x = cx + dx
        const y = cy + dy - 100
        if (x < -50 || x > w + 50 || y < -50 || y > h + 50) continue
        const sz = p.size * (1 - progress * 0.3)
        ctx.save()
        ctx.globalAlpha = 1 - progress * 0.7
        ctx.fillStyle = p.color
        ctx.translate(x, y)
        ctx.rotate(p.rotationSpeed * progress * Math.PI)
        switch (p.shape) {
          case 'circle':
            ctx.beginPath(); ctx.arc(0, 0, sz / 2, 0, 2 * Math.PI); ctx.fill(); break
          case 'square':
            ctx.fillRect(-sz / 2, -sz / 2, sz, sz); break
          case 'star':
            drawStar(ctx, sz); break
          case 'triangle':
            drawTriangle(ctx, sz); break
        }
        ctx.restore()
      }
      if (progress < 1) {
        rafRef.current = requestAnimationFrame(frame)
      } else {
        ctx.clearRect(0, 0, w, h)
      }
    }
    rafRef.current = requestAnimationFrame(frame)

    return () => {
      cancelAnimationFrame(rafRef.current)
      wipe()
    }
  }, [play])

  return (
    <canvas
      ref={canvasRef}
      className="pointer-events-none fixed inset-0 z-50"
      style={{ width: '100vw', height: '100vh' }}
      aria-hidden="true"
    />
  )
}
