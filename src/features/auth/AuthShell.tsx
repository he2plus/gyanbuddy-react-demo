/**
 * AuthShell — shared chrome for Login / Register / Forgot / Reset pages.
 * Two-column on lg+ (brand panel on the left, form card on the right),
 * single-column on smaller. Matches the rest of the Figma rebuild's
 * design language: navy primary, cyan accent, Open Sans body.
 */
import { type ReactNode } from 'react'
import { motion } from 'framer-motion'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'

export function AuthShell({
  title, subtitle, children, footer,
}: {
  title: string
  subtitle?: string
  children: ReactNode
  footer?: ReactNode
}) {
  return (
    <div
      className="flex min-h-screen"
      style={{ background: '#FAFAFA' }}
    >
      {/* Brand panel — hidden on small screens */}
      <div
        className="relative overflow-hidden hidden lg:flex flex-col items-start justify-between"
        style={{
          width: '40%', minWidth: 480, padding: 64,
          background: `radial-gradient(circle at 20% 20%, #1F3DB8 0%, ${NAVY} 60%, #000A4A 100%)`,
          color: '#fff',
        }}
      >
        {/* Logo / lockup */}
        <div className="flex items-center" style={{ gap: 16 }}>
          <div
            className="grid place-items-center bg-white shadow-lg"
            style={{ width: 60, height: 60, borderRadius: 14 }}
          >
            <span
              className="font-display"
              style={{ fontSize: 32, fontWeight: 800, color: NAVY, lineHeight: 1 }}
            >
              G
            </span>
          </div>
          <div className="flex flex-col leading-tight">
            <span
              className="font-body"
              style={{ fontSize: 24, fontWeight: 700, color: '#fff' }}
            >
              GyanBuddy
            </span>
            <span
              className="font-body"
              style={{ fontSize: 14, fontWeight: 500, color: 'rgba(255,255,255,0.7)' }}
            >
              A smarter way to learn
            </span>
          </div>
        </div>

        {/* Decorative animated orbs */}
        <div className="pointer-events-none absolute inset-0 overflow-hidden">
          <motion.div
            className="absolute rounded-full"
            style={{
              width: 360, height: 360, right: -120, top: '20%',
              background: 'radial-gradient(circle, rgba(26,188,254,0.30), transparent 70%)',
            }}
            animate={{ y: [0, 18, 0], x: [0, -8, 0] }}
            transition={{ duration: 11, repeat: Infinity, ease: 'easeInOut' }}
          />
          <motion.div
            className="absolute rounded-full"
            style={{
              width: 220, height: 220, left: -60, bottom: '12%',
              background: 'radial-gradient(circle, rgba(124,58,237,0.30), transparent 70%)',
            }}
            animate={{ y: [0, -14, 0], x: [0, 10, 0] }}
            transition={{ duration: 13, repeat: Infinity, ease: 'easeInOut', delay: 1 }}
          />
        </div>

        {/* Tagline */}
        <div className="relative z-10 flex flex-col" style={{ gap: 18, maxWidth: 460 }}>
          <h2
            className="font-body"
            style={{
              fontSize: 38, fontWeight: 800, color: '#fff',
              lineHeight: '50px', letterSpacing: '-0.5px', margin: 0,
            }}
          >
            Master every topic.
            <br />
            On your terms.
          </h2>
          <p
            className="font-body"
            style={{
              fontSize: 16, fontWeight: 500, color: 'rgba(255,255,255,0.8)',
              lineHeight: '24px', margin: 0,
            }}
          >
            Personalised quizzes, daily missions, and a class leaderboard that
            actually motivates. Make studying feel like making progress.
          </p>
        </div>

        {/* Footer credit */}
        <div className="relative z-10 flex flex-col" style={{ gap: 4 }}>
          <span
            className="font-body"
            style={{ fontSize: 12, fontWeight: 500, color: 'rgba(255,255,255,0.5)' }}
          >
            © Gyaan Buddy
          </span>
        </div>
      </div>

      {/* Form panel */}
      <div
        className="flex-1 flex items-center justify-center"
        style={{ padding: '40px 24px' }}
      >
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
          className="bg-white w-full"
          style={{
            maxWidth: 460, padding: 40, borderRadius: 34,
            border: '1px solid #E7E7E7',
            boxShadow: '0 12px 40px rgba(0,0,0,0.06)',
          }}
        >
          {/* Compact G logo for sm screens */}
          <div className="flex lg:hidden items-center" style={{ gap: 12, marginBottom: 24 }}>
            <div
              className="grid place-items-center"
              style={{
                width: 44, height: 44, borderRadius: 12,
                background: NAVY,
              }}
            >
              <span
                className="font-display"
                style={{ fontSize: 22, fontWeight: 800, color: '#fff', lineHeight: 1 }}
              >
                G
              </span>
            </div>
            <span
              className="font-body"
              style={{ fontSize: 18, fontWeight: 700, color: NAVY }}
            >
              GyanBuddy
            </span>
          </div>

          <h1
            className="font-body"
            style={{
              fontSize: 28, fontWeight: 700, color: TXT_DARK,
              lineHeight: '36px', letterSpacing: '-0.3px', margin: 0,
            }}
          >
            {title}
          </h1>
          {subtitle && (
            <p
              className="font-body"
              style={{
                marginTop: 6, fontSize: 16, fontWeight: 400, color: TXT_MID,
                lineHeight: '24px',
              }}
            >
              {subtitle}
            </p>
          )}

          <div style={{ marginTop: 24 }}>{children}</div>

          {footer && (
            <div
              className="font-body"
              style={{
                marginTop: 28, paddingTop: 20, borderTop: '1px solid #F1F1F1',
                fontSize: 14, color: TXT_MID,
              }}
            >
              {footer}
            </div>
          )}
        </motion.div>
      </div>

      {/* Suppress unused exports */}
      {/* @ts-ignore */}
      {false && CYAN}
    </div>
  )
}

