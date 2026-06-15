/**
 * QuizFlow — shared quiz player for chapter quizzes, mission quizzes and
 * test quizzes. Implements docx #16 in full:
 *   - 2 XP on first-attempt correct, 1 XP on second-attempt correct, 0 after.
 *     (Backend already computes this from the `tries` field; see
 *     subjects/views.py check_answer — we just send `tries` and read the
 *     `exp_awarded` value back.)
 *   - On a WRONG first attempt the hint card auto-opens.
 *   - On a WRONG second attempt a "Why?" button reveals the explanation.
 *   - A correct-answer animation (green check + ring pulse + XP bump float)
 *     plays before the user advances.
 *   - Three question types supported:
 *       mcq_single    — radio
 *       mcq_multiple  — checkbox
 *       rearrange     — drag-with-arrows reorder list (no library, keyboard-
 *                       accessible). Backend storage is in place; backend
 *                       scoring for rearrange is still TBD so we accept the
 *                       backend's answer when present and grade client-side
 *                       against the option order otherwise.
 *
 * Visual language matches the rest of the Figma rebuild: white card with
 * radius 34, Open Sans body, navy primary, cyan accent.
 */
import { useEffect, useMemo, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Check, X, Lightbulb, ArrowRight, AlertTriangle,
  ChevronUp, ChevronDown, HelpCircle, Sparkles,
} from 'lucide-react'

import { checkAnswer } from '../../api/quiz'
import { ChapterCompletedSplash } from '../module/ChapterCompletedSplash'
import type { Question, QuestionOption } from '../../types/question'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'

type FeedbackState =
  | { kind: 'idle' }
  | { kind: 'checking' }
  | { kind: 'correct'; xp: number }
  | { kind: 'incorrect'; attempts: number }

type Props = {
  questions: Question[]
  onExit: () => void
  /**
   * Where the empty-state "Back" button goes. Defaults to onExit. Chapter
   * quizzes pass their journey-back handler so an unseeded topic returns the
   * student to the path they came from instead of the post-quiz standings.
   */
  onEmpty?: () => void
  /**
   * Optional celebratory interstitial title/subtitle. When the caller is a
   * chapter quiz, pass the chapter + module names — the ResultsCard then
   * triggers the ChapterCompletedSplash on Done instead of just exiting.
   */
  celebration?: {
    chapterName: string
    moduleName: string
    /** When true, finishing fires the splash; when false, plain Done. */
    enabled: boolean
  }
}

