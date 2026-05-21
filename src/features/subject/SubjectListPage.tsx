/**
 * SubjectListPage — pixel-faithful rebuild of Figma frame 10:1259
 * ("Subject Screen 1", 1920 × 1182).
 *
 * Per the docx directives (Tasks & Particular Improvements):
 *   #5  search bar removed
 *   #6  expanded subject row shows chapter chips with status tags
 *       (DONE / OVERDUE / DUE / LOCKED); selected subject is navy
 *   #7  clicking a filter chip narrows the visible chapters to that status
 *   #8  "All" filter is the default open state
 *   #9  rename header label "All Subjects" → "All Chapters"
 *   #10 wrap chapter chips after 5 per row
 *
 * Status chip palette (verified against the Figma extracted spec):
 *   Done    : bg #d0f6eb, text #22d3a0
 *   Overdue : bg #ffd9d9, text #ff3131
 *   Due     : bg #ffe7d7, text #ff8f3d
 *   Locked  : bg #f1f1f1, text #989ca5
 */
import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ChevronDown, ChevronUp, Lock, AlertTriangle,
  Atom, FlaskConical, Globe, Leaf, Layers, Dna, Castle, Scroll, BookOpen,
  type LucideIcon,
} from 'lucide-react'
import { useQuery } from '@tanstack/react-query'

import { TopBar } from '../../shell/TopBar'
import { useSubjects } from './useSubjects'
import { getSubjectModules } from '../../api/modules'
import type { Subject } from '../../types/subject'
import type { Module } from '../../types/module'

const NAVY = '#00167A'
const CYAN = '#1ABCFE'
const TXT_DARK = '#121212'
const TXT_MID = '#545454'
const TXT_MUTED = '#989CA5'
const SURFACE_BG = '#FAFAFA'

const SUBJECT_ICON: Record<string, LucideIcon> = {
  CHEM: FlaskConical, PHY: Atom, GEO: Globe, BIO: Leaf,
  MATH: Layers, GEN: Dna, HIS: Castle, SAN: Scroll,
}
const iconFor = (s: Subject): LucideIcon =>
  SUBJECT_ICON[(s.code || '').toUpperCase()] ?? BookOpen

// Figma-rendered 3D PNGs — same mapping as the Home rail. Used in the
// collapsed subject row icon and as a fallback illustration for chapter
// chips when there's no subject-specific chapter art.
const SUBJECT_PNG: Record<string, string> = {
  CHEM: '/images/figma/subj-1-chemistry.png',
  BIO:  '/images/figma/subj-2-biology.png',
  PHY:  '/images/figma/subj-3-physics.png',
  GEO:  '/images/figma/subj-4-geography.png',
  MATH: '/images/figma/subj-5-maths.png',
  ENG:  '/images/figma/subj-6-english.png',
  HIS:  '/images/figma/subj-7-history.png',
  SAN:  '/images/figma/subj-8-sanskrit.png',
  GEN:  '/images/figma/subj-2-biology.png',
}
const subjectPngFor = (s: Subject): string | null =>
  SUBJECT_PNG[(s.code || '').toUpperCase()] ?? null

type Filter = 'all' | 'overdue' | 'in_progress' | 'locked'

// Chapter status (derived client-side from Module fields the backend ships).
// The Figma uses the labels DONE / OVERDUE / DUE / LOCKED on chapter chips;
// we map the backend `status` + `due_date` into one of those.
type ChapterStatus = 'done' | 'overdue' | 'due' | 'locked'
function chapterStatus(m: Module): ChapterStatus {
  if (m.status === 'completed' || m.userPercentage >= 100) return 'done'
  if (m.dueDate) {
    const due = new Date(m.dueDate).getTime()
    if (Number.isFinite(due) && due < Date.now()) return 'overdue'
    return 'due'
  }
  if (m.status === 'in_progress') return 'due'
  return 'locked'
}

const STATUS_CHIP: Record<ChapterStatus, { bg: string; fg: string; label: string }> = {
  done:    { bg: '#D0F6EB', fg: '#22D3A0', label: 'Done' },
  overdue: { bg: '#FFD9D9', fg: '#FF3131', label: 'Overdue' },
  due:     { bg: '#FFE7D7', fg: '#FF8F3D', label: 'Due' },
  locked:  { bg: '#F1F1F1', fg: '#989CA5', label: 'Locked' },
}

