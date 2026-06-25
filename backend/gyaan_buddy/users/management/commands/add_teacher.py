"""
Add a teacher (or assign an existing teacher to a new class/subject) interactively.

Flow:
  1. School  — find by name, create if missing
  2. Class   — find by name in school, create if missing
  3. Subject — find by name or code (must already exist)
  4. Teacher — create Account + TeacherProfile if new username,
               then create Teacher assignment (class + subject)

Usage:
    # Fully interactive
    python manage.py add_teacher

    # Non-interactive
    python manage.py add_teacher \\
        --first-name "Ramesh" --last-name "Kumar" \\
        --school "Delhi Public School" \\
        --class-name "9-A" \\
        --subject "Mathematics" \\
        --employee-id "EMP001"

    # Dry-run preview
    python manage.py add_teacher --dry-run
"""

from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from gyaan_buddy.users.models import Account, Class, School, Teacher, TeacherProfile, UserProfile
from gyaan_buddy.subjects.models import Subject


def _to_username(first_name, last_name, existing_usernames):
    """'Ramesh', 'Kumar' → 'ramesh.kumar'; auto-increments on collision."""
    import re
    parts = []
    for p in [first_name, last_name]:
        slug = re.sub(r"[^a-z0-9]+", ".", p.lower().strip()).strip(".")
        if slug:
            parts.append(slug)
    base = ".".join(parts) or "teacher"
    candidate = base
    n = 2
    while candidate in existing_usernames:
        candidate = f"{base}{n}"
        n += 1
    existing_usernames.add(candidate)
    return candidate


class Command(BaseCommand):
    help = "Add a teacher and assign them to a class + subject."

    def add_arguments(self, parser):
        parser.add_argument("--first-name", dest="first_name", default=None)
        parser.add_argument("--last-name", dest="last_name", default=None)
        parser.add_argument("--school", dest="school_name", default=None)
        parser.add_argument("--class-name", dest="class_name", default=None)
        parser.add_argument("--subject", dest="subject_name", default=None)
        parser.add_argument("--employee-id", dest="employee_id", default=None)
        parser.add_argument("--password", dest="password", default=None,
                            help="Default: Teacher@<employee_id or 1234>")
        parser.add_argument("--dry-run", action="store_true",
                            help="Preview without saving anything.")

    # ------------------------------------------------------------------
    def _ask(self, prompt, default=None, required=True):
        suffix = f" [{default}]" if default else ""
        value = input(f"{prompt}{suffix}: ").strip()
        result = value if value else default
        if required and not result:
            raise CommandError(f"'{prompt}' is required.")
        return result

    def _get_or_create_school(self, name):
        school, created = School.objects.get_or_create(
            name__iexact=name, defaults={"name": name, "is_active": True}
        )
        tag = "Created" if created else "Using existing"
        self.stdout.write(f"  {tag} school: '{school.name}'")
        return school

    def _get_or_create_class(self, class_name, school):
        cls, created = Class.objects.get_or_create(
            name__iexact=class_name, school=school,
            defaults={"name": class_name, "school": school, "is_active": True},
        )
        tag = "Created" if created else "Using existing"
        self.stdout.write(f"  {tag} class: '{cls.name}'")
        return cls

    def _get_or_create_subject(self, subject_name, school):
        """Find subject by name or code within the given school; create it if missing."""
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

    # ------------------------------------------------------------------
    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        if dry_run:
            self.stdout.write(self.style.WARNING("\n*** DRY-RUN — nothing will be saved ***\n"))

        # --- Collect inputs ---
        first_name  = options["first_name"]  or self._ask("First name")
        last_name   = options["last_name"]   or self._ask("Last name", required=False) or ""
        school_name = options["school_name"] or self._ask("School name")
        class_name  = options["class_name"]  or self._ask("Class name (e.g. 9-A)")
        subject_name = options["subject_name"] or self._ask("Subject name or code")
        employee_id = options["employee_id"] or self._ask("Employee ID (optional)", required=False) or ""
        password    = options["password"] or f"Teacher@{employee_id or '1234'}"

        self.stdout.write("")

        if dry_run:
            self.stdout.write(f"  Would process teacher: {first_name} {last_name}")
            self.stdout.write(f"  School  : {school_name}")
            self.stdout.write(f"  Class   : {class_name}")
            self.stdout.write(f"  Subject : {subject_name}")
            self.stdout.write(f"  Emp ID  : {employee_id or '(auto)'}")
            self.stdout.write(self.style.WARNING("\nDry-run complete — nothing saved."))
            return

        with transaction.atomic():
            school  = self._get_or_create_school(school_name)
            cls     = self._get_or_create_class(class_name, school)
            subject, subj_created = self._get_or_create_subject(subject_name, school)
            if subj_created:
                self.stdout.write(self.style.SUCCESS(f"  Created subject: '{subject.name}' ({subject.code})"))
            else:
                self.stdout.write(f"  Using subject: '{subject.name}' ({subject.code})")

            # --- Find existing teacher account by employee_id or name+school ---
            account = None
            if employee_id:
                tp_match = TeacherProfile.objects.filter(
                    employee_id=employee_id
                ).select_related("user_profile__account").first()
                if tp_match:
                    account = tp_match.user_profile.account

            if account is None:
                # Match by first+last name scoped to this school
                from gyaan_buddy.users.models import UserProfile as UP
                profile_match = UP.objects.filter(
                    school=school,
                    user_type="teacher",
                    account__first_name__iexact=first_name.strip(),
                    account__last_name__iexact=last_name.strip(),
                ).select_related("account").first()
                if profile_match:
                    account = profile_match.account

            if account is not None:
                self.stdout.write(f"  Using existing account: '{account.username}'")
                acct_created = False
            else:
                existing_usernames = set(Account.objects.values_list("username", flat=True))
                username = _to_username(first_name, last_name, existing_usernames)
                account = Account.objects.create(
                    username=username,
                    first_name=first_name.title(),
                    last_name=last_name.title(),
                    email=f"{username}@school.gyaanbuddy.com",
                    password=make_password(password),
                    is_active=True,
                )
                self.stdout.write(self.style.SUCCESS(f"  Created account: '{username}'"))
                acct_created = True

            # --- UserProfile (auto-created by signal; update it) ---
            profile = account.profile
            profile.school = school
            profile.user_type = "teacher"
            profile.save(update_fields=["school", "user_type"])

            # --- TeacherProfile ---
            teacher_profile, tp_created = TeacherProfile.objects.get_or_create(
                user_profile=profile,
                defaults={"employee_id": employee_id or None},
            )
            if tp_created:
                self.stdout.write(self.style.SUCCESS("  Created teacher profile"))
            else:
                self.stdout.write("  Using existing teacher profile")
                if employee_id and not teacher_profile.employee_id:
                    teacher_profile.employee_id = employee_id
                    teacher_profile.save(update_fields=["employee_id"])

            # --- Link subject to class (Class.subjects M2M) ---
            cls.subjects.add(subject)

            # --- Teacher assignment (class + subject) ---
            assignment, assign_created = Teacher.objects.get_or_create(
                teacher=teacher_profile,
                class_instance=cls,
                subject=subject,
            )
            if assign_created:
                self.stdout.write(self.style.SUCCESS(
                    f"  Assigned: {subject.name} in {cls.name}"
                ))
            else:
                self.stdout.write(self.style.WARNING(
                    f"  Assignment already exists: {subject.name} in {cls.name} — skipped."
                ))

        self.stdout.write(self.style.SUCCESS(
            f"\nDone. Teacher '{first_name} {last_name}' "
            f"({username}) | password: {password}"
        ))