export function QuizFlow({ questions, onExit, onEmpty, celebration }: Props) {
  const [showSplash, setShowSplash] = useState(false)
  const [index, setIndex] = useState(0)
  const [selectedIds, setSelectedIds] = useState<string[]>([])
  const [shortAnswer, setShortAnswer] = useState('')
  const [rearrangeOrder, setRearrangeOrder] = useState<string[]>([])
  const [feedback, setFeedback] = useState<FeedbackState>({ kind: 'idle' })
  const [showHint, setShowHint] = useState(false)
  const [revealedExplanation, setRevealedExplanation] = useState(false)
  const [attempts, setAttempts] = useState(0)
  const [totalXp, setTotalXp] = useState(0)
  const [finished, setFinished] = useState(false)

  const question = questions[index]
  const total = questions.length
  const progress = total ? ((index + 1) / total) * 100 : 0

  // Reset per-question state when the index changes.
  useEffect(() => {
    setSelectedIds([])
    setShortAnswer('')
    setRearrangeOrder(question?.options.map((o) => o.id) ?? [])
    setFeedback({ kind: 'idle' })
    setShowHint(false)
    setRevealedExplanation(false)
    setAttempts(0)
  }, [index, question?.id])

  const hasAnswered = useMemo(() => {
    if (!question) return false
    if (question.type === 'short_answer') return shortAnswer.trim().length > 0
    if (question.type === 'rearrange') return rearrangeOrder.length > 0
    return selectedIds.length > 0
  }, [question, selectedIds, shortAnswer, rearrangeOrder])

  if (!question && !finished) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
        className="bg-white text-center mx-auto"
        style={{
          maxWidth: 460, padding: 48, borderRadius: 34,
          border: '1px solid #E7E7E7', boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
        }}
      >
        <div
          className="grid place-items-center mx-auto"
          style={{
            width: 88, height: 88, borderRadius: 24, marginBottom: 24,
            background: '#F4F6FC', border: `1px solid ${NAVY}22`,
          }}
        >
          <HelpCircle className="w-11 h-11" style={{ color: NAVY }} strokeWidth={1.5} />
        </div>
        <h2
          className="font-body"
          style={{ fontSize: 24, fontWeight: 700, color: TXT_DARK, lineHeight: '32px', margin: 0 }}
        >
          No quiz here yet
        </h2>
        <p
          className="font-body mx-auto"
          style={{ maxWidth: 360, marginTop: 10, fontSize: 16, fontWeight: 400, color: TXT_MID, lineHeight: '24px' }}
        >
          Questions for this topic haven&rsquo;t been added yet. Check back soon —
          new quizzes are added regularly.
        </p>
        <div className="flex justify-center" style={{ marginTop: 24 }}>
          <button
            type="button"
            onClick={onEmpty ?? onExit}
            className="flex items-center font-body"
            style={{
              gap: 8, padding: '14px 32px', borderRadius: 999,
              background: NAVY, color: '#fff', fontSize: 16, fontWeight: 700,
            }}
          >
            <ArrowRight className="w-4 h-4 rotate-180" strokeWidth={2.5} />
            Back
          </button>
        </div>
      </motion.div>
    )
  }

  if (finished) {
    const maxPossible = questions.length * 2  // best case = 2 XP per Q
    return (
      <>
        <ResultsCard
          xpEarned={totalXp}
          xpMax={maxPossible}
          onExit={() => {
            if (celebration?.enabled) {
              setShowSplash(true)
            } else {
              onExit()
            }
          }}
        />
        {showSplash && celebration?.enabled && (
          <ChapterCompletedSplash
            chapterName={celebration.chapterName}
            moduleName={celebration.moduleName}
            xpEarned={totalXp}
            onContinue={() => {
              setShowSplash(false)
              onExit()
            }}
          />
        )}
      </>
    )
  }

  // ---- option interaction ----
  const isLocked =
    feedback.kind === 'correct' || feedback.kind === 'checking'

  const toggleOption = (id: string) => {
    if (isLocked) return
    if (question.type === 'mcq_single') {
      setSelectedIds([id])
    } else {
      setSelectedIds((prev) =>
        prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
      )
    }
  }

  const moveRearrange = (id: string, dir: -1 | 1) => {
    if (isLocked) return
    setRearrangeOrder((arr) => {
      const i = arr.indexOf(id)
      if (i < 0) return arr
      const j = i + dir
      if (j < 0 || j >= arr.length) return arr
      const next = [...arr]
      ;[next[i], next[j]] = [next[j], next[i]]
      return next
    })
  }

  // ---- submit ----
  const submit = async () => {
    if (!hasAnswered) return
    const tries = attempts + 1
    setFeedback({ kind: 'checking' })
    const optionPayload =
      question.type === 'rearrange'
        ? rearrangeOrder
        : selectedIds

    const result = await checkAnswer(
      question,
      optionPayload,
      shortAnswer || undefined,
      tries,
    )

    if (result.isCorrect) {
      setTotalXp((x) => x + result.expAwarded)
      setFeedback({ kind: 'correct', xp: result.expAwarded })
    } else {
      const nextAttempts = attempts + 1
      setAttempts(nextAttempts)
      setFeedback({ kind: 'incorrect', attempts: nextAttempts })
      // Auto-open the hint on the first wrong attempt (docx #16).
      if (nextAttempts === 1 && question.hint) {
        setShowHint(true)
      }
      // After the 2nd miss the question is spent — surface the explanation so
      // the student sees why before moving to the next question.
      if (nextAttempts >= 2 && question.explanation) {
        setRevealedExplanation(true)
      }
    }
  }

  const goNext = () => {
    if (index + 1 >= total) setFinished(true)
    else setIndex((i) => i + 1)
  }

  const isChecking = feedback.kind === 'checking'
  const isCorrect = feedback.kind === 'correct'
  const isIncorrect = feedback.kind === 'incorrect'
  // After 2 failed attempts the question is spent (0 XP): reveal the answer and
  // let the student move on instead of trapping them on "Try again".
  const exhausted = isIncorrect && attempts >= 2
  const resolved = isCorrect || exhausted

  // Show the Why-button after 2 failed attempts (docx #16).
  const showWhyButton =
    isIncorrect && attempts >= 2 && !!question.explanation && !revealedExplanation

  return (
    <div className="flex flex-col" style={{ gap: 24 }}>
      {/* Progress + counter */}
      <div>
        <div className="flex items-center justify-between font-body">
          <span style={{ fontSize: 16, fontWeight: 700, color: NAVY, lineHeight: '22px' }}>
            Question {index + 1} of {total}
          </span>
          <span
            style={{ fontSize: 16, fontWeight: 600, color: TXT_MID, lineHeight: '22px' }}
          >
            {Math.round(progress)}%
          </span>
        </div>
        <div
          className="mt-2 overflow-hidden"
          style={{ height: 8, borderRadius: 14, background: '#F1F1F1' }}
        >
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${progress}%` }}
            transition={{ duration: 0.5, ease: 'easeOut' }}
            style={{ height: '100%', borderRadius: 14, background: CYAN }}
          />
        </div>
      </div>

      {/* Question card */}
      <AnimatePresence mode="wait">
        <motion.div
          key={question.id}
          initial={{ opacity: 0, x: 24 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -24 }}
          transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
          className="bg-white relative overflow-hidden"
          style={{
            borderRadius: 34, padding: '34px 34px 24px',
            boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
            border: '1px solid #E7E7E7',
          }}
        >
          {/* Tags */}
          <div className="flex flex-wrap items-center" style={{ gap: 8 }}>
            <span
              className="grid place-items-center"
              style={{
                background: NAVY, color: '#fff', borderRadius: 999,
                padding: '4px 12px',
                fontFamily: 'var(--font-body)',
                fontSize: 12, fontWeight: 700, letterSpacing: '0.06em',
                textTransform: 'uppercase',
              }}
            >
              {labelFor(question.type)}
            </span>
            <span
              className="grid place-items-center"
              style={{
                background: '#F1F1F1', color: TXT_MID, borderRadius: 999,
                padding: '4px 12px',
                fontFamily: 'var(--font-body)',
                fontSize: 12, fontWeight: 700, letterSpacing: '0.06em',
                textTransform: 'uppercase',
              }}
            >
              Up to 2 XP
            </span>
            {question.isHots && (
              <span
                className="grid place-items-center"
                style={{
                  background: '#F5D0FE', color: '#86198F', borderRadius: 999,
                  padding: '4px 12px',
                  fontFamily: 'var(--font-body)',
                  fontSize: 12, fontWeight: 700, letterSpacing: '0.06em',
                  textTransform: 'uppercase',
                }}
              >
                HOTS
              </span>
            )}
          </div>

          {/* Question text */}
          <h2
            className="font-body"
            style={{
              marginTop: 16, fontSize: 26, fontWeight: 700, color: TXT_DARK,
              lineHeight: '36px',
            }}
          >
            {question.text}
          </h2>

          {/* Optional question image */}
          {question.image && (
            <img
              src={question.image}
              alt=""
              className="block w-full"
              style={{
                marginTop: 16, maxHeight: 360, objectFit: 'contain',
                borderRadius: 16, background: '#F8FAFC',
              }}
            />
          )}

          {/* Answer area */}
          <div style={{ marginTop: 24 }}>
            {question.type === 'short_answer' && (
              <input
                type="text"
                value={shortAnswer}
                onChange={(e) => setShortAnswer(e.target.value)}
                disabled={isLocked}
                placeholder="Type your answer…"
                className="w-full font-body"
                style={{
                  height: 56, borderRadius: 16, padding: '0 18px',
                  border: `1px solid #E7E7E7`, background: '#F8FAFC',
                  fontSize: 18, color: TXT_DARK,
                  outline: 'none',
                }}
                onFocus={(e) => {
                  e.currentTarget.style.borderColor = CYAN
                  e.currentTarget.style.background = '#fff'
                }}
                onBlur={(e) => {
                  e.currentTarget.style.borderColor = '#E7E7E7'
                  e.currentTarget.style.background = '#F8FAFC'
                }}
              />
            )}

            {question.type === 'rearrange' && (
              <RearrangeList
                order={rearrangeOrder}
                options={question.options}
                disabled={isLocked}
                onMove={moveRearrange}
              />
            )}

            {(question.type === 'mcq_single' || question.type === 'mcq_multiple') && (
              <ul className="flex flex-col" style={{ gap: 12 }}>
                {question.options.map((o) => (
                  <OptionRow
                    key={o.id}
                    option={o}
                    selected={selectedIds.includes(o.id)}
                    disabled={isLocked}
                    multiSelect={question.type === 'mcq_multiple'}
                    feedback={
                      resolved && o.isCorrect
                        ? 'correct'
                        : isIncorrect && selectedIds.includes(o.id) && !o.isCorrect
                          ? 'incorrect'
                          : 'none'
                    }
                    onToggle={() => toggleOption(o.id)}
                  />
                ))}
              </ul>
            )}
          </div>

          {/* Hint card — auto-opens on first wrong attempt */}
          <AnimatePresence>
            {showHint && question.hint && (
              <motion.div
                key="hint"
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 8 }}
                className="flex items-start"
                style={{
                  marginTop: 20, gap: 12, padding: 16, borderRadius: 16,
                  background: '#FFF4D6', border: '1px solid #FFE48B',
                }}
              >
                <Lightbulb
                  className="w-5 h-5 shrink-0"
                  style={{ color: '#B45309', marginTop: 2 }}
                  strokeWidth={2.5}
                />
                <div className="flex flex-col flex-1" style={{ gap: 4 }}>
                  <span
                    className="font-body"
                    style={{
                      fontSize: 13, fontWeight: 700, color: '#92400E',
                      letterSpacing: '0.06em', textTransform: 'uppercase',
                    }}
                  >
                    Hint
                  </span>
                  <p
                    className="font-body"
                    style={{ fontSize: 16, fontWeight: 400, color: '#78350F', lineHeight: '24px', margin: 0 }}
                  >
                    {question.hint}
                  </p>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Why? button → reveals explanation after 2 fails */}
          <AnimatePresence>
            {showWhyButton && (
              <motion.div
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0 }}
                style={{ marginTop: 16 }}
              >
                <button
                  type="button"
                  onClick={() => setRevealedExplanation(true)}
                  className="flex items-center font-body"
                  style={{
                    gap: 8, padding: '10px 18px', borderRadius: 999,
                    background: '#fff', border: `1px solid ${NAVY}`, color: NAVY,
                    fontSize: 16, fontWeight: 700,
                  }}
                >
                  <HelpCircle className="w-4 h-4" strokeWidth={2.5} />
                  Why? Show the explanation
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          <AnimatePresence>
            {revealedExplanation && question.explanation && (
              <motion.div
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex items-start"
                style={{
                  marginTop: 16, gap: 12, padding: 16, borderRadius: 16,
                  background: '#E0E7FF', border: `1px solid #C7D2FE`,
                }}
              >
                <Sparkles
                  className="w-5 h-5 shrink-0"
                  style={{ color: NAVY, marginTop: 2 }}
                  strokeWidth={2.5}
                />
                <div className="flex flex-col flex-1" style={{ gap: 4 }}>
                  <span
                    className="font-body"
                    style={{
                      fontSize: 13, fontWeight: 700, color: NAVY,
                      letterSpacing: '0.06em', textTransform: 'uppercase',
                    }}
                  >
                    Explanation
                  </span>
                  <p
                    className="font-body"
                    style={{ fontSize: 16, fontWeight: 400, color: TXT_DARK, lineHeight: '24px', margin: 0 }}
                  >
                    {question.explanation}
                  </p>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Feedback banner — correct or incorrect */}
          <AnimatePresence>
            {isCorrect && <CorrectBanner xp={feedback.xp} />}
            {isIncorrect && (
              <IncorrectBanner
                attempts={feedback.attempts}
                hasExplanation={!!question.explanation}
                explanationRevealed={revealedExplanation}
                exhausted={exhausted}
              />
            )}
          </AnimatePresence>

          {/* Correct-answer overlay celebration */}
          <AnimatePresence>
            {isCorrect && <CorrectOverlay xp={feedback.xp} />}
          </AnimatePresence>
        </motion.div>
      </AnimatePresence>

      {/* Action bar */}
      <div
        className="flex items-center justify-between bg-white"
        style={{
          padding: 16, borderRadius: 24, gap: 12,
          boxShadow: '0 -4px 18px rgba(0,0,0,0.04)',
          border: '1px solid #E7E7E7',
        }}
      >
        <button
          type="button"
          onClick={onExit}
          className="font-body"
          style={{
            padding: '12px 18px', borderRadius: 999, color: TXT_MID,
            fontSize: 16, fontWeight: 600, background: 'transparent',
          }}
        >
          Exit
        </button>
        {!resolved ? (
          <motion.button
            type="button"
            onClick={submit}
            disabled={!hasAnswered || isChecking}
            whileTap={hasAnswered ? { scale: 0.96 } : undefined}
            className="grid place-items-center font-body disabled:cursor-not-allowed"
            style={{
              background: hasAnswered ? NAVY : '#CBD5E1', color: '#fff',
              borderRadius: 999, padding: '14px 32px', height: 52,
              fontSize: 18, fontWeight: 700,
              opacity: hasAnswered ? 1 : 0.7,
            }}
          >
            {isChecking ? 'Checking…' : isIncorrect ? 'Try again' : 'Check'}
          </motion.button>
        ) : (
          <motion.button
            type="button"
            onClick={goNext}
            whileTap={{ scale: 0.96 }}
            className="grid place-items-center font-body"
            style={{
              background: NAVY, color: '#fff',
              borderRadius: 999, padding: '14px 32px', height: 52,
              fontSize: 18, fontWeight: 700,
            }}
          >
            <span className="flex items-center" style={{ gap: 10 }}>
              {index + 1 >= total ? 'Finish' : 'Next'}
              <ArrowRight className="w-5 h-5" strokeWidth={2.5} />
            </span>
          </motion.button>
        )}
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
function labelFor(t: Question['type']): string {
  if (t === 'mcq_multiple') return 'Select all that apply'
  if (t === 'short_answer') return 'Short answer'
  if (t === 'rearrange')    return 'Rearrange'
  return 'Multiple choice'
}

// ---------------------------------------------------------------------------
function OptionRow({
  option, selected, disabled, multiSelect, feedback, onToggle,
}: {
  option: QuestionOption
  selected: boolean
  disabled: boolean
  multiSelect: boolean
  feedback: 'none' | 'correct' | 'incorrect'
  onToggle: () => void
}) {
  const border =
    feedback === 'correct' ? '#22C55E' :
    feedback === 'incorrect' ? '#FF3131' :
    selected ? NAVY : '#E7E7E7'
  const bg =
    feedback === 'correct' ? '#DCFCE7' :
    feedback === 'incorrect' ? '#FFE2E2' :
    selected ? '#F0F4FF' : '#fff'

  return (
    <li>
      <motion.button
        type="button"
        onClick={onToggle}
        disabled={disabled}
        whileTap={!disabled ? { scale: 0.99 } : undefined}
        className="flex items-center w-full font-body text-left disabled:cursor-not-allowed"
        style={{
          gap: 14, padding: '16px 20px', borderRadius: 18,
          border: `1.5px solid ${border}`, background: bg,
          transition: 'all 0.2s ease',
        }}
      >
        <span
          className="grid place-items-center shrink-0"
          style={{
            width: 24, height: 24,
            borderRadius: multiSelect ? 6 : 999,
            border: `2px solid ${
              feedback === 'correct' ? '#22C55E' :
              feedback === 'incorrect' ? '#FF3131' :
              selected ? NAVY : '#D4D4D8'
            }`,
            background:
              feedback === 'correct' ? '#22C55E' :
              feedback === 'incorrect' ? '#FF3131' :
              selected ? NAVY : '#fff',
            color: '#fff',
          }}
        >
          {feedback === 'correct'   ? <Check className="w-4 h-4" strokeWidth={3} /> :
           feedback === 'incorrect' ? <X     className="w-4 h-4" strokeWidth={3} /> :
           selected
             ? (multiSelect
                 ? <Check className="w-4 h-4" strokeWidth={3} />
                 : <span style={{ width: 9, height: 9, borderRadius: 999, background: '#fff' }} />)
             : null}
        </span>
        <span
          className="font-body"
          style={{ fontSize: 18, fontWeight: 500, color: TXT_DARK, lineHeight: '26px' }}
        >
          {option.optionText}
        </span>
      </motion.button>
    </li>
  )
}

// ---------------------------------------------------------------------------
function RearrangeList({
  order, options, disabled, onMove,
}: {
  order: string[]
  options: QuestionOption[]
  disabled: boolean
  onMove: (id: string, dir: -1 | 1) => void
}) {
  const byId = useMemo(() => {
    const m = new Map<string, QuestionOption>()
    for (const o of options) m.set(o.id, o)
    return m
  }, [options])

  return (
    <div className="flex flex-col" style={{ gap: 10 }}>
      <p
        className="font-body"
        style={{
          fontSize: 14, fontWeight: 600, color: TXT_MUTED,
          letterSpacing: '0.06em', textTransform: 'uppercase', margin: 0,
        }}
      >
        Use the arrows to put these in the correct order
      </p>
      <ul className="flex flex-col" style={{ gap: 10 }}>
        {order.map((id, idx) => {
          const o = byId.get(id)
          if (!o) return null
          return (
            <motion.li
              key={id}
              layout
              transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
              className="flex items-center bg-white"
              style={{
                gap: 14, padding: '14px 20px', borderRadius: 18,
                border: '1.5px solid #E7E7E7',
              }}
            >
              <span
                className="grid place-items-center font-body shrink-0"
                style={{
                  width: 36, height: 36, borderRadius: 999,
                  background: NAVY, color: '#fff',
                  fontSize: 18, fontWeight: 700,
                }}
              >
                {idx + 1}
              </span>
              <span
                className="font-body flex-1"
                style={{ fontSize: 18, fontWeight: 500, color: TXT_DARK, lineHeight: '26px' }}
              >
                {o.optionText}
              </span>
              <div className="flex flex-col" style={{ gap: 4 }}>
                <button
                  type="button"
                  aria-label="Move up"
                  disabled={disabled || idx === 0}
                  onClick={() => onMove(id, -1)}
                  className="grid place-items-center disabled:opacity-30"
                  style={{
                    width: 32, height: 28, borderRadius: 8,
                    background: '#F1F5F9', color: NAVY,
                  }}
                >
                  <ChevronUp className="w-4 h-4" strokeWidth={2.5} />
                </button>
                <button
                  type="button"
                  aria-label="Move down"
                  disabled={disabled || idx === order.length - 1}
                  onClick={() => onMove(id, 1)}
                  className="grid place-items-center disabled:opacity-30"
                  style={{
                    width: 32, height: 28, borderRadius: 8,
                    background: '#F1F5F9', color: NAVY,
                  }}
                >
                  <ChevronDown className="w-4 h-4" strokeWidth={2.5} />
                </button>
              </div>
            </motion.li>
          )
        })}
      </ul>
    </div>
  )
}

// ---------------------------------------------------------------------------
function CorrectBanner({ xp }: { xp: number }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0 }}
      className="flex items-start"
      style={{
        marginTop: 20, gap: 12, padding: 16, borderRadius: 16,
        background: '#DCFCE7', border: '1px solid #86EFAC',
      }}
    >
      <span
        className="grid place-items-center shrink-0"
        style={{
          width: 32, height: 32, borderRadius: 999,
          background: '#22C55E', color: '#fff',
        }}
      >
        <Check className="w-5 h-5" strokeWidth={3} />
      </span>
      <div>
        <div
          className="font-body"
          style={{ fontSize: 18, fontWeight: 700, color: '#15803D', lineHeight: '24px' }}
        >
          Correct! +{xp} XP
        </div>
        <div
          className="font-body"
          style={{ fontSize: 14, fontWeight: 400, color: '#166534', lineHeight: '20px' }}
        >
          {xp === 2 ? 'Nice — first try!' : xp === 1 ? 'Got it on the second try.' : 'Already answered before.'}
        </div>
      </div>
    </motion.div>
  )
}

