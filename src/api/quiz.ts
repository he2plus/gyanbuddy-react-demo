/**
 * Quiz API — wraps:
 *   GET  /module_chapters/{chapterId}/module_questions/   → list of Questions
 *   POST /questions/{questionId}/check/                   → verify an answer
 *
 * Plus a mission-quiz path that re-uses the embedded questions on the Mission
 * object (no extra round-trip).
 *
 * In mock mode we answer-check client-side using the `is_correct` flag on
 * options. Real backend will return server-validated correctness.
 */
import { api } from './client'
import type { ApiEnvelope } from '../types/api'
import { parseQuestion, type Question, type QuestionDTO } from '../types/question'
import { isMockSessionActive } from './modules'
import { getUserMissions } from './missions'
import { getModuleChapters } from './modules'

export async function getChapterQuestions(chapterId: string): Promise<Question[]> {
  if (isMockSessionActive()) {
    // Mock path: synthesize a small quiz per chapter so the flow works offline.
    return mockQuestionsForChapter(chapterId)
  }
  const { data: envelope } = await api.get<ApiEnvelope<QuestionDTO[]>>(
    `/module_chapters/${chapterId}/module_questions/`,
  )
  if (!envelope.success) {
    throw new Error(envelope.message || 'Failed to load questions')
  }
  return (envelope.data ?? []).map(parseQuestion)
}

export async function getMissionQuestions(missionId: string): Promise<Question[]> {
  const missions = await getUserMissions()
  const m = missions.find((mm) => mm.id === missionId)
  return m?.questions ?? []
}

export type CheckResult = {
  isCorrect: boolean
  expAwarded: number
  explanation?: string
}

/**
 * Validate an answer. In mock mode this is purely client-side.
 *
 * Inputs:
 *   - question      → the Question being answered
 *   - optionIds     → user's selected option IDs (MCQ)
 *   - shortAnswer   → user's text answer (short_answer type)
 *   - tries         → 1 on first attempt, 2 on second. Backend's check_answer
 *                     uses this to compute XP (2 / 1 / 0 per docx #16).
 */
export async function checkAnswer(
  question: Question,
  optionIds: string[],
  shortAnswer?: string,
  tries: number = 1,
): Promise<CheckResult> {
  if (isMockSessionActive()) {
    return mockCheck(question, optionIds, shortAnswer, tries)
  }
  try {
    const body: Record<string, unknown> = { tries }
    if (optionIds && optionIds.length > 1) body.answer_ids = optionIds
    else if (optionIds && optionIds.length === 1) body.answer_id = optionIds[0]
    if (shortAnswer) body.answer_text = shortAnswer
    const { data: envelope } = await api.patch<ApiEnvelope<{
      is_correct?: boolean
      exp_awarded?: number
      exp_earned?: number
      explanation?: string
    }>>(`/questions/${question.id}/check/`, body)
    if (!envelope.success || !envelope.data) {
      throw new Error(envelope.message || 'Could not check answer')
    }
    const isCorrect = !!envelope.data.is_correct
    // Backend may name the field exp_awarded OR exp_earned depending on
    // version; fall back to the docx-prescribed 2/1/0 formula if neither.
    const expFromBackend =
      typeof envelope.data.exp_awarded === 'number' ? envelope.data.exp_awarded :
      typeof envelope.data.exp_earned === 'number'  ? envelope.data.exp_earned :
      null
    const expAwarded = expFromBackend ?? (isCorrect ? (tries === 1 ? 2 : 1) : 0)
    return {
      isCorrect,
      expAwarded,
      explanation: envelope.data.explanation,
    }
  } catch {
    return mockCheck(question, optionIds, shortAnswer, tries)
  }
}

