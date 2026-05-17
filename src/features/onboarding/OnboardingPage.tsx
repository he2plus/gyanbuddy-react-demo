/**
 * OnboardingPage — clean 4-step intro using brand colors only.
 *
 * Earlier version used per-page colored gradients (deep blue → cyan, navy →
 * gold, etc.). Stripped that whole palette — it screamed "AI generated".
 * Now: white surface, brand navy `#00167A` accent, brand primary `#365DEA`
 * progress dots, single illustration per page using existing Flutter assets.
 */
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowRight, GraduationCap, HelpCircle, TrendingUp, Trophy } from 'lucide-react'

import { onboardingStore } from '../../lib/onboarding'

const BRAND_NAVY = '#00167A'
const BRAND_PRIMARY = '#365DEA'

type Page = {
  title: string
  subtitle: string
  description: string
  icon: typeof GraduationCap
}

const PAGES: Page[] = [
  {
    title: 'Welcome to GyanBuddy',
    subtitle: 'Your smart learning companion',
    description:
      'Master any subject with personalised quizzes and keep track of your progress as you learn.',
    icon: GraduationCap,
  },
  {
    title: 'Interactive quizzes',
    subtitle: 'Learn by doing',
    description:
      'Engaging quizzes across multiple subjects with instant feedback and explanations for every answer.',
    icon: HelpCircle,
  },
  {
    title: 'Track your progress',
    subtitle: 'See your growth',
    description:
      'Detailed progress tracking shows you exactly where you are and what to study next.',
    icon: TrendingUp,
  },
  {
    title: 'Compete and win',
    subtitle: 'Rise to the top',
    description:
      'Challenge yourself on the leaderboard. Compete with other learners and become the week’s champion.',
    icon: Trophy,
  },
]

export function OnboardingPage() {
  const navigate = useNavigate()
  const [index, setIndex] = useState(0)
  const page = PAGES[index]
  const isLast = index === PAGES.length - 1
  const Icon = page.icon

  const complete = () => {
    onboardingStore.complete()
    navigate('/login', { replace: true })
  }
  const next = () => {
    if (isLast) complete()
    else setIndex((i) => Math.min(i + 1, PAGES.length - 1))
  }

  return (
    <div className="flex min-h-screen flex-col bg-white">
      {/* Top bar */}
      <header className="flex items-center justify-between border-b border-[#F0F0F0] px-6 py-4">
        <div className="text-base font-extrabold tracking-tight text-[#222]">
          Gyaan<span style={{ color: BRAND_PRIMARY }}>Buddy</span>
        </div>
        {!isLast && (
          <button
            type="button"
            onClick={complete}
            className="text-sm font-semibold text-[#666] hover:text-[#222]"
          >
            Skip
          </button>
        )}
      </header>

      {/* Body */}
      <main className="mx-auto flex w-full max-w-[640px] flex-1 flex-col items-center justify-center px-6 py-12 text-center">
        {/* Illustration */}
        <div
          className="grid h-32 w-32 place-items-center rounded-2xl"
          style={{ background: '#F4F6FC', border: `1px solid ${BRAND_PRIMARY}22` }}
        >
          <Icon className="h-16 w-16" style={{ color: BRAND_NAVY }} strokeWidth={1.5} />
        </div>

        <h1 className="mt-8 text-3xl font-extrabold tracking-tight text-[#222] sm:text-4xl">
          {page.title}
        </h1>
        <p className="mt-2 text-sm font-semibold uppercase tracking-widest" style={{ color: BRAND_PRIMARY }}>
          {page.subtitle}
        </p>
        <p className="mt-5 max-w-md text-base leading-relaxed text-[#555]">
          {page.description}
        </p>
      </main>

      {/* Footer */}
      <footer className="border-t border-[#F0F0F0] px-6 py-5">
        <div className="mx-auto flex w-full max-w-[640px] items-center justify-between gap-4">
          {/* Indicators */}
          <div className="flex items-center gap-1.5" role="tablist">
            {PAGES.map((_, i) => {
              const active = i === index
              return (
                <button
                  key={i}
                  type="button"
                  onClick={() => setIndex(i)}
                  aria-label={`Go to step ${i + 1}`}
                  className="h-2 rounded-full transition-all"
                  style={{
                    width: active ? 24 : 8,
                    background: active ? BRAND_PRIMARY : '#DDD',
                  }}
                />
              )
            })}
          </div>

          <button
            type="button"
            onClick={next}
            className="inline-flex items-center gap-2 rounded-md px-6 py-2.5 text-sm font-semibold text-white"
            style={{ background: BRAND_NAVY }}
          >
            {isLast ? 'Get started' : 'Next'}
            <ArrowRight className="h-4 w-4" />
          </button>
        </div>
      </footer>
    </div>
  )
}
