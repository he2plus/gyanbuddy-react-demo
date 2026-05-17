/**
 * QuizFlow — shared quiz UI used by both chapter quizzes and mission quizzes.
 *
 * Supports:
 *   - mcq_single   (radio)
 *   - mcq_multiple (checkboxes)
 *   - short_answer (text input)
 *
 * Doesn't yet support: `rearrange` (drag/drop — Tier 5 polish).
 *
 * Submission goes through `checkAnswer()` which:
 *   - In mock mode: validates client-side via option.isCorrect
 *   - With real backend: POSTs /questions/{id}/check/
 *
 * On finish: shows a results card with XP earned + restart / exit buttons.
 */
import { useEffect, useMemo, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Check, X, Lightbulb, ArrowRight, RotateCcw, AlertTriangle } from 'lucide-react'

import { Button } from '../../components/Button'
import { checkAnswer } from '../../api/quiz'
import type { Question, QuestionOption } from '../../types/question'

type FeedbackState =
  | { kind: 'idle' }
  | { kind: 'checking' }
  | { kind: 'correct'; xp: number; explanation?: string }
  | { kind: 'incorrect'; explanation?: string; attempts: number }

type Props = {
  questions: Question[]
  accent?: string
  onExit: () => void
}

export function QuizFlow({ questions, accent = '#365DEA', onExit }: Props) {
  const [index, setIndex] = useState(0)
  const [selectedIds, setSelectedIds] = useState<string[]>([])
  const [shortAnswer, setShortAnswer] = useState('')
  const [feedback, setFeedback] = useState<FeedbackState>({ kind: 'idle' })
  const [showHint, setShowHint] = useState(false)
  const [attempts, setAttempts] = useState(0)
  const [totalXp, setTotalXp] = useState(0)
  const [finished, setFinished] = useState(false)

  const question = questions[index]
  const total = questions.length

  // Reset per-question state when the index changes.
  useEffect(() => {
    setSelectedIds([])
    setShortAnswer('')
    setFeedback({ kind: 'idle' })
    setShowHint(false)
    setAttempts(0)
  }, [index])

  const hasSelection = useMemo(() => {
    if (!question) return false
    if (question.type === 'short_answer') return shortAnswer.trim().length > 0
    return selectedIds.length > 0
  }, [question, selectedIds, shortAnswer])

  if (!question && !finished) {
    return (
      <div className="grid place-items-center py-20 text-[var(--color-text-secondary)]">
        No questions in this quiz.
      </div>
    )
  }

  if (finished) {
    const maxPossible = questions.reduce((sum, q) => sum + q.expPoints, 0)
    return (
      <ResultsCard
        accent={accent}
        xpEarned={totalXp}
        xpMax={maxPossible}
        onExit={onExit}
        onRestart={() => {
          setIndex(0)
          setTotalXp(0)
          setFinished(false)
        }}
      />
    )
  }

  const toggleOption = (id: string) => {
    if (feedback.kind === 'correct' || feedback.kind === 'checking') return
    if (question.type === 'mcq_single') {
      setSelectedIds([id])
    } else {
      setSelectedIds((prev) =>
        prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
      )
    }
  }

  const submit = async () => {
    if (!hasSelection) return
    setFeedback({ kind: 'checking' })
    const result = await checkAnswer(
      question,
      selectedIds,
      shortAnswer || undefined,
    )
    if (result.isCorrect) {
      // Award scaled XP: full on first try, half on second, none after.
      const award =
        attempts === 0
          ? question.expPoints
          : attempts === 1
            ? Math.round(question.expPoints / 2)
            : 0
      setTotalXp((x) => x + award)
      setFeedback({
        kind: 'correct',
        xp: award,
        explanation: result.explanation,
      })
    } else {
      setAttempts((a) => a + 1)
      setFeedback({
        kind: 'incorrect',
        explanation: result.explanation,
        attempts: attempts + 1,
      })
    }
  }

  const goNext = () => {
    if (index + 1 >= total) {
      setFinished(true)
    } else {
      setIndex((i) => i + 1)
    }
  }

  const isIdle = feedback.kind === 'idle'
  const isChecking = feedback.kind === 'checking'
  const isCorrect = feedback.kind === 'correct'
  const isIncorrect = feedback.kind === 'incorrect'

  return (
    <div className="flex flex-col gap-5">
      {/* Progress + counter */}
      <div>
        <div className="flex items-center justify-between text-sm text-[var(--color-text-secondary)]">
          <span className="font-semibold">
            Question {index + 1} of {total}
          </span>
          <span>{Math.round(((index + 1) / total) * 100)}%</span>
        </div>
        <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-[var(--color-input-fill)]">
          <motion.div
            className="h-full rounded-full"
            style={{ background: accent }}
            initial={{ width: 0 }}
            animate={{ width: `${((index + 1) / total) * 100}%` }}
            transition={{ duration: 0.4, ease: 'easeOut' }}
          />
        </div>
      </div>

      {/* Question card */}
      <AnimatePresence mode="wait">
        <motion.div
          key={question.id}
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -20 }}
          transition={{ duration: 0.25, ease: 'easeOut' }}
          className="rounded-2xl border border-[var(--color-input-border)] bg-white p-6 shadow-sm sm:p-8"
        >
          {/* Tags */}
          <div className="flex flex-wrap items-center gap-2">
            <span
              className="rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-widest text-white"
              style={{ background: accent }}
            >
              {question.type === 'mcq_multiple'
                ? 'Select all that apply'
                : question.type === 'short_answer'
                  ? 'Short answer'
                  : question.type === 'rearrange'
                    ? 'Rearrange'
                    : 'Multiple choice'}
            </span>
            <span className="rounded-full bg-[var(--color-input-fill)] px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-widest text-[var(--color-text-secondary)]">
              {question.expPoints} XP
            </span>
            {question.isHots && (
              <span className="rounded-full bg-fuchsia-100 px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-widest text-fuchsia-700">
                HOTS
              </span>
            )}
          </div>

          {/* Question text + optional image */}
          <h2 className="mt-4 text-xl font-bold text-[var(--color-text-primary)] sm:text-2xl">
            {question.text}
          </h2>
          {question.image && (
            <img
              src={question.image}
              alt=""
              className="mt-4 max-h-72 w-full rounded-xl object-contain"
            />
          )}

          {/* Options */}
          {question.type === 'short_answer' ? (
            <input
              type="text"
              value={shortAnswer}
              onChange={(e) => setShortAnswer(e.target.value)}
              disabled={isCorrect || isChecking}
              placeholder="Type your answer…"
              className="mt-6 h-12 w-full rounded-xl border border-[var(--color-input-border)] bg-[var(--color-input-fill)] px-4 text-base text-[var(--color-text-primary)] outline-none focus:border-[var(--color-input-focus)] focus:bg-white"
            />
          ) : question.type === 'rearrange' ? (
            <div className="mt-6 rounded-xl border border-dashed border-[var(--color-input-border)] bg-[var(--color-input-fill)] p-4 text-sm text-[var(--color-text-secondary)]">
              Drag-to-rearrange UI lands in Tier 5 polish. For now, treat this
              question as informational.
            </div>
          ) : (
            <ul className="mt-6 space-y-3">
              {question.options.map((o) => (
                <OptionRow
                  key={o.id}
                  option={o}
                  selected={selectedIds.includes(o.id)}
                  disabled={isCorrect || isChecking}
                  multiSelect={question.type === 'mcq_multiple'}
                  accent={accent}
                  feedback={
                    isCorrect && o.isCorrect
                      ? 'correct'
                      : isIncorrect && selectedIds.includes(o.id)
                        ? 'incorrect'
                        : 'none'
                  }
                  onToggle={() => toggleOption(o.id)}
                />
              ))}
            </ul>
          )}

          {/* Hint */}
          {question.hint && (
            <div className="mt-5">
              <button
                type="button"
                onClick={() => setShowHint((s) => !s)}
                className="inline-flex items-center gap-1.5 text-sm font-semibold text-[var(--color-primary)] hover:underline"
              >
                <Lightbulb className="h-4 w-4" />
                {showHint ? 'Hide hint' : 'Show hint'}
              </button>
              {showHint && (
                <p className="mt-2 rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-900">
                  {question.hint}
                </p>
              )}
            </div>
          )}

          {/* Feedback row */}
          {isCorrect && (
            <FeedbackBanner kind="correct" xp={feedback.xp} note={feedback.explanation} />
          )}
          {isIncorrect && (
            <FeedbackBanner
              kind="incorrect"
              note={feedback.explanation}
              attempts={feedback.attempts}
            />
          )}
        </motion.div>
      </AnimatePresence>

      {/* Action bar */}
      <div className="sticky bottom-3 flex items-center justify-between gap-3 rounded-2xl border border-[var(--color-input-border)] bg-white p-3 shadow-[0_8px_24px_-8px_rgba(0,0,0,0.18)]">
        <Button variant="ghost" onClick={onExit}>
          Exit
        </Button>
        {isIdle || isChecking || isIncorrect ? (
          <Button
            onClick={submit}
            disabled={!hasSelection || isChecking}
            loading={isChecking}
            className="px-6"
          >
            {isIncorrect ? 'Try again' : 'Check'}
          </Button>
        ) : (
          <Button onClick={goNext} className="px-6">
            {index + 1 >= total ? 'Finish' : 'Next'}
            <ArrowRight className="h-4 w-4" />
          </Button>
        )}
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

