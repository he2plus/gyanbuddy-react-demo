"""
Diagnostic: Find duplicate ModuleChapter names in the same module,
and trace UserChapterProgress rows that look like duplicates in admin.

Usage: python manage.py shell < scripts/debug_duplicate_chapters.py
"""

from django.db.models import Count
from gyaan_buddy.subjects.models import ModuleChapter, Module
from gyaan_buddy.users.models import UserChapterProgress
from django.contrib.auth import get_user_model

Account = get_user_model()

# ── CONFIG ──────────────────────────────────────────────────────────────────
# Set USERNAME to narrow down, or leave None for all users
USERNAME = None
# ────────────────────────────────────────────────────────────────────────────

print(f"\n{'='*80}")
print("  1. Duplicate ModuleChapter titles within the same module")
print(f"{'='*80}")

dupes = (
    ModuleChapter.objects
    .filter(is_deleted=False, is_enabled=True)
    .values('module', 'title')
    .annotate(cnt=Count('id'))
    .filter(cnt__gt=1)
    .order_by('module', 'title')
)

if not dupes.exists():
    print("  ✅ No duplicate chapter titles found within any module.")
else:
    print(f"  ❌ Found {dupes.count()} duplicate chapter title(s)!\n")
    for d in dupes:
        module = Module.objects.filter(id=d['module']).first()
        chapters = ModuleChapter.objects.filter(
            module_id=d['module'], title=d['title'], is_deleted=False
        ).order_by('order', 'created_at')
        print(f"  Module : {module.name if module else d['module']}")
        print(f"  Title  : {d['title']}  ({d['cnt']} copies)")
        for ch in chapters:
            q_count = ch.contents.filter(content_type='question', is_deleted=False).count()
            print(f"    id={ch.id}  order={ch.order}  questions={q_count}  created={ch.created_at.date()}  enabled={ch.is_enabled}")
        print()


print(f"\n{'='*80}")
print("  2. UserChapterProgress rows that appear as 'duplicates' in admin")
print("     (same user + same chapter title + same module → different chapter IDs)")
print(f"{'='*80}")

qs = UserChapterProgress.objects.select_related(
    'account', 'chapter', 'chapter__module'
).order_by('account__username', 'chapter__module__name', 'chapter__title', 'chapter__order')

if USERNAME:
    qs = qs.filter(account__username=USERNAME)

# Group by (user, module, chapter title)
from collections import defaultdict
groups = defaultdict(list)
for row in qs:
    key = (row.account.username, row.chapter.module.name, row.chapter.title)
    groups[key].append(row)

found = False
for (username, module_name, chapter_title), rows in groups.items():
    if len(rows) > 1:
        found = True
        print(f"\n  User    : {username}")
        print(f"  Module  : {module_name}")
        print(f"  Chapter : {chapter_title}")
        for r in rows:
            print(f"    progress_id={r.id}")
            print(f"      chapter_id={r.chapter.id}  order={r.chapter.order}  enabled={r.chapter.is_enabled}")
            print(f"      status={r.status}  %={r.percentage}  updated={r.updated_at.strftime('%Y-%m-%d %H:%M')}")

if not found:
    print("  ✅ No users have progress rows for two different chapters with the same title.")


print(f"\n{'='*80}")
print("  3. Chapters with order conflicts in the same module")
print(f"{'='*80}")

order_dupes = (
    ModuleChapter.objects
    .filter(is_deleted=False, is_enabled=True)
    .values('module', 'order')
    .annotate(cnt=Count('id'))
    .filter(cnt__gt=1)
    .order_by('module', 'order')
)

if not order_dupes.exists():
    print("  ✅ No order conflicts.")
else:
    print(f"  ❌ Found {order_dupes.count()} order conflict(s):\n")
    for d in order_dupes:
        module = Module.objects.filter(id=d['module']).first()
        chapters = ModuleChapter.objects.filter(
            module_id=d['module'], order=d['order'], is_deleted=False
        )
        print(f"  Module: {module.name if module else d['module']}  order={d['order']}")
        for ch in chapters:
            print(f"    id={ch.id}  title='{ch.title}'  enabled={ch.is_enabled}")
        print()


print(f"\n{'='*80}")
print("  4. Full chapter list for modules that have duplicate-titled chapters")
print(f"     (shows the complete chapter ordering so you know which to keep)")
print(f"{'='*80}")

dupe_module_ids = set(
    ModuleChapter.objects
    .filter(is_deleted=False)
    .values('module', 'title')
    .annotate(cnt=Count('id'))
    .filter(cnt__gt=1)
    .values_list('module', flat=True)
)

if not dupe_module_ids:
    print("  ✅ No modules with duplicate-titled chapters.")
else:
    for mid in dupe_module_ids:
        module = Module.objects.filter(id=mid).first()
        print(f"\n  Module: {module.name if module else mid}")
        print(f"  {'Order':>5}  {'Title':<40} {'ID':<36}  {'Del':>3}  {'Q':>3}")
        print(f"  {'─'*5}  {'─'*40} {'─'*36}  {'─'*3}  {'─'*3}")
        for ch in ModuleChapter.objects.filter(module_id=mid).order_by('order', 'created_at'):
            q = ch.contents.filter(content_type='question', is_deleted=False).count()
            deleted = 'Yes' if ch.is_deleted else 'No'
            print(f"  {ch.order:>5}  {ch.title[:39]:<40} {ch.id}  {deleted:>3}  {q:>3}")


print(f"\n{'='*80}\n  Done.\n{'='*80}\n")