function mockCheck(
  question: Question,
  optionIds: string[],
  shortAnswer: string | undefined,
  tries: number,
): CheckResult {
  let isCorrect: boolean
  if (question.type === 'short_answer') {
    const target = question.options.find((o) => o.isCorrect)?.optionText?.trim().toLowerCase() ?? ''
    isCorrect = !!shortAnswer && shortAnswer.trim().toLowerCase() === target
  } else {
    const correctIds = new Set(question.options.filter((o) => o.isCorrect).map((o) => o.id))
    const selected = new Set(optionIds)
    isCorrect = correctIds.size === selected.size && [...correctIds].every((id) => selected.has(id))
  }
  const expAwarded = isCorrect ? (tries === 1 ? 2 : tries === 2 ? 1 : 0) : 0
  return { isCorrect, expAwarded, explanation: question.explanation ?? undefined }
}

// ---------------------------------------------------------------------------
// Mock chapter questions — chapter-specific banks so the Vercel demo feels
// like real subject content, not three meta questions about "the topic of
// this chapter". The bank is keyed by a string derived from the chapterId
// (which embeds the parent moduleId / subjectId in mock mode).
// ---------------------------------------------------------------------------

type QBank = Array<{
  text: string
  options: Array<{ t: string; c?: boolean }>
  hint: string
  explanation: string
}>

const CHEMISTRY_BANK: QBank = [
  {
    text: 'Which of the following is a chemical change?',
    options: [
      { t: 'Melting of ice' },
      { t: 'Burning of paper', c: true },
      { t: 'Boiling of water' },
      { t: 'Crushing a soda can' },
    ],
    hint: 'A chemical change creates a new substance and is usually irreversible.',
    explanation:
      'Burning paper produces new substances (ash, smoke, CO₂) and cannot be reversed — it is a chemical change. Melting, boiling and crushing are all physical changes; the matter just changes form.',
  },
  {
    text: 'The pH of a neutral solution at 25°C is:',
    options: [{ t: '0' }, { t: '7', c: true }, { t: '14' }, { t: '1' }],
    hint: 'The pH scale runs 0–14; the midpoint is neutral.',
    explanation:
      'A pH of 7 is neutral (pure water). Less than 7 is acidic, more than 7 is basic.',
  },
  {
    text: 'Which gas is produced when an acid reacts with a metal?',
    options: [
      { t: 'Oxygen' },
      { t: 'Carbon dioxide' },
      { t: 'Hydrogen', c: true },
      { t: 'Nitrogen' },
    ],
    hint: 'It is the lightest element on the periodic table.',
    explanation:
      'Most acid-metal reactions release hydrogen gas. For example, Zn + 2HCl → ZnCl₂ + H₂.',
  },
  {
    text: 'Chemical formula of water?',
    options: [{ t: 'HO' }, { t: 'H₂O', c: true }, { t: 'H₂O₂' }, { t: 'OH' }],
    hint: 'Two hydrogen atoms bonded to one oxygen atom.',
    explanation:
      'Water is H₂O. H₂O₂ is hydrogen peroxide (an oxidising agent), OH⁻ is the hydroxide ion.',
  },
]

const PHYSICS_BANK: QBank = [
  {
    text: 'SI unit of force is:',
    options: [
      { t: 'Joule' },
      { t: 'Newton', c: true },
      { t: 'Watt' },
      { t: 'Pascal' },
    ],
    hint: 'It is named after the scientist who formulated the three laws of motion.',
    explanation:
      'Force is measured in Newtons (N). 1 N = the force needed to accelerate 1 kg by 1 m/s².',
  },
  {
    text: 'Acceleration due to gravity on Earth is approximately:',
    options: [
      { t: '9.8 m/s²', c: true },
      { t: '8.9 m/s²' },
      { t: '10.8 m/s²' },
      { t: '6.5 m/s²' },
    ],
    hint: 'Just under 10 — easy to remember.',
    explanation:
      'g ≈ 9.8 m/s² on Earth\'s surface. It varies slightly with latitude and altitude.',
  },
  {
    text: "Newton's First Law is also called?",
    options: [
      { t: 'Law of Inertia', c: true },
      { t: 'Law of Action' },
      { t: 'Law of Gravity' },
      { t: 'Law of Momentum' },
    ],
    hint: "Objects 'want' to keep doing whatever they're already doing.",
    explanation:
      'The First Law (Law of Inertia) says a body remains at rest or in uniform motion unless acted on by a net external force.',
  },
  {
    text: 'F = ma is which Law of Motion?',
    options: [
      { t: 'First Law' },
      { t: 'Second Law', c: true },
      { t: 'Third Law' },
      { t: 'Fourth Law' },
    ],
    hint: 'It quantifies the relationship between force, mass, and acceleration.',
    explanation:
      'Newton\'s Second Law: net force = mass × acceleration. F = ma quantifies how much a given force will accelerate a given mass.',
  },
]

