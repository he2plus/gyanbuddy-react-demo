"""
Import subjects and modules from an Excel file (2 columns: Subject, Module).

Usage:
    python manage.py import_subjects_from_excel \\
        --school "Delhi Public School" \\
        --class-name "9-A" \\
        [--teacher "Ramesh Kumar"] \\
        [--excel-url "https://...Modules.xlsx"] \\
        [--dry-run]

- For each unique subject in the Excel, a Subject is created (get_or_create).
- For each row, a Module is created under that subject + class (get_or_create).
- If --teacher is given (username or "First Last"), the teacher is assigned
  to each subject in that class (Teacher assignment + Class.subjects M2M).
- --teacher is also set as created_by on new subjects/modules.
"""

import io
import urllib.request

import openpyxl
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from gyaan_buddy.subjects.models import Module, Subject
from gyaan_buddy.users.models import Class, School, Teacher, TeacherProfile, UserProfile


DEFAULT_EXCEL_URL = "https://storage.googleapis.com/gyaanbuddy-media/Modules.xlsx"

# Map common subject name variants -> (code, color)
SUBJECT_DEFAULTS = {
    "maths":      ("MATH",  "FF6B6B"),
    "math":       ("MATH",  "FF6B6B"),
    "mathematics":("MATH",  "FF6B6B"),
    "science":    ("SCI",   "4ECDC4"),
    "english":    ("ENG",   "45B7D1"),
    "history":    ("HIST",  "96CEB4"),
    "civics":     ("CIV",   "FFEAA7"),
    "geography":  ("GEO",   "DDA0DD"),
    "economics":  ("ECO",   "98FB98"),
}


def _subject_code_and_color(name):
    key = name.strip().lower()
    if key in SUBJECT_DEFAULTS:
        return SUBJECT_DEFAULTS[key]
    code = name.strip().upper().replace(" ", "")[:10]
    return code, "0DA6F2"


