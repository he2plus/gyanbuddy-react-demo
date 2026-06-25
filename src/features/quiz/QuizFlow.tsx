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
import { motion, AnimatePresence, useAnimationControls } from 'framer-motion'
import {
  Check, Ban, Lightbulb, ArrowRight, AlertTriangle,
  GripVertical, HelpCircle, Sparkles,
} from 'lucide-react'

import { checkAnswer } from '../../api/quiz'
import { ChapterCompletedSplash } from '../module/ChapterCompletedSplash'
import { Confetti } from '../../components/Confetti'
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
   * Called the moment the final question is finished. When provided, the quiz
   * navigates straight here (e.g. the class leaderboard) — no in-app results
   * card — to mirror the original Flutter flow, which pushes the student
   * directly to the standings/podium after the last question.
   */
  onComplete?: () => void
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

export function QuizFlow({ questions, onExit, onEmpty, onComplete, celebration }: Props) {
  const [showSplash, setShowSplash] = useState(false)
  const [index, setIndex] = useState(0)
  const [selectedIds, setSelectedIds] = useState<string[]>([])
  const [shortAnswer, setShortAnswer] = useState('')
  // Rearrange = tap-to-number (mirrors the Flutter app): the option ids the
  // student has tapped, in tap order. An id's 1-based position in this list is
  // its assigned order number; tapping a numbered option removes it and the
  // rest shift down. Options never physically move — only the badges change.
  const [rearrangeSeq, setRearrangeSeq] = useState<string[]>([])
  const [feedback, setFeedback] = useState<FeedbackState>({ kind: 'idle' })
  const [showHint, setShowHint] = useState(false)
  // Single-choice options the student has already tried and got wrong — they
  // grey out (eliminated) so the student re-picks, exactly like the original.
  const [eliminated, setEliminated] = useState<string[]>([])
  const [attempts, setAttempts] = useState(0)
  // Spent = answered wrong twice (the Flutter 2-attempt cap): the question
  // locks, the correct answer is revealed, and the explanation becomes available.
  const [exhausted, setExhausted] = useState(false)
  const [revealedExplanation, setRevealedExplanation] = useState(false)
  const [apiExplanation, setApiExplanation] = useState<string | null>(null)
  const [totalXp, setTotalXp] = useState(0)
  const [finished, setFinished] = useState(false)
  const [showConfetti, setShowConfetti] = useState(false)

  const cardControls = useAnimationControls()
  const triggerShake = () =>
    cardControls.start({
      x: [0, -10, 10, -8, 8, -4, 4, 0],
      transition: { duration: 0.45, ease: 'easeInOut' },
    })

  const question = questions[index]
  const total = questions.length
  // Progress bar starts at 0 and advances only when moving to the next question.
  const progress = total ? (index / total) * 100 : 0

  // Reset per-question state + replay the slide-in entrance when the index
  // changes (mirrors the original's question whoosh / staggered entrance).
  useEffect(() => {
    setSelectedIds([])
    setShortAnswer('')
    setRearrangeSeq([])
    setFeedback({ kind: 'idle' })
    setShowHint(false)
    setEliminated([])
    setAttempts(0)
    setExhausted(false)
    setRevealedExplanation(false)
    setApiExplanation(null)
    setShowConfetti(false)
    cardControls.set({ opacity: 0, x: 24 })
    cardControls.start({ opacity: 1, x: 0, transition: { duration: 0.3, ease: [0.22, 1, 0.36, 1] } })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [index, question?.id])

  const hasAnswered = useMemo(() => {
    if (!question) return false
    if (question.type === 'short_answer') return shortAnswer.trim().length > 0
    // Rearrange is answerable only once EVERY option has a number (matches the
    // Flutter rule `_rearrangeOrder.length == _answers.length`).
    if (question.type === 'rearrange') return rearrangeSeq.length === question.options.length
    return selectedIds.length > 0
  }, [question, selectedIds, shortAnswer, rearrangeSeq])

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
    feedback.kind === 'correct' || feedback.kind === 'checking' || exhausted

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

  // Tap-to-number: tapping an un-numbered option appends it (gets the next
  // order); tapping a numbered one removes it and the rest shift down.
  const toggleRearrange = (id: string) => {
    if (isLocked) return
    setRearrangeSeq((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
    )
  }

  // ---- submit ----
  const submit = async () => {
    if (!hasAnswered || isLocked) return
    const tries = attempts + 1
    setAttempts(tries)
    setFeedback({ kind: 'checking' })
    const optionPayload =
      question.type === 'rearrange'
        ? rearrangeSeq
        : selectedIds

    const result = await checkAnswer(
      question,
      optionPayload,
      shortAnswer || undefined,
      tries,
      index === total - 1,   // is_last → backend completes the chapter & advances the next
    )
    if (result.explanation) setApiExplanation(result.explanation)

    if (result.isCorrect) {
      // XP is computed CLIENT-SIDE exactly like the Flutter app — 2 on the 1st
      // attempt, 1 on the 2nd, 0 after — independent of the backend's exp field
      // (which returns 0 when re-doing an already-finished chapter).
      const xp = tries <= 1 ? 2 : tries === 2 ? 1 : 0
      setTotalXp((x) => x + xp)
      setFeedback({ kind: 'correct', xp })
      // Play once, then force-dismiss after the original's 1600ms.
      setShowConfetti(true)
      window.setTimeout(() => setShowConfetti(false), 1600)
    } else {
      triggerShake()
      if (question.hint) setShowHint(true)
      if (question.type === 'mcq_single') {
        // Grey out (eliminate) the wrong pick either way.
        setEliminated((prev) => [...prev, ...selectedIds])
      }
      if (tries >= 2) {
        // Second wrong attempt → the Flutter 2-attempt cap kicks in: lock the
        // question, reveal the correct answer (green), and offer the explanation.
        setExhausted(true)
        setFeedback({ kind: 'idle' })
      } else {
        // First wrong attempt → auto-hint, clear the selection, let them retry.
        if (question.type === 'mcq_single') setSelectedIds([])
        setFeedback({ kind: 'idle' })
      }
    }
  }

  const goNext = () => {
    if (index + 1 >= total) {
      // Original flow: the last question drops the student straight onto the
      // leaderboard. Only fall back to the in-app ResultsCard when no direct
      // completion handler is supplied (e.g. tests that show a score summary).
      if (onComplete) onComplete()
      else setFinished(true)
    } else {
      setIndex((i) => i + 1)
    }
  }

  const isChecking = feedback.kind === 'checking'
  const isCorrect = feedback.kind === 'correct'
  // "Resolved" = the question is done: either answered correctly, or spent after
  // two wrong attempts. Both reveal the green answer and switch Check → Next.
  const resolved = isCorrect || exhausted
  const explanationText = question.explanation ?? apiExplanation

  return (
    <div className="flex flex-col" style={{ gap: 24 }}>
      <Confetti play={showConfetti} />
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

      {/* Question card — controls drive both the slide-in entrance and the
          shake on a wrong answer. */}
      <motion.div
        initial={{ opacity: 0, x: 24 }}
        animate={cardControls}
        className="bg-white relative overflow-hidden"
        style={{
          borderRadius: 34, padding: '34px 34px 24px',
          boxShadow: '0 4px 18px rgba(0,0,0,0.04)',
          border: '1px solid #E7E7E7',
        }}
      >
          {/* Question type tag + hint lamp */}
          <div className="flex items-center justify-between" style={{ gap: 8 }}>
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
            {question.hint && (
              <button
                type="button"
                onClick={() => {
                  if (attempts === 0) return
                  setShowHint((s) => !s)
                }}
                disabled={attempts === 0}
                aria-label="Show hint"
                title={attempts === 0 ? 'Hint unlocks after your first try' : 'Hint'}
                className="grid place-items-center shrink-0"
                style={{
                  width: 40, height: 40, borderRadius: 999,
                  background: '#FFF4D6', border: '1px solid #FFE48B',
                  opacity: attempts === 0 ? 0.45 : 1,
                  cursor: attempts === 0 ? 'not-allowed' : 'pointer',
                }}
              >
                <img src="/images/lamp.png" alt="" style={{ width: 22, height: 22, objectFit: 'contain' }} />
              </button>
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
                options={question.options}
                seq={rearrangeSeq}
                disabled={isLocked}
                resolved={resolved}
                onToggle={toggleRearrange}
              />
            )}

            {(question.type === 'mcq_single' || question.type === 'mcq_multiple') && (
              <ul className="flex flex-col" style={{ gap: 12 }}>
                {question.options.map((o) => (
                  <OptionRow
                    key={o.id}
                    option={o}
                    selected={selectedIds.includes(o.id)}
                    disabled={isLocked || eliminated.includes(o.id)}
                    eliminated={eliminated.includes(o.id)}
                    multiSelect={question.type === 'mcq_multiple'}
                    feedback={resolved && o.isCorrect ? 'correct' : 'none'}
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

          {/* Why? → reveal the explanation, only after the 2nd wrong attempt
              (the Flutter "Why?" button on the incorrect panel). */}
          <AnimatePresence>
            {exhausted && explanationText && !revealedExplanation && (
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
            {revealedExplanation && explanationText && (
              <motion.div
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex items-start"
                style={{
                  marginTop: 16, gap: 12, padding: 16, borderRadius: 16,
                  background: '#E0E7FF', border: '1px solid #C7D2FE',
                }}
              >
                <Sparkles className="w-5 h-5 shrink-0" style={{ color: NAVY, marginTop: 2 }} strokeWidth={2.5} />
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
                    {explanationText}
                  </p>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Correct-answer banner — a wrong answer just shakes + hints. */}
          <AnimatePresence>
            {isCorrect && <CorrectBanner xp={feedback.xp} />}
          </AnimatePresence>
      </motion.div>

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
            {isChecking ? 'Checking…' : 'Check'}
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
  option, selected, disabled, eliminated, multiSelect, feedback, onToggle,
}: {
  option: QuestionOption
  selected: boolean
  disabled: boolean
  /** Already-tried wrong single-choice option — greyed out, not clickable. */
  eliminated: boolean
  multiSelect: boolean
  feedback: 'none' | 'correct'
  onToggle: () => void
}) {
  // When the question is exhausted (2 wrong attempts), show the last picked
  // option in red so the student can see what they chose vs the correct answer.
  const wasLastPick = selected && eliminated
  const border =
    feedback === 'correct' ? '#22C55E' :
    wasLastPick ? '#FF3131' :
    eliminated ? '#E7E7E7' :
    selected ? NAVY : '#E7E7E7'
  const bg =
    feedback === 'correct' ? '#DCFCE7' :
    wasLastPick ? '#FFF1F1' :
    eliminated ? '#F4F4F5' :
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
          opacity: (eliminated && !wasLastPick) ? 0.5 : 1,
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
              wasLastPick ? '#FF3131' :
              eliminated ? '#C4C4CC' :
              selected ? NAVY : '#D4D4D8'
            }`,
            background:
              feedback === 'correct' ? '#22C55E' :
              wasLastPick ? '#FF3131' :
              selected && !eliminated ? NAVY : '#fff',
            color: '#fff',
          }}
        >
          {feedback === 'correct' ? <Check className="w-4 h-4" strokeWidth={3} /> :
           wasLastPick ? <Ban className="w-3.5 h-3.5" strokeWidth={2.5} /> :
           eliminated ? <Ban className="w-3.5 h-3.5" style={{ color: '#A1A1AA' }} strokeWidth={2.5} /> :
           selected
             ? (multiSelect
                 ? <Check className="w-4 h-4" strokeWidth={3} />
                 : <span style={{ width: 9, height: 9, borderRadius: 999, background: '#fff' }} />)
             : null}
        </span>
        <span
          className="font-body"
          style={{
            fontSize: 18, fontWeight: 500, lineHeight: '26px',
            color: eliminated ? TXT_MUTED : TXT_DARK,
          }}
        >
          {option.optionText}
        </span>
      </motion.button>
    </li>
  )
}

// ---------------------------------------------------------------------------
// Rearrange = tap-to-number, exactly like the Flutter app. Options stay in a
// fixed position; tapping one assigns it the next order number (badge), tapping
// it again clears it and the rest renumber. No dragging, no arrows.
function RearrangeList({
  options, seq, disabled, resolved, onToggle,
}: {
  options: QuestionOption[]
  /** Option ids in tap order — index + 1 is the assigned number. */
  seq: string[]
  disabled: boolean
  /** Answered correctly — every row turns green. */
  resolved: boolean
  onToggle: (id: string) => void
}) {
  return (
    <div className="flex flex-col" style={{ gap: 10 }}>
      <p
        className="font-body"
        style={{
          fontSize: 14, fontWeight: 600, color: TXT_MUTED,
          letterSpacing: '0.06em', textTransform: 'uppercase', margin: 0,
        }}
      >
        Tap the options in the correct order
      </p>
      <ul className="flex flex-col" style={{ gap: 12 }}>
        {options.map((o) => {
          const pos = seq.indexOf(o.id)
          const selected = pos >= 0
          const number = pos + 1
          const green = resolved

          const border = green ? '#22C55E' : selected ? NAVY : '#E7E7E7'
          const bg = green ? '#DCFCE7' : selected ? '#F0F4FF' : '#fff'
          const badgeBg = green ? '#22C55E' : selected ? NAVY : '#F1F1F1'

          return (
            <li key={o.id}>
              <motion.button
                type="button"
                onClick={() => onToggle(o.id)}
                disabled={disabled}
                whileTap={!disabled ? { scale: 0.99 } : undefined}
                className="flex items-center w-full font-body text-left disabled:cursor-not-allowed"
                style={{
                  gap: 14, padding: '16px 20px', borderRadius: 18,
                  border: `1.5px solid ${border}`, background: bg,
                  boxShadow: (selected || green)
                    ? `0 4px 12px ${green ? 'rgba(34,197,94,0.18)' : 'rgba(0,22,122,0.14)'}`
                    : 'none',
                  transition: 'all 0.2s ease',
                }}
              >
                {/* Order badge — number when selected, grip icon otherwise */}
                <span
                  className="grid place-items-center shrink-0"
                  style={{
                    width: 32, height: 32, borderRadius: 10,
                    background: badgeBg, color: '#fff',
                  }}
                >
                  {selected || green ? (
                    <span
                      className="font-body tabular-nums"
                      style={{ fontSize: 15, fontWeight: 700, lineHeight: 1 }}
                    >
                      {number}
                    </span>
                  ) : (
                    <GripVertical className="w-4 h-4" style={{ color: '#9CA3AF' }} strokeWidth={2} />
                  )}
                </span>
                <span
                  className="font-body flex-1"
                  style={{
                    fontSize: 18, fontWeight: 500, lineHeight: '26px',
                    color: green ? '#15803D' : TXT_DARK,
                  }}
                >
                  {o.optionText}
                </span>
              </motion.button>
            </li>
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
      <div
        className="font-body"
        style={{ fontSize: 18, fontWeight: 700, color: '#15803D', lineHeight: '32px' }}
      >
        Correct! +{xp} XP
      </div>
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
