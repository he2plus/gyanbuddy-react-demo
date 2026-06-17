/**
 * Responsive shell. Sidebar width depends on the persisted collapsed state
 * from useUIStore.
 */
import { useEffect, useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'

import { BottomTabs } from './BottomTabs'
import { SideNav } from './SideNav'
import { useUIStore } from '../state/ui'

// Pages with their own Figma-faithful top bar render the chrome themselves;
// the persistent SideNav would steal width and break pixel-exact layouts.
// Exact paths or prefix patterns (anything starting with these) are hidden.
const HIDE_CHROME_EXACT = new Set([
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/onboarding',
  '/confirmation',
  '/home',
  '/subjects',
  '/missions',
  '/leaderboard',
  '/podium',
  '/tests',
  '/notifications',
  '/profile',
  '/credits',
])
// Anything under these prefixes also runs chrome-less (Journey page, etc.)
const HIDE_CHROME_PREFIX = ['/subjects/', '/missions/', '/tests/', '/profile/']

function isChromeless(path: string): boolean {
  if (HIDE_CHROME_EXACT.has(path)) return true
  return HIDE_CHROME_PREFIX.some((p) => path.startsWith(p))
}

// ---------------------------------------------------------------------------
// Viewport-fit scaling.
//
// The whole UI was ported pixel-for-pixel from a 1920px-wide Figma frame, so
// every font/size/gap is an absolute px value tuned for that canvas. On a
// smaller laptop the design therefore renders at its FIXED size and feels
// oversized — it doesn't scale to the screen, it just overflows.
//
// Rather than re-tune hundreds of inline px values page by page, we scale the
// entire app uniformly with `zoom`, proportional to how much narrower the
// viewport is than the design canvas. `zoom` (unlike transform: scale) also
// shrinks the layout box, so a 1920 design at 0.8 genuinely occupies 1536px
// and fits — no leftover whitespace, no horizontal scroll.
//
// IMPORTANT: apply `zoom` ALONE. An earlier version also inflated the box with
// `width: 100/scale%` + `maxWidth: 1920/scale` to "refill" the viewport, on the
// assumption that zoom shrinks paint but leaves the layout box at viewport
// width. Current Chrome's `zoom` already shrinks the layout box *and* the box
// keeps filling its container, so that inflation double-applied: the shell grew
// to 1920px on a 1440px viewport, overflowed to the right, and shoved every
// centered (chromeless) page off-center. Just zoom; let `w-full max-w-[1680px]`
// size and center the box.
//
// Scaling is proportional to the viewport so the design fills the screen at
// EVERY desktop size, not just shrinks:
//   - 1024-1920px (laptop): scale 0.66-1.0, the 1920 canvas shrinks to fit.
//   - exactly 1920px: scale 1.0 (native).
//   - >1920px (large desktop / TV): scale UP so the canvas fills the monitor
//     instead of sitting at 1920 in a sea of whitespace. Capped at MAX_SCALE so
//     a 4K panel doesn't blow the type up absurdly.
// Phones & tablets (<1024px) keep zoom 1 and use the fluid flex + clamp() layout,
// which already stacks/reflows natively (verified iPhone & iPad widths).
// Treat 1680 as the reference width (not the raw 1920 canvas): the layouts are
// responsive enough to fit 1680, and basing the scale here means a 1512 laptop
// renders at ~0.9 instead of ~0.79 — noticeably larger, more legible type — and
// wide monitors fill sooner. Page containers are capped to 1680 to match.
const DESIGN_WIDTH = 1680
const MIN_SCALE = 0.7     // never shrink below this (keeps tiny laptops legible)
const MAX_SCALE = 1.5     // fill large monitors/TVs; cap so 4K type isn't huge

function computeFitScale(width: number): number {
  if (width < 1024) return 1
  const raw = width / DESIGN_WIDTH
  return Math.min(MAX_SCALE, Math.max(MIN_SCALE, raw))
}

function useFitScale(): number {
  const [scale, setScale] = useState(() =>
    typeof window === 'undefined' ? 1 : computeFitScale(window.innerWidth),
  )
  useEffect(() => {
    let frame = 0
    const onResize = () => {
      cancelAnimationFrame(frame)
      frame = requestAnimationFrame(() => setScale(computeFitScale(window.innerWidth)))
    }
    window.addEventListener('resize', onResize)
    onResize()
    return () => {
      cancelAnimationFrame(frame)
      window.removeEventListener('resize', onResize)
    }
  }, [])
  return scale
}

export function AppShell() {
  const { pathname } = useLocation()
  const showChrome = !isChromeless(pathname)
  const collapsed = useUIStore((s) => s.sidenavCollapsed)
  const fitScale = useFitScale()

  const sidebarWidth = collapsed ? 64 : 240

  return (
    <div className="min-h-screen w-full overflow-x-hidden bg-white">
      {/* `zoom` scales the whole app to fit the viewport (see useFitScale).
          Apply zoom only — `w-full max-w-[1680px] mx-auto` already sizes and
          centers the box. Inflating width here overflows and breaks centering.
          `--fit-scale` lets full-height (`min-h-screen`) pages counter-scale
          `vh` so they still reach the viewport bottom (see globals.css). */}
      <div
        className="mx-auto flex w-full max-w-[1680px]"
        style={
          fitScale !== 1
            ? ({ zoom: fitScale, '--fit-scale': fitScale } as React.CSSProperties)
            : undefined
        }
      >
        {showChrome && (
          <aside
            className="hidden shrink-0 transition-[width] duration-200 ease-out lg:block"
            style={{ width: sidebarWidth }}
          >
            <SideNav />
          </aside>
        )}

        <main className="relative min-h-screen min-w-0 flex-1">
          <Outlet />

          {showChrome && (
            <div className="lg:hidden">
              <BottomTabs />
            </div>
          )}
        </main>
      </div>
    </div>
  )
}
