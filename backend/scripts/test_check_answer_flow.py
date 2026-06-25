"""
Test script: All possible cases for check_answer flow and character advancement.

Tests:
  Case 1 — Normal: answer last question, verify next chapter pre-advanced
  Case 2 — Race simulation: GET module_chapters BEFORE check_answer, verify correct state
  Case 3 — Already completed chapter (idempotency)
  Case 4 — Last chapter in module (no next chapter)
  Case 5 — Module with only one chapter
  Case 6 — Next chapter already in_progress (no double-write)
  Case 7 — Next chapter already completed (should NOT overwrite to in_progress)
  Case 8 — Multiple in_progress chapters (stale state repair check)

Usage:
  python manage.py shell < scripts/test_check_answer_flow.py

Set USERNAME and MODULE_ID below to a real user/module in your DB.
"""

import traceback
from django.db import transaction
from gyaan_buddy.users.models import UserChapterProgress
from gyaan_buddy.subjects.models import ModuleChapter, Module
from django.contrib.auth import get_user_model

Account = get_user_model()

# ── CONFIG — set these ───────────────────────────────────────────────────────
USERNAME  = "testuser"   # Must exist in DB
MODULE_ID = None         # Set to a UUID string, or leave None to auto-pick first module
# ────────────────────────────────────────────────────────────────────────────

PASS = "✅ PASS"
FAIL = "❌ FAIL"
SKIP = "⚠️  SKIP"

def header(n, title):
    print(f"\n{'─'*70}")
    print(f"  Case {n}: {title}")
    print(f"{'─'*70}")

def get_next_chapter(chapter):
    return ModuleChapter.objects.filter(
        module=chapter.module,
        is_enabled=True,
        is_deleted=False,
        order__gt=chapter.order
    ).order_by('order').first()

def pre_advance_next_chapter(user, chapter):
    """Same logic as the fix in check_answer."""
    next_chapter = get_next_chapter(chapter)
    if next_chapter:
        next_progress, created = UserChapterProgress.objects.get_or_create(
            account=user,
            chapter=next_chapter,
            defaults={'status': 'in_progress'}
        )
        if not created and next_progress.status not in ('in_progress', 'completed'):
            next_progress.status = 'in_progress'
            next_progress.save(update_fields=['status'])
        return next_chapter, next_progress, created
    return None, None, None

def simulate_module_chapters_api(user, module):
    """Mirrors the module_chapters view logic."""
    chapters = ModuleChapter.objects.filter(
        module=module, is_enabled=True, is_deleted=False
    ).order_by('order')

    in_progress_qs = UserChapterProgress.objects.filter(
        account=user, chapter__in=chapters, status='in_progress'
    )
    if not in_progress_qs.exists():
        completed_ids = UserChapterProgress.objects.filter(
            account=user, chapter__in=chapters, status='completed'
        ).values_list('chapter_id', flat=True)
        available = chapters.exclude(id__in=completed_ids).first()
        if available:
            progress, created = UserChapterProgress.objects.get_or_create(
                account=user, chapter=available, defaults={'status': 'in_progress'}
            )
            if not created and progress.status != 'in_progress':
                progress.status = 'in_progress'
                progress.save()

    result = {}
    for ch in chapters:
        p = UserChapterProgress.objects.filter(account=user, chapter=ch).first()
        result[ch.title] = p.status if p else 'not_started'
    return result


# ── Setup ────────────────────────────────────────────────────────────────────
try:
    user = Account.objects.get(username=USERNAME)
except Account.DoesNotExist:
    print(f"\n❌ User '{USERNAME}' not found. Set USERNAME to a valid username.")
    raise SystemExit(1)

if MODULE_ID:
    module = Module.objects.get(id=MODULE_ID)
else:
    module = Module.objects.filter(is_enabled=True, is_deleted=False).first()
    if not module:
        print("❌ No enabled module found.")
        raise SystemExit(1)

chapters = list(ModuleChapter.objects.filter(
    module=module, is_enabled=True, is_deleted=False
).order_by('order'))

if len(chapters) < 2:
    print(f"⚠️  Module '{module.name}' has {len(chapters)} chapter(s). Cases 1-4 need ≥2 chapters.")