const BIOLOGY_BANK: QBank = [
  {
    text: 'The basic structural and functional unit of life is:',
    options: [
      { t: 'Tissue' },
      { t: 'Organ' },
      { t: 'Cell', c: true },
      { t: 'Organ system' },
    ],
    hint: 'Tissues, organs, and organ systems are all made of these.',
    explanation:
      'The cell is the basic unit of life. Multiple cells form a tissue, tissues form organs, organs make up organ systems.',
  },
  {
    text: 'Which organelle is known as the powerhouse of the cell?',
    options: [
      { t: 'Nucleus' },
      { t: 'Ribosome' },
      { t: 'Mitochondrion', c: true },
      { t: 'Golgi body' },
    ],
    hint: 'It is where ATP — the cell\'s energy currency — is produced.',
    explanation:
      'Mitochondria carry out cellular respiration, generating ATP. Hence the "powerhouse" nickname.',
  },
  {
    text: 'Which process is responsible for the loss of water vapour from leaves?',
    options: [
      { t: 'Transpiration', c: true },
      { t: 'Respiration' },
      { t: 'Photosynthesis' },
      { t: 'Digestion' },
    ],
    hint: "It is the plant equivalent of perspiration.",
    explanation:
      'Transpiration is the evaporation of water from plant surfaces — primarily through stomata in the leaves.',
  },
  {
    text: 'The longest bone in the human body is the:',
    options: [
      { t: 'Tibia' },
      { t: 'Humerus' },
      { t: 'Femur', c: true },
      { t: 'Fibula' },
    ],
    hint: 'It is in the upper leg.',
    explanation:
      'The femur (thigh bone) is the longest and strongest bone in the human body.',
  },
]

const MATH_BANK: QBank = [
  {
    text: 'Solve: x + 5 = 10',
    options: [
      { t: 'x = 5', c: true },
      { t: 'x = 15' },
      { t: 'x = 2' },
      { t: 'x = 50' },
    ],
    hint: 'Subtract 5 from both sides — the goal is to isolate x.',
    explanation:
      'x + 5 = 10  →  x = 10 - 5  →  x = 5. Always perform the same operation on both sides until x is alone.',
  },
  {
    text: '(a + b)² is equal to:',
    options: [
      { t: 'a² + b²' },
      { t: 'a² + 2ab + b²', c: true },
      { t: 'a² − 2ab + b²' },
      { t: 'a² + ab + b²' },
    ],
    hint: 'Expand by multiplying (a + b) by itself term-by-term.',
    explanation:
      '(a + b)² = (a + b)(a + b) = a² + ab + ab + b² = a² + 2ab + b². The "2ab" comes from the two cross-terms.',
  },
  {
    text: 'Sum of angles in a triangle?',
    options: [
      { t: '180°', c: true },
      { t: '360°' },
      { t: '90°' },
      { t: '270°' },
    ],
    hint: 'A foundational rule of plane geometry.',
    explanation:
      'The three interior angles of any flat (Euclidean) triangle always add up to exactly 180°.',
  },
  {
    text: 'Right triangle legs 3 and 4 — hypotenuse = ?',
    options: [{ t: '6' }, { t: '5', c: true }, { t: '7' }, { t: '4' }],
    hint: 'Apply the Pythagorean theorem: a² + b² = c².',
    explanation:
      '3² + 4² = 9 + 16 = 25, so c = √25 = 5. This is the classic 3-4-5 right triangle.',
  },
]