export function AuthTextField({
  label, error, ...props
}: React.InputHTMLAttributes<HTMLInputElement> & {
  label: string
  error?: string
}) {
  return (
    <label className="flex flex-col" style={{ gap: 6 }}>
      <span
        className="font-body"
        style={{ fontSize: 13, fontWeight: 700, color: TXT_DARK, letterSpacing: '0.04em', textTransform: 'uppercase' }}
      >
        {label}
      </span>
      <input
        {...props}
        className="font-body"
        style={{
          height: 52, padding: '0 16px', borderRadius: 14,
          border: `1.5px solid ${error ? '#FF3131' : '#E7E7E7'}`,
          background: '#F8FAFC',
          fontSize: 16, color: TXT_DARK,
          outline: 'none',
        }}
        onFocus={(e) => {
          if (!error) {
            e.currentTarget.style.borderColor = NAVY
            e.currentTarget.style.background = '#fff'
          }
        }}
        onBlur={(e) => {
          if (!error) {
            e.currentTarget.style.borderColor = '#E7E7E7'
            e.currentTarget.style.background = '#F8FAFC'
          }
        }}
      />
      {error && (
        <span
          className="font-body"
          style={{ fontSize: 13, fontWeight: 500, color: '#FF3131' }}
        >
          {error}
        </span>
      )}
    </label>
  )
}

export function AuthSubmitButton({
  loading, children, ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  loading?: boolean
}) {
  return (
    <button
      {...props}
      disabled={loading || props.disabled}
      className="w-full grid place-items-center font-body disabled:cursor-not-allowed"
      style={{
        height: 52, borderRadius: 14, background: NAVY, color: '#fff',
        fontSize: 16, fontWeight: 700,
        opacity: loading ? 0.7 : 1,
        transition: 'opacity 0.2s',
        ...props.style,
      }}
      onMouseEnter={(e) => {
        if (!loading && !props.disabled) e.currentTarget.style.background = '#000F5C'
      }}
      onMouseLeave={(e) => {
        if (!loading && !props.disabled) e.currentTarget.style.background = NAVY
      }}
    >
      {loading ? 'Please wait…' : children}
    </button>
  )
}