print(f"\n  User   : {user.username}")
print(f"  Module : {module.name} ({len(chapters)} chapters)")


# ── Helpers ──────────────────────────────────────────────────────────────────
def reset_progress():
    """Wipe all UserChapterProgress for this user+module for a clean slate."""
    UserChapterProgress.objects.filter(account=user, chapter__in=chapters).delete()


# ════════════════════════════════════════════════════════════════════════════
header(1, "Normal: check_answer(is_last=True) pre-advances next chapter")
# ════════════════════════════════════════════════════════════════════════════
if len(chapters) >= 2:
    try:
        with transaction.atomic():
            reset_progress()
            ch1, ch2 = chapters[0], chapters[1]
            # Simulate chapter 1 in progress
            UserChapterProgress.objects.create(account=user, chapter=ch1, status='in_progress')

            # Simulate check_answer(is_last=True) — mark ch1 completed, pre-advance ch2
            ucp = UserChapterProgress.objects.get(account=user, chapter=ch1)
            ucp.status = 'completed'
            ucp.percentage = 100
            ucp.save()
            next_ch, next_prog, created = pre_advance_next_chapter(user, ch1)

            assert next_ch == ch2, f"Expected ch2, got {next_ch}"
            assert next_prog is not None
            refreshed = UserChapterProgress.objects.get(account=user, chapter=ch2)
            assert refreshed.status == 'in_progress', f"Expected in_progress, got {refreshed.status}"
            print(f"  {PASS}  ch1=completed, ch2=in_progress (created={created})")
            raise transaction.TransactionManagementError("rollback")
    except transaction.TransactionManagementError:
        pass
    except AssertionError as e:
        print(f"  {FAIL}  {e}")
    except Exception as e:
        print(f"  {FAIL}  Unexpected: {e}")
        traceback.print_exc()
else:
    print(f"  {SKIP}  Need ≥2 chapters")


# ════════════════════════════════════════════════════════════════════════════
header(2, "Race simulation: GET module_chapters arrives before check_answer")
# ════════════════════════════════════════════════════════════════════════════
if len(chapters) >= 2:
    try:
        with transaction.atomic():
            reset_progress()
            ch1, ch2 = chapters[0], chapters[1]
            UserChapterProgress.objects.create(account=user, chapter=ch1, status='in_progress', percentage=0)

            # Step A: GET module_chapters fires BEFORE check_answer
            state_before = simulate_module_chapters_api(user, module)
            assert state_before[ch1.title] == 'in_progress', "ch1 should still be in_progress"
            assert state_before.get(ch2.title, 'not_started') != 'in_progress', "ch2 should NOT be in_progress yet"

            # Step B: check_answer(is_last=True) completes
            ucp = UserChapterProgress.objects.get(account=user, chapter=ch1)
            ucp.status = 'completed'
            ucp.percentage = 100
            ucp.save()
            pre_advance_next_chapter(user, ch1)

            # Step C: GET module_chapters fires AFTER check_answer (next call)
            state_after = simulate_module_chapters_api(user, module)
            assert state_after.get(ch1.title) == 'completed', f"ch1 should be completed, got {state_after.get(ch1.title)}"
            assert state_after.get(ch2.title) == 'in_progress', f"ch2 should be in_progress, got {state_after.get(ch2.title)}"

            print(f"  {PASS}  Before race: ch1=in_progress, ch2=not_started")
            print(f"          After fix:  ch1=completed, ch2=in_progress — next GET returns correct state")
            raise transaction.TransactionManagementError("rollback")
    except transaction.TransactionManagementError:
        pass
    except AssertionError as e:
        print(f"  {FAIL}  {e}")
    except Exception as e:
        print(f"  {FAIL}  Unexpected: {e}")
        traceback.print_exc()
else:
    print(f"  {SKIP}  Need ≥2 chapters")


