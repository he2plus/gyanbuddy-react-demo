/**
 * ChapterTheoryPage — "Learn mode" per docx #15.
 *
 * Shows the chapter's theory content (image + text — image optional) before
 * the user starts the quiz. Visual language matches the rest of the Figma
 * rebuild: TopBar, navy primary, cyan accent, Open Sans typography.
 *
 * Theory text supports a tiny markdown subset (**bold** and paragraph breaks)
 * since some backend content is lightly formatted.
 */
import { useMemo } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import {
  ArrowLeft, ArrowRight, AlertTriangle, BookOpen, Play,
} from 'lucide-react'

import { TopBar } from '../../shell/TopBar'
import { getSubjectById } from '../../api/subjects'
import { useModuleChapters } from './useModuleChapters'
import type { Subject } from '../../types/subject'

type Params = { subjectId: string; moduleId: string; chapterId: string }

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

export function ChapterTheoryPage() {
  const params = useParams<Params>()
  const subjectId = params.subjectId ?? ''
  const moduleId = params.moduleId ?? ''
  const chapterId = params.chapterId ?? ''
  const navigate = useNavigate()

  const subjectQ = useQuery<Subject>({
    queryKey: ['subjects', subjectId, 'detail'],
    queryFn: () => getSubjectById(subjectId),
    enabled: !!subjectId,
    staleTime: 5 * 60_000,
  })
  const chaptersQ = useModuleChapters(moduleId)

  const chapter = useMemo(
    () => chaptersQ.data?.find((c) => c.id === chapterId) ?? null,
    [chaptersQ.data, chapterId],
  )

  const onStartQuiz = () =>
    navigate(`/subjects/${subjectId}/modules/${moduleId}/chapters/${chapterId}/quiz`)

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle={chapter?.name ?? 'Chapter'} />

      <main className="mx-auto" style={{ maxWidth: 1680, padding: 'clamp(20px, 3vw, 40px) clamp(16px, 4vw, 120px) clamp(32px, 5vw, 60px)' }}>
        {/* Back button */}
        <button
          type="button"
          onClick={() => navigate(`/subjects/${subjectId}/modules/${moduleId}/chapters`)}
          className="flex items-center font-body"
          style={{
            gap: 10, padding: '10px 18px', borderRadius: 999,
            background: '#fff', border: '1px solid #E7E7E7', color: TXT_MID,
            fontSize: 16, fontWeight: 600,
            marginBottom: 24,
          }}
        >
          <ArrowLeft className="w-4 h-4" strokeWidth={2.5} />
          Back to Journey
        </button>

        {chaptersQ.isLoading || subjectQ.isLoading ? (
          <LoadingState />
        ) : chaptersQ.isError ? (
          <ErrorState
            message={chaptersQ.error instanceof Error ? chaptersQ.error.message : 'Failed to load chapter'}
            onRetry={() => chaptersQ.refetch()}
          />
        ) : !chapter ? (
          <NotFoundState />
        ) : (
          <article
            className="mx-auto flex flex-col"
            style={{ maxWidth: 1000, gap: 24 }}
          >
            {/* Hero card */}
            <motion.section
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
              className="bg-white relative overflow-hidden"
              style={{
                padding: 34, borderRadius: 34,
                border: '1px solid #E7E7E7',
                boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
              }}
            >
              <div className="flex flex-col" style={{ gap: 20 }}>
                <div className="flex items-center" style={{ gap: 12 }}>
                  <span
                    className="font-body"
                    style={{
                      fontSize: 14, fontWeight: 700, color: CYAN,
                      letterSpacing: '0.06em', textTransform: 'uppercase',
                    }}
                  >
                    Topic {chapter.order}
                  </span>
                  {chapter.isImportant && (
                    <span
                      className="grid place-items-center"
                      style={{
                        background: '#FFE48B', color: '#92400E', borderRadius: 999,
                        padding: '4px 12px',
                        fontFamily: 'var(--font-body)',
                        fontSize: 12, fontWeight: 700,
                        letterSpacing: '0.06em', textTransform: 'uppercase',
                      }}
                    >
                      Important
                    </span>
                  )}
                </div>
                <h1
                  className="font-body"
                  style={{
                    fontSize: 36, fontWeight: 700, color: TXT_DARK,
                    lineHeight: '48px', letterSpacing: '-0.3px', margin: 0,
                  }}
                >
                  {chapter.name}
                </h1>
                {chapter.description && (
                  <p
                    className="font-body"
                    style={{ fontSize: 18, fontWeight: 400, color: TXT_MID, lineHeight: '28px', margin: 0 }}
                  >
                    {chapter.description}
                  </p>
                )}
                <div className="flex items-center" style={{ gap: 24 }}>
                  <span className="flex items-center font-body" style={{ gap: 8, color: TXT_MID }}>
                    <BookOpen className="w-4 h-4" strokeWidth={2.2} />
                    <span style={{ fontSize: 14, fontWeight: 600 }}>
                      {chapter.questionCount} {chapter.questionCount === 1 ? 'item' : 'items'} of content
                    </span>
                  </span>
                  {chapter.hasHots && (
                    <span
                      className="grid place-items-center"
                      style={{
                        background: '#F5D0FE', color: '#86198F', borderRadius: 999,
                        padding: '4px 12px',
                        fontFamily: 'var(--font-body)',
                        fontSize: 12, fontWeight: 700,
                        letterSpacing: '0.06em', textTransform: 'uppercase',
                      }}
                    >
                      Includes HOTS
                    </span>
                  )}
                </div>
              </div>
            </motion.section>

            {/* Illustration zone — the real subject art (chapter logo if the
                backend ships one, else the subject's icon). No dummy ball. */}
            {(chapter.logo || subjectQ.data?.logo) && (
              <motion.section
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.45, delay: 0.05, ease: [0.22, 1, 0.36, 1] }}
                className="grid place-items-center overflow-hidden bg-white"
                style={{
                  padding: 24, borderRadius: 34, border: '1px solid #E7E7E7',
                  minHeight: 240,
                  background: 'radial-gradient(circle at 50% 40%, rgba(26,188,254,0.12), transparent 70%), #fff',
                }}
              >
                <motion.img
                  src={chapter.logo || subjectQ.data?.logo || ''}
                  alt=""
                  className="max-h-56 w-auto select-none"
                  style={{ objectFit: 'contain', filter: 'drop-shadow(0 14px 30px rgba(0,22,122,0.18))' }}
                  animate={{ y: [0, -6, 0] }}
                  transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut' }}
                  onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none' }}
                />
              </motion.section>
            )}

            {/* Theory body */}
            <motion.section
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.45, delay: 0.1, ease: [0.22, 1, 0.36, 1] }}
              className="bg-white"
              style={{
                padding: 34, borderRadius: 34, border: '1px solid #E7E7E7',
                boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
              }}
            >
              <h2
                className="font-body"
                style={{
                  fontSize: 20, fontWeight: 700, color: NAVY,
                  lineHeight: '28px', margin: 0,
                  letterSpacing: '0.02em',
                }}
              >
                What you'll learn
              </h2>
              <TheoryBody text={chapter.theory ?? ''} />
            </motion.section>

            {/* CTA — sticky-feel start quiz */}
            <motion.section
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.45, delay: 0.15, ease: [0.22, 1, 0.36, 1] }}
              className="flex items-center"
              style={{
                padding: '24px 28px', borderRadius: 34, gap: 16,
                background: '#fff', border: `2px solid ${CYAN}`,
                boxShadow: '0 8px 28px rgba(26,188,254,0.16)',
                position: 'sticky', bottom: 20,
              }}
            >
              <div className="flex-1 flex flex-col" style={{ gap: 4 }}>
                <span
                  className="font-body"
                  style={{ fontSize: 14, fontWeight: 600, color: TXT_MID, lineHeight: '20px' }}
                >
                  {chapter.isCompleted ? 'Already completed' : 'Ready when you are'}
                </span>
                <span
                  className="font-body"
                  style={{ fontSize: 20, fontWeight: 700, color: NAVY, lineHeight: '28px' }}
                >
                  {chapter.isCompleted
                    ? `Review ${chapter.name}`
                    : `Start the quiz for ${chapter.name}`}
                </span>
              </div>
              <motion.button
                type="button"
                onClick={onStartQuiz}
                whileTap={{ scale: 0.96 }}
                whileHover={{ y: -2 }}
                className="grid place-items-center font-body shrink-0"
                style={{
                  background: NAVY, color: '#fff', borderRadius: 999,
                  padding: '14px 28px', height: 56, gap: 12,
                }}
              >
                <span className="flex items-center" style={{ gap: 12 }}>
                  <Play className="w-5 h-5" strokeWidth={2.5} fill="#fff" />
                  <span style={{ fontSize: 18, fontWeight: 700, lineHeight: '25px' }}>
                    {chapter.isCompleted ? 'Review' : 'Start Quiz'}
                  </span>
                  <ArrowRight className="w-5 h-5" strokeWidth={2.5} />
                </span>
              </motion.button>
            </motion.section>
          </article>
        )}
      </main>
    </div>
  )
}

