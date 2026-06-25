"""
Add a subject for a specific school interactively or via arguments.

Usage:
    # Interactive
    python manage.py add_subject

    # Non-interactive
    python manage.py add_subject \\
        --school "Delhi Public School" \\
        --name "Mathematics" \\
        --code "MATH" \\
        --description "Core mathematics curriculum" \\
        --color "0DA6F2" \\
        --order 1

    # Dry-run preview
    python manage.py add_subject --dry-run
"""

from django.core.management.base import BaseCommand, CommandError

from gyaan_buddy.subjects.models import Subject
from gyaan_buddy.users.models import School


class Command(BaseCommand):
    help = "Add a subject for a school (get_or_create by code + school)."

    def add_arguments(self, parser):
        parser.add_argument("--school", dest="school_name", default=None,
                            help="School name the subject belongs to.")
        parser.add_argument("--name", dest="name", default=None)
        parser.add_argument("--code", dest="code", default=None,
                            help="Short code (max 10 chars), unique per school, e.g. MATH, SCI")
        parser.add_argument("--description", dest="description", default=None)
        parser.add_argument("--color", dest="color", default=None,
                            help="Hex color without #, default: 0DA6F2")
        parser.add_argument("--order", dest="order", type=int, default=None,
                            help="Display order (integer)")
        parser.add_argument("--dry-run", action="store_true",
                            help="Preview without saving.")

    def _ask(self, prompt, default=None, required=True):
        suffix = f" [{default}]" if default else ""
        value = input(f"{prompt}{suffix}: ").strip()
        result = value if value else default
        if required and not result:
            raise CommandError(f"'{prompt}' is required.")
        return result

    def _get_school(self, name):
        school = School.objects.filter(name__iexact=name).first()
        if not school:
            available = list(School.objects.values_list("name", flat=True))
            hint = ", ".join(available) if available else "none"
            raise CommandError(f"School '{name}' not found.\nAvailable: {hint}")
        return school

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        if dry_run:
            self.stdout.write(self.style.WARNING("\n*** DRY-RUN — nothing will be saved ***\n"))

        school_name = options["school_name"] or self._ask("School name")
        name        = options["name"]        or self._ask("Subject name (e.g. Mathematics)")
        code        = options["code"]        or self._ask("Subject code (e.g. MATH, max 10 chars)")
        description = options["description"] or self._ask("Description (optional)", required=False) or ""
        color_input = options["color"]       or self._ask("Hex color without # (optional)", default="0DA6F2", required=False)
        color       = (color_input or "0DA6F2").lstrip("#")[:6]

        order_input = options["order"]
        if order_input is None:
            raw = self._ask("Display order (optional, integer)", default="0", required=False) or "0"
            try:
                order = int(raw)
            except ValueError:
                order = 0
        else:
            order = order_input

        code = code.upper().strip()[:10]

        if dry_run:
            self.stdout.write(f"  Would create/find subject:")
            self.stdout.write(f"    School      : {school_name}")
            self.stdout.write(f"    Name        : {name}")
            self.stdout.write(f"    Code        : {code}")
            self.stdout.write(f"    Description : {description or '(none)'}")
            self.stdout.write(f"    Color       : #{color}")
            self.stdout.write(f"    Order       : {order}")
            self.stdout.write(self.style.WARNING("\nDry-run complete — nothing saved."))
            return

        school = self._get_school(school_name)

        subject, created = Subject.objects.get_or_create(
            code=code,
            school=school,
            defaults={
                "name": name,
                "description": description,
                "color": color,
                "order": order,
                "is_active": True,
            },
        )

        if created:
            self.stdout.write(self.style.SUCCESS(
                f"\nCreated subject: '{subject.name}' (code={subject.code}, school='{school.name}', id={subject.id})"
            ))
        else:
            self.stdout.write(self.style.WARNING(
                f"\nSubject '{code}' already exists for school '{school.name}': '{subject.name}' (id={subject.id})"
            ))
            self.stdout.write("No changes made. To update an existing subject use the admin panel.")