// ---------------------------------------------------------------------------
export function SubjectListPage() {
  const navigate = useNavigate()
  const subjectsQ = useSubjects()
  const [params] = useSearchParams()
  const [filter, setFilter] = useState<Filter>('all')
  // Tri-state: undefined = "use the default (first subject) as a starter",
  // null = "user explicitly collapsed everything", string = "this id is open".
  // The undefined sentinel is what lets the user actually close the
  // auto-expanded row — without it, activeId would fall back to default and
  // the row would never visually collapse.
  const [expandedId, setExpandedId] = useState<string | null | undefined>(undefined)

  const subjects = subjectsQ.data ?? []
  const expandFromUrl = params.get('expand')
  useEffect(() => {
    if (expandFromUrl) setExpandedId(expandFromUrl)
  }, [expandFromUrl])
  const defaultExpanded = subjects[0]?.id ?? null
  const activeId = expandedId === undefined ? defaultExpanded : expandedId

  return (
    <div className="min-h-screen" style={{ background: SURFACE_BG }}>
      <TopBar pageTitle="Subject" testCount={1} />

      <main className="mx-auto" style={{ maxWidth: 1920, padding: '50px 120px 80px' }}>
        {/* Filter chip row — search bar intentionally omitted per directive #5 */}
        <FilterChipRow active={filter} onChange={setFilter} />

        {/* Subject rows. One can be expanded at a time. */}
        <div className="flex flex-col" style={{ gap: 44, marginTop: 44 }}>
          {subjectsQ.isLoading && <LoadingState />}
          {subjectsQ.isError && <ErrorState onRetry={() => subjectsQ.refetch()} />}
          {!subjectsQ.isLoading && !subjectsQ.isError && subjects.map((s, i) => (
            <SubjectRow
              key={s.id}
              subject={s}
              expanded={s.id === activeId}
              filter={filter}
              delay={i * 0.05}
              onToggle={() => setExpandedId(s.id === activeId ? null : s.id)}
              onChapterClick={(moduleId) =>
                navigate(`/subjects/${s.id}/modules/${moduleId}/chapters`)
              }
            />
          ))}
        </div>
      </main>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Filter chips — Figma Frame 73 row, 4 chips (active = navy bg, white text;
// inactive = white bg, status dot + black text)
// ---------------------------------------------------------------------------
function FilterChipRow({
  active, onChange,
}: {
  active: Filter; onChange: (f: Filter) => void
}) {
  const chips: { id: Filter; label: string; dot?: string }[] = [
    { id: 'all',         label: 'All Chapters' },                     // docx #9 rename
    { id: 'overdue',     label: 'Overdue',     dot: '#FF3131' },
    { id: 'in_progress', label: 'In Progress', dot: CYAN },
    { id: 'locked',      label: 'Locked',      dot: TXT_MUTED },
  ]
  return (
    <div className="flex" style={{ gap: 24 }}>
      {chips.map((c, i) => {
        const isActive = c.id === active
        return (
          <motion.button
            key={c.id}
            type="button"
            onClick={() => onChange(c.id)}
            className="flex items-center"
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.04, duration: 0.3 }}
            whileTap={{ scale: 0.96 }}
            style={{
              height: 49, borderRadius: 50, gap: 8,
              padding: c.dot ? '12px 20px' : '12px 26px',
              background: isActive ? NAVY : '#fff',
              border: isActive ? 'none' : `1px solid ${isActive ? NAVY : '#EAEAEA'}`,
              boxShadow: isActive ? '0 4px 12px rgba(0,22,122,0.18)' : '0 1px 3px rgba(0,0,0,0.04)',
            }}
          >
            {c.dot && !isActive && (
              <span
                style={{
                  width: 10, height: 10, borderRadius: 999, background: c.dot,
                }}
              />
            )}
            <span
              className="font-body"
              style={{
                fontSize: 18, fontWeight: 700,
                color: isActive ? '#fff' : TXT_DARK,
                lineHeight: '25px',
              }}
            >
              {c.label}
            </span>
          </motion.button>
        )
      })}
    </div>
  )
}

// ---------------------------------------------------------------------------
// SubjectRow — either expanded (navy header + chapter chips below) or
// collapsed (white pill with progress bar)
// ---------------------------------------------------------------------------
function SubjectRow({
  subject, expanded, filter, delay, onToggle, onChapterClick,
}: {
  subject: Subject
  expanded: boolean
  filter: Filter
  delay: number
  onToggle: () => void
  onChapterClick: (moduleId: string) => void
}) {
  const Icon = iconFor(subject)
  const accent = subject.color || NAVY
  const subjectPng = subjectPngFor(subject)

  // Fetch modules for the expanded row only — avoids loading every subject's
  // chapter data when most rows are collapsed.
  const modulesQ = useQuery<Module[]>({
    queryKey: ['subjects', subject.id, 'modules'],
    queryFn: () => getSubjectModules(subject.id),
    enabled: expanded,
    staleTime: 5 * 60_000,
  })
  const modules = modulesQ.data ?? []

  // Overall percentage = mean of module userPercentage
  const overallPct = useMemo(() => {
    if (!modules.length) return 0
    const total = modules.reduce((s, m) => s + (m.userPercentage || 0), 0)
    return Math.round(total / modules.length)
  }, [modules])

  // Apply filter to chapter chips inside the expanded row
  const filtered = useMemo(() => {
    if (filter === 'all') return modules
    return modules.filter((m) => {
      const st = chapterStatus(m)
      if (filter === 'overdue') return st === 'overdue'
      if (filter === 'in_progress') return st === 'due' // backend's in-progress maps to "due" in the chip vocabulary
      if (filter === 'locked') return st === 'locked'
      return true
    })
  }, [modules, filter])

  // Collapsed row uses subject.moduleCount (no module fetch needed)
  const moduleCount = modules.length || subject.moduleCount

  return (
    <motion.section
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
    >
      {/* Pill header. Expanded → navy bg, white text. Collapsed → white bg. */}
      <motion.button
        type="button"
        onClick={onToggle}
        className="w-full flex items-center"
        style={{
          height: 112, borderRadius: 68, padding: '20px 56px 20px 24px', gap: 24,
          background: expanded ? NAVY : '#fff',
          boxShadow: expanded
            ? '0 12px 32px rgba(0,22,122,0.18)'
            : '0 2px 8px rgba(0,0,0,0.04)',
          border: expanded ? 'none' : '1px solid #EAEAEA',
        }}
        whileHover={{ y: expanded ? 0 : -2 }}
      >
        {/* Icon container 105 x 84 (expanded) / 100 x 72 (collapsed) — uses
            the Figma 3D PNG for the subject when available, falls back to
            the tinted Lucide glyph for codes we don't have art for yet. */}
        <div
          className="grid place-items-center shrink-0"
          style={{
            width: expanded ? 105 : 100, height: expanded ? 84 : 72,
            borderRadius: 68, background: '#fff',
            boxShadow: expanded ? `0 6px 14px ${accent}28` : `0 4px 10px ${accent}18`,
          }}
        >
          {subjectPng ? (
            <img
              src={subjectPng}
              alt=""
              draggable={false}
              className="select-none"
              style={{
                width: 60, height: 60, objectFit: 'contain',
                filter: 'drop-shadow(0 3px 6px rgba(0,0,0,0.08))',
              }}
              onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none' }}
            />
          ) : (
            <span
              className="grid place-items-center"
              style={{
                width: 56, height: 56, borderRadius: 16,
                background: `linear-gradient(135deg, ${accent}26 0%, ${accent}10 100%)`,
                color: accent,
              }}
            >
              <Icon className="w-8 h-8" strokeWidth={2} />
            </span>
          )}
        </div>

        {/* Title + count + progress */}
        <div className="flex-1 flex flex-col" style={{ gap: 8 }}>
          <div className="flex items-center" style={{ gap: 10 }}>
            <span
              className="font-body"
              style={{
                fontSize: 26, fontWeight: 700, lineHeight: '36px',
                color: expanded ? '#fff' : TXT_DARK,
              }}
            >
              {subject.name}
            </span>
            <span
              className="grid place-items-center"
              style={{
                height: 38, borderRadius: 50, padding: '8px 20px',
                background: expanded ? 'rgba(255,255,255,0.16)' : '#fff',
                color: expanded ? '#fff' : TXT_MID,
                fontFamily: 'var(--font-body)', fontSize: 16, fontWeight: 400, lineHeight: '22px',
                border: expanded ? 'none' : '1px solid #EAEAEA',
              }}
            >
              {moduleCount} chapter{moduleCount === 1 ? '' : 's'}
            </span>
          </div>
          <div className="flex items-center" style={{ gap: 14 }}>
            <div
              className="flex-1"
              style={{
                height: 8, borderRadius: 14,
                background: expanded ? 'rgba(255,255,255,0.18)' : '#F1F1F1',
                overflow: 'hidden',
              }}
            >
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${overallPct}%` }}
                transition={{ duration: 0.9, ease: 'easeOut' }}
                style={{
                  height: '100%', borderRadius: 14,
                  background: expanded ? '#fff' : CYAN,
                }}
              />
            </div>
            <span
              className="font-body tabular-nums"
              style={{
                fontSize: 26, fontWeight: 700, lineHeight: '36px',
                color: expanded ? '#fff' : NAVY,
                minWidth: 64, textAlign: 'right',
              }}
            >
              {overallPct}%
            </span>
          </div>
        </div>

        {/* Chevron */}
        <div className="shrink-0" style={{ color: expanded ? '#fff' : TXT_MID }}>
          {expanded
            ? <ChevronUp className="w-6 h-6" strokeWidth={2.5} />
            : <ChevronDown className="w-6 h-6" strokeWidth={2.5} />}
        </div>
      </motion.button>

      {/* Expanded chapter chips — wrap after 5 per row (docx #10) */}
      <AnimatePresence initial={false}>
        {expanded && (
          <motion.div
            key="chips"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.3, ease: 'easeInOut' }}
            style={{ overflow: 'hidden' }}
          >
            <div
              className="grid"
              style={{
                gridTemplateColumns: 'repeat(auto-fill, minmax(224px, 1fr))',
                gap: 24,
                marginTop: 44,
                maxWidth: 5 * 224 + 4 * 24, // hard cap so we never exceed 5 per row
              }}
            >
              {modulesQ.isLoading && Array.from({ length: 4 }).map((_, i) => (
                <div
                  key={i}
                  className="bg-white animate-pulse"
                  style={{ height: 261, borderRadius: 34 }}
                />
              ))}
              {!modulesQ.isLoading && filtered.length === 0 && (
                <div
                  className="grid place-items-center font-body"
                  style={{
                    gridColumn: '1 / -1', height: 120, color: TXT_MUTED,
                    fontSize: 16, fontWeight: 400,
                  }}
                >
                  No chapters match this filter.
                </div>
              )}
              {filtered.map((m, i) => (
                <ChapterChip
                  key={m.id}
                  module={m}
                  subjectCode={subject.code}
                  orderIndex={i}
                  delay={i * 0.04}
                  onClick={() => onChapterClick(m.id)}
                />
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.section>
  )
}

// Biology-themed 3D illustrations exported from Figma. Indexed by chapter
// position within the subject (the Figma's Biology row showed lungs, brain,
// genetics, seed). For non-Biology subjects we fall back to a tinted glyph.
const BIO_ILLUSTRATIONS = [
  '/images/figma/illus-life-processes.png',
  '/images/figma/illus-control-coord.png',
  '/images/figma/illus-heredity.png',
  '/images/figma/illus-reproduction.png',
]

function illustrationFor(subjectCode: string, orderIndex: number): string | null {
  const upper = subjectCode?.toUpperCase()
  if (upper === 'BIO' && orderIndex < BIO_ILLUSTRATIONS.length) {
    return BIO_ILLUSTRATIONS[orderIndex]
  }
  // Fallback: use the subject's own 3D icon so the chapter chip is never
  // a blank tinted box. Biology gets specific illustrations because Figma
  // shipped them; other subjects re-use the rail icon for now.
  return SUBJECT_PNG[upper] ?? null
}

// ---------------------------------------------------------------------------
// ChapterChip — Figma Frame 37/38/39/40 (224 × 261, white bg, radius 34)
// ---------------------------------------------------------------------------
function ChapterChip({
  module: m, subjectCode, orderIndex, delay, onClick,
}: {
  module: Module
  subjectCode: string
  orderIndex: number
  delay: number
  onClick: () => void
}) {
  const status = chapterStatus(m)
  const chip = STATUS_CHIP[status]
  const locked = status === 'locked'
  const chapterIllustration = illustrationFor(subjectCode, orderIndex)

  return (
    <motion.button
      type="button"
      onClick={locked ? undefined : onClick}
      disabled={locked}
      className="bg-white flex flex-col text-left relative overflow-hidden cursor-pointer disabled:cursor-default"
      style={{
        height: 261, borderRadius: 34, padding: 24, gap: 10,
        boxShadow: '0 2px 8px rgba(0,0,0,0.04)',
        opacity: locked ? 0.85 : 1,
      }}
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: locked ? 0.85 : 1, y: 0 }}
      transition={{ delay, duration: 0.3 }}
      whileHover={locked ? undefined : { y: -4, boxShadow: '0 12px 28px rgba(0,0,0,0.10)' }}
    >
      {/* Status chip top-left */}
      <div className="flex items-center justify-between">
        <span
          className="grid place-items-center"
          style={{
            height: 37, borderRadius: 42, padding: '6px 24px',
            background: chip.bg, color: chip.fg,
            fontFamily: 'var(--font-body)', fontSize: 18, fontWeight: 700, lineHeight: '25px',
          }}
        >
          {chip.label}
        </span>
        {locked && (
          <span
            className="grid place-items-center"
            style={{
              width: 44, height: 44, borderRadius: 14,
              background: '#fff', border: '1px solid #E7E7E7',
            }}
          >
            <Lock className="w-5 h-5" style={{ color: TXT_MID }} strokeWidth={2.2} />
          </span>
        )}
      </div>

      {/* Illustration zone — Biology-themed 3D PNGs by chapter order, with
          a tinted-glyph fallback for other subjects until they have their
          own art. */}
      <div
        className="grid place-items-center relative"
        style={{
          height: 95, marginTop: 10,
          background: locked
            ? 'radial-gradient(circle at 50% 50%, #EEF2F5 0%, #FAFAFA 70%)'
            : 'radial-gradient(circle at 50% 30%, rgba(26,188,254,0.14), rgba(124,58,237,0.04) 60%, transparent 80%)',
          borderRadius: 16, overflow: 'hidden',
        }}
      >
        {chapterIllustration ? (
          <img
            src={chapterIllustration}
            alt=""
            draggable={false}
            className="select-none"
            style={{
              maxHeight: 88, width: 'auto', height: 'auto',
              opacity: locked ? 0.45 : 1,
              filter: locked ? 'grayscale(0.8)' : 'none',
            }}
            onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none' }}
          />
        ) : (
          <div
            className="grid place-items-center"
            style={{
              width: 60, height: 60, borderRadius: 999,
              background: locked
                ? 'linear-gradient(135deg, #E2E8F0 0%, #CBD5E1 100%)'
                : `linear-gradient(135deg, ${chip.fg} 0%, ${chip.bg} 100%)`,
              boxShadow: locked ? 'none' : `0 8px 22px ${chip.fg}40`,
            }}
          >
            <Leaf
              className="w-7 h-7"
              style={{ color: locked ? TXT_MUTED : '#fff', opacity: 0.95 }}
              strokeWidth={2}
            />
          </div>
        )}
      </div>

      {/* Title + progress */}
      <div className="mt-auto flex flex-col" style={{ gap: 4 }}>
        <span
          className="font-body line-clamp-2"
          style={{
            fontSize: 18, fontWeight: 700, lineHeight: '25px',
            color: locked ? TXT_MID : TXT_DARK,
            minHeight: 50,
          }}
        >
          {m.name}
        </span>
        {!locked && (
          <div className="flex items-center" style={{ gap: 4, marginTop: 6 }}>
            <div
              className="flex-1"
              style={{
                height: 8, borderRadius: 14, background: '#F1F1F1', overflow: 'hidden',
              }}
            >
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${m.userPercentage || 0}%` }}
                transition={{ duration: 0.8, ease: 'easeOut' }}
                style={{ height: '100%', borderRadius: 14, background: CYAN }}
              />
            </div>
            <span
              className="font-body tabular-nums shrink-0"
              style={{
                fontSize: 16, fontWeight: 400, lineHeight: '22px', color: '#000',
                width: 36, textAlign: 'right',
              }}
            >
              {m.userPercentage || 0}%
            </span>
          </div>
        )}
      </div>
    </motion.button>
  )
}

// ---------------------------------------------------------------------------
function LoadingState() {
  return (
    <div className="flex flex-col" style={{ gap: 44 }}>
      {Array.from({ length: 3 }).map((_, i) => (
        <div
          key={i}
          className="bg-white animate-pulse"
          style={{ height: 112, borderRadius: 68 }}
        />
      ))}
    </div>
  )
}

function ErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="grid place-items-center py-24 text-center">
      <AlertTriangle className="w-10 h-10" style={{ color: TXT_MUTED }} />
      <h2
        className="font-body mt-3"
        style={{ fontSize: 18, fontWeight: 700, color: TXT_DARK }}
      >
        Couldn't load subjects
      </h2>
      <button
        type="button"
        onClick={onRetry}
        className="mt-4 grid place-items-center"
        style={{
          background: NAVY, color: '#fff', borderRadius: 42,
          padding: '10px 26px',
          fontFamily: 'var(--font-body)', fontSize: 16, fontWeight: 700,
        }}
      >
        Retry
      </button>
    </div>
  )
}