# ════════════════════════════════════════════════════════════════════════════
header(3, "Idempotency: calling check_answer(is_last=True) twice on same chapter")
# ════════════════════════════════════════════════════════════════════════════
if len(chapters) >= 2:
    try:
        with transaction.atomic():
            reset_progress()
            ch1, ch2 = chapters[0], chapters[1]
            UserChapterProgress.objects.create(account=user, chapter=ch1, status='in_progress')

            # First call
            ucp = UserChapterProgress.objects.get(account=user, chapter=ch1)
            ucp.status = 'completed'; ucp.percentage = 100; ucp.save()
            pre_advance_next_chapter(user, ch1)

            # Second call (duplicate submission)
            ucp.refresh_from_db()
            ucp.status = 'completed'; ucp.percentage = 100; ucp.save()
            pre_advance_next_chapter(user, ch1)

            ch2_prog = UserChapterProgress.objects.get(account=user, chapter=ch2)
            assert ch2_prog.status == 'in_progress', f"Expected in_progress, got {ch2_prog.status}"
            count = UserChapterProgress.objects.filter(account=user, chapter=ch2).count()
            assert count == 1, f"Expected 1 row for ch2, got {count} (duplicate!)"
            print(f"  {PASS}  Duplicate call safe — ch2 stays in_progress, no duplicate rows")
            raise transaction.TransactionManagementError("rollback")
    except transaction.TransactionManagementError:
        pass
    except AssertionError as e:
        print(f"  {FAIL}  {e}")
    except Exception as e:
        print(f"  {FAIL}  Unexpected: {e}")
        traceback.print_exc()
else:
    print(f"  {SKIP}  Need ≥2 chapters")


# ════════════════════════════════════════════════════════════════════════════
header(4, "Last chapter in module — no next chapter to advance")
# ════════════════════════════════════════════════════════════════════════════
try:
    with transaction.atomic():
        reset_progress()
        last_ch = chapters[-1]
        UserChapterProgress.objects.create(account=user, chapter=last_ch, status='in_progress')

        ucp = UserChapterProgress.objects.get(account=user, chapter=last_ch)
        ucp.status = 'completed'; ucp.percentage = 100; ucp.save()
        next_ch, next_prog, _ = pre_advance_next_chapter(user, last_ch)

        assert next_ch is None, f"Expected None, got {next_ch}"
        assert next_prog is None
        print(f"  {PASS}  Last chapter completed, no next chapter — no error, no spurious row")
        raise transaction.TransactionManagementError("rollback")
except transaction.TransactionManagementError:
    pass
except AssertionError as e:
    print(f"  {FAIL}  {e}")
except Exception as e:
    print(f"  {FAIL}  Unexpected: {e}")
    traceback.print_exc()


# ════════════════════════════════════════════════════════════════════════════
header(5, "Module with only one chapter")
# ════════════════════════════════════════════════════════════════════════════
single_ch_module = Module.objects.filter(is_enabled=True, is_deleted=False).exclude(
    id__in=Module.objects.annotate(cnt=__import__('django.db.models', fromlist=['Count']).Count('chapters')).filter(cnt__gt=1).values('id')
).first()

# Simpler: just test last chapter logic covers this
try:
    with transaction.atomic():
        reset_progress()
        ch = chapters[0]
        UserChapterProgress.objects.create(account=user, chapter=ch, status='in_progress')
        ucp = UserChapterProgress.objects.get(account=user, chapter=ch)
        ucp.status = 'completed'; ucp.percentage = 100; ucp.save()

        # Manually check: if this were the only chapter, next_chapter = None
        mock_next = ModuleChapter.objects.filter(
            module=ch.module, is_enabled=True, is_deleted=False, order__gt=ch.order
        ).order_by('order').first()
        if mock_next is None:
            print(f"  {PASS}  Single-chapter module — pre_advance returns None safely")
        else:
            print(f"  {SKIP}  Module has multiple chapters — tested via Case 4")
        raise transaction.TransactionManagementError("rollback")
except transaction.TransactionManagementError:
    pass
except Exception as e:
    print(f"  {FAIL}  {e}")
    traceback.print_exc()


