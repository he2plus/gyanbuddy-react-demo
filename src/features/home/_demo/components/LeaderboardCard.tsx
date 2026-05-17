import { motion } from 'framer-motion'
import { leaderboard, me } from '../data/mock'
import { Avatar } from './Avatar'

function TrophyIllustration() {
  return (
    <svg viewBox="0 0 200 200" fill="none" className="h-32 w-32 sm:h-44 sm:w-44 opacity-90">
      <path d="M50 40h100v40c0 25-20 45-45 45h-10c-25 0-45-20-45-45V40z" fill="white" />
      <path
        d="M50 50c-15 0-25 8-25 20s10 20 25 20"
        stroke="white"
        strokeWidth="6"
        fill="none"
      />
      <path
        d="M150 50c15 0 25 8 25 20s-10 20-25 20"
        stroke="white"
        strokeWidth="6"
        fill="none"
      />
      <rect x="80" y="125" width="40" height="20" fill="white" />
      <rect x="60" y="145" width="80" height="14" rx="3" fill="white" />
      <path
        d="M100 60l6 14 15 1-11 10 4 15-14-8-14 8 4-15-11-10 15-1 6-14z"
        fill="#1F2484"
      />
    </svg>
  )
}

export function LeaderboardCard() {
  const top = leaderboard[0]

  return (
    <div className="space-y-6">
      <div
        className="relative overflow-hidden rounded-2xl p-6 sm:p-7"
        style={{
          background:
            'linear-gradient(135deg, #1a1a6e 0%, #0a0d4d 60%, #0a0d4d 100%)',
        }}
      >
        <div className="relative z-10 max-w-[58%]">
          <div className="text-xl font-extrabold tracking-tight text-white">
            Gyan<span className="text-cyan-300">Buddy</span>
          </div>
          <div className="mt-0.5 text-[10px] font-medium tracking-widest text-cyan-200/70">
            A SMARTER WAY TO LEARN
          </div>

          <div className="mt-5 inline-flex rounded-full bg-white/15 px-4 py-2 text-sm font-medium text-white backdrop-blur">
            The week King of Leaderboard
          </div>

          <div className="mt-4 flex items-center gap-3">
            <Avatar initial={top.initial} color={top.avatarColor} size="md" />
            <div>
              <div className="text-xl font-bold text-white">{me.name}</div>
              <div className="text-sm text-cyan-200/80">{top.xp} Xp</div>
            </div>
          </div>
        </div>

        <div className="pointer-events-none absolute right-0 top-1/2 -translate-y-1/2">
          <TrophyIllustration />
        </div>
      </div>

      <div>
        <h3 className="text-center text-2xl font-bold text-slate-900">Leaderboard</h3>

        <div className="mt-4 flex justify-center">
          <span
            className="inline-flex min-w-[280px] items-center justify-center rounded-full px-8 py-1.5 text-sm font-semibold text-white shadow-md"
            style={{
              background: 'linear-gradient(135deg, #6366f1 0%, #818cf8 100%)',
            }}
          >
            {me.classroom}
          </span>
        </div>

        <ul className="mt-4 space-y-3">
          {leaderboard.map((entry, i) => (
            <motion.li
              key={entry.rank}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.06 * i, duration: 0.35, ease: 'easeOut' }}
              className={`flex items-center justify-between rounded-2xl border px-4 py-3 transition-all hover:-translate-y-0.5 hover:shadow-md ${
                entry.isYou
                  ? 'border-blue-200 bg-blue-50/60'
                  : 'border-slate-200 bg-white'
              }`}
            >
              <div className="flex items-center gap-3">
                <span className="w-6 text-center text-sm font-semibold text-slate-700">
                  {entry.rank}.
                </span>
                <Avatar initial={entry.initial} color={entry.avatarColor} size="md" />
                <div className="flex items-center gap-2">
                  <span className="font-medium text-slate-900">{entry.name}</span>
                  {entry.isYou && (
                    <span className="rounded-full bg-blue-100 px-2 py-0.5 text-xs font-semibold text-blue-700">
                      You
                    </span>
                  )}
                </div>
              </div>
              <span className="text-sm font-semibold text-slate-700">{entry.xp} XP</span>
            </motion.li>
          ))}
        </ul>
      </div>
    </div>
  )
}
