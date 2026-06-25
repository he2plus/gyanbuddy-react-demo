"""
Django management command to create dummy data for ModuleChapter table.
Deletes all existing entries first, then creates 100 new entries.
"""

from django.core.management.base import BaseCommand
from gyaan_buddy.subjects.models import ModuleChapter, Module
from gyaan_buddy.users.models import Account
from faker import Faker
import random

fake = Faker()

CHAPTER_TITLES = [
    'Introduction to', 'Understanding', 'Exploring', 'Learning About', 'Mastering',
    'Fundamentals of', 'Advanced', 'Applications of', 'Theory of', 'Practice in',
    'Basics of', 'Deep Dive into', 'Overview of', 'Review of', 'Summary of',
    'Getting Started with', 'Working with', 'Using', 'Implementing', 'Analyzing',
    'Concepts in', 'Principles of', 'Methods in', 'Techniques for', 'Strategies for'
]


class Command(BaseCommand):
    help = 'Create 100 dummy chapters. Deletes all existing chapters first.'

    def handle(self, *args, **options):
        self.stdout.write('Deleting all existing chapters...')
        ModuleChapter.objects.all().delete()
        self.stdout.write(self.style.SUCCESS('All chapters deleted.'))

        modules = list(Module.objects.all())
        if not modules:
            self.stdout.write(self.style.ERROR('No modules found. Please create modules first.'))
            return

        accounts = list(Account.objects.filter(is_superuser=False))
        created_by = random.choice(accounts) if accounts else None

        self.stdout.write('Creating 100 dummy chapters...')
        
        chapters = []
        module_order_map = {}
        
        for i in range(100):
            module = random.choice(modules)
            chapter_title = f"{random.choice(CHAPTER_TITLES)} {fake.word().title()}"
            
            if module.id not in module_order_map:
                module_order_map[module.id] = 0
            module_order_map[module.id] += 1
            order = module_order_map[module.id]
            
            chapter = ModuleChapter(
                module=module,
                title=chapter_title,
                description=fake.text(max_nb_chars=200),
                order=order,
                is_enabled=random.choice([True, True, False]),
                is_important=random.choice([True, False]),
                created_by=created_by
            )
            chapters.append(chapter)
        
        ModuleChapter.objects.bulk_create(chapters)
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {len(chapters)} chapters!')
        )

