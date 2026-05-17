/**
 * CreditsPage — mirrors lib/screens/profile/credits_screen.dart.
 *
 * Static content. Team list copied verbatim from Dart source so the brand
 * roster stays in sync until/unless the team explicitly changes it.
 */
import {
  Briefcase,
  GraduationCap,
  Palette,
  Brain,
  Code2,
  type LucideIcon,
} from 'lucide-react'
import { ScreenHeader } from '../../components/ScreenHeader'
import { Card } from '../../components/Card'
import { PageContainer } from '../../components/PageContainer'

type TeamMember = { name: string; role: string; icon: LucideIcon }

const TEAM: TeamMember[] = [
  { name: 'Rehan Sareen', role: 'Founder, CEO', icon: Briefcase },
  { name: 'Parul Nagpal', role: 'Academic Advisor', icon: GraduationCap },
  { name: 'Sanskriti Vaidya', role: 'Brand Identity Designer', icon: Palette },
  { name: 'Bhavya Bharadwaj', role: 'AI Specialist', icon: Brain },
  { name: 'Mridul Saxena', role: 'Developer', icon: Code2 },
  { name: 'Aayush Sharma', role: 'Developer', icon: Code2 },
  { name: 'Rahul Srivastava', role: 'Developer', icon: Code2 },
]

export function CreditsPage() {
  const year = new Date().getFullYear()

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader title="Credits" />

      <PageContainer variant="narrow" className="flex flex-col items-center pt-8 pb-10">
        {/* Real Flutter asset: gyaan_buddy/assets/images/final_logo.png */}
        <div
          className="grid h-28 w-28 place-items-center overflow-hidden rounded-full bg-emerald-50 shadow-[0_5px_15px_rgba(16,185,129,0.2)]"
          aria-label="Gyaan Buddy logo"
        >
          <img
            src="/images/final_logo.png"
            alt="Gyaan Buddy"
            className="h-full w-full object-cover"
          />
        </div>

        <h2 className="mt-6 text-3xl font-bold text-emerald-600">GyanBuddy</h2>
        <p className="mt-2 italic text-[var(--color-text-secondary)]">
          A Smarter way to learn
        </p>

        <div className="mt-10 flex w-full flex-col gap-5">
          <Card title="About GyanBuddy" accent="green">
            <p className="px-5 py-4 text-center text-sm leading-relaxed text-[var(--color-text-secondary)]">
              GyanBuddy is a learning platform designed to make education
              engaging and fun. Built with passion and dedication to help
              students learn effectively through interactive quizzes,
              missions, and gamified learning experiences.
            </p>
          </Card>

          <Card title="Special Thanks" accent="green">
            <p className="px-5 py-4 text-center text-sm leading-relaxed text-[var(--color-text-secondary)]">
              Thank you to all the users, educators, and supporters who
              believe in making quality education accessible to everyone.
              Your feedback and encouragement drive us to keep improving
              GyanBuddy.
            </p>
          </Card>

          <Card title="Our Team" accent="green">
            <ul className="grid grid-cols-1 gap-x-2 sm:grid-cols-2">
              {TEAM.map(({ name, role, icon: Icon }) => (
                <li
                  key={name}
                  className="flex items-center gap-4 border-b border-[var(--color-input-border)] px-5 py-4 last:border-b-0 sm:[&:nth-last-child(2):nth-child(odd)]:border-b-0"
                >
                  <span className="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-emerald-100 text-emerald-700">
                    <Icon className="h-5 w-5" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <div className="font-semibold text-[var(--color-text-primary)]">
                      {name}
                    </div>
                    <div className="text-sm text-[var(--color-text-secondary)]">
                      {role}
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          </Card>
        </div>

        <p className="mt-10 text-xs text-[var(--color-text-light)]">
          © {year} GyanBuddy
        </p>
        <p className="mt-1 text-xs text-[var(--color-text-light)]">
          Built by{' '}
          <a
            href="mailto:dptmywork@gmail.com"
            className="font-semibold text-[#365DEA] hover:underline"
          >
            Prakhar Tripathi
          </a>
        </p>
      </PageContainer>
    </div>
  )
}
