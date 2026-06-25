"""
Add a school and a principal (admin) account for it.

Usage:
    # Interactive
    python manage.py add_school

    # Non-interactive
    python manage.py add_school \\
        --name "Delhi Public School" \\
        --address "Sector 45, Gurugram" \\
        --phone "0124-1234567" \\
        --email "info@dps.edu" \\
        --website "https://dps.edu" \\
        --principal-first-name "Rajesh" \\
        --principal-last-name "Sharma" \\
        --principal-employee-id "PRIN001"

    # Dry-run preview
    python manage.py add_school --dry-run
"""

import re

from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from gyaan_buddy.users.models import Account, School, UserProfile


def _to_username(first_name, last_name):
    parts = []
    for p in [first_name, last_name]:
        slug = re.sub(r"[^a-z0-9]+", ".", p.lower().strip()).strip(".")
        if slug:
            parts.append(slug)
    base = ".".join(parts) or "principal"
    candidate = base
    existing = set(Account.objects.values_list("username", flat=True))
    n = 2
    while candidate in existing:
        candidate = f"{base}{n}"
        n += 1
    return candidate


class Command(BaseCommand):
    help = "Add a school and create a principal (admin) account for it."

    def add_arguments(self, parser):
        # School fields
        parser.add_argument("--name",    dest="name",    default=None)
        parser.add_argument("--address", dest="address", default=None)
        parser.add_argument("--phone",   dest="phone",   default=None)
        parser.add_argument("--email",   dest="email",   default=None)
        parser.add_argument("--website", dest="website", default=None)

        # Principal fields
        parser.add_argument("--principal-first-name", dest="principal_first_name", default=None)
        parser.add_argument("--principal-last-name",  dest="principal_last_name",  default=None)
        parser.add_argument("--principal-employee-id", dest="principal_employee_id", default=None)
        parser.add_argument("--principal-password",   dest="principal_password",   default=None,
                            help="Default: Principal@<employee_id or 1234>")

        parser.add_argument("--dry-run", action="store_true", help="Preview without saving.")

    def _ask(self, prompt, required=True):
        value = input(f"{prompt}: ").strip()
        if required and not value:
            raise CommandError(f"'{prompt}' is required.")
        return value

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        if dry_run:
            self.stdout.write(self.style.WARNING("\n*** DRY-RUN — nothing will be saved ***\n"))

        # --- School inputs ---
        name    = options["name"]    or self._ask("School name")
        address = options["address"] or self._ask("Address (optional)", required=False)
        phone   = options["phone"]   or self._ask("Phone (optional)",   required=False)
        email   = options["email"]   or self._ask("Email (optional)",   required=False)
        website = options["website"] or self._ask("Website (optional)", required=False)

        # --- Principal inputs ---
        p_first = options["principal_first_name"] or self._ask("Principal first name")
        p_last  = options["principal_last_name"]  or self._ask("Principal last name (optional)", required=False) or ""
        p_empid = options["principal_employee_id"] or self._ask("Principal employee ID (optional)", required=False) or ""
        p_password = options["principal_password"] or f"Principal@{p_empid or '1234'}"

        if dry_run:
            self.stdout.write(f"  School:")
            self.stdout.write(f"    Name    : {name}")
            self.stdout.write(f"    Address : {address or '(none)'}")
            self.stdout.write(f"    Phone   : {phone or '(none)'}")
            self.stdout.write(f"    Email   : {email or '(none)'}")
            self.stdout.write(f"    Website : {website or '(none)'}")
            self.stdout.write(f"  Principal:")
            self.stdout.write(f"    Name    : {p_first} {p_last}".strip())
            self.stdout.write(f"    Emp ID  : {p_empid or '(none)'}")
            self.stdout.write(f"    Password: {p_password}")
            self.stdout.write(self.style.WARNING("\nDry-run complete — nothing saved."))
            return

        with transaction.atomic():
            # --- School ---
            school, school_created = School.objects.get_or_create(
                name__iexact=name,
                defaults={
                    "name": name,
                    "address": address or "",
                    "phone": phone or "",
                    "email": email or "",
                    "website": website or "",
                    "is_active": True,
                },
            )
            if school_created:
                self.stdout.write(self.style.SUCCESS(f"\n  Created school: '{school.name}' (id={school.id})"))
            else:
                self.stdout.write(self.style.WARNING(f"\n  School already exists: '{school.name}' (id={school.id})"))

            # --- Principal account ---
            # Check if a principal already exists for this school
            existing_principal = UserProfile.objects.filter(
                school=school,
                user_type="administrator",
            ).select_related("account").first()

            if existing_principal:
                self.stdout.write(self.style.WARNING(
                    f"  Principal already exists: '{existing_principal.account.username}' — skipped."
                ))
            else:
                username = _to_username(p_first, p_last)
                account = Account.objects.create(
                    username=username,
                    first_name=p_first.title(),
                    last_name=p_last.title(),
                    email=f"{username}@school.gyaanbuddy.com",
                    password=make_password(p_password),
                    is_active=True,
                )
                profile = account.profile
                profile.school = school
                profile.user_type = "administrator"
                profile.save()

                self.stdout.write(self.style.SUCCESS(
                    f"  Created principal: '{username}' | password: {p_password}"
                ))

        self.stdout.write(self.style.SUCCESS("\nDone."))
