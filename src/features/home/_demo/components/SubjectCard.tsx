import { Check, Clock, Atom } from 'lucide-react'
import { motion } from 'framer-motion'
import { chemistry } from '../data/mock'
import type { ChapterStatus } from '../data/mock'

function StatusIcon({ status }: { status: ChapterStatus }) {
  if (status === 'completed') {
    return (
      <span className="grid h-6 w-6 place-items-center rounded-full bg-emerald-500 text-white">
        <Check className="h-4 w-4" strokeWidth={3} />
      </span>
    )
  }
  if (status === 'due') {
    return (
      <span className="grid h-6 w-6 place-items-center rounded-full bg-amber-100 text-amber-600">
        <Clock className="h-4 w-4" />
      </span>
    )
  }
  return null
}

function MoleculePlaceholder() {
  return (
    <svg viewBox="0 0 220 130" className="h-28 w-auto sm:h-32" aria-hidden="true">
      <line x1="40" y1="70" x2="100" y2="45" stroke="#6366F1" strokeWidth="3" />
      <line x1="100" y1="45" x2="170" y2="70" stroke="#6366F1" strokeWidth="3" />
      <line x1="100" y1="45" x2="100" y2="100" stroke="#6366F1" strokeWidth="3" />
      <line x1="170" y1="70" x2="195" y2="50" stroke="#8B5CF6" strokeWidth="3" />
      <circle cx="40" cy="70" r="14" fill="#3B82F6" />
      <circle cx="100" cy="45" r="14" fill="#6366F1" />
      <circle cx="170" cy="70" r="14" fill="#3B82F6" />
      <circle cx="100" cy="100" r="14" fill="#8B5CF6" />
      <circle cx="195" cy="50" r="9" fill="#A78BFA" />
      <circle cx="40" cy="70" r="5" fill="white" opacity="0.35" />
      <circle cx="100" cy="45" r="5" fill="white" opacity="0.35" />
      <circle cx="170" cy="70" r="5" fill="white" opacity="0.35" />
      <circle cx="100" cy="100" r="5" fill="white" opacity="0.35" />
    </svg>
  )
}

export function SubjectCard() {
  const visibleChapters = chemistry.chapters.slice(0, 2)
  const moreCount = chemistry.chapters.length - visibleChapters.length

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-slate-900">{chemistry.name}</h2>
          <div className="mt-1 text-xs font-semibold tracking-widest text-slate-400">
            LEVEL {chemistry.level}
          </div>
        </div>
        {chemistry.due && (
          <span className="inline-flex items-center gap-1 rounded-full bg-amber-500 px-3 py-1 text-xs font-semibold text-white shadow-sm">
            <Clock className="h-3 w-3" />
            Due
          </span>
        )}
      </div>

      <div className="my-5 grid place-items-center">
        <MoleculePlaceholder />
      </div>

      <div className="mt-2">
        <h3 className="text-sm font-semibold text-slate-700">Chapters</h3>
        <ul className="mt-3 space-y-2">
          {visibleChapters.map((c) => (
            <li
              key={c.id}
              className="flex items-center justify-between rounded-xl bg-slate-50 px-3 py-2.5 transition-colors hover:bg-slate-100"
            >
              <div className="flex items-center gap-3">
                <span
                  className="grid h-9 w-9 place-items-center rounded-lg"
                  style={{
                    background:
                      'linear-gradient(135deg, #f3e8ff 0%, #ddd6fe 100%)',
                  }}
                >
                  <Atom className="h-5 w-5 text-violet-600" />
                </span>
                <span className="text-sm font-medium text-slate-800">{c.title}</span>
              </div>
              <StatusIcon status={c.status} />
            </li>
          ))}
        </ul>
        <p className="mt-3 text-xs text-slate-500">+{moreCount} more chapters</p>
      </div>

      <motion.button
        whileTap={{ scale: 0.97 }}
        whileHover={{ y: -1 }}
        className="mt-5 w-full rounded-xl bg-blue-500 py-3.5 text-base font-semibold text-white shadow-md shadow-blue-500/30 transition-colors hover:bg-blue-600"
      >
        Start
      </motion.button>
    </div>
  )
}
