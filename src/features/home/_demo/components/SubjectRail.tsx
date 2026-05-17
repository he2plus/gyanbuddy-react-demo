import { motion } from 'framer-motion'
import { subjectRail } from '../data/mock'

export function SubjectRail() {
  return (
    <div className="-mx-2 overflow-x-auto px-2">
      <ul className="flex items-center gap-3 pb-2">
        {subjectRail.map((s, i) => {
          const Icon = s.icon
          return (
            <motion.li
              key={s.id}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.04 * i, duration: 0.3, ease: 'easeOut' }}
            >
              <button
                aria-label={s.label}
                title={s.label}
                className={`grid h-14 w-14 place-items-center rounded-2xl border bg-white shadow-sm transition-all hover:scale-105 hover:shadow-md sm:h-16 sm:w-16 ${
                  s.active ? 'border-blue-400 ring-2 ring-blue-100' : 'border-slate-200'
                }`}
              >
                <Icon className={`h-6 w-6 ${s.active ? 'text-blue-600' : 'text-slate-700'}`} />
              </button>
            </motion.li>
          )
        })}
      </ul>
    </div>
  )
}
