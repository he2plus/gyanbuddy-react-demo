/**
 * CreditsPage — restyled. Static attribution screen.
 */
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Heart, ExternalLink, Mail, ArrowLeft } from 'lucide-react'

import { TopBar } from '../../shell/TopBar'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

const TEAM = [
  { name: 'GyanBuddy Engineering', role: 'Engineering & integration', email: null },
  { name: 'GyanBuddy Design', role: 'UI / UX', email: null },
  { name: 'The teachers',     role: 'Subject content and curriculum guidance', email: null },
]

export function CreditsPage() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Credits" />

      <main
        className="mx-auto flex flex-col"
        style={{ maxWidth: 720, padding: '60px 24px 60px', gap: 32 }}
      >
        {/* Hero */}
        <motion.section
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.45 }}
          className="bg-white text-center"
          style={{
            padding: 40, borderRadius: 34,
            border: '1px solid #E7E7E7',
            boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
          }}
        >
          <div
            className="mx-auto grid place-items-center"
            style={{
              width: 80, height: 80, borderRadius: 22,
              background: `linear-gradient(135deg, ${CYAN} 0%, ${NAVY} 100%)`,
              color: '#fff', marginBottom: 18,
              boxShadow: `0 12px 24px ${NAVY}33`,
            }}
          >
            <span
              className="font-display"
              style={{ fontSize: 38, fontWeight: 800, lineHeight: 1 }}
            >
              G
            </span>
          </div>
          <h1
            className="font-body"
            style={{ fontSize: 32, fontWeight: 700, color: TXT_DARK, lineHeight: '42px', margin: 0 }}
          >
            GyanBuddy
          </h1>
          <p
            className="font-body"
            style={{ marginTop: 6, fontSize: 16, fontWeight: 500, color: TXT_MID, lineHeight: '24px' }}
          >
            A smarter way to learn.
          </p>
          <div
            className="inline-flex items-center font-body"
            style={{
              marginTop: 18, gap: 6, padding: '6px 14px', borderRadius: 999,
              background: '#FFE2E2', color: '#B91C1C',
              fontSize: 13, fontWeight: 700,
            }}
          >
            <Heart className="w-4 h-4" strokeWidth={2.5} fill="#B91C1C" />
            Built with care
          </div>
        </motion.section>

        {/* Team */}
        <section
          className="bg-white overflow-hidden"
          style={{
            borderRadius: 34, border: '1px solid #E7E7E7',
            boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
          }}
        >
          <div
            className="font-body"
            style={{
              padding: '20px 28px', fontSize: 13, fontWeight: 700,
              color: TXT_MUTED, letterSpacing: '0.06em', textTransform: 'uppercase',
              borderBottom: '1px solid #F1F1F1',
            }}
          >
            Made by
          </div>
          {TEAM.map((m, i) => (
            <div
              key={m.name}
              className="flex items-center"
              style={{
                padding: '20px 28px', gap: 18,
                borderBottom: i < TEAM.length - 1 ? '1px solid #F1F1F1' : 'none',
              }}
            >
              <div
                className="grid place-items-center shrink-0"
                style={{
                  width: 48, height: 48, borderRadius: 14,
                  background: NAVY, color: '#fff',
                }}
              >
                <span
                  className="font-body"
                  style={{ fontSize: 20, fontWeight: 700 }}
                >
                  {m.name[0]}
                </span>
              </div>
              <div className="flex-1 flex flex-col" style={{ gap: 2 }}>
                <span
                  className="font-body"
                  style={{ fontSize: 16, fontWeight: 700, color: TXT_DARK, lineHeight: '22px' }}
                >
                  {m.name}
                </span>
                <span
                  className="font-body"
                  style={{ fontSize: 14, fontWeight: 400, color: TXT_MID, lineHeight: '20px' }}
                >
                  {m.role}
                </span>
              </div>
              {m.email && (
                <a
                  href={`mailto:${m.email}`}
                  className="grid place-items-center"
                  style={{
                    width: 44, height: 44, borderRadius: 14,
                    background: '#F0F4FF', color: NAVY,
                  }}
                >
                  <Mail className="w-5 h-5" strokeWidth={2.2} />
                </a>
              )}
            </div>
          ))}
        </section>

        {/* Footer */}
        <div className="text-center flex flex-col" style={{ gap: 8 }}>
          <a
            href="https://github.com/he2plus/gyanbuddy-react-demo"
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center font-body self-center"
            style={{
              gap: 8, padding: '10px 18px', borderRadius: 999,
              background: '#fff', border: '1px solid #E7E7E7', color: TXT_DARK,
              fontSize: 14, fontWeight: 700, textDecoration: 'none',
            }}
          >
            <ExternalLink className="w-4 h-4" strokeWidth={2.2} />
            Source on GitHub
          </a>
          <p
            className="font-body"
            style={{ fontSize: 12, fontWeight: 500, color: TXT_MUTED, margin: 0 }}
          >
            © GyanBuddy · v0.1.0
          </p>
        </div>

        <button
          type="button"
          onClick={() => navigate('/home')}
          className="self-center font-body"
          style={{
            color: NAVY, fontWeight: 700, fontSize: 16,
            background: 'transparent', display: 'inline-flex', alignItems: 'center', gap: 6,
          }}
        >
          <ArrowLeft className="w-4 h-4" strokeWidth={2.5} />
          Back to home
        </button>
      </main>
    </div>
  )
}