const GEOGRAPHY_BANK: QBank = [
  {
    text: 'Which is the largest continent by area?',
    options: [
      { t: 'Africa' },
      { t: 'Asia', c: true },
      { t: 'North America' },
      { t: 'Antarctica' },
    ],
    hint: 'It also has the largest population.',
    explanation:
      'Asia covers about 44.6 million km² — by far the largest continent. Africa is second.',
  },
  {
    text: 'The longest river in the world is:',
    options: [
      { t: 'Amazon' },
      { t: 'Nile', c: true },
      { t: 'Yangtze' },
      { t: 'Mississippi' },
    ],
    hint: 'It runs through northeastern Africa.',
    explanation:
      'The Nile (~6650 km) is conventionally the longest river. The Amazon is a very close second and often debated.',
  },
  {
    text: "Which planet is known as the 'Red Planet'?",
    options: [
      { t: 'Venus' },
      { t: 'Mars', c: true },
      { t: 'Jupiter' },
      { t: 'Saturn' },
    ],
    hint: 'Its colour comes from iron oxide on its surface.',
    explanation:
      'Mars appears reddish because of iron oxide (rust) dust on its surface.',
  },
]

const HISTORY_BANK: QBank = [
  {
    text: 'India gained independence in which year?',
    options: [
      { t: '1945' },
      { t: '1947', c: true },
      { t: '1950' },
      { t: '1942' },
    ],
    hint: 'Sandwiched between WWII and the Republic.',
    explanation:
      'India gained independence from British rule on 15 August 1947. The Constitution came into force in 1950.',
  },
  {
    text: 'The Quit India Movement was launched in:',
    options: [
      { t: '1940' },
      { t: '1942', c: true },
      { t: '1944' },
      { t: '1946' },
    ],
    hint: 'Launched by Gandhi during World War II.',
    explanation:
      'Quit India was launched by Mahatma Gandhi on 8 August 1942 with the famous "Do or Die" call.',
  },
  {
    text: 'Who was the first Prime Minister of India?',
    options: [
      { t: 'Sardar Patel' },
      { t: 'Jawaharlal Nehru', c: true },
      { t: 'Lal Bahadur Shastri' },
      { t: 'Rajendra Prasad' },
    ],
    hint: 'He gave the famous "Tryst with Destiny" speech.',
    explanation:
      'Jawaharlal Nehru became the first Prime Minister on 15 August 1947 and served until his death in 1964.',
  },
]

// Pick a question bank from the chapterId. Mock chapter IDs are like
// "chem-m1-c1" (subject-module-chapter). We sniff the subject prefix.
function bankForChapter(chapterId: string): QBank {
  const prefix = chapterId.split('-')[0]?.toLowerCase() ?? ''
  switch (prefix) {
    case 'chem': return CHEMISTRY_BANK
    case 'phys': return PHYSICS_BANK
    case 'bio':  return BIOLOGY_BANK
    case 'math': return MATH_BANK
    case 'geo':  return GEOGRAPHY_BANK
    case 'hist': return HISTORY_BANK
    default:     return CHEMISTRY_BANK
  }
}

function mockQuestionsForChapter(chapterId: string): Question[] {
  const bank = bankForChapter(chapterId)
  const make = (i: number, q: QBank[number]): QuestionDTO => ({
    id: `${chapterId}-q${i + 1}`,
    question_text: q.text,
    question_type: 'mcq_single',
    exp_points: 10,
    difficulty_level: 'medium',
    is_active: true,
    is_hots: false,
    level: 1,
    hint: q.hint,
    explanation: q.explanation,
    options: q.options.map((o, idx) => ({
      id: `${chapterId}-q${i + 1}-o${idx + 1}`,
      option_text: o.t,
      is_correct: o.c === true,
      order: idx + 1,
    })),
  })
  return bank.map((q, i) => parseQuestion(make(i, q)))
}

// Re-export for symmetry with other features
export { getModuleChapters }