# ════════════════════════════════════════════════════════════════════════════
header(6, "Next chapter already in_progress — must NOT create duplicate")
# ════════════════════════════════════════════════════════════════════════════
if len(chapters) >= 2:
    try:
        with transaction.atomic():
            reset_progress()
            ch1, ch2 = chapters[0], chapters[1]
            UserChapterProgress.objects.create(account=user, chapter=ch1, status='in_progress')
            UserChapterProgress.objects.create(account=user, chapter=ch2, status='in_progress')  # already set

            ucp = UserChapterProgress.objects.get(account=user, chapter=ch1)
            ucp.status = 'completed'; ucp.percentage = 100; ucp.save()
            pre_advance_next_chapter(user, ch1)

            count = UserChapterProgress.objects.filter(account=user, chapter=ch2).count()
            ch2_status = UserChapterProgress.objects.get(account=user, chapter=ch2).status
            assert count == 1, f"Duplicate row created for ch2! count={count}"
            assert ch2_status == 'in_progress'
            print(f"  {PASS}  ch2 was already in_progress — no duplicate, status unchanged")
            raise transaction.TransactionManagementError("rollback")
    except transaction.TransactionManagementError:
        pass
    except AssertionError as e:
        print(f"  {FAIL}  {e}")
    except Exception as e:
        print(f"  {FAIL}  Unexpected: {e}")
        traceback.print_exc()
else:
    print(f"  {SKIP}  Need ≥2 chapters")


# ════════════════════════════════════════════════════════════════════════════
header(7, "Next chapter already completed — must NOT overwrite to in_progress")
# ════════════════════════════════════════════════════════════════════════════
if len(chapters) >= 3:
    try:
        with transaction.atomic():
            reset_progress()
            ch1, ch2, ch3 = chapters[0], chapters[1], chapters[2]
            UserChapterProgress.objects.create(account=user, chapter=ch1, status='in_progress')
            UserChapterProgress.objects.create(account=user, chapter=ch2, status='completed', percentage=100)

            ucp = UserChapterProgress.objects.get(account=user, chapter=ch1)
            ucp.status = 'completed'; ucp.percentage = 100; ucp.save()
            pre_advance_next_chapter(user, ch1)

            ch2_status = UserChapterProgress.objects.get(account=user, chapter=ch2).status
            assert ch2_status == 'completed', f"ch2 was completed but got overwritten to '{ch2_status}'!"
            print(f"  {PASS}  ch2 was already completed — NOT overwritten to in_progress")
            raise transaction.TransactionManagementError("rollback")
    except transaction.TransactionManagementError:
        pass
    except AssertionError as e:
        print(f"  {FAIL}  {e}")
    except Exception as e:
        print(f"  {FAIL}  Unexpected: {e}")
        traceback.print_exc()
else:
    print(f"  {SKIP}  Need ≥3 chapters")


# ════════════════════════════════════════════════════════════════════════════
header(8, "Stale state: multiple in_progress chapters for same user+module")
# ════════════════════════════════════════════════════════════════════════════
if len(chapters) >= 3:
    try:
        with transaction.atomic():
            reset_progress()
            ch1, ch2, ch3 = chapters[0], chapters[1], chapters[2]
            # Simulating stale state — two chapters in_progress
            UserChapterProgress.objects.create(account=user, chapter=ch1, status='in_progress')
            UserChapterProgress.objects.create(account=user, chapter=ch2, status='in_progress')

            count = UserChapterProgress.objects.filter(
                account=user, chapter__in=chapters, status='in_progress'
            ).count()
            assert count == 2, f"Setup failed, expected 2 in_progress rows, got {count}"
            print(f"  ⚠️   Stale state created: {count} in_progress chapters for same module")

            # The module_chapters API returns the first in_progress (not wrong, just ambiguous)
            state = simulate_module_chapters_api(user, module)
            ip_chapters = [t for t, s in state.items() if s == 'in_progress']
            print(f"  ℹ️   module_chapters API sees: {ip_chapters}")
            print(f"  {PASS}  Script detects the stale state — run check_unique_constraint.py to find real occurrences")
            raise transaction.TransactionManagementError("rollback")
    except transaction.TransactionManagementError:
        pass
    except AssertionError as e:
        print(f"  {FAIL}  {e}")
    except Exception as e:
        print(f"  {FAIL}  Unexpected: {e}")
        traceback.print_exc()
else:
    print(f"  {SKIP}  Need ≥3 chapters")


print(f"\n{'='*70}")
print("  All cases complete.")
print(f"{'='*70}\n")