function OptionRow({
  option,
  selected,
  disabled,
  multiSelect,
  accent,
  feedback,
  onToggle,
}: {
  option: QuestionOption
  selected: boolean
  disabled: boolean
  multiSelect: boolean
  accent: string
  feedback: 'none' | 'correct' | 'incorrect'
  onToggle: () => void
}) {
  return (
    <li>
      <motion.button
        type="button"
        onClick={onToggle}
        disabled={disabled}
        whileTap={{ scale: 0.99 }}
        className={`flex w-full items-center gap-3 rounded-xl border bg-white px-4 py-3.5 text-left transition-all disabled:cursor-not-allowed ${
          feedback === 'correct'
            ? 'border-emerald-500 bg-emerald-50'
            : feedback === 'incorrect'
              ? 'border-[var(--color-error)] bg-red-50'
              : selected
                ? 'border-[color:var(--color-primary)] shadow-sm'
                : 'border-[var(--color-input-border)] hover:bg-[var(--color-input-fill)]'
        }`}
      >
        <span
          className={`grid h-6 w-6 shrink-0 place-items-center transition-colors ${
            multiSelect ? 'rounded' : 'rounded-full'
          } ${
            feedback === 'correct'
              ? 'border-2 border-emerald-500 bg-emerald-500 text-white'
              : feedback === 'incorrect'
                ? 'border-2 border-[var(--color-error)] bg-[var(--color-error)] text-white'
                : selected
                  ? 'border-2 text-white'
                  : 'border-2 border-[var(--color-input-border)]'
          }`}
          style={
            selected && feedback === 'none'
              ? { borderColor: accent, background: accent }
              : undefined
          }
        >
          {feedback === 'correct' ? (
            <Check className="h-4 w-4" strokeWidth={3} />
          ) : feedback === 'incorrect' ? (
            <X className="h-4 w-4" strokeWidth={3} />
          ) : selected ? (
            multiSelect ? (
              <Check className="h-4 w-4" strokeWidth={3} />
            ) : (
              <span className="h-2.5 w-2.5 rounded-full bg-white" />
            )
          ) : null}
        </span>
        <span className="text-base text-[var(--color-text-primary)]">
          {option.optionText}
        </span>
      </motion.button>
    </li>
  )
}

