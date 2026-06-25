from django.core.management.base import BaseCommand
from django.db import transaction

from gyaan_buddy.subjects.models import Subject, Module
from gyaan_buddy.users.models import School, UserProfile


class Command(BaseCommand):
    help = (
        "Clone all subjects and modules. New subjects/modules are linked to the "
        "given school and created_by is set to that school's Administrator. "
        "Modules are linked to the newly created subjects."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "school_name",
            type=str,
            help="Exact name of the school to link the cloned subjects/modules to.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show what would be created without writing to the database.",
        )

    def handle(self, *args, **options):
        school_name = options["school_name"].strip()
        dry_run = options["dry_run"]

        if not school_name:
            self.stdout.write(self.style.ERROR("School name cannot be empty."))
            return

        school = School.objects.filter(name=school_name, is_deleted=False).first()
        if not school:
            self.stdout.write(
                self.style.ERROR(
                    f"School with name '{school_name}' not found or is deleted."
                )
            )
            return

        admin_profile = (
            UserProfile.objects.filter(
                school=school,
                user_type="administrator",
                is_deleted=False,
            )
            .select_related("account")
            .first()
        )
        if not admin_profile:
            self.stdout.write(
                self.style.ERROR(
                    f"No Administrator found for school '{school_name}'. "
                    "Create an admin user profile for this school first."
                )
            )
            return

        admin_account = admin_profile.account
        self.stdout.write(
            f"Using Administrator: {admin_account.username} (school: {school_name})"
        )

        subjects = list(Subject.objects.all().order_by("order"))
        if not subjects:
            self.stdout.write(self.style.WARNING("No subjects found in the database."))
            return

        modules = list(
            Module.objects.select_related("subject").all().order_by("subject", "order")
        )

        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    f"[DRY RUN] Would clone {len(subjects)} subjects and {len(modules)} modules."
                )
            )
            for s in subjects:
                new_name = self._unique_subject_name(s.name, school)
                new_code = self._unique_subject_code(s.code, school)
                self.stdout.write(f"  Subject: '{s.name}' -> '{new_name}' (code: {new_code})")
            for m in modules:
                self.stdout.write(
                    f"  Module: '{m.name}' (subject: {m.subject.name}) -> same name under cloned subject"
                )
            return

        with transaction.atomic():
            subject_map = {}
            existing_codes = set(Subject.objects.values_list("code", flat=True))
            existing_names = set(Subject.objects.values_list("name", flat=True))

            for old_subject in subjects:
                new_name = self._unique_subject_name(
                    old_subject.name, school, existing_names
                )
                new_code = self._unique_subject_code(
                    old_subject.code, school, existing_codes
                )
                existing_names.add(new_name)
                existing_codes.add(new_code)

                new_subject = Subject(
                    name=new_name,
                    code=new_code,
                    description=old_subject.description or "",
                    color=old_subject.color,
                    is_active=old_subject.is_active,
                    order=old_subject.order,
                    logo_url=old_subject.logo_url or "",
                    created_by=admin_account,
                )
                new_subject.save()
                subject_map[old_subject.pk] = new_subject

            self.stdout.write(
                self.style.SUCCESS(f"Cloned {len(subject_map)} subjects.")
            )

            created_modules = 0
            for old_module in modules:
                new_subject = subject_map.get(old_module.subject_id)
                if not new_subject:
                    continue
                Module.objects.create(
                    name=old_module.name,
                    subject=new_subject,
                    description=old_module.description or "",
                    order=old_module.order,
                    is_active=old_module.is_active,
                    logo_url=old_module.logo_url or "",
                    is_enabled=old_module.is_enabled,
                    created_by=admin_account,
                )
                created_modules += 1

            self.stdout.write(
                self.style.SUCCESS(f"Cloned {created_modules} modules.")
            )

    def _unique_subject_name(self, base_name, school, existing_names=None):
        candidate = f"{base_name} ({school.name})"
        if existing_names is None:
            existing_names = set(Subject.objects.values_list("name", flat=True))
        if candidate not in existing_names:
            return candidate
        suffix = 1
        while f"{candidate} {suffix}" in existing_names:
            suffix += 1
        return f"{candidate} {suffix}"

    def _unique_subject_code(self, base_code, school, existing_codes=None):
        base = (base_code or "X")[:4].upper()
        candidate = f"{base}_S{school.id}"[:10]
        if existing_codes is None:
            existing_codes = set(Subject.objects.values_list("code", flat=True))
        if candidate not in existing_codes:
            return candidate
        for i in range(1, 100):
            candidate = f"{base}{i}_S{school.id}"[:10]
            if candidate not in existing_codes:
                return candidate
        return f"{base}_S{school.id}"[:10]