function IncorrectBanner({
  attempts, hasExplanation, explanationRevealed, exhausted,
}: {
  attempts: number
  hasExplanation: boolean
  explanationRevealed: boolean
  exhausted: boolean
}) {
  // Pick copy that always lines up with the UI the user can actually see:
  // never tell them to hit Why? if there is no explanation OR they've
  // already revealed it.
  let copy: string
  if (exhausted) {
    copy = "That's 2 tries — the correct answer is highlighted in green. Tap Next to keep going."
  } else if (attempts === 1) {
    copy = hasExplanation
      ? 'Not quite — the hint just opened. Take another look and try again.'
      : 'Not quite — take another look and try again.'
  } else if (explanationRevealed) {
    copy = 'Still off. Re-read the explanation above and give it one more go.'
  } else if (hasExplanation) {
    copy = 'Still off. Hit "Why?" below to see the explanation.'
  } else {
    copy = 'Still off. Re-read the chapter and give it another try.'
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 8, x: 0 }}
      animate={{ opacity: 1, y: 0, x: [0, -6, 6, -4, 4, 0] }}
      exit={{ opacity: 0 }}
      transition={{ x: { duration: 0.4 } }}
      className="flex items-start"
      style={{
        marginTop: 20, gap: 12, padding: 16, borderRadius: 16,
        background: '#FFE2E2', border: '1px solid #FCA5A5',
      }}
    >
      <span
        className="grid place-items-center shrink-0"
        style={{
          width: 32, height: 32, borderRadius: 999,
          background: '#FF3131', color: '#fff',
        }}
      >
        <X className="w-5 h-5" strokeWidth={3} />
      </span>
      <div>
        <div
          className="font-body"
          style={{ fontSize: 18, fontWeight: 700, color: '#B91C1C', lineHeight: '24px' }}
        >
          {copy}
        </div>
      </div>
    </motion.div>
  )
}

