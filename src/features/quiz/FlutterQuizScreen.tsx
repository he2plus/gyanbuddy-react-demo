/**
 * FlutterQuizScreen — faithful React port of lib/screens/quiz/quiz_screen.dart
 *
 * Rules matched exactly from the Flutter source:
 *
 * 1. MCQ types (single/multiple/rearrange) are checked CLIENT-SIDE immediately
 *    (using option.isCorrect). The backend call fires in background when Continue
 *    is pressed — exactly like the Flutter _trackAnswerInBackground pattern.
 *    Short answer is STILL server-checked (no local oracle).
 *
 * 2. Attempt cap = 2 (Flutter constant). First wrong → hint auto-opens, wrong
 *    option greys out (disabled), selection clears so user can retry.
 *    Second wrong → showIncorrect bar with "Why?" and "Continue".
 *
 * 3. XP: tries=1 → +2 XP, tries=2 → +1 XP, else → 0 XP (matches _earnedXpForCurrentAttempt)
 *
 * 4. Short-answer: clears the text input after the first wrong attempt.
 *
 * 5. Hint button: disabled (opacity 0.45) until the user has made at least
 *    one attempt (_tries == 0 → ignore pointer).
 *
 * 6. Progress bar: fraction = completedCount / totalMain. Starts at 0, fills
 *    left as the student finishes each question (NOT the current index).
 *
 * 7. Continue debounce: a boolean flag prevents double-taps.
 *
 * 8. HOTS flow: after all main questions, if hotsQuestions is non-empty, the
 *    header dots count through 3 steps (matching Flutter's row of 3 dots).
 *    After all HOTS done → onComplete / onExit.
 *
 * 9. Option shuffle: randomised once per question using the same _shuffleOptions
 *    approach. Shuffle is stable across re-renders for that question.
 *
 * 10. "Why?" opens a bottom-sheet modal with the explanation text, matching
 *     Flutter's _showExplanationModal() pattern exactly.
 *
 * Colors: 1-to-1 from _hexToColor calls in quiz_screen.dart.
 */

import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { motion, AnimatePresence, useAnimationControls } from 'framer-motion'
import { X, Flag } from 'lucide-react'
import { Confetti } from '../../components/Confetti'
import { checkAnswer } from '../../api/quiz'
import type { Question, QuestionOption } from '../../types/question'

// ─── Flutter colour palette ───────────────────────────────────────────────────
const C = {
  headerBg:            '#FFFCFC',
  checkInactive:       '#F2F2F2',
  checkInactiveText:   '#999999',
  checkActive:         '#2D2D2D',
  continueGreen:       '#29CC57',
  continueDark:        '#1F9940',
  successBg:           '#E8F5E9',
  incorrectBg:         '#FFF9C4',
  whyBtn:              '#D9D9D9',
  whyBorder:           '#BFBFBF',
  continueLightBg:     '#E5E5E5',
  continueLightBorder: '#CCCCCC',
  optionSelected:      '#E3F2FD',
  optionSelectedBorder:'#2196F3',
  optionCorrect:       '#E8F5E9',
  optionCorrectBorder: '#4CAF50',
  optionDisabled:      '#F5F5F5',
  optionDisabledBorder:'#BDBDBD',
  xpGreen:             '#22C55E',
  progressGreen:       '#4CAF50',
}

