"""
Wipes ALL data from the database while keeping table structure and migrations.

Uses TRUNCATE ... CASCADE instead of Django's flush command, which often
fails on PostgreSQL with complex foreign-key relationships.

Usage:
    python manage.py wipe_all_data           # prompts for confirmation
    python manage.py wipe_all_data --confirm  # no prompt (for scripts)
"""

from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = "Wipe ALL data from every table (keeps schema and migrations)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--confirm",
            action="store_true",
            help="Skip confirmation prompt",
        )

    def handle(self, *args, **options):
        if not options["confirm"]:
            self.stdout.write(self.style.WARNING(
                "\nThis will DELETE ALL DATA from every table in the database.\n"
                "Schema and migrations are preserved.\n"
            ))
            answer = input("Type YES to continue: ").strip()
            if answer != "YES":
                self.stdout.write("Aborted.")
                return

        self.stdout.write("Wiping all data...")

        with connection.cursor() as cursor:
            if connection.vendor == "postgresql":
                # Fetch all user tables (exclude Django internals we want to keep)
                cursor.execute("""
                    SELECT tablename
                    FROM pg_tables
                    WHERE schemaname = 'public'
                      AND tablename != 'django_migrations'
                    ORDER BY tablename;
                """)
                tables = [row[0] for row in cursor.fetchall()]

                if not tables:
                    self.stdout.write("No tables found.")
                    return

                # Single TRUNCATE with CASCADE handles FK order automatically
                table_list = ", ".join(f'"{t}"' for t in tables)
                cursor.execute(f"TRUNCATE {table_list} RESTART IDENTITY CASCADE;")

            elif connection.vendor == "sqlite":
                # SQLite: delete from each table individually
                cursor.execute(
                    "SELECT name FROM sqlite_master WHERE type='table' "
                    "AND name != 'django_migrations' AND name NOT LIKE 'sqlite_%';"
                )
                tables = [row[0] for row in cursor.fetchall()]
                for table in tables:
                    cursor.execute(f'DELETE FROM "{table}";')

            else:
                self.stdout.write(self.style.ERROR(
                    f"Unsupported database vendor: {connection.vendor}"
                ))
                return

        self.stdout.write(self.style.SUCCESS(
            f"Done. {len(tables)} table(s) cleared. Database is now empty."
        ))
