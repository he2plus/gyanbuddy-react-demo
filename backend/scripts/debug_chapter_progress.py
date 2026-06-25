"""
Debug script: UserChapterProgress data with username.
Usage: python manage.py shell < scripts/debug_chapter_progress.py
   or: python manage.py shell -c "exec(open('scripts/debug_chapter_progress.py').read())"

Optional filters at the bottom — edit USERNAME / MODULE_ID / CHAPTER_ID as needed.
"""

from gyaan_buddy.users.models import UserChapterProgress
from django.contrib.auth import get_user_model

Account = get_user_model()

# ── CONFIG ──────────────────────────────────────────────────────────────────
USERNAME    = None   # set to "john" to filter by user, None = all users
MODULE_ID   = None   # set to UUID string to filter by module, None = all modules
CHAPTER_ID  = None   # set to UUID string to filter by chapter, None = all chapters
STATUS      = None   # "in_progress" | "completed" | "not_started" | "due" | None = all
# ────────────────────────────────────────────────────────────────────────────

qs = UserChapterProgress.objects.select_related(
    'account', 'chapter', 'chapter__module', 'current_question'
).order_by('account__username', 'chapter__module__name', 'chapter__order')

if USERNAME:
    qs = qs.filter(account__username=USERNAME)
if MODULE_ID:
    qs = qs.filter(chapter__module__id=MODULE_ID)
if CHAPTER_ID:
    qs = qs.filter(chapter__id=CHAPTER_ID)
if STATUS:
    qs = qs.filter(status=STATUS)

total = qs.count()
print(f"\n{'='*90}")
print(f"  UserChapterProgress — {total} record(s)")
print(f"{'='*90}")
print(f"{'Username':<20} {'Module':<25} {'Chapter':<30} {'Ord':>3}  {'Status':<12} {'%':>4}  {'CurrentQuestion'}")
print(f"{'-'*20} {'-'*25} {'-'*30} {'-'*3}  {'-'*12} {'-'*4}  {'-'*36}")

for p in qs:
    cq = str(p.current_question.id)[:8] + '…' if p.current_question else '—'
    print(
        f"{p.account.username:<20} "
        f"{p.chapter.module.name[:24]:<25} "
        f"{p.chapter.title[:29]:<30} "
        f"{p.chapter.order:>3}  "
        f"{p.status:<12} "
        f"{p.percentage:>4}%  "
        f"{cq}"
    )

print(f"\nTotal: {total}")


# ── Per-user summary ─────────────────────────────────────────────────────────
print(f"\n{'='*60}")
print("  Per-user summary")
print(f"{'='*60}")
from django.db.models import Count

summary = (
    UserChapterProgress.objects
    .values('account__username', 'status')
    .annotate(count=Count('id'))
    .order_by('account__username', 'status')
)
if USERNAME:
    summary = summary.filter(account__username=USERNAME)

prev_user = None
for row in summary:
    if row['account__username'] != prev_user:
        print(f"\n  {row['account__username']}")
        prev_user = row['account__username']
    print(f"    {row['status']:<15} {row['count']}")
