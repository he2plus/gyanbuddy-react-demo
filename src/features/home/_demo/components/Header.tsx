import { Menu, LogOut } from 'lucide-react'

export function Header() {
  return (
    <header className="flex items-center justify-between px-4 py-4 sm:px-8 sm:py-5">
      <div className="flex items-center gap-3">
        <button
          aria-label="Open menu"
          className="grid h-9 w-9 place-items-center rounded-lg text-slate-700 transition-colors hover:bg-slate-100"
        >
          <Menu className="h-5 w-5" />
        </button>
        <h1 className="text-xl font-semibold text-slate-900">Home</h1>
      </div>
      <button className="flex items-center gap-2 rounded-lg px-3 py-2 text-slate-700 transition-colors hover:bg-slate-100">
        <LogOut className="h-4 w-4" />
        <span className="text-sm font-medium">Logout</span>
      </button>
    </header>
  )
}
