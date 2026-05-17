/**
 * ChapterTheoryPage — mirrors lib/screens/module/chapter_theory_screen.dart.
 *
 * Shown when the user taps a chapter (or the Start CTA) on the journey page.
 * Renders the chapter's theory content as a readable article, plus a CTA to
 * start the quiz.
 *
 * The Flutter version triggers `GET /module_chapters/{id}/module_questions/`
 * on Continue and navigates to QuizScreen with the resulting list. Quiz is
 * Tier 4 — for now the CTA shows a toast and routes to a placeholder.
 *
 * Theory text comes directly from `chapter.theory` returned by
 * `GET /modules/{moduleId}/module_chapters/`. No extra API call needed for
 * the preview body.
 */
import { useMemo } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import { ArrowRight, AlertTriangle, BookOpen } from 'lucide-react'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import { Button } from '../../components/Button'
import { getSubjectById } from '../../api/subjects'
import { useModuleChapters } from './useModuleChapters'
import type { Subject } from '../../types/subject'

type Params = { subjectId: string; moduleId: string; chapterId: string }

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

  const subjectColor = subjectQ.data?.color ?? '#365DEA'

  const onStartQuiz = () => {
    navigate(
      `/subjects/${subjectId}/modules/${moduleId}/chapters/${chapterId}/quiz`,
    )
  }

  return (
    <div className="min-h-screen bg-white">
      <div>
        <ScreenHeader
          title={chapter?.name ?? 'Chapter'}
          onBack={() =>
            navigate(`/subjects/${subjectId}/modules/${moduleId}/chapters`)
          }
        />

        <PageContainer variant="medium" className="pb-12 pt-2">
          {chaptersQ.isLoading || subjectQ.isLoading ? (
            <LoadingState />
          ) : chaptersQ.isError ? (
            <ErrorState
              message={
                chaptersQ.error instanceof Error
                  ? chaptersQ.error.message
                  : 'Failed to load chapter'
              }
              onRetry={() => chaptersQ.refetch()}
            />
          ) : !chapter ? (
            <NotFoundState />
          ) : (
            <article className="flex flex-col gap-6">
              {/* Hero card */}
              <motion.section
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, ease: 'easeOut' }}
                className="relative overflow-hidden rounded-2xl border border-[var(--color-input-border)] bg-white p-6 shadow-sm sm:p-8"
              >
                <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
                  {/* Hero illustration — lamp.png on a flat tinted surface */}
                  <div
                    className="grid h-20 w-20 shrink-0 place-items-center rounded-xl"
                    style={{ background: `${subjectColor}14` }}
                  >
                    <img
                      src="/images/lamp.png"
                      alt=""
                      className="h-14 w-auto select-none"
                      draggable={false}
                    />
                  </div>

                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-widest text-[var(--color-text-light)]">
                      <span>Chapter {chapter.order}</span>
                      {chapter.isImportant && (
                        <span className="rounded-md border border-amber-300 bg-amber-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-widest text-amber-700">
                          Important
                        </span>
                      )}
                    </div>
                    <h1 className="mt-1 text-2xl font-bold leading-tight text-[var(--color-text-primary)] sm:text-3xl">
                      {chapter.name}
                    </h1>
                    {chapter.description && (
                      <p className="mt-2 text-sm text-[var(--color-text-secondary)]">
                        {chapter.description}
                      </p>
                    )}
                  </div>
                </div>

                <div className="mt-5 flex flex-wrap gap-4 text-sm text-[var(--color-text-secondary)]">
                  <span className="inline-flex items-center gap-1.5">
                    <BookOpen className="h-4 w-4" />
                    {chapter.questionCount}{' '}
                    {chapter.questionCount === 1 ? 'item' : 'items'} of content
                  </span>
                  {chapter.hasHots && (
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-fuchsia-100 px-2.5 py-0.5 text-xs font-semibold text-fuchsia-700">
                      Includes HOTS questions
                    </span>
                  )}
                </div>
              </motion.section>

              {/* Theory body */}
              <motion.section
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.1, ease: 'easeOut' }}
                className="rounded-2xl border border-[var(--color-input-border)] bg-white p-6 shadow-sm sm:p-8"
              >
                <h2 className="text-lg font-bold text-[var(--color-text-primary)]">
                  What you'll learn
                </h2>
                <TheoryBody text={chapter.theory ?? ''} />
              </motion.section>

              {/* CTA */}
              <motion.section
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.2, ease: 'easeOut' }}
                className="sticky bottom-4 rounded-2xl border-2 p-5 shadow-[0_8px_28px_-8px_rgba(0,0,0,0.18)] sm:p-6"
                style={{
                  borderColor: `${subjectColor}55`,
                  background: 'white',
                }}
              >
                <div className="flex flex-col items-center justify-between gap-3 sm:flex-row sm:gap-4">
                  <div className="text-center sm:text-left">
                    <div className="text-sm text-[var(--color-text-secondary)]">
                      Ready to test what you've learned?
                    </div>
                    <div className="text-base font-bold text-[var(--color-text-primary)] sm:text-lg">
                      Start the quiz for{' '}
                      <span style={{ color: subjectColor }}>{chapter.name}</span>
                    </div>
                  </div>
                  <Button onClick={onStartQuiz} className="px-6 sm:shrink-0">
                    Start Quiz
                    <ArrowRight className="h-4 w-4" />
                  </Button>
                </div>
              </motion.section>
            </article>
          )}
        </PageContainer>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Body renderer — supports a tiny subset of Markdown so backend content with
