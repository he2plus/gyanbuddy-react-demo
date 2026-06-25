"""
Wipe all data for a single school: users (students, teachers, admins),
classes, subjects, modules, questions, missions, tests, competitions,
and the school record itself.

Cascade order:
  1. Delete all Accounts whose profile is linked to this school
     → cascades to UserProfile, Student, TeacherProfile, Teacher,
       StudentSubjectEnrollment, UserModuleProgress, UserChapterProgress,
       UserMissionProgress, UserCompetitionProgress, UserTestProgress, etc.
  2. Delete Subjects linked to this school
     → cascades to Module, ModuleChapter, ModuleContent, Question, Option,
       Answer, Mission, MissionQuestion, Test, TestQuestion, Competition, etc.
  3. Delete Classes linked to this school.
  4. Delete the School record.

Usage:
    python manage.py wipe_school_data --school "Delhi Public School"
    python manage.py wipe_school_data --school "Delhi Public School" --confirm
    python manage.py wipe_school_data --school "Delhi Public School" --dry-run
"""

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from gyaan_buddy.users.models import Account, Class, School
from gyaan_buddy.subjects.models import Subject


class Command(BaseCommand):
    help = "Wipe all data for a single school (users, classes, subjects, and the school itself)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--school", dest="school_name", required=True,
            help="Exact name of the school to wipe.",
        )
        parser.add_argument(
            "--confirm", action="store_true",
            help="Skip the interactive confirmation prompt.",
        )
        parser.add_argument(
            "--dry-run", action="store_true",
            help="Show what would be deleted without deleting anything.",
        )

    def handle(self, *args, **options):
        school_name = options["school_name"]
        dry_run = options["dry_run"]

        school = School.objects.filter(name__iexact=school_name).first()
        if not school:
            available = ", ".join(School.objects.values_list("name", flat=True)) or "none"
            raise CommandError(
                f"School '{school_name}' not found.\nAvailable schools: {available}"
            )

        # Count everything that will be deleted
        accounts = Account.objects.filter(profile__school=school)
        subjects = Subject.objects.filter(school=school)
        classes  = Class.objects.filter(school=school)

        account_count = accounts.count()
        subject_count = subjects.count()
        class_count   = classes.count()

        self.stdout.write(
            f"\nSchool : {school.name}\n"
            f"  Accounts (students + teachers + admins) : {account_count}\n"
            f"  Classes                                 : {class_count}\n"
            f"  Subjects (+ modules, questions, etc.)  : {subject_count}\n"
        )

        if dry_run:
            self.stdout.write(self.style.WARNING("Dry-run — nothing deleted."))
            return

        if not options["confirm"]:
            self.stdout.write(self.style.WARNING(
                "This will permanently delete ALL data for this school.\n"
                "This action CANNOT be undone."
            ))
            answer = input("Type YES to continue: ").strip()
            if answer != "YES":
                self.stdout.write("Aborted.")
                return

        with transaction.atomic():
            # 1. Accounts (cascades to profiles and all user-linked data)
            deleted_accounts, _ = accounts.delete()

            # 2. Subjects (cascades to modules, questions, missions, tests, etc.)
            deleted_subjects, _ = subjects.delete()

            # 3. Classes (anything not already cascade-deleted)
            deleted_classes, _ = classes.delete()

            # 4. School itself
            school.delete()

        self.stdout.write(self.style.SUCCESS(
            f"\nDone. Wiped school '{school_name}':\n"
            f"  Accounts deleted : {account_count}\n"
            f"  Classes deleted  : {class_count}\n"
            f"  Subjects deleted : {subject_count}\n"
            f"  (All related modules, questions, missions, tests, and progress "
            f"records were removed via cascade.)"
        ))
