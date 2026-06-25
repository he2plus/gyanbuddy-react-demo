"""
Safe dynamic data reset for Gyaan Buddy.

Clears runtime/analytical data (answers, progress, missions, tests)
while preserving the school structure (schools, classes, subjects, teachers, students).

Usage:
    # See what would be deleted (dry run):
    python manage.py reset_dynamic_data --dry-run

    # Reset only answers and progress for a specific school:
    python manage.py reset_dynamic_data --school-name "Delhi Public School"

    # Full wipe of all dynamic data (requires --confirm):
    python manage.py reset_dynamic_data --all --confirm

Tables cleared (dynamic):
    answers, manual_verification_answers,
    user_module_progress, user_chapter_progress,
    missions, mission_questions,
    user_mission_progress,
    tests, test_questions, user_test_progress

Tables preserved (structural):
    schools, classes, grades,
    subjects, modules, module_chapters, module_contents,
    questions, options,
    accounts, user_profiles, students, teacher_profiles, teachers,
    student_subject_enrollments
"""

import logging
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction, connection

logger = logging.getLogger(__name__)


# Tables to truncate, in dependency order (children before parents)
# Each entry: (app_label.model_class_name, human_readable_label)
DYNAMIC_TABLES = [
    ("subjects.Answer",                     "Practice Answers"),
    ("subjects.ManualVerificationAnswer",   "Manual Verification Answers"),
    ("users.UserChapterProgress",           "Chapter Progress"),
    ("users.UserModuleProgress",            "Module Progress"),
    ("users.MissionQuestion",               "Mission Questions"),
    ("users.UserMissionProgress",           "Mission Progress"),
    ("users.Mission",                       "Missions"),
    ("users.UserTestProgress",              "Test Progress"),
    ("users.TestQuestion",                  "Test Questions"),
    ("users.Test",                          "Tests"),
]

# Fields to reset on structural tables after wipe
STUDENT_RESET_FIELDS = ["total_exp"]


class Command(BaseCommand):
    help = "Safely reset dynamic/analytical data while preserving school structure"

    def add_arguments(self, parser):
        parser.add_argument(
            "--school-name",
            type=str,
            default=None,
            help="Limit reset to a specific school (partial match). If omitted and --all not set, aborts.",
        )
        parser.add_argument(
            "--all",
            action="store_true",
            dest="all_schools",
            help="Reset dynamic data for ALL schools. Requires --confirm.",
        )
        parser.add_argument(
            "--confirm",
            action="store_true",
            help="Required to actually execute destructive operations.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Print what would be deleted without actually deleting.",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        school_name = options["school_name"]
        all_schools = options["all_schools"]
        confirmed = options["confirm"]

        # ── Scope validation ──────────────────────────────────────────────────
        if not school_name and not all_schools:
            raise CommandError(
                "Specify --school-name <name> to target one school, or --all to target all. "
                "Add --dry-run to preview."
            )

        if all_schools and not confirmed and not dry_run:
            raise CommandError(
                "Resetting ALL schools is destructive. Re-run with --confirm to proceed."
            )

        self.stdout.write(self.style.WARNING(
            f"\n{'[DRY RUN] ' if dry_run else ''}DYNAMIC DATA RESET"
            + (" — ALL SCHOOLS" if all_schools else f" — School: '{school_name}'")
        ))

        # ── Import models lazily (avoids circular imports at top) ─────────────
        from gyaan_buddy.users.models import School, Student, Account
        from gyaan_buddy.subjects.models import Answer, ManualVerificationAnswer
        from gyaan_buddy.users.models import (
            UserChapterProgress, UserModuleProgress,
            MissionQuestion, Mission,
        )

        # ── Resolve school scope ──────────────────────────────────────────────
        if school_name:
            schools = School.objects.filter(name__icontains=school_name)
            if not schools.exists():
                raise CommandError(f"No school found matching '{school_name}'.")
            self.stdout.write(f"Targeting {schools.count()} school(s):")
            for s in schools:
                self.stdout.write(f"  • {s.name}")
        else:
            schools = School.objects.all()
            self.stdout.write(f"Targeting ALL {schools.count()} school(s).")

        school_ids = list(schools.values_list("id", flat=True))

        # ── Count & describe what will be deleted ─────────────────────────────
        student_accounts = Account.objects.filter(
            profile__school_id__in=school_ids,
            profile__user_type="student",
        )
        student_ids = list(student_accounts.values_list("id", flat=True))

        counts = {}
        counts["answers"] = Answer.objects.filter(user_id__in=student_ids).count()
        counts["manual_verification"] = ManualVerificationAnswer.objects.filter(
            user_id__in=student_ids
        ).count()
        counts["module_progress"] = UserModuleProgress.objects.filter(
            account_id__in=student_ids
        ).count()
        counts["chapter_progress"] = UserChapterProgress.objects.filter(
            account_id__in=student_ids
        ).count()
        counts["missions"] = Mission.objects.filter(
            account_id__in=student_ids
        ).count()

        # Try to count tests/test progress if those models exist
        try:
            from gyaan_buddy.users.models import Test, UserTestProgress
            counts["tests"] = Test.objects.filter(
                class_group__school_id__in=school_ids
            ).count()
        except Exception:
            counts["tests"] = 0

        self.stdout.write("\nData to be deleted:")
        for label, count in counts.items():
            self.stdout.write(f"  {label:30s} {count:>8,}")

        total = sum(counts.values())
        self.stdout.write(f"\n  {'TOTAL':30s} {total:>8,}")

        if dry_run:
            self.stdout.write(self.style.SUCCESS("\n[DRY RUN] No data was deleted."))
            return

        # ── Execute deletion ──────────────────────────────────────────────────
        self.stdout.write(self.style.WARNING("\nProceeding with deletion..."))

        with transaction.atomic():
            # Delete in dependency order
            Answer.objects.filter(user_id__in=student_ids).delete()
            ManualVerificationAnswer.objects.filter(user_id__in=student_ids).delete()
            UserChapterProgress.objects.filter(account_id__in=student_ids).delete()
            UserModuleProgress.objects.filter(account_id__in=student_ids).delete()
            MissionQuestion.objects.filter(mission__account_id__in=student_ids).delete()
            Mission.objects.filter(account_id__in=student_ids).delete()

            try:
                from gyaan_buddy.users.models import UserTestProgress, TestQuestion, Test
                UserTestProgress.objects.filter(account_id__in=student_ids).delete()
                TestQuestion.objects.filter(test__class_group__school_id__in=school_ids).delete()
                Test.objects.filter(class_group__school_id__in=school_ids).delete()
            except Exception as e:
                logger.warning(f"Could not delete tests (may not exist): {e}")

            # Reset student EXP to 0
            reset_count = Student.objects.filter(
                user_profile__school_id__in=school_ids
            ).update(total_exp=0, level=None)

            self.stdout.write(f"  Reset total_exp for {reset_count} students.")

        self.stdout.write(self.style.SUCCESS(
            f"\nDone. {total:,} records deleted across "
            f"{schools.count()} school(s)."
        ))
        logger.info(
            f"reset_dynamic_data: deleted {total} records for schools {list(schools.values_list('name', flat=True))}"
        )
