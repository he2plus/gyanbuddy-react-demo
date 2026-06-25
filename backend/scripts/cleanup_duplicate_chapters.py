"""
Cleanup: Merge duplicate ModuleChapter objects and fix UserChapterProgress.

Root cause: Multiple ModuleChapter objects with identical title+order exist in
the same module (likely from repeated imports). The module_chapters view uses
.order_by('order').first() which is non-deterministic with duplicate orders,
so different users were assigned to different chapter UUIDs.

Strategy:
  1. For each (module, title) duplicate group, pick ONE canonical chapter
     (most completed UserChapterProgress entries; tiebreak: earliest created_at)
  2. For each user who has progress on a non-canonical duplicate:
       - If user already has a row on canonical: keep the better row (higher %
         or completed > in_progress), delete the other
       - If user only has a row on a duplicate: reassign it to canonical
  3. Soft-delete all non-canonical duplicate chapters (is_deleted=True)

Usage:
  DRY_RUN = True   → prints what would happen, no DB changes
  DRY_RUN = False  → actually applies the changes

  python manage.py shell -c "
  DRY_RUN = True  # change to False to apply
  exec(open('scripts/cleanup_duplicate_chapters.py').read())
  "

  Or set DRY_RUN at the bottom of this file and run:
  python manage.py shell < scripts/cleanup_duplicate_chapters.py
"""

import sys
from collections import defaultdict
from django.db import transaction
from django.db.models import Count
from django.utils import timezone
from gyaan_buddy.subjects.models import ModuleChapter, Module
from gyaan_buddy.users.models import UserChapterProgress

# ── Set this before running ──────────────────────────────────────────────────
try:
    DRY_RUN
except NameError:
    DRY_RUN = True  # default to safe mode
# ────────────────────────────────────────────────────────────────────────────

STATUS_RANK = {'completed': 3, 'in_progress': 2, 'due': 1, 'not_started': 0}

def better_progress(a, b):
    """Return the UserChapterProgress row that represents more advancement."""
    rank_a = STATUS_RANK.get(a.status, 0)
    rank_b = STATUS_RANK.get(b.status, 0)
    if rank_a != rank_b:
        return a if rank_a > rank_b else b
    return a if a.percentage >= b.percentage else b

def pick_canonical(chapters):
    """
    Pick the canonical chapter from a list of duplicates.
    Prefer: most completed UCP entries → most total UCP entries → earliest created_at.
    """
    best = None
    best_completed = -1
    best_total = -1
    for ch in chapters:
        completed = UserChapterProgress.objects.filter(chapter=ch, status='completed').count()
        total = UserChapterProgress.objects.filter(chapter=ch).count()
        if (completed > best_completed or
                (completed == best_completed and total > best_total) or
                (completed == best_completed and total == best_total and best is not None and ch.created_at < best.created_at)):
            best = ch
            best_completed = completed
            best_total = total
    return best


print(f"\n{'='*80}")
print(f"  Duplicate Chapter Cleanup  |  DRY_RUN={'YES — no changes will be made' if DRY_RUN else 'NO — APPLYING CHANGES'}")
print(f"{'='*80}")

# Find all (module, title) pairs with more than one non-deleted chapter
dupe_groups = (
    ModuleChapter.objects
    .filter(is_deleted=False)
    .values('module', 'title')
    .annotate(cnt=Count('id'))
    .filter(cnt__gt=1)
    .order_by('module', 'title')
)

if not dupe_groups.exists():
    print("\n  ✅ No duplicate chapters found. Nothing to do.\n")
    sys.exit(0)

total_chapters_deleted = 0
total_ucp_reassigned = 0
total_ucp_deleted = 0

with transaction.atomic():
    for group in dupe_groups:
        chapters = list(
            ModuleChapter.objects.filter(
                module_id=group['module'], title=group['title'], is_deleted=False
            ).order_by('created_at')
        )
        module = Module.objects.filter(id=group['module']).first()
        canonical = pick_canonical(chapters)
        duplicates = [ch for ch in chapters if ch.id != canonical.id]

        print(f"\n  Module  : {module.name if module else group['module']}")
        print(f"  Chapter : {group['title']}  ({len(chapters)} copies)")
        print(f"  Canonical → id={canonical.id}  order={canonical.order}  created={canonical.created_at.date()}")

        for dup in duplicates:
            dup_ucp_rows = list(UserChapterProgress.objects.filter(chapter=dup).select_related('account'))
            print(f"\n    Duplicate id={dup.id}  order={dup.order}  created={dup.created_at.date()}"
                  f"  ({len(dup_ucp_rows)} progress rows)")

            for dup_row in dup_ucp_rows:
                user = dup_row.account
                try:
                    canonical_row = UserChapterProgress.objects.get(account=user, chapter=canonical)
                    # User has rows on BOTH — keep the better one on canonical, delete dup
                    winner = better_progress(canonical_row, dup_row)
                    loser = dup_row if winner == canonical_row else canonical_row

                    print(f"      User {user.username}: has BOTH rows")
                    print(f"        canonical: status={canonical_row.status} %={canonical_row.percentage}")
                    print(f"        duplicate: status={dup_row.status} %={dup_row.percentage}")
                    print(f"        → keep {'canonical' if winner == canonical_row else 'duplicate (merge to canonical)'}, delete {'duplicate' if winner == canonical_row else 'canonical'}")

                    if not DRY_RUN:
                        if winner == dup_row:
                            # Dup row is better — copy its values onto canonical row, then delete dup
                            canonical_row.status = dup_row.status
                            canonical_row.percentage = dup_row.percentage
                            canonical_row.current_question = dup_row.current_question
                            canonical_row.started_at = canonical_row.started_at or dup_row.started_at
                            canonical_row.completed_at = canonical_row.completed_at or dup_row.completed_at
                            canonical_row.save()
                        dup_row.delete()
                    total_ucp_deleted += 1

                except UserChapterProgress.DoesNotExist:
                    # User only has row on duplicate — reassign to canonical
                    print(f"      User {user.username}: only on duplicate (status={dup_row.status} %={dup_row.percentage}) → reassign to canonical")
                    if not DRY_RUN:
                        dup_row.chapter = canonical
                        dup_row.save(update_fields=['chapter'])
                    total_ucp_reassigned += 1

            # Soft-delete the duplicate chapter
            print(f"    → Soft-delete duplicate id={dup.id}")
            if not DRY_RUN:
                dup.is_deleted = True
                dup.save(update_fields=['is_deleted'])
            total_chapters_deleted += 1

    print(f"\n{'='*80}")
    print(f"  Summary")
    print(f"{'='*80}")
    print(f"  Chapters soft-deleted  : {total_chapters_deleted}")
    print(f"  UCP rows reassigned    : {total_ucp_reassigned}")
    print(f"  UCP rows deleted       : {total_ucp_deleted}")
    if DRY_RUN:
        print(f"\n  ⚠️  DRY RUN — no changes were made.")
        print(f"  Re-run with DRY_RUN=False to apply.")
    else:
        print(f"\n  ✅ Changes applied successfully.")
    print(f"{'='*80}\n")

    if DRY_RUN:
        # Force rollback even if atomic block succeeded
        transaction.set_rollback(True)
