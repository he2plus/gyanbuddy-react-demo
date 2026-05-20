/**
 * ChapterCompletedSplash — fullscreen celebratory interstitial shown when
 * the LAST chapter of a module is completed (docx #13 last bullet).
 *
 * Renders a confetti-ish particle burst, a giant trophy + check, the chapter
 * name, and a Continue button that returns to the journey.
 */
import { useEffect, useMemo } from 'react'
import { motion } from 'framer-motion'
import { Trophy, ArrowRight, Sparkles, Check } from 'lucide-react'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'

export function ChapterCompletedSplash({
  moduleName, chapterName, xpEarned, onContinue,
}: {
  moduleName: string
  chapterName: string
  xpEarned: number
  onContinue: () => void
}) {
  // Pre-compute confetti positions so they don't re-randomize on re-render.
  const confetti = useMemo(() => {
    const items: Array<{ x: number; delay: number; color: string; rot: number }> = []
    const colors = [CYAN, NAVY, '#22C55E', '#F59E0B', '#7C3AED', '#FF3131']
    for (let i = 0; i < 60; i++) {
      items.push({
        x: Math.random() * 100,
        delay: Math.random() * 0.6,
        color: colors[i % colors.length],
        rot: Math.random() * 360,
      })
    }
    return items
  }, [])

  // Disable body scroll while open.
  useEffect(() => {
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => { document.body.style.overflow = prev }
  }, [])

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="fixed inset-0 z-[60] flex items-center justify-center"
      style={{
        background: `radial-gradient(circle at 50% 35%, rgba(0,22,122,0.95) 0%, rgba(0,10,74,0.98) 70%)`,
        color: '#fff',
      }}
    >
      {/* Confetti rain */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        {confetti.map((c, i) => (
          <motion.span
            key={i}
            className="absolute"
            style={{
              left: `${c.x}%`,
              top: -20,
              width: 10, height: 14, borderRadius: 2,
              background: c.color,
              transformOrigin: 'center',
            }}
            initial={{ y: -40, opacity: 0, rotate: c.rot }}
            animate={{
              y: ['-40px', '110vh'],
              opacity: [0, 1, 1, 0],
              rotate: c.rot + 720,
            }}
            transition={{
              duration: 3 + (i % 5) * 0.3,
              delay: c.delay,
              ease: 'easeIn',
              repeat: Infinity,
              repeatDelay: 1.5,
            }}
          />
        ))}
      </div>

      {/* Center card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.86, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ type: 'spring', stiffness: 240, damping: 18 }}
        className="relative flex flex-col items-center text-center"
        style={{ padding: 48, maxWidth: 560 }}
      >
        {/* Big trophy */}
        <motion.div
          className="grid place-items-center relative"
          style={{
            width: 160, height: 160, borderRadius: 999,
            background: `radial-gradient(circle at 32% 28%, #FCD34D 0%, #F59E0B 60%, #B45309 100%)`,
            boxShadow: '0 24px 50px rgba(245,158,11,0.5), inset 0 -10px 20px rgba(0,0,0,0.15)',
          }}
          animate={{ y: [0, -10, 0], rotate: [0, 5, 0, -5, 0] }}
          transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
        >
          <Trophy className="w-24 h-24" style={{ color: '#fff' }} strokeWidth={2} fill="#fff" />
          <motion.span
            className="absolute"
            style={{
              top: -6, right: -6, width: 36, height: 36, borderRadius: 999,
              background: '#22C55E', display: 'grid', placeItems: 'center',
              border: '3px solid #fff',
            }}
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.3, type: 'spring', stiffness: 300, damping: 14 }}
          >
            <Check className="w-5 h-5" style={{ color: '#fff' }} strokeWidth={3} />
          </motion.span>
        </motion.div>

        {/* Eyebrow */}
        <motion.div
          initial={{ opacity: 0, y: 6 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.15, duration: 0.4 }}
          className="font-body"
          style={{
            marginTop: 28, fontSize: 14, fontWeight: 700,
            color: CYAN, letterSpacing: '0.12em', textTransform: 'uppercase',
          }}
        >
          Chapter Complete
        </motion.div>

        {/* Big title */}
        <motion.h1
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2, duration: 0.4 }}
          className="font-body"
          style={{
            marginTop: 10, fontSize: 44, fontWeight: 800,
            color: '#fff', lineHeight: '52px', margin: 0,
            letterSpacing: '-0.5px',
          }}
        >
          {chapterName}
        </motion.h1>

        <motion.div
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.25, duration: 0.4 }}
          className="font-body"
          style={{
            marginTop: 8, fontSize: 18, fontWeight: 500,
            color: 'rgba(255,255,255,0.7)', lineHeight: '26px',
          }}
        >
          You finished {moduleName}!
        </motion.div>

        {/* XP badge */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.4, type: 'spring', stiffness: 200, damping: 14 }}
          className="flex items-center"
          style={{
            marginTop: 24, padding: '14px 24px', borderRadius: 999,
            background: 'rgba(255,255,255,0.15)',
            border: '1px solid rgba(255,255,255,0.3)',
            backdropFilter: 'blur(8px)',
            gap: 10,
          }}
        >
          <Sparkles className="w-5 h-5" style={{ color: '#FCD34D' }} strokeWidth={2.5} />
          <span
            style={{
              fontFamily: 'var(--font-numeric)',
              fontSize: 24, fontWeight: 900, color: '#fff', lineHeight: 1,
            }}
          >
            +{xpEarned} XP earned
          </span>
        </motion.div>

        {/* Continue */}
        <motion.button
          type="button"
          onClick={onContinue}
          whileHover={{ y: -2 }}
          whileTap={{ scale: 0.96 }}
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5, duration: 0.4 }}
          className="grid place-items-center font-body"
          style={{
            marginTop: 32, padding: '16px 36px', height: 60,
            borderRadius: 999, background: '#fff', color: NAVY,
            fontSize: 18, fontWeight: 700, gap: 12,
            boxShadow: '0 12px 32px rgba(255,255,255,0.2)',
          }}
        >
          <span className="flex items-center" style={{ gap: 12 }}>
            Continue
            <ArrowRight className="w-5 h-5" strokeWidth={2.5} />
          </span>
        </motion.button>
      </motion.div>

      {/* Suppress unused */}
      {/* @ts-ignore */}
      {false && (TXT_DARK + TXT_MID)}
    </motion.div>
  )
}
