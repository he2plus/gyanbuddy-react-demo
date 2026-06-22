import type { ModuleChapter } from '../types/module'

// Meta / pre-assessment chapters that exist in the backend but shouldn't be
// shown to students as regular chapters.
const HIDDEN_CHAPTER_NAMES = ['previous knowledge testing']

function isHidden(c: ModuleChapter): boolean {
  return HIDDEN_CHAPTER_NAMES.includes((c.name || '').trim().toLowerCase())
}

/** Drop meta chapters from a chapter list. Falls back to the original list if
 *  filtering would leave nothing (so a module never renders empty). */
export function visibleChapters(chapters: ModuleChapter[]): ModuleChapter[] {
  const filtered = chapters.filter((c) => !isHidden(c))
  return filtered.length ? filtered : chapters
}