// Confetti particle burst — 24 colored shards that fly outward and fade.
const CONFETTI = Array.from({ length: 24 }, (_, i) => {
  const angle = (i / 24) * Math.PI * 2
  const dist = 140 + (i % 4) * 40
  return {
    color: ['#22C55E', '#1ABCFE', '#00167A', '#F59E0B', '#7C3AED', '#FF3131'][i % 6],
    dx: Math.cos(angle) * dist,
    dy: Math.sin(angle) * dist,
    delay: (i % 6) * 0.02,
    rot: (i * 47) % 360,
  }
})

// Full-card celebration overlay on a correct answer — green check + XP bump
// + radiating confetti shards so it actually feels like a win.
function CorrectOverlay({ xp }: { xp: number }) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="pointer-events-none absolute inset-0 grid place-items-center overflow-hidden"
      style={{ background: 'radial-gradient(circle at 50% 40%, rgba(34,197,94,0.16), transparent 70%)' }}
    >
      {/* Confetti burst */}
      {CONFETTI.map((c, i) => (
        <motion.span
          key={i}
          className="absolute"
          style={{
            left: '50%', top: '45%',
            width: 10, height: 14, borderRadius: 2,
            background: c.color,
            transformOrigin: 'center',
          }}
          initial={{ x: 0, y: 0, opacity: 0, rotate: 0, scale: 0.6 }}
          animate={{
            x: c.dx, y: c.dy,
            opacity: [0, 1, 1, 0],
            rotate: c.rot,
            scale: [0.6, 1, 1, 0.8],
          }}
          transition={{ duration: 1.4, delay: c.delay, ease: 'easeOut' }}
        />
      ))}

      {/* Pulse ring behind the check */}
      <motion.span
        className="absolute"
        style={{
          width: 120, height: 120, borderRadius: 999,
          border: '4px solid rgba(34,197,94,0.55)',
        }}
        initial={{ scale: 0.4, opacity: 0.9 }}
        animate={{ scale: 1.9, opacity: 0 }}
        transition={{ duration: 1.0, ease: 'easeOut' }}
      />

      {/* Green check medallion */}
      <motion.div
        initial={{ scale: 0.4, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: 'spring', stiffness: 240, damping: 14 }}
        className="grid place-items-center"
        style={{
          width: 120, height: 120, borderRadius: 999,
          background: 'radial-gradient(circle at 32% 28%, #4ADE80 0%, #16A34A 70%)',
          boxShadow: '0 18px 40px rgba(22,163,74,0.4)',
        }}
      >
        <Check className="w-16 h-16" style={{ color: '#fff' }} strokeWidth={3} />
      </motion.div>

      {/* Floating XP number */}
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: [0, 1, 1, 0], y: [-8, -28, -36, -52] }}
        transition={{ delay: 0.2, duration: 1.4 }}
        className="absolute font-body"
        style={{
          top: 'calc(50% + 60px)',
          fontFamily: 'var(--font-numeric)',
          fontSize: 28, fontWeight: 900, color: '#15803D',
          textShadow: '0 2px 6px rgba(34,197,94,0.4)',
        }}
      >
        +{xp} XP
      </motion.div>
    </motion.div>
  )
}

