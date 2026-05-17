import {
  Atom,
  Globe,
  Leaf,
  Layers,
  Dna,
  Castle,
  Truck,
  Scroll,
  FlaskConical,
  type LucideIcon,
} from 'lucide-react'

export type User = {
  id: string
  name: string
  initial: string
  xp: number
  classroom: string
  progress: number
}

export type LeaderboardEntry = {
  rank: number
  name: string
  initial: string
  xp: number
  isYou: boolean
  avatarColor: string
}

export type ChapterStatus = 'completed' | 'due' | 'locked' | 'pending'

export type Chapter = {
  id: string
  title: string
  status: ChapterStatus
}

export type Subject = {
  id: string
  name: string
  level: number
  due: boolean
  chapters: Chapter[]
}

export type RailItem = {
  id: string
  label: string
  icon: LucideIcon
  active?: boolean
}

export const me: User = {
  id: 'u_kanwarjot',
  name: 'Kanwarjot',
  initial: 'K',
  xp: 1544,
  classroom: '10-C',
  progress: 19,
}

export const leaderboard: LeaderboardEntry[] = [
  { rank: 1, name: 'Kanwarjot Kaur', initial: 'K', xp: 1544, isYou: true, avatarColor: '#FACC15' },
  { rank: 2, name: 'Chirag Rajput', initial: 'C', xp: 1197, isYou: false, avatarColor: '#9CA3AF' },
  { rank: 3, name: 'Daksh', initial: 'D', xp: 1007, isYou: false, avatarColor: '#92400E' },
]

export const chemistry: Subject = {
  id: 's_chemistry',
  name: 'Chemistry',
  level: 1,
  due: true,
  chapters: [
    { id: 'c1', title: 'Chemical Reactions and Equations', status: 'completed' },
    { id: 'c2', title: 'Acids, Bases and Salts', status: 'due' },
    { id: 'c3', title: 'Metals and Non-metals', status: 'pending' },
    { id: 'c4', title: 'Carbon and its Compounds', status: 'pending' },
  ],
}

export const subjectRail: RailItem[] = [
  { id: 'r1', label: 'Chemistry', icon: FlaskConical, active: true },
  { id: 'r2', label: 'Physics', icon: Atom },
  { id: 'r3', label: 'Geography', icon: Globe },
  { id: 'r4', label: 'Biology', icon: Leaf },
  { id: 'r5', label: 'Maths', icon: Layers },
  { id: 'r6', label: 'Genetics', icon: Dna },
  { id: 'r7', label: 'History', icon: Castle },
  { id: 'r8', label: 'Economics', icon: Truck },
  { id: 'r9', label: 'Sanskrit', icon: Scroll },
]
