import { Bell, ClipboardList, TrendingUp } from 'lucide-react'
import { AnimatedCounter } from './AnimatedCounter'
import { me } from '../data/mock'

export function HeroGreeting() {
  return (
    <section className="flex flex-col gap-5 px-4 sm:flex-row sm:items-center sm:justify-between sm:gap-6 sm:px-8">
      <div className="flex items-center gap-4">
        <div
          className="grid h-16 w-16 place-items-center rounded-full text-2xl font-bold text-white shadow-lg shadow-violet-300/40 sm:h-20 sm:w-20 sm:text-3xl"
          style={{ background: 'linear-gradient(135deg, #a855f7 0%, #6d28d9 100%)' }}
          aria-hidden="true"
        >
          {me.initial}
        </div>
        <div className="min-w-0">
          <h2 className="text-2xl font-bold text-slate-900 sm:text-3xl">Hello, {me.name}</h2>
          <div className="mt-2 flex flex-wrap items-center gap-2 text-sm text-slate-600">
            <TrendingUp className="h-4 w-4 text-blue-500" />
            <span>
              Progress: <span className="font-semibold text-slate-900">{me.progress}%</span>
            </span>
            <div
              className="ml-1 h-1.5 w-24 overflow-hidden rounded-full bg-slate-200"
              role="progressbar"
              aria-valuenow={me.progress}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-label="Overall progress"
            >
              <div
                className="h-full rounded-full bg-gradient-to-r from-blue-500 to-violet-500 transition-all duration-700 ease-out"
                style={{ width: `${me.progress}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2 shadow-sm">
          <span className="text-xs font-bold text-blue-600">XP</span>
          <AnimatedCounter value={me.xp} className="text-sm font-semibold text-slate-900" />
        </div>
        <button
          aria-label="Notifications"
          className="grid h-10 w-10 place-items-center rounded-full border border-slate-200 bg-white text-slate-700 shadow-sm transition-colors hover:bg-slate-50"
        >
          <Bell className="h-4 w-4" />
        </button>
        <button className="flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-900 shadow-sm transition-colors hover:bg-slate-50">
          <ClipboardList className="h-4 w-4 text-blue-600" />
          Tests
        </button>
      </div>
    </section>
  )
}
