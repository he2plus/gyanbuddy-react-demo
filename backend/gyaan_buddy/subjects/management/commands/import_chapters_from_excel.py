"""
Import subjects, modules, and chapters from an Excel file (3 columns: Subject, Module, Chapter).

Usage:
    python manage.py import_chapters_from_excel \\
        --school "Delhi Public School" \\
        --class-name "9-A" \\
        [--teacher "Ramesh Kumar"] \\
        [--excel-url "https://...Chapters.xlsx"] \\
        [--dry-run]

Excel format (3 columns):
    Column A: Subject name  (e.g. "Maths")
    Column B: Module name   (e.g. "Number Systems")
    Column C: Chapter title (e.g. "Introduction to Number Systems")

- Subjects, Modules, and Chapters are all created with get_or_create (safe to re-run).
- If --teacher is given, they are set as created_by and assigned to each subject in the class.
- Order is auto-assigned per module (continuing after any existing chapters).
"""

import io
import urllib.request
from collections import defaultdict

import openpyxl
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from gyaan_buddy.subjects.models import Module, ModuleChapter, Subject
from gyaan_buddy.users.models import Class, School, Teacher, TeacherProfile, UserProfile


DEFAULT_EXCEL_URL = "https://storage.googleapis.com/gyaanbuddy-media/Chapters.xlsx"

SUBJECT_DEFAULTS = {
    "maths":       ("MATH", "FF6B6B"),
    "math":        ("MATH", "FF6B6B"),
    "mathematics": ("MATH", "FF6B6B"),
    "science":     ("SCI",  "4ECDC4"),
    "english":     ("ENG",  "45B7D1"),
    "history":     ("HIST", "96CEB4"),
    "civics":      ("CIV",  "FFEAA7"),
    "geography":   ("GEO",  "DDA0DD"),
    "economics":   ("ECO",  "98FB98"),
}


def _subject_code_and_color(name):
    key = name.strip().lower()
    if key in SUBJECT_DEFAULTS:
        return SUBJECT_DEFAULTS[key]
    code = name.strip().upper().replace(" ", "")[:10]
    return code, "0DA6F2"


class Command(BaseCommand):
    help = "Import subjects, modules, and chapters from a 3-column Excel file."

    def add_arguments(self, parser):
        parser.add_argument(
            "--school", dest="school_name", required=True,
            help="Exact school name."
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
        raise CommandError(
            f"Teacher '{teacher_input}' not found in school '{school.name}'.\n"
            f"Available teachers: {', '.join(available) or 'none'}"
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
            subject_name  = str(row[0]).strip() if row[0] else ""
            module_name   = str(row[1]).strip() if len(row) > 1 and row[1] else ""
            chapter_title = str(row[2]).strip() if len(row) > 2 and row[2] else ""
            if subject_name and module_name and chapter_title:
                rows.append((subject_name, module_name, chapter_title))
        return rows

    # ------------------------------------------------------------------
    # Main
    # ------------------------------------------------------------------

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        if dry_run:
            self.stdout.write(self.style.WARNING("\n*** DRY-RUN — nothing will be saved ***\n"))

        school_name    = options["school_name"]
        class_name     = options["class_name"]
        teacher_input  = options["teacher"]
        excel_url      = options["excel_url"]

        # --- Load Excel ---
        rows = self._load_excel(excel_url)
        if not rows:
            raise CommandError(
                "No valid rows found. Excel must have 3 columns: Subject, Module, Chapter."
            )

        # --- Summarise ---
        summary = defaultdict(lambda: defaultdict(list))
        for subject_name, module_name, chapter_title in rows:
            summary[subject_name][module_name].append(chapter_title)

        self.stdout.write(f"\n  Found {len(rows)} rows:")
        for subj, modules in summary.items():
            self.stdout.write(f"    Subject: {subj}")
            for mod, chapters in modules.items():
                self.stdout.write(f"      Module: {mod} — {len(chapters)} chapter(s)")

        if dry_run:
            self.stdout.write(f"\n  Would attach to school : {school_name}")
            self.stdout.write(f"  Would attach to class  : {class_name}")
            self.stdout.write(f"  Teacher                : {teacher_input or '(none)'}")
            self.stdout.write(self.style.WARNING("\nDry-run complete — nothing saved."))
            return

        # --- Resolve entities ---
        school          = self._get_school(school_name)
        cls             = self._get_or_create_class(class_name, school)
        teacher_profile = self._resolve_teacher(teacher_input, school)
        created_by      = teacher_profile.account if teacher_profile else None

        if teacher_profile:
            self.stdout.write(f"  Using teacher: '{teacher_profile.account.username}'")
        else:
            self.stdout.write("  No teacher specified — created_by will be null.")

        subject_created = subject_existing = 0
        module_created  = module_existing  = 0
        chapter_created = chapter_existing = 0

        with transaction.atomic():
            subject_cache     = {}
            module_cache      = {}
            module_order_map  = {}

            for subject_name, module_name, chapter_title in rows:

                # --- Subject ---
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
                        self.stdout.write(f"  Existing subject: '{subject.name}'")

                    # Link subject to class
                    cls.subjects.add(subject)

                    # Assign teacher (skip if already assigned)
                    if teacher_profile:
                        existing = Teacher.objects.filter(
                            class_instance=cls, subject=subject
                        ).select_related("teacher__user_profile__account").first()

                        if existing:
                            self.stdout.write(self.style.WARNING(
                                f"    Skipped assignment: '{subject.name}' already assigned "
                                f"to '{existing.teacher.user_profile.account.username}'"
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

                # --- Module ---
                module_key = (subject_name, module_name)
                if module_key not in module_cache:
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
                    module_cache[module_key] = module
                    if m_created:
                        module_created += 1
                        self.stdout.write(self.style.SUCCESS(
                            f"    Created module: '{module.name}'"
                        ))
                    else:
                        module_existing += 1
                        self.stdout.write(f"    Existing module: '{module.name}'")

                module = module_cache[module_key]

                # --- Chapter ---
                if module.id not in module_order_map:
                    existing_max = (
                        ModuleChapter.objects.filter(module=module)
                        .order_by("-order")
                        .values_list("order", flat=True)
                        .first()
                    ) or 0
                    module_order_map[module.id] = existing_max

                module_order_map[module.id] += 1
                order = module_order_map[module.id]

                chapter, c_created = ModuleChapter.objects.get_or_create(
                    title__iexact=chapter_title,
                    module=module,
                    defaults={
                        "title": chapter_title,
                        "module": module,
                        "order": order,
                        "is_enabled": True,
                        "is_important": False,
                        "created_by": created_by,
                    },
                )
                if c_created:
                    chapter_created += 1
                    self.stdout.write(self.style.SUCCESS(
                        f"      Created chapter: '{chapter.title}'"
                    ))
                else:
                    chapter_existing += 1
                    self.stdout.write(f"      Existing chapter: '{chapter.title}'")

        self.stdout.write(self.style.SUCCESS(
            f"\nDone."
            f"\n  Subjects — created: {subject_created}, already existed: {subject_existing}"
            f"\n  Modules  — created: {module_created}, already existed: {module_existing}"
            f"\n  Chapters — created: {chapter_created}, already existed: {chapter_existing}"
        ))