// ---------------------------------------------------------------------------
function TheoryBody({ text }: { text: string }) {
  if (!text) {
    return (
      <p
        className="font-body"
        style={{ marginTop: 16, fontSize: 16, fontWeight: 400, color: TXT_MUTED, lineHeight: '24px' }}
      >
        No theory content provided for this chapter yet.
      </p>
    )
  }
  const paragraphs = text.split(/\n\s*\n/).filter((p) => p.trim().length > 0)
  return (
    <div style={{ marginTop: 16 }}>
      {paragraphs.map((p, i) => (
        <p
          key={i}
          className="font-body"
          style={{
            fontSize: 18, fontWeight: 400, color: TXT_DARK,
            lineHeight: '30px', marginTop: i === 0 ? 0 : 16,
          }}
        >
          {renderInline(p)}
        </p>
      ))}
    </div>
  )
}

function renderInline(text: string) {
  const parts = text.split(/(\*\*[^*]+\*\*)/g)
  return parts.map((seg, i) => {
    if (seg.startsWith('**') && seg.endsWith('**')) {
      return (
        <strong key={i} style={{ fontWeight: 700, color: NAVY }}>
          {seg.slice(2, -2)}
        </strong>
      )
    }
    return <span key={i}>{seg}</span>
  })
}

// ---------------------------------------------------------------------------
function LoadingState() {
  return (
    <div className="grid place-items-center text-center" style={{ padding: '80px 0' }}>
      <div
        className="animate-spin"
        style={{
          width: 36, height: 36, borderRadius: 999,
          border: `4px solid ${CYAN}`, borderTopColor: 'transparent',
        }}
      />
      <p
        className="font-body"
        style={{ marginTop: 16, fontSize: 16, color: TXT_MID }}
      >
        Loading chapter…
      </p>
    </div>
  )
}

function NotFoundState() {
  return (
    <div
      className="grid place-items-center font-body"
      style={{ padding: '80px 0', color: TXT_MID }}
    >
      Chapter not found.
    </div>
  )
}

function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="grid place-items-center text-center" style={{ padding: '80px 0' }}>
      <AlertTriangle className="w-14 h-14" style={{ color: TXT_MUTED }} />
      <h2
        className="font-body"
        style={{ marginTop: 12, fontSize: 18, fontWeight: 700, color: TXT_DARK }}
      >
        Couldn't load this chapter
      </h2>
      <p
        className="font-body"
        style={{ marginTop: 4, fontSize: 16, color: TXT_MUTED }}
      >
        {message}
      </p>
      <button
        type="button"
        onClick={onRetry}
        className="font-body"
        style={{
          marginTop: 20, padding: '12px 28px', borderRadius: 999,
          background: NAVY, color: '#fff',
          fontSize: 16, fontWeight: 700,
        }}
      >
        Retry
      </button>
    </div>
  )
}