// ─── Types ────────────────────────────────────────────────────────────────────
export type FlutterQuizScreenProps = {
  questions: Question[]
  /** Subject hex colour (e.g. "#3B82F6"). Tints the question-type badge. */
  subjectColor?: string
  onExit: () => void
  onComplete?: () => void | Promise<void>
  onEmpty?: () => void
  /** HOTS questions appended after the main set (mirrors Flutter `hasHots`). */
  hotsQuestions?: Question[]
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
function hexToRgba(hex: string, alpha: number) {
  const h = hex.replace('#', '')
  const r = parseInt(h.slice(0, 2), 16)
  const g = parseInt(h.slice(2, 4), 16)
  const b = parseInt(h.slice(4, 6), 16)
  return `rgba(${r},${g},${b},${alpha})`
}

function shuffleArray<T>(arr: T[]): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

function questionTypeLabel(type: Question['type']): string {
  if (type === 'mcq_multiple') return 'Select all that apply'
  if (type === 'short_answer') return 'Short answer'
  if (type === 'rearrange')    return 'Rearrange'
  return 'Multiple choice'
}

// ─── Main component ──────────────────────────────────────────────────────────
export function FlutterQuizScreen({
  questions,
  subjectColor = '#2196F3',
  onExit,
  onComplete,
  onEmpty,
  hotsQuestions = [],
}: FlutterQuizScreenProps) {

  // ── navigation ──
  const [mainIndex,    setMainIndex]    = useState(0)
  const [isShowingHots, setIsShowingHots] = useState(false)
  const [hotsIndex,    setHotsIndex]    = useState(0)
  // count of main questions fully answered (used for progress bar)
  const [completed,    setCompleted]    = useState(0)

  // ── per-question answer state ──
  const [selectedIndex,   setSelectedIndex]   = useState<number | null>(null)
  const [selectedIndices, setSelectedIndices] = useState<Set<number>>(new Set())
  const [shortAnswer,     setShortAnswer]     = useState('')
  // tap-to-order: array of actual option indices in tap order
  const [rearrangeSeq,    setRearrangeSeq]    = useState<number[]>([])
  // shuffled display order — stable per question (re-shuffled on id change)
  const [shuffledIndices, setShuffledIndices] = useState<number[]>([])

  // ── feedback state ──
  const [tries,           setTries]           = useState(0)
  const [disabledIndices, setDisabledIndices] = useState<Set<number>>(new Set())
  const [showSuccess,     setShowSuccess]     = useState(false)
  const [showIncorrect,   setShowIncorrect]   = useState(false)
  const [showHint,        setShowHint]        = useState(false)
  const [showExplModal,   setShowExplModal]   = useState(false)
  const [showConfetti,    setShowConfetti]    = useState(false)
  const [earnedXp,        setEarnedXp]        = useState(0)
  const [isChecking,      setIsChecking]      = useState(false) // short_answer API wait

  // ── button 3-D press states (matches Flutter GestureDetector onTapDown/Up) ──
  const [checkPressed,    setCheckPressed]    = useState(false)
  const [continuePressed, setContinuePressed] = useState(false)
  const [whyPressed,      setWhyPressed]      = useState(false)
  const [tryAgainPressed, setTryAgainPressed] = useState(false)

  // ── debounce: prevent double-tap on Continue (Flutter _isProcessingContinue) ──
  const processingContinue = useRef(false)

  // ── animation ──
  const cardControls = useAnimationControls()
  const triggerShake = useCallback(() =>
    cardControls.start({
      x: [0, -10, 10, -8, 8, -4, 4, 0],
      transition: { duration: 0.45, ease: 'easeInOut' },
    }), [cardControls])

  // ─── Current question ───────────────────────────────────────────────────────
  const allQs   = isShowingHots ? hotsQuestions : questions
  const curIdx  = isShowingHots ? hotsIndex     : mainIndex
  const question = allQs[curIdx] ?? null
  const totalMain = questions.length

  // ─── Shuffle options when question id changes (stable per question) ─────────
  useEffect(() => {
    if (!question) return
    setShuffledIndices(shuffleArray(question.options.map((_, i) => i)))
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [question?.id])

  // ─── Reset per-question state + slide-in animation ─────────────────────────
  useEffect(() => {
    setSelectedIndex(null)
    setSelectedIndices(new Set())
    setShortAnswer('')
    setRearrangeSeq([])
    setTries(0)
    setDisabledIndices(new Set())
    setShowSuccess(false)
    setShowIncorrect(false)
    setShowHint(false)
    setShowConfetti(false)
    setIsChecking(false)
    setCheckPressed(false)
    setContinuePressed(false)
    setWhyPressed(false)
    setTryAgainPressed(false)
    processingContinue.current = false

    // Question slides in from left — matches Flutter _questionController (left→0)
    cardControls.set({ opacity: 0, x: -30 })
    cardControls.start({
      opacity: 1, x: 0,
      transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] },
    })
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [question?.id])

  // ─── Answer presence guard (matches Flutter _hasAnswerSelected) ────────────
  const hasAnswer = useMemo(() => {
    if (!question) return false
    if (question.type === 'short_answer') return shortAnswer.trim().length > 0
    if (question.type === 'rearrange')    return rearrangeSeq.length === question.options.length
    if (question.type === 'mcq_multiple') return selectedIndices.size > 0
    return selectedIndex !== null
  }, [question, selectedIndex, selectedIndices, shortAnswer, rearrangeSeq])

  // ─── Correct indices (derived from option.isCorrect) ───────────────────────
  const correctIndices = useMemo(() =>
    (question?.options ?? []).reduce<number[]>((acc, o, i) => {
      if (o.isCorrect) acc.push(i)
      return acc
    }, []),
  [question?.id]) // eslint-disable-line react-hooks/exhaustive-deps

  // Rearrange: correct sequence = options sorted by their `.order` field
  const correctRearrangeIndices = useMemo(() => {
    if (!question) return []
    return [...question.options.entries()]
      .sort((a, b) => a[1].order - b[1].order || a[0] - b[0])
      .map(([i]) => i)
  }, [question?.id]) // eslint-disable-line react-hooks/exhaustive-deps

  const isRearrangeCorrect = useMemo(() => {
    if (!question || rearrangeSeq.length !== question.options.length) return false
    return rearrangeSeq.every((idx, pos) => idx === correctRearrangeIndices[pos])
  }, [rearrangeSeq, correctRearrangeIndices, question?.options.length])

  // ─── Option toggle handlers ─────────────────────────────────────────────────
  const toggleSingle = (actualIdx: number) => {
    if (showSuccess || showIncorrect || disabledIndices.has(actualIdx)) return
    setSelectedIndex(actualIdx)
  }
  const toggleMulti = (actualIdx: number) => {
    if (showSuccess || showIncorrect || disabledIndices.has(actualIdx)) return
    setSelectedIndices((prev) => {
      const next = new Set(prev)
      if (next.has(actualIdx)) next.delete(actualIdx); else next.add(actualIdx)
      return next
    })
  }
  const toggleRearrange = (actualIdx: number) => {
    if (showSuccess || showIncorrect) return
    setRearrangeSeq((prev) =>
      prev.includes(actualIdx) ? prev.filter((x) => x !== actualIdx) : [...prev, actualIdx],
    )
  }

  // ─── Submit handler ────────────────────────────────────────────────────────
  // Flutter behaviour (CRITICAL):
  //   MCQ types → client-side check FIRST (instant), API fires in background.
  //   Short answer → awaits API (no local oracle).
  const handleCheck = async () => {
    if (!question || !hasAnswer || showSuccess || showIncorrect || isChecking) return

    const attempt = tries + 1
    setTries(attempt)

    const optionIds =
      question.type === 'rearrange'
        ? rearrangeSeq.map((i) => question.options[i].id)
        : question.type === 'mcq_multiple' || question.type === 'mcq_single'
        ? (question.type === 'mcq_single'
            ? selectedIndex !== null ? [question.options[selectedIndex].id] : []
            : [...selectedIndices].map((i) => question.options[i].id))
        : []

    const isLast = !isShowingHots && mainIndex >= totalMain - 1

    let isCorrect = false

    if (question.type === 'short_answer') {
      // ── server-checked (must await) ────────────────────────────────────────
      setIsChecking(true)
      try {
        const result = await checkAnswer(question, [], shortAnswer, attempt, isLast)
        isCorrect = result.isCorrect
      } catch {
        // Unreachable on real backend; mock fallback
        const target = question.options.find((o) => o.isCorrect)?.optionText?.trim().toLowerCase() ?? ''
        isCorrect = shortAnswer.trim().toLowerCase() === target
      } finally {
        setIsChecking(false)
      }
    } else {
      // ── client-side check (instant, like Flutter) ──────────────────────────
      if (question.type === 'rearrange') {
        isCorrect = isRearrangeCorrect
      } else if (question.type === 'mcq_multiple') {
        const correctSet = new Set(correctIndices)
        isCorrect =
          correctSet.size === selectedIndices.size &&
          [...selectedIndices].every((i) => correctSet.has(i))
      } else {
        isCorrect = selectedIndex !== null && correctIndices.includes(selectedIndex)
      }
      // Fire-and-forget API tracking (background, does NOT block UI)
      checkAnswer(question, optionIds, undefined, attempt, isLast).catch(() => undefined)
    }

    if (isCorrect) {
      const xp = attempt <= 1 ? 2 : attempt === 2 ? 1 : 0
      setEarnedXp(xp)
      setShowSuccess(true)
      setShowConfetti(true)
      window.setTimeout(() => setShowConfetti(false), 1600)
    } else {
      void triggerShake()
      if (question.hint) setShowHint(true)

      if (attempt < 2) {
        // ── first wrong attempt ──────────────────────────────────────────────
        // Disable wrong options, clear selection, let them retry (no incorrect bar)
        if (question.type === 'mcq_single' && selectedIndex !== null) {
          setDisabledIndices((prev) => new Set([...prev, selectedIndex]))
          setSelectedIndex(null)
        } else if (question.type === 'mcq_multiple') {
          const wrongOnes = [...selectedIndices].filter((i) => !correctIndices.includes(i))
          setDisabledIndices((prev) => new Set([...prev, ...wrongOnes]))
          setSelectedIndices(new Set())
        } else if (question.type === 'rearrange') {
          setRearrangeSeq([])
        } else if (question.type === 'short_answer') {
          // Flutter clears the text field after first wrong short-answer attempt
          setShortAnswer('')
        }
      } else {
        // ── second wrong attempt → show incorrect bar ────────────────────────
        setShowIncorrect(true)
      }
    }
  }

  // ─── Advance to next question (Continue pressed) ───────────────────────────
  // Flutter's debounce: _isProcessingContinue flag (ref so no re-render).
  const advance = () => {
    if (processingContinue.current) return
    processingContinue.current = true

    if (isShowingHots) {
      if (hotsIndex >= hotsQuestions.length - 1) {
        void (onComplete?.() ?? Promise.resolve())
        void onExit()
      } else {
        setHotsIndex((i) => i + 1)
      }
      return
    }

    if (mainIndex >= totalMain - 1) {
      // Last main question finished
      setCompleted((c) => c + 1)
      if (hotsQuestions.length > 0) {
        setIsShowingHots(true)
        setHotsIndex(0)
      } else {
        if (onComplete) void onComplete()
        else onExit()
      }
    } else {
      setCompleted((c) => c + 1)
      setMainIndex((i) => i + 1)
    }
  }

  // ─── Empty state ─────────────────────────────────────────────────────────
  if (!question) {
    return (
      <div
        className="flex flex-col items-center justify-center min-h-screen bg-white"
        style={{ padding: '40px 24px' }}
      >
        <div style={{ fontSize: 48, marginBottom: 16 }}>📚</div>
        <p style={{ fontSize: 18, color: '#444', textAlign: 'center', margin: 0 }}>
          No questions available yet. Check back soon!
        </p>
        <button
          type="button"
          onClick={onEmpty ?? onExit}
          style={{
            marginTop: 24, padding: '14px 32px', borderRadius: 28,
            background: C.checkActive, color: '#fff',
            fontSize: 16, fontWeight: 600, border: 'none', cursor: 'pointer',
          }}
        >
          Go back
        </button>
      </div>
    )
  }

  const isLocked = showSuccess || showIncorrect
  const subjectBg   = hexToRgba(subjectColor, 0.15)
  const subjectBdr  = hexToRgba(subjectColor, 0.3)
  // Progress: completed / totalMain  (Flutter: _currentQuestionIndex / widget.questions.length)
  const progress = totalMain > 0 ? completed / totalMain : 0

  return (
    <div
      className="flex flex-col"
      style={{ minHeight: '100vh', background: '#fff', width: '100%' }}
    >
      <Confetti play={showConfetti} />

      {/* ── Header ─────────────────────────────────────────────────────────── */}
      <div
        style={{
          background: C.headerBg,
          borderBottom: '1px solid #E5E5E5',
          flexShrink: 0,
        }}
      >
        <div
          className="flex items-center"
          style={{
            gap: 12,
            maxWidth: 900,
            margin: '0 auto',
            padding: '12px clamp(16px, 4vw, 40px)',
          }}
        >
          {/* Circular close button */}
          <button
            type="button"
            onClick={onExit}
            aria-label="Close quiz"
            style={{
              width: 36, height: 36, borderRadius: '50%',
              background: '#F3F3F3', border: 'none',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer', flexShrink: 0,
            }}
          >
            <X size={18} color="#000" strokeWidth={2.5} />
          </button>

          {/* Animated progress bar */}
          <div
            className="flex-1"
            style={{ height: 12, borderRadius: 6, background: '#E0E0E0', overflow: 'hidden' }}
          >
            <motion.div
              animate={{ width: `${progress * 100}%` }}
              transition={{ duration: 0.8, ease: 'easeOut' }}
              style={{ height: '100%', borderRadius: 6, background: C.progressGreen }}
            />
          </div>

          {/* HOTS progress dots — 3 pills, orange when reached */}
          {hotsQuestions.length > 0 && (
            <div className="flex" style={{ gap: 2, flexShrink: 0 }}>
              {[0, 1, 2].map((i) => (
                <div
                  key={i}
                  style={{
                    width: 18, height: 12, borderRadius: 6,
                    background: isShowingHots && i <= hotsIndex ? '#FF9800' : '#E0E0E0',
                    transition: 'background 0.3s',
                  }}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── Scrollable question area ────────────────────────────────────────── */}
      <div className="flex-1 overflow-y-auto" style={{ position: 'relative' }}>
        <div
          style={{
            maxWidth: 900,
            margin: '0 auto',
            padding: '8px 0 0',
            position: 'relative',
          }}
        >

          {/* Flag + Hint icons — top-right, absolutely positioned */}
          <div
            style={{
              position: 'absolute', top: 8, right: 'clamp(16px, 4vw, 40px)', zIndex: 10,
              display: 'flex', gap: 8,
            }}
          >
            <button
              type="button"
              aria-label="Report question"
              style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }}
            >
              <Flag size={20} color="#9E9E9E" strokeWidth={1.5} />
            </button>

            {/* Hint lamp — disabled (opacity 0.45) until first attempt */}
            {question.hint && (
              <button
                type="button"
                aria-label="Show hint"
                disabled={tries === 0}
                onClick={() => { if (tries > 0) setShowHint((s) => !s) }}
                style={{
                  background: 'none', border: 'none',
                  cursor: tries === 0 ? 'default' : 'pointer',
                  opacity: tries === 0 ? 0.45 : 1, padding: 4,
                }}
              >
                <img
                  src="/images/lamp.png"
                  alt="Hint"
                  width={24} height={24}
                  style={{ objectFit: 'contain' }}
                  onError={(e) => {
                    e.currentTarget.style.display = 'none'
                    const span = document.createElement('span')
                    span.textContent = '💡'
                    span.style.fontSize = '20px'
                    e.currentTarget.parentElement?.appendChild(span)
                  }}
                />
              </button>
            )}
          </div>

          {/* Hint tooltip — speech-bubble below hint button */}
          <AnimatePresence>
            {showHint && question.hint && (
              <motion.div
                initial={{ opacity: 0, y: -8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                style={{
                  position: 'absolute', top: 44, right: 4, zIndex: 20,
                  maxWidth: '75%',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'flex-end', paddingRight: 20 }}>
                  <div style={{
                    width: 0, height: 0,
                    borderLeft: '8px solid transparent',
                    borderRight: '8px solid transparent',
                    borderBottom: '10px solid #FF9800',
                  }} />
                </div>
                <div
                  style={{
                    background: '#fff',
                    border: '1.5px solid #FF9800',
                    borderRadius: '14px 4px 14px 14px',
                    padding: 14,
                    boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                  }}
                >
                  <div className="flex items-center justify-between" style={{ marginBottom: 8 }}>
                    <span style={{ fontSize: 14, fontWeight: 700, color: '#E65100' }}>💡 Hint:</span>
                    <button
                      type="button"
                      onClick={() => setShowHint(false)}
                      style={{
                        width: 24, height: 24, borderRadius: '50%',
                        background: 'rgba(255,152,0,0.3)', border: 'none',
                        cursor: 'pointer',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}
                    >
                      <X size={14} color="#E65100" />
                    </button>
                  </div>
                  <p style={{ fontSize: 13, color: '#212121', lineHeight: 1.5, margin: 0 }}>
                    {question.hint}
                  </p>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Question card — slides in from left on change, shakes on wrong */}
          <motion.div
            animate={cardControls}
            style={{ padding: `40px clamp(16px, 4vw, 40px) 24px` }}
          >

            {/* Question type badge */}
            <div
              style={{
                display: 'inline-flex', alignItems: 'center', gap: 6,
                padding: '8px 14px', borderRadius: 10,
                background: subjectBg, border: `1px solid ${subjectBdr}`,
                marginBottom: 10,
              }}
            >
              <span style={{ fontSize: 16, color: subjectColor }}>📝</span>
              <span style={{ fontSize: 13, fontWeight: 600, color: subjectColor }}>
                {questionTypeLabel(question.type)}
              </span>
            </div>

            {/* Question text */}
            <p style={{
              fontSize: 'clamp(17px, 2.2vw, 22px)', fontWeight: 500, color: '#000',
              lineHeight: 1.55, margin: '8px 0 20px',
            }}>
              {question.text}
            </p>

            {/* Question image */}
            {question.image && (
              <div
                style={{
                  borderRadius: 10, overflow: 'hidden',
                  border: '1px solid #E0E0E0', marginBottom: 16,
                  boxShadow: '0 2px 4px rgba(0,0,0,0.05)',
                  maxHeight: 220,
                }}
              >
                <img
                  src={question.image}
                  alt="Question illustration"
                  style={{ width: '100%', maxHeight: 220, objectFit: 'contain' }}
                />
              </div>
            )}

            {/* Answer area */}
            <div style={{ paddingBottom: 8 }}>
              {question.type === 'short_answer' && (
                <ShortAnswerInput
                  value={shortAnswer}
                  disabled={isLocked}
                  onChange={setShortAnswer}
                />
              )}
              {question.type === 'rearrange' && (
                <RearrangeOptions
                  options={question.options}
                  shuffledIndices={shuffledIndices}
                  seq={rearrangeSeq}
                  disabled={isLocked}
                  showCorrect={showSuccess}
                  correctRearrangeIndices={correctRearrangeIndices}
                  onToggle={toggleRearrange}
                />
              )}
              {(question.type === 'mcq_single' || question.type === 'mcq_multiple') && (
                <McqOptions
                  options={question.options}
                  shuffledIndices={shuffledIndices}
                  selectedIndex={selectedIndex}
                  selectedIndices={selectedIndices}
                  disabledIndices={disabledIndices}
                  correctIndices={correctIndices}
                  isMultiple={question.type === 'mcq_multiple'}
                  showCorrect={showSuccess || showIncorrect}
                  disabled={isLocked}
                  onToggleSingle={toggleSingle}
                  onToggleMulti={toggleMulti}
                />
              )}
            </div>
          </motion.div>
        </div>
      </div>

      {/* ── Bottom button bar ───────────────────────────────────────────────── */}
      <div
        style={{
          height: 90, flexShrink: 0,
          borderTop: '1.5px solid #E0E0E0',
          background: showIncorrect ? C.incorrectBg : '#fff',
          position: 'relative', overflow: 'hidden',
          transition: 'background 0.2s',
        }}
      >
        <AnimatePresence mode="wait">

          {/* ── CORRECT state ─────────────────────────────────────────────── */}
          {showSuccess && (
            <motion.div
              key="success"
              initial={{ y: 90 }}
              animate={{ y: 0 }}
              transition={{ duration: 0.4, ease: [0.34, 1.56, 0.64, 1] }}
              style={{
                /* inset:0 not supported in Safari < 14.1 — use explicit TRBL */
                position: 'absolute', top: 0, right: 0, bottom: 0, left: 0,
                background: C.successBg,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                padding: '0 clamp(20px, 4vw, 40px)',
              }}
            >
              <div
                className="flex items-center"
                style={{ maxWidth: 900, width: '100%', justifyContent: 'space-between' }}
              >
                {/* 🎉 celebrate image */}
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ duration: 0.8, ease: [0.34, 1.56, 0.64, 1] }}
                >
                  <img
                    src="/images/celebrate.png"
                    alt="🎉"
                    width={32} height={32}
                    style={{ objectFit: 'contain' }}
                    onError={(e) => {
                      e.currentTarget.style.display = 'none'
                      const span = document.createElement('span')
                      span.textContent = '🎉'
                      span.style.fontSize = '24px'
                      e.currentTarget.parentElement?.appendChild(span)
                    }}
                  />
                </motion.div>

                <span style={{ fontSize: 20, fontWeight: 600, color: '#000' }}>Correct!</span>

                {/* XP badge — bounces in */}
                <motion.div
                  initial={{ scale: 0, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ duration: 0.6, ease: [0.34, 1.56, 0.64, 1] }}
                  style={{
                    padding: '4px 10px', borderRadius: 14,
                    background: C.xpGreen, color: '#fff',
                    fontSize: 14, fontWeight: 700,
                    boxShadow: '0 2px 8px rgba(34,197,94,0.4)',
                  }}
                >
                  +{earnedXp} XP
                </motion.div>

                <div style={{ flex: 1, maxWidth: 60 }} />

                {/* Continue — onClick is the action (works in all Safari versions).
                    onPointerDown/Up are ONLY for the press-depth visual. */}
                <button
                  type="button"
                  onPointerDown={() => setContinuePressed(true)}
                  onPointerUp={() => setContinuePressed(false)}
                  onPointerLeave={() => setContinuePressed(false)}
                  onPointerCancel={() => setContinuePressed(false)}
                  onClick={advance}
                  style={{
                    height: 50, padding: '0 32px', borderRadius: 28,
                    background: C.continueGreen, color: '#fff',
                    fontSize: 18, fontWeight: 500,
                    border: 'none',
                    borderBottom: `${continuePressed ? 1 : 4}px solid ${C.continueDark}`,
                    cursor: 'pointer',
                    boxShadow: continuePressed
                      ? '0 1px 4px rgba(41,204,87,0.4)'
                      : '0 4px 8px rgba(41,204,87,0.4)',
                    transition: 'border-bottom-width 0.1s, box-shadow 0.1s',
                    WebkitTapHighlightColor: 'transparent',
                  }}
                >
                  Continue
                </button>
              </div>
            </motion.div>
          )}

          {/* ── INCORRECT state ───────────────────────────────────────────── */}
          {showIncorrect && !showSuccess && (
            <motion.div
              key="incorrect"
              initial={{ y: 90 }}
              animate={{ y: 0 }}
              transition={{ duration: 0.4, ease: [0.34, 1.56, 0.64, 1] }}
              style={{
                position: 'absolute', top: 0, right: 0, bottom: 0, left: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                padding: '0 clamp(20px, 4vw, 40px)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', maxWidth: 900, width: '100%' }}>
                {/* Why? — onClick opens modal */}
                <button
                  type="button"
                  onPointerDown={() => setWhyPressed(true)}
                  onPointerUp={() => setWhyPressed(false)}
                  onPointerLeave={() => setWhyPressed(false)}
                  onPointerCancel={() => setWhyPressed(false)}
                  onClick={() => setShowExplModal(true)}
                  style={{
                    height: 50, padding: '0 20px', borderRadius: 28,
                    background: C.whyBtn, color: '#212121',
                    fontSize: 16, fontWeight: 600, border: 'none',
                    borderBottom: `${whyPressed ? 1 : 4}px solid ${C.whyBorder}`,
                    cursor: 'pointer', flexShrink: 0, marginRight: 12,
                    transition: 'border-bottom-width 0.1s',
                    WebkitTapHighlightColor: 'transparent',
                  }}
                >
                  Why?
                </button>

                {/* Continue — onClick is the action */}
                <button
                  type="button"
                  onPointerDown={() => setTryAgainPressed(true)}
                  onPointerUp={() => setTryAgainPressed(false)}
                  onPointerLeave={() => setTryAgainPressed(false)}
                  onPointerCancel={() => setTryAgainPressed(false)}
                  onClick={() => {
                    if (tries >= 2) {
                      advance()
                    } else {
                      setShowIncorrect(false)
                      setSelectedIndex(null)
                      setSelectedIndices(new Set())
                      setShortAnswer('')
                      setRearrangeSeq([])
                    }
                  }}
                  style={{
                    flex: 1, height: 50, borderRadius: 28,
                    background: tries >= 2 ? C.checkActive : C.continueLightBg,
                    color: tries >= 2 ? '#fff' : 'rgba(0,0,0,0.54)',
                    fontSize: 18, fontWeight: 500, border: 'none',
                    borderBottom: `${tryAgainPressed ? 1 : 4}px solid ${tries >= 2 ? '#000' : C.continueLightBorder}`,
                    cursor: 'pointer', marginRight: 12,
                    transition: 'border-bottom-width 0.1s',
                    WebkitTapHighlightColor: 'transparent',
                  }}
                >
                  Continue
                </button>

                {/* Incorrect label — bounces in */}
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ duration: 0.8, ease: [0.34, 1.56, 0.64, 1] }}
                  style={{ display: 'flex', alignItems: 'center', flexShrink: 0 }}
                >
                  <span style={{ fontSize: 22 }}>❌</span>
                  <span style={{ fontSize: 18, fontWeight: 600, color: '#000', marginLeft: 6 }}>Incorrect</span>
                </motion.div>
              </div>
            </motion.div>
          )}

          {/* ── IDLE / CHECK state ────────────────────────────────────────── */}
          {!showSuccess && !showIncorrect && (
            <motion.div
              key="check"
              style={{
                position: 'absolute', top: 0, right: 0, bottom: 0, left: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                padding: '0 clamp(20px, 4vw, 40px)',
              }}
            >
              <button
                type="button"
                disabled={!hasAnswer || isChecking}
                onPointerDown={() => hasAnswer && setCheckPressed(true)}
                onPointerUp={() => setCheckPressed(false)}
                onPointerLeave={() => setCheckPressed(false)}
                onPointerCancel={() => setCheckPressed(false)}
                onClick={async () => {
                  if (!hasAnswer || isChecking) return
                  await handleCheck()
                }}
                style={{
                  width: '100%', maxWidth: 480, height: 50, borderRadius: 28,
                  background: hasAnswer ? C.checkActive : C.checkInactive,
                  color: hasAnswer ? '#fff' : C.checkInactiveText,
                  fontSize: 18, fontWeight: 500, border: 'none',
                  borderBottom: hasAnswer ? `${checkPressed ? 1 : 4}px solid #000` : 'none',
                  cursor: hasAnswer ? 'pointer' : 'default',
                  transition: 'border-bottom-width 0.1s, background 0.15s',
                  WebkitTapHighlightColor: 'transparent',
                }}
              >
                {isChecking ? 'Checking…' : 'Check'}
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* ── Explanation bottom-sheet modal (Why? → Flutter _showExplanationModal) */}
      <AnimatePresence>
        {showExplModal && (
          <>
            <motion.div
              key="overlay"
              initial={{ opacity: 0 }}
              animate={{ opacity: 0.4 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowExplModal(false)}
              style={{ position: 'fixed', top: 0, right: 0, bottom: 0, left: 0, background: '#000', zIndex: 40 }}
            />
            <motion.div
              key="modal"
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
              style={{
                position: 'fixed', bottom: 0, left: 0, right: 0, zIndex: 50,
                background: '#fff',
                borderRadius: '24px 24px 0 0',
                maxHeight: '60vh', maxWidth: 900, margin: '0 auto',
                boxShadow: '0 -4px 20px rgba(0,0,0,0.1)',
                display: 'flex', flexDirection: 'column',
              }}
            >
              {/* Handle bar */}
              <div style={{ display: 'flex', justifyContent: 'center', padding: '12px 0 0' }}>
                <div style={{ width: 40, height: 4, borderRadius: 2, background: '#E0E0E0' }} />
              </div>
              {/* Header */}
              <div
                className="flex items-center"
                style={{ padding: '16px 20px', gap: 12, borderBottom: '1px solid #F0F0F0' }}
              >
                <div
                  style={{
                    width: 40, height: 40, borderRadius: '50%',
                    background: '#FFF3E0',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  <span style={{ fontSize: 20 }}>💡</span>
                </div>
                <span style={{ fontSize: 20, fontWeight: 700, color: '#212121', flex: 1 }}>
                  Explanation
                </span>
                <button
                  type="button"
                  onClick={() => setShowExplModal(false)}
                  style={{
                    width: 32, height: 32, borderRadius: '50%',
                    background: '#F5F5F5', border: 'none', cursor: 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}
                >
                  <X size={16} color="#757575" />
                </button>
              </div>
              {/* Explanation text */}
              <div style={{ flex: 1, overflowY: 'auto', padding: '16px 20px 32px' }}>
                <p style={{ fontSize: 15, color: '#212121', lineHeight: 1.7, margin: 0 }}>
                  {question.explanation ?? 'Answer the question correctly to proceed.'}
                </p>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  )
}

// ─── MCQ Options ─────────────────────────────────────────────────────────────
function McqOptions({
  options, shuffledIndices, selectedIndex, selectedIndices,
  disabledIndices, correctIndices, isMultiple, showCorrect, disabled,
  onToggleSingle, onToggleMulti,
}: {
  options: QuestionOption[]
  shuffledIndices: number[]
  selectedIndex: number | null
  selectedIndices: Set<number>
  disabledIndices: Set<number>
  correctIndices: number[]
  isMultiple: boolean
  showCorrect: boolean
  disabled: boolean
  onToggleSingle: (i: number) => void
  onToggleMulti: (i: number) => void
}) {
  return (
    <div className="flex flex-col" style={{ gap: 12 }}>
      {shuffledIndices.map((actualIdx, displayIdx) => {
        const option          = options[actualIdx]
        const isSelected      = isMultiple ? selectedIndices.has(actualIdx) : selectedIndex === actualIdx
        const isCorrect       = correctIndices.includes(actualIdx)
        const isDisabled      = disabledIndices.has(actualIdx) || (disabled && !isCorrect)
        const highlightCorrect = showCorrect && isCorrect

        const border = isDisabled        ? C.optionDisabledBorder
                     : highlightCorrect  ? C.optionCorrectBorder
                     : isSelected        ? C.optionSelectedBorder
                     :                    '#E0E0E0'
        const bg     = isDisabled        ? C.optionDisabled
                     : highlightCorrect  ? C.optionCorrect
                     : isSelected        ? C.optionSelected
                     :                    '#fff'
        const badgeBg = isDisabled        ? '#BDBDBD'
                      : highlightCorrect  ? '#4CAF50'
                      : isSelected        ? '#2196F3'
                      :                    '#E0E0E0'

        return (
          <motion.button
            key={actualIdx}
            type="button"
            initial={{ opacity: 0, x: 30 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4, delay: 0.2 + displayIdx * 0.1, ease: [0.22, 1, 0.36, 1] }}
            onClick={() => {
              if (disabled || isDisabled) return
              if (isMultiple) onToggleMulti(actualIdx); else onToggleSingle(actualIdx)
            }}
            disabled={disabled || isDisabled}
            style={{
              width: '100%', padding: '14px 16px', borderRadius: 14,
              background: bg,
              border: `${isSelected || highlightCorrect ? 2 : 1}px solid ${border}`,
              boxShadow: (isSelected || highlightCorrect) && !isDisabled
                ? `0 2px 8px ${highlightCorrect ? 'rgba(76,175,80,0.2)' : 'rgba(33,150,243,0.2)'}`
                : 'none',
              display: 'flex', alignItems: 'center', gap: 12,
              cursor: disabled || isDisabled ? 'default' : 'pointer',
              textAlign: 'left',
              transition: 'all 0.2s',
            }}
          >
            {/* A/B/C/D label */}
            <div
              style={{
                width: 30, height: 30, borderRadius: 8,
                background: badgeBg, flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}
            >
              {isDisabled
                ? <span style={{ color: '#fff', fontSize: 13 }}>🚫</span>
                : highlightCorrect
                ? <span style={{ color: '#fff', fontSize: 14, fontWeight: 700 }}>✓</span>
                : (isMultiple && isSelected)
                ? <span style={{ color: '#fff', fontSize: 14, fontWeight: 700 }}>✓</span>
                : <span style={{ fontSize: 13, fontWeight: 700, color: isSelected ? '#fff' : '#757575' }}>
                    {String.fromCharCode(65 + displayIdx)}
                  </span>
              }
            </div>
            <span style={{
              fontSize: 15, fontWeight: 500, lineHeight: 1.4,
              color: isDisabled ? '#9E9E9E' : highlightCorrect ? '#2E7D32' : '#212121',
            }}>
              {option.optionText}
            </span>
          </motion.button>
        )
      })}
    </div>
  )
}

// ─── Short Answer Input ───────────────────────────────────────────────────────
function ShortAnswerInput({
  value, disabled, onChange,
}: {
  value: string; disabled: boolean; onChange: (v: string) => void
}) {
  return (
    <textarea
      value={value}
      disabled={disabled}
      onChange={(e) => onChange(e.target.value)}
      placeholder="Type your answer here..."
      rows={3}
      style={{
        width: '100%', padding: '14px 16px', borderRadius: 12,
        border: '1px solid #E0E0E0',
        fontSize: 16, fontWeight: 500, color: '#212121',
        background: '#fff', resize: 'none', outline: 'none',
        fontFamily: 'inherit', lineHeight: 1.5, boxSizing: 'border-box',
      }}
      onFocus={(e) => { e.currentTarget.style.borderColor = '#2196F3'; e.currentTarget.style.borderWidth = '2px' }}
      onBlur={(e)  => { e.currentTarget.style.borderColor = '#E0E0E0'; e.currentTarget.style.borderWidth = '1px' }}
    />
  )
}

// ─── Rearrange Options ────────────────────────────────────────────────────────
// Tap-to-number: exactly like Flutter. Options stay in fixed positions;
// tapping assigns the next order number. Tapping again removes and renumbers.
function RearrangeOptions({
  options, shuffledIndices, seq, disabled, showCorrect,
  correctRearrangeIndices, onToggle,
}: {
  options: QuestionOption[]
  shuffledIndices: number[]
  seq: number[]
  disabled: boolean
  showCorrect: boolean
  correctRearrangeIndices: number[]
  onToggle: (actualIdx: number) => void
}) {
  const correctDisplayOrder = useMemo(() => {
    const map: Record<number, number> = {}
    correctRearrangeIndices.forEach((actualIdx, pos) => { map[actualIdx] = pos + 1 })
    return map
  }, [correctRearrangeIndices])

  return (
    <div className="flex flex-col" style={{ gap: 12 }}>
      <p style={{
        fontSize: 13, fontWeight: 600, color: '#9E9E9E',
        textTransform: 'uppercase', letterSpacing: '0.06em', margin: '0 0 4px',
      }}>
        Tap the options in the correct order
      </p>
      {shuffledIndices.map((actualIdx, displayIdx) => {
        const seqPos   = seq.indexOf(actualIdx)
        const isSelected = seqPos >= 0
        const userOrder  = seqPos + 1
        const border  = showCorrect ? C.optionCorrectBorder : isSelected ? C.optionSelectedBorder : '#E0E0E0'
        const bg      = showCorrect ? C.optionCorrect       : isSelected ? C.optionSelected       : '#fff'
        const badgeBg = showCorrect ? '#4CAF50'             : isSelected ? '#2196F3'              : '#F1F1F1'

        return (
          <motion.button
            key={actualIdx}
            type="button"
            initial={{ opacity: 0, x: 30 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4, delay: 0.2 + displayIdx * 0.1, ease: [0.22, 1, 0.36, 1] }}
            onClick={() => { if (!disabled) onToggle(actualIdx) }}
            disabled={disabled}
            style={{
              width: '100%', padding: '14px 16px', borderRadius: 14,
              background: bg, border: `${isSelected || showCorrect ? 2 : 1}px solid ${border}`,
              boxShadow: (isSelected || showCorrect)
                ? `0 4px 12px ${showCorrect ? 'rgba(76,175,80,0.18)' : 'rgba(33,150,243,0.14)'}`
                : 'none',
              display: 'flex', alignItems: 'center', gap: 12,
              cursor: disabled ? 'default' : 'pointer',
              textAlign: 'left', transition: 'all 0.2s',
            }}
          >
            <div
              style={{
                width: 32, height: 32, borderRadius: 10,
                background: badgeBg, flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}
            >
              {(isSelected || showCorrect)
                ? <span style={{ fontSize: 15, fontWeight: 700, color: '#fff' }}>
                    {showCorrect ? correctDisplayOrder[actualIdx] : userOrder}
                  </span>
                : <span style={{ fontSize: 18, color: '#9CA3AF' }}>⠿</span>
              }
            </div>
            <span style={{
              fontSize: 15, fontWeight: 500, lineHeight: 1.4,
              color: showCorrect ? '#2E7D32' : '#212121',
            }}>
              {options[actualIdx].optionText}
            </span>
          </motion.button>
        )
      })}
    </div>
  )
}
