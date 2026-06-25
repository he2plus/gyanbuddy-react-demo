"""
Django management command to create dummy data for Module table.
Deletes all existing entries first, then creates 100 new entries.
"""

from django.core.management.base import BaseCommand
from gyaan_buddy.subjects.models import Module, Subject
from gyaan_buddy.users.models import Account
from faker import Faker
import random

fake = Faker()

MODULE_NAMES = [
    'Introduction', 'Basics', 'Fundamentals', 'Advanced Topics', 'Applications',
    'Theory', 'Practice', 'Exercises', 'Problems', 'Solutions',
    'Chapter 1', 'Chapter 2', 'Chapter 3', 'Unit 1', 'Unit 2',
    'Part A', 'Part B', 'Part C', 'Section 1', 'Section 2',
    'Overview', 'Review', 'Summary', 'Conclusion', 'Appendix',
    'Getting Started', 'Core Concepts', 'Extended Topics', 'Case Studies', 'Projects'
]


class Command(BaseCommand):
    help = 'Create 100 dummy modules. Deletes all existing modules first.'

    def handle(self, *args, **options):
        self.stdout.write('Deleting all existing modules...')
        Module.objects.all().delete()
        self.stdout.write(self.style.SUCCESS('All modules deleted.'))

        subjects = list(Subject.objects.all())
        if not subjects:
            self.stdout.write(self.style.ERROR('No subjects found. Please create subjects first.'))
            return

        accounts = list(Account.objects.filter(is_superuser=False))
        created_by = random.choice(accounts) if accounts else None

        self.stdout.write('Creating 100 dummy modules...')
        
        modules = []
        for i in range(100):
            subject = random.choice(subjects)
            module_name = f"{random.choice(MODULE_NAMES)} {i+1}"
            
            order = i % 10 + 1
            
            module = Module(
                name=module_name,
                subject=subject,
                description=fake.text(max_nb_chars=200),
                order=order,
                is_active=random.choice([True, True, True, False]),
                is_enabled=random.choice([True, False]),
                created_by=created_by
            )
            modules.append(module)
        
        Module.objects.bulk_create(modules)
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {len(modules)} modules!')
        )

