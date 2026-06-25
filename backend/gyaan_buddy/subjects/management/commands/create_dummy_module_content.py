"""
Django management command to create dummy data for ModuleContent table.
Deletes all existing entries first, then creates 100 new entries (question type only).
"""

from django.core.management.base import BaseCommand
from gyaan_buddy.subjects.models import ModuleContent, ModuleChapter, Question
from gyaan_buddy.users.models import Account
from faker import Faker
import random

fake = Faker()


class Command(BaseCommand):
    help = 'Create 100 dummy module contents (question type only). Deletes all existing contents first.'

    def handle(self, *args, **options):
        self.stdout.write('Deleting all existing module contents...')
        ModuleContent.objects.all().delete()
        self.stdout.write(self.style.SUCCESS('All module contents deleted.'))

        chapters = list(ModuleChapter.objects.all())
        if not chapters:
            self.stdout.write(self.style.ERROR('No chapters found. Please create chapters first.'))
            return

        questions = list(Question.objects.all())
        if not questions:
            self.stdout.write(self.style.ERROR('No questions found. Please create questions first.'))
            return

        accounts = list(Account.objects.filter(is_superuser=False))
        created_by = random.choice(accounts) if accounts else None

        self.stdout.write('Creating 100 dummy module contents (question type only)...')
        
        contents = []
        chapter_order_map = {}
        
        for i in range(100):
            chapter = random.choice(chapters)
            question = random.choice(questions)
            
            if chapter.id not in chapter_order_map:
                chapter_order_map[chapter.id] = 0
            chapter_order_map[chapter.id] += 1
            order = chapter_order_map[chapter.id]
            
            content = ModuleContent(
                chapter=chapter,
                content_type='question',
                question=question,
                order=order,
                created_by=created_by
            )
            contents.append(content)
        
        ModuleContent.objects.bulk_create(contents)
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {len(contents)} module contents!')
        )