function FeedbackBanner({
  kind,
  xp,
  note,
  attempts,
}: {
  kind: 'correct' | 'incorrect'
  xp?: number
  note?: string
  attempts?: number
}) {
  if (kind === 'correct') {
    return (
      <motion.div
        initial={{ opacity: 0, y: 6 }}
        animate={{ opacity: 1, y: 0 }}
        className="mt-5 flex items-start gap-3 rounded-xl border border-emerald-200 bg-emerald-50 p-4"
      >
        <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-emerald-500 text-white">
          <Check className="h-5 w-5" strokeWidth={3} />
        </span>
        <div>
          <div className="font-bold text-emerald-700">
            Correct! +{xp ?? 0} XP
          </div>
          {note && (
            <div className="mt-1 text-sm text-emerald-900">{note}</div>
          )}
        </div>
      </motion.div>
    )
  }
  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      className="mt-5 flex items-start gap-3 rounded-xl border border-red-200 bg-red-50 p-4"
    >
      <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-[var(--color-error)] text-white">
        <X className="h-5 w-5" strokeWidth={3} />
      </span>
      <div>
        <div className="font-bold text-[var(--color-error)]">
          Not quite{attempts && attempts > 1 ? ` — attempt #${attempts}` : ''}
        </div>
        {note && <div className="mt-1 text-sm text-red-900">{note}</div>}
      </div>
    </motion.div>
  )
}

function ResultsCard({
  xpEarned,
  xpMax,
  onExit,
  onRestart,
}: {
  accent: string
  xpEarned: number
  xpMax: number
  onExit: () => void
  onRestart: () => void
}) {
  const pct = xpMax > 0 ? Math.round((xpEarned / xpMax) * 100) : 0
  const scoreColor = pct >= 70 ? '#10B981' : pct >= 50 ? '#F39C12' : '#666'
  const message =
    pct >= 70
      ? 'Well done. You can move on to the next chapter.'
      : pct >= 50
        ? 'Solid attempt. Run through the chapter once more to push the score up.'
        : 'Have another look at the theory and try again.'

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
      className="rounded-2xl border bg-white p-8 text-center"
      style={{ borderColor: '#E0E0E0' }}
    >
      <div className="text-[11px] font-bold uppercase tracking-widest text-[#888]">
        Quiz complete
      </div>
      <div
        className="mt-3 text-5xl font-extrabold tabular-nums"
        style={{ color: scoreColor }}
      >
        {pct}%
      </div>
      <div className="mt-1 text-sm text-[#666]">
        {xpEarned} of {xpMax} XP earned
      </div>
      <p className="mx-auto mt-5 max-w-sm text-sm leading-relaxed text-[#555]">
        {message}
      </p>
      <div className="mt-6 flex flex-wrap justify-center gap-3">
        <Button variant="secondary" onClick={onRestart}>
          <RotateCcw className="h-4 w-4" /> Try again
        </Button>
        <Button onClick={onExit} className="px-6">
          Done
        </Button>
      </div>
    </motion.div>
  )
}

export function QuizErrorState({ message, onRetry, onExit }: { message: string; onRetry: () => void; onExit: () => void }) {
  return (
    <div className="grid place-items-center px-6 py-12 text-center">
      <AlertTriangle className="h-12 w-12 text-[var(--color-text-light)]" />
      <p className="mt-3 text-sm text-[var(--color-text-secondary)]">{message}</p>
      <div className="mt-4 flex gap-3">
        <Button variant="secondary" onClick={onExit}>Exit</Button>
        <Button onClick={onRetry}>Retry</Button>
      </div>
    </div>
  )
}
