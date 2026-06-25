"""
Django management command to create dummy data for Subject table.
Deletes all existing entries first, then creates 100 new entries.
"""

from django.core.management.base import BaseCommand
from gyaan_buddy.subjects.models import Subject
from faker import Faker
import random
import string
import os
from django.conf import settings

fake = Faker()

SUBJECT_NAMES = [
    'Mathematics', 'English', 'Science', 'History', 'Geography',
    'Physics', 'Chemistry', 'Biology', 'Economics', 'Computer Science',
    'Art', 'Music', 'Physical Education', 'Philosophy', 'Psychology',
    'Sociology', 'Political Science', 'Literature', 'Language', 'Statistics',
    'Algebra', 'Geometry', 'Calculus', 'Trigonometry', 'Statistics',
    'World History', 'Indian History', 'Geography', 'Civics', 'Social Studies',
    'Environmental Science', 'Astronomy', 'Geology', 'Meteorology', 'Oceanography',
    'Business Studies', 'Accountancy', 'Commerce', 'Marketing', 'Finance',
    'Programming', 'Data Structures', 'Algorithms', 'Database', 'Networking',
    'Creative Writing', 'Grammar', 'Vocabulary', 'Comprehension', 'Literature Analysis',
    'Organic Chemistry', 'Inorganic Chemistry', 'Physical Chemistry', 'Biochemistry', 'Analytical Chemistry',
    'Mechanics', 'Thermodynamics', 'Electromagnetism', 'Optics', 'Quantum Physics',
    'Cell Biology', 'Genetics', 'Ecology', 'Anatomy', 'Physiology',
    'Microeconomics', 'Macroeconomics', 'International Economics', 'Development Economics', 'Public Economics',
    'Painting', 'Sculpture', 'Drawing', 'Photography', 'Digital Art',
    'Classical Music', 'Jazz', 'Rock', 'Pop', 'Folk Music',
    'Yoga', 'Sports', 'Athletics', 'Swimming', 'Basketball',
    'Ethics', 'Logic', 'Metaphysics', 'Epistemology', 'Aesthetics',
    'Cognitive Psychology', 'Social Psychology', 'Clinical Psychology', 'Developmental Psychology', 'Behavioral Psychology',
    'Social Theory', 'Research Methods', 'Cultural Studies', 'Anthropology', 'Demography',
    'International Relations', 'Comparative Politics', 'Political Theory', 'Public Administration', 'Constitutional Law'
]


class Command(BaseCommand):
    help = 'Create 100 dummy subjects. Deletes all existing subjects first.'

    def handle(self, *args, **options):
        self.stdout.write('Deleting all existing subjects...')
        Subject.objects.all().delete()
        self.stdout.write(self.style.SUCCESS('All subjects deleted.'))

        logo_path = None
        logo_dir = os.path.join(settings.MEDIA_ROOT, 'subject_logos')
        if os.path.exists(logo_dir):
            logo_files = [f for f in os.listdir(logo_dir) if f.endswith(('.png', '.jpg', '.jpeg'))]
            if logo_files:
                logo_path = os.path.join('subject_logos', logo_files[0])
        
        if not logo_path:
            self.stdout.write(self.style.WARNING('No logo file found. Subjects will be created without logos (may fail if logo is required).'))
            self.stdout.write(self.style.WARNING('Please ensure at least one logo exists in media/subject_logos/'))

        self.stdout.write('Creating 100 dummy subjects...')
        
        used_names = set()
        used_codes = set()
        created_count = 0
        
        for i in range(100):
            name = random.choice(SUBJECT_NAMES)
            counter = 1
            while name in used_names:
                name = f"{random.choice(SUBJECT_NAMES)} {counter}"
                counter += 1
            used_names.add(name)
            
            code = name[:3].upper().replace(' ', '')
            counter = 1
            while code in used_codes or len(code) < 3:
                code = f"{name[:3].upper().replace(' ', '')}{counter}"
                counter += 1
            used_codes.add(code)
            
            subject = Subject(
                name=name,
                code=code[:10],
                description=fake.text(max_nb_chars=200),
                is_active=random.choice([True, True, True, False])
            )
            
            if logo_path:
                from django.core.files import File
                logo_file_path = os.path.join(settings.MEDIA_ROOT, logo_path)
                if os.path.exists(logo_file_path):
                    with open(logo_file_path, 'rb') as f:
                        subject.logo.save(os.path.basename(logo_path), File(f), save=False)
            
            subject.save()
            created_count += 1
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {created_count} subjects!')
        )