// ---------------------------------------------------------------------------
function ResultsCard({
  xpEarned, xpMax, onExit,
}: {
  xpEarned: number; xpMax: number; onExit: () => void
}) {
  const pct = xpMax > 0 ? Math.round((xpEarned / xpMax) * 100) : 0
  const tone = pct >= 70 ? '#22C55E' : pct >= 50 ? '#F59E0B' : '#FF3131'
  const message =
    pct >= 70 ? 'Well done. Ready for the next chapter.'
    : pct >= 50 ? 'Solid attempt. Run through the chapter once more to push the score up.'
    : 'Have another look at the theory and try again.'

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
      className="bg-white text-center"
      style={{
        padding: 48, borderRadius: 34, border: '1px solid #E7E7E7',
        boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
      }}
    >
      <div
        className="font-body"
        style={{
          fontSize: 13, fontWeight: 700, color: TXT_MUTED,
          letterSpacing: '0.08em', textTransform: 'uppercase',
        }}
      >
        Quiz complete
      </div>
      <div
        style={{
          fontFamily: 'var(--font-numeric)',
          fontSize: 72, fontWeight: 900, color: tone,
          lineHeight: 1, marginTop: 12,
        }}
      >
        {pct}%
      </div>
      <div
        className="font-body"
        style={{ fontSize: 16, fontWeight: 400, color: TXT_MID, marginTop: 4 }}
      >
        {xpEarned} of {xpMax} XP earned
      </div>
      <p
        className="font-body mx-auto"
        style={{
          maxWidth: 380, marginTop: 20, fontSize: 16, fontWeight: 400,
          color: TXT_DARK, lineHeight: '24px',
        }}
      >
        {message}
      </p>
      <div className="flex justify-center" style={{ marginTop: 24 }}>
        <button
          type="button"
          onClick={onExit}
          className="flex items-center font-body"
          style={{
            gap: 8, padding: '14px 32px', borderRadius: 999,
            background: NAVY, color: '#fff',
            fontSize: 16, fontWeight: 700,
          }}
        >
          See standings <ArrowRight className="w-4 h-4" strokeWidth={2.5} />
        </button>
      </div>
    </motion.div>
  )
}

export function QuizErrorState({
  message, onRetry, onExit,
}: {
  message: string; onRetry: () => void; onExit: () => void
}) {
  return (
    <div className="grid place-items-center px-6 py-12 text-center">
      <AlertTriangle className="w-12 h-12" style={{ color: TXT_MUTED }} />
      <p
        className="font-body"
        style={{ marginTop: 12, fontSize: 16, color: TXT_DARK }}
      >
        {message}
      </p>
      <div className="flex" style={{ marginTop: 16, gap: 12 }}>
        <button
          type="button"
          onClick={onExit}
          className="font-body"
          style={{
            padding: '10px 20px', borderRadius: 999,
            background: '#fff', border: `1px solid ${NAVY}`, color: NAVY,
            fontSize: 16, fontWeight: 700,
          }}
        >
          Exit
        </button>
        <button
          type="button"
          onClick={onRetry}
          className="font-body"
          style={{
            padding: '10px 20px', borderRadius: 999,
            background: NAVY, color: '#fff',
            fontSize: 16, fontWeight: 700,
          }}
        >
          Retry
        </button>
      </div>
    </div>
  )
}
