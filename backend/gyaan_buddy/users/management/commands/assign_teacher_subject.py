"""
Assign an additional class+subject to an existing teacher.

Looks up the teacher by employee ID (or name+school as fallback).
Never overrides existing data — only ADDS new assignments.

Usage:
    # By employee ID (recommended)
    python manage.py assign_teacher_subject \\
        --employee-id "EMP001" \\
        --class-name "9-B" \\
        --subject "Science"

    # By name + school (if no employee ID)
    python manage.py assign_teacher_subject \\
        --first-name "Sapna" --last-name "Kohli" \\
        --school "D.A.V" \\
        --class-name "9-B" \\
        --subject "Science"

    # Dry-run preview
    python manage.py assign_teacher_subject --employee-id "EMP001" \\
        --class-name "9-B" --subject "Science" --dry-run
"""

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from gyaan_buddy.users.models import Account, Class, School, Teacher, TeacherProfile, UserProfile
from gyaan_buddy.subjects.models import Subject


class Command(BaseCommand):
    help = "Add a new class+subject assignment to an existing teacher."

    def add_arguments(self, parser):
        parser.add_argument("--employee-id", dest="employee_id", default=None,
                            help="Employee ID of the existing teacher (preferred lookup key).")
        parser.add_argument("--first-name", dest="first_name", default=None,
                            help="First name (fallback lookup when no employee ID).")
        parser.add_argument("--last-name", dest="last_name", default=None,
                            help="Last name (fallback lookup when no employee ID).")
        parser.add_argument("--school", dest="school_name", default=None,
                            help="School name (required for name-based lookup).")
        parser.add_argument("--class-name", dest="class_name", default=None,
                            help="Class to assign (created if missing).")
        parser.add_argument("--subject", dest="subject_name", default=None,
                            help="Subject to assign (created if missing).")
        parser.add_argument("--dry-run", action="store_true",
                            help="Preview without saving anything.")

    def _ask(self, prompt, default=None, required=True):
        suffix = f" [{default}]" if default else ""
        value = input(f"{prompt}{suffix}: ").strip()
        result = value if value else default
        if required and not result:
            raise CommandError(f"'{prompt}' is required.")
        return result

    def _find_teacher_profile(self, employee_id, first_name, last_name, school):
        """Locate TeacherProfile by employee_id or name+school. Raise if not found."""
        if employee_id:
            tp = TeacherProfile.objects.filter(
                employee_id=employee_id
            ).select_related("user_profile__account", "user_profile__school").first()
            if tp:
                return tp
            raise CommandError(f"No teacher found with employee ID '{employee_id}'.")

        # Fallback: name + school
        if not (first_name and school):
            raise CommandError(
                "Provide --employee-id, or both --first-name and --school to identify the teacher."
            )
        profile_match = UserProfile.objects.filter(
            school=school,
            user_type="teacher",
            account__first_name__iexact=first_name.strip(),
            account__last_name__iexact=(last_name or "").strip(),
        ).select_related("account", "teacher_profile").first()
        if not profile_match:
            raise CommandError(
                f"No teacher '{first_name} {last_name}' found in school '{school.name}'."
            )
        if not hasattr(profile_match, "teacher_profile"):
            raise CommandError(
                f"Account '{profile_match.account.username}' exists but has no TeacherProfile."
            )
        return profile_match.teacher_profile

    def _get_or_create_class(self, class_name, school):
        cls, created = Class.objects.get_or_create(
            name__iexact=class_name, school=school,
            defaults={"name": class_name, "school": school, "is_active": True},
        )
        tag = "Created" if created else "Using existing"
        self.stdout.write(f"  {tag} class: '{cls.name}'")
        return cls

    def _get_or_create_subject(self, subject_name, school):
        subject = (
            Subject.objects.filter(name__iexact=subject_name, school=school).first()
            or Subject.objects.filter(code__iexact=subject_name, school=school).first()
        )
        if subject:
            return subject, False
        code = subject_name.strip()[:10].upper()
        subject, created = Subject.objects.get_or_create(
            code=code,
            school=school,
            defaults={"name": subject_name.strip(), "is_active": True},
        )
        return subject, created

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        if dry_run:
            self.stdout.write(self.style.WARNING("\n*** DRY-RUN — nothing will be saved ***\n"))

        employee_id  = options["employee_id"]
        first_name   = options["first_name"]
        last_name    = options["last_name"] or ""
        school_name  = options["school_name"]
        class_name   = options["class_name"]  or self._ask("Class name (e.g. 9-B)")
        subject_name = options["subject_name"] or self._ask("Subject name or code")

        if not employee_id and not first_name:
            employee_id = self._ask("Employee ID (leave blank to use name instead)", required=False)
        if not employee_id:
            if not first_name:
                first_name = self._ask("First name")
            if not last_name:
                last_name = self._ask("Last name", required=False) or ""
            if not school_name:
                school_name = self._ask("School name")

        if dry_run:
            lookup = f"employee_id={employee_id}" if employee_id else f"{first_name} {last_name} @ {school_name}"
            self.stdout.write(f"  Teacher  : {lookup}")
            self.stdout.write(f"  Class    : {class_name}")
            self.stdout.write(f"  Subject  : {subject_name}")
            self.stdout.write(self.style.WARNING("\nDry-run complete — nothing saved."))
            return

        with transaction.atomic():
            # Resolve school for name-based lookup
            school = None
            if school_name:
                school = School.objects.filter(name__iexact=school_name).first()
                if not school:
                    raise CommandError(f"School '{school_name}' not found.")
            elif not employee_id:
                raise CommandError("--school is required when not using --employee-id.")

            # Find teacher
            teacher_profile = self._find_teacher_profile(employee_id, first_name, last_name, school)
            account = teacher_profile.user_profile.account
            teacher_school = teacher_profile.user_profile.school
            self.stdout.write(
                f"  Found teacher: '{account.get_full_name()}' ({account.username})"
                f" @ {teacher_school.name}"
            )

            # Resolve class and subject against teacher's school
            cls     = self._get_or_create_class(class_name, teacher_school)
            subject, subj_created = self._get_or_create_subject(subject_name, teacher_school)
            if subj_created:
                self.stdout.write(self.style.SUCCESS(f"  Created subject: '{subject.name}' ({subject.code})"))
            else:
                self.stdout.write(f"  Using subject: '{subject.name}' ({subject.code})")

            # Link subject to class
            cls.subjects.add(subject)

            # Add assignment (no override — get_or_create only adds if missing)
            assignment, created = Teacher.objects.get_or_create(
                teacher=teacher_profile,
                class_instance=cls,
                subject=subject,
            )
            if created:
                self.stdout.write(self.style.SUCCESS(
                    f"  Added assignment: {subject.name} in {cls.name}"
                ))
            else:
                self.stdout.write(self.style.WARNING(
                    f"  Assignment already exists: {subject.name} in {cls.name} — skipped."
                ))

            # Print all current assignments for this teacher
            all_assignments = Teacher.objects.filter(
                teacher=teacher_profile, is_deleted=False
            ).select_related("class_instance", "subject").order_by("class_instance__name", "subject__name")
            self.stdout.write(f"\n  All assignments for {account.get_full_name()}:")
            for a in all_assignments:
                self.stdout.write(f"    • {a.class_instance.name}  →  {a.subject.name}")
