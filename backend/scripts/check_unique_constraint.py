"""
Script: Detect duplicate UserChapterProgress entries (unique_together violation).
Usage: python manage.py shell < scripts/check_unique_constraint.py

Reports:
  - Any (account, chapter) pairs with more than one row
  - Orphaned rows (user or chapter deleted but FK not cascaded)
  - Chapters with more than one user having in_progress status
"""

from django.db.models import Count
from gyaan_buddy.users.models import UserChapterProgress

print(f"\n{'='*70}")
print("  1. Duplicate (account, chapter) pairs")
print(f"{'='*70}")

dupes = (
    UserChapterProgress.objects
    .values('account', 'chapter')
    .annotate(cnt=Count('id'))
    .filter(cnt__gt=1)
    .order_by('-cnt')
)

if not dupes.exists():
    print("  ✅ No duplicates found — unique constraint is clean.")
else:
    print(f"  ❌ Found {dupes.count()} duplicate pair(s)!\n")
    from gyaan_buddy.users.models import UserChapterProgress
    from django.contrib.auth import get_user_model
    Account = get_user_model()

    for d in dupes:
        user = Account.objects.filter(id=d['account']).first()
        from gyaan_buddy.subjects.models import ModuleChapter
        chapter = ModuleChapter.objects.filter(id=d['chapter']).first()
        rows = UserChapterProgress.objects.filter(
            account_id=d['account'], chapter_id=d['chapter']
        ).order_by('created_at')
        print(f"  User: {user.username if user else d['account']}  |  Chapter: {chapter.title if chapter else d['chapter']}")
        for r in rows:
            print(f"    id={r.id}  status={r.status}  %={r.percentage}  created={r.created_at}  updated={r.updated_at}")
        print()


print(f"\n{'='*70}")
print("  2. Multiple in_progress rows per user per module")
print(f"{'='*70}")

multi_ip = (
    UserChapterProgress.objects
    .filter(status='in_progress')
    .values('account', 'chapter__module')
    .annotate(cnt=Count('id'))
    .filter(cnt__gt=1)
    .order_by('-cnt')
)

if not multi_ip.exists():
    print("  ✅ No user has multiple in_progress chapters in the same module.")
else:
    print(f"  ❌ Found {multi_ip.count()} case(s) of multiple in_progress chapters!\n")
    from django.contrib.auth import get_user_model
    Account = get_user_model()
    from gyaan_buddy.subjects.models import Module

    for d in multi_ip:
        user = Account.objects.filter(id=d['account']).first()
        module = Module.objects.filter(id=d['chapter__module']).first()
        rows = UserChapterProgress.objects.filter(
            account_id=d['account'],
            chapter__module_id=d['chapter__module'],
            status='in_progress'
        ).select_related('chapter').order_by('chapter__order')
        print(f"  User: {user.username if user else d['account']}  |  Module: {module.name if module else d['chapter__module']}")
        for r in rows:
            print(f"    chapter='{r.chapter.title}'  order={r.chapter.order}  %={r.percentage}  updated={r.updated_at}")
        print()


print(f"\n{'='*70}")
print("  3. Chapters with no in_progress and no completed for any active user")
print(f"     (users who have started a module but have no active chapter)")
print(f"{'='*70}")

from gyaan_buddy.users.models import UserModuleProgress

# Users who have an in_progress module but zero in_progress chapters in it
problem_users = []
for ump in UserModuleProgress.objects.filter(status='in_progress').select_related('account', 'module'):
    has_ip_chapter = UserChapterProgress.objects.filter(
        account=ump.account,
        chapter__module=ump.module,
        status='in_progress'
    ).exists()
    if not has_ip_chapter:
        problem_users.append(ump)

if not problem_users:
    print("  ✅ All in_progress modules have at least one in_progress chapter.")
else:
    print(f"  ⚠️  Found {len(problem_users)} module(s) in_progress with no in_progress chapter:\n")
    for ump in problem_users:
        completed = UserChapterProgress.objects.filter(
            account=ump.account, chapter__module=ump.module, status='completed'
        ).count()
        total = ump.module.chapters.filter(is_enabled=True, is_deleted=False).count()
        print(f"  User: {ump.account.username}  |  Module: {ump.module.name}  |  Completed: {completed}/{total}")


print(f"\n{'='*70}")
print("  4. Completed chapters where the next chapter has no progress row at all")
print(f"     (chapters that should have been pre-advanced but weren't)")
print(f"{'='*70}")

from gyaan_buddy.subjects.models import ModuleChapter

missing_next = []
for ucp in UserChapterProgress.objects.filter(status='completed').select_related('account', 'chapter', 'chapter__module'):
    next_chapter = ModuleChapter.objects.filter(
        module=ucp.chapter.module,
        is_enabled=True,
        is_deleted=False,
        order__gt=ucp.chapter.order
    ).order_by('order').first()
    if next_chapter:
        next_exists = UserChapterProgress.objects.filter(
            account=ucp.account,
            chapter=next_chapter
        ).exists()
        if not next_exists:
            missing_next.append((ucp, next_chapter))

if not missing_next:
    print("  ✅ All completed chapters have a progress row for the next chapter.")
else:
    print(f"  ⚠️  Found {len(missing_next)} case(s) where next chapter has no progress row:\n")
    for ucp, nc in missing_next:
        print(f"  User: {ucp.account.username}  |  Completed: '{ucp.chapter.title}' (order={ucp.chapter.order})  |  Missing next: '{nc.title}' (order={nc.order})")

print(f"\n{'='*70}\n  Done.\n{'='*70}\n")
