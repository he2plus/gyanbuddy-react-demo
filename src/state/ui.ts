/**
 * UI store — theme, modals, sidenav collapsed state.
 *
 * Sidenav collapsed state is persisted to localStorage so the user's
 * preference survives page reloads.
 */
import { create } from 'zustand'

const SIDENAV_KEY = 'sidenav_collapsed'

const readCollapsed = (): boolean => {
  if (typeof window === 'undefined') return false
  return localStorage.getItem(SIDENAV_KEY) === '1'
}

type UIState = {
  modal: { kind: string; payload?: unknown } | null
  sidenavCollapsed: boolean

  openModal: (kind: string, payload?: unknown) => void
  closeModal: () => void
  toggleSidenav: () => void
  setSidenavCollapsed: (collapsed: boolean) => void
}

export const useUIStore = create<UIState>((set, get) => ({
  modal: null,
  sidenavCollapsed: readCollapsed(),

  openModal: (kind, payload) => set({ modal: { kind, payload } }),
  closeModal: () => set({ modal: null }),

  toggleSidenav: () => {
    const next = !get().sidenavCollapsed
    if (typeof window !== 'undefined') {
      localStorage.setItem(SIDENAV_KEY, next ? '1' : '0')
    }
    set({ sidenavCollapsed: next })
  },
  setSidenavCollapsed: (collapsed) => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(SIDENAV_KEY, collapsed ? '1' : '0')
    }
    set({ sidenavCollapsed: collapsed })
  },
}))