class Command(BaseCommand):
    help = "Import subjects and modules from an Excel file into a school and class."

    def add_arguments(self, parser):
        parser.add_argument(
            "--school", dest="school_name", required=True,
            help="Exact school name to attach subjects to."
        )
        parser.add_argument(
            "--class-name", dest="class_name", required=True,
            help="Class name (e.g. '9-A'). Created if it doesn't exist."
        )
        parser.add_argument(
            "--teacher", dest="teacher", default=None,
            help=(
                "Teacher username or 'First Last' name. "
                "Used as created_by and assigned to each subject in the class."
            )
        )
        parser.add_argument(
            "--excel-url", dest="excel_url", default=DEFAULT_EXCEL_URL,
            help=f"URL of the .xlsx file. Defaults to: {DEFAULT_EXCEL_URL}"
        )
        parser.add_argument(
            "--dry-run", action="store_true",
            help="Preview what would be created without saving anything."
        )

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _get_school(self, name):
        school = School.objects.filter(name__iexact=name, is_deleted=False).first()
        if not school:
            available = ", ".join(School.objects.values_list("name", flat=True)) or "none"
            raise CommandError(f"School '{name}' not found. Available: {available}")
        return school

    def _get_or_create_class(self, class_name, school):
        cls, created = Class.objects.get_or_create(
            name__iexact=class_name,
            school=school,
            defaults={"name": class_name, "school": school, "is_active": True},
        )
        tag = "Created" if created else "Using existing"
        self.stdout.write(f"  {tag} class: '{cls.name}'")
        return cls

    def _resolve_teacher(self, teacher_input, school):
        """Return TeacherProfile or None. Searches username then first+last name."""
        if not teacher_input:
            return None

        # Try username
        tp = TeacherProfile.objects.filter(
            user_profile__account__username__iexact=teacher_input.strip(),
            user_profile__school=school,
            is_deleted=False,
        ).select_related("user_profile__account").first()
        if tp:
            return tp

        # Try "First Last"
        parts = teacher_input.strip().split(None, 1)
        first = parts[0]
        last = parts[1] if len(parts) > 1 else ""
        tp = TeacherProfile.objects.filter(
            user_profile__school=school,
            user_profile__account__first_name__iexact=first,
            user_profile__account__last_name__iexact=last,
            is_deleted=False,
        ).select_related("user_profile__account").first()
        if tp:
            return tp

        available = list(
            UserProfile.objects.filter(school=school, user_type="teacher", is_deleted=False)
            .values_list("account__username", flat=True)
        )
        hint = ", ".join(available) if available else "none"
        raise CommandError(
            f"Teacher '{teacher_input}' not found in school '{school.name}'.\n"
            f"Available teachers: {hint}"
        )

    def _load_excel(self, url):
        self.stdout.write(f"  Fetching: {url}")
        try:
            data = urllib.request.urlopen(url, timeout=30).read()
        except Exception as exc:
            raise CommandError(f"Failed to fetch Excel file: {exc}")
        wb = openpyxl.load_workbook(io.BytesIO(data), data_only=True)
        ws = wb.active
        rows = []
        for row in ws.iter_rows(values_only=True):
            subject_name = (row[0] or "").strip() if row[0] else ""
            module_name = (row[1] or "").strip() if len(row) > 1 and row[1] else ""
            if subject_name and module_name:
                rows.append((subject_name, module_name))
        return rows

    # ------------------------------------------------------------------
    # Main
    # ------------------------------------------------------------------

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        if dry_run:
            self.stdout.write(self.style.WARNING("\n*** DRY-RUN — nothing will be saved ***\n"))

        school_name = options["school_name"]
        class_name = options["class_name"]
        teacher_input = options["teacher"]
        excel_url = options["excel_url"]

        # --- Load data from Excel ---
        rows = self._load_excel(excel_url)
        if not rows:
            raise CommandError("No valid rows found in the Excel file (expected 2 columns: Subject, Module).")

        # Summarise
        unique_subjects = list(dict.fromkeys(name for name, _ in rows))
        self.stdout.write(f"\n  Found {len(rows)} rows across {len(unique_subjects)} subjects:")
        for s in unique_subjects:
            count = sum(1 for subj, _ in rows if subj == s)
            self.stdout.write(f"    - {s}: {count} module(s)")

        if dry_run:
            self.stdout.write(f"\n  Would attach to school : {school_name}")
            self.stdout.write(f"  Would attach to class  : {class_name}")
            self.stdout.write(f"  Teacher                : {teacher_input or '(none)'}")
            self.stdout.write(self.style.WARNING("\nDry-run complete — nothing saved."))
            return

        # --- Resolve entities ---
        school = self._get_school(school_name)
        cls = self._get_or_create_class(class_name, school)
        teacher_profile = self._resolve_teacher(teacher_input, school)
        created_by = teacher_profile.account if teacher_profile else None

        if teacher_profile:
            self.stdout.write(f"  Using teacher: '{teacher_profile.account.username}'")
        else:
            self.stdout.write("  No teacher specified — created_by will be null.")

        # --- Import ---
        subject_created = subject_existing = 0
        module_created = module_existing = 0

        with transaction.atomic():
            subject_cache = {}

            for subject_name, module_name in rows:
                # Get or create Subject
                if subject_name not in subject_cache:
                    code, color = _subject_code_and_color(subject_name)
                    subject, s_created = Subject.objects.get_or_create(
                        code=code,
                        school=school,
                        defaults={
                            "name": subject_name,
                            "color": color,
                            "is_active": True,
                            "order": 0,
                            "created_by": created_by,
                        },
                    )
                    subject_cache[subject_name] = subject
                    if s_created:
                        subject_created += 1
                        self.stdout.write(self.style.SUCCESS(
                            f"  Created subject: '{subject.name}' (code={subject.code})"
                        ))
                    else:
                        subject_existing += 1
                        self.stdout.write(
                            f"  Existing subject: '{subject.name}' (code={subject.code})"
                        )

                    # Link subject to class
                    cls.subjects.add(subject)

                    # Assign teacher to this subject in this class only if no
                    # teacher is already assigned to it (preserve existing assignments)
                    if teacher_profile:
                        existing_assignment = Teacher.objects.filter(
                            class_instance=cls,
                            subject=subject,
                        ).select_related('teacher__user_profile__account').first()

                        if existing_assignment:
                            existing_username = existing_assignment.teacher.user_profile.account.username
                            self.stdout.write(self.style.WARNING(
                                f"    Skipped assignment: '{subject.name}' already assigned "
                                f"to '{existing_username}' in '{cls.name}'"
                            ))
                        else:
                            Teacher.objects.create(
                                teacher=teacher_profile,
                                class_instance=cls,
                                subject=subject,
                            )
                            self.stdout.write(self.style.SUCCESS(
                                f"    Assigned teacher to '{subject.name}' in '{cls.name}'"
                            ))

                subject = subject_cache[subject_name]

                # Get or create Module
                module, m_created = Module.objects.get_or_create(
                    name__iexact=module_name,
                    subject=subject,
                    class_instance=cls,
                    defaults={
                        "name": module_name,
                        "subject": subject,
                        "class_instance": cls,
                        "is_active": True,
                        "is_enabled": False,
                        "order": 1,
                        "created_by": created_by,
                    },
                )
                if m_created:
                    module_created += 1
                else:
                    module_existing += 1

        self.stdout.write(self.style.SUCCESS(
            f"\nDone."
            f"\n  Subjects — created: {subject_created}, already existed: {subject_existing}"
            f"\n  Modules  — created: {module_created}, already existed: {module_existing}"
        ))