// **bold** or paragraph breaks renders cleanly. Backend has rich text in some
// cases; the Flutter app shows it as plain text, but a bit of polish is free.
// ---------------------------------------------------------------------------

function TheoryBody({ text }: { text: string }) {
  if (!text) {
    return (
      <p className="mt-4 text-sm text-[var(--color-text-light)]">
        No theory content provided for this chapter yet.
      </p>
    )
  }

  const paragraphs = text.split(/\n\s*\n/).filter((p) => p.trim().length > 0)

  return (
    <div className="mt-4 space-y-4">
      {paragraphs.map((p, i) => (
        <p
          key={i}
          className="text-base leading-relaxed text-[var(--color-text-secondary)]"
        >
          {renderInline(p)}
        </p>
      ))}
    </div>
  )
}

/** Renders **bold** segments inline. Everything else stays plain text. */
function renderInline(text: string) {
  const parts = text.split(/(\*\*[^*]+\*\*)/g)
  return parts.map((seg, i) => {
    if (seg.startsWith('**') && seg.endsWith('**')) {
      return (
        <strong key={i} className="font-semibold text-[var(--color-text-primary)]">
          {seg.slice(2, -2)}
        </strong>
      )
    }
    return <span key={i}>{seg}</span>
  })
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

function LoadingState() {
  return (
    <div className="grid place-items-center py-20 text-center">
      <div className="h-8 w-8 animate-spin rounded-full border-4 border-[var(--color-primary)] border-t-transparent" />
      <p className="mt-4 text-sm text-[var(--color-text-secondary)]">
        Loading chapter…
      </p>
    </div>
  )
}

function NotFoundState() {
  return (
    <div className="grid place-items-center py-20 text-[var(--color-text-secondary)]">
      Chapter not found.
    </div>
  )
}

function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="grid place-items-center px-6 py-16 text-center">
      <AlertTriangle className="h-16 w-16 text-[var(--color-text-light)]" />
      <h2 className="mt-4 text-lg font-bold text-[var(--color-text-secondary)]">
        Couldn't load this chapter
      </h2>
      <p className="mt-1 text-sm text-[var(--color-text-light)]">{message}</p>
      <div className="mt-6">
        <Button onClick={onRetry}>Retry</Button>
      </div>
    </div>
  )
}

