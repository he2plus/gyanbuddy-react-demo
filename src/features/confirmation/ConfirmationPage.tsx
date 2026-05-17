/**
 * ConfirmationPage — clean post-signup acknowledgement.
 *
 * Dropped (vs Flutter source):
 *   - 4 floating blue decorative circles (AI-template look on web)
 *   - Spring/elastic animation on the check icon
 *   - Blue drop-shadow glow on the check disc
 *
 * Auto-navigates to /home after 1.5 s (matches the Flutter timing).
 */
import { useEffect } from 'react'
import { motion } from 'framer-motion'
import { Check } from 'lucide-react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Button } from '../../components/Button'

const AUTO_NAV_MS = 1500
const BRAND_PRIMARY = '#365DEA'

export function ConfirmationPage() {
  const navigate = useNavigate()
  const [params] = useSearchParams()

  const title = params.get('title') ?? 'Thank you'
  const subtitle = params.get('subtitle') ?? 'Your account has been created.'

  useEffect(() => {
    const t = window.setTimeout(() => {
      navigate('/home', { replace: true })
    }, AUTO_NAV_MS)
    return () => window.clearTimeout(t)
  }, [navigate])

  return (
    <div className="flex min-h-screen items-center justify-center bg-white px-8">
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
        className="flex max-w-sm flex-col items-center text-center"
      >
        <div
          className="grid h-20 w-20 place-items-center rounded-full text-white"
          style={{ background: BRAND_PRIMARY }}
        >
          <Check className="h-10 w-10" strokeWidth={3} />
        </div>

        <h1 className="mt-8 text-2xl font-bold tracking-tight text-[#222]">
          {title}
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-[#666]">{subtitle}</p>

        <div className="mt-10 w-full">
          <Button
            fullWidth
            onClick={() => navigate('/home', { replace: true })}
            aria-label="Continue to home"
          >
            Continue
          </Button>
        </div>
      </motion.div>
    </div>
  )
}
