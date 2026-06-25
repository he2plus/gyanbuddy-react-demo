"""
Dev data setup script — run once after a fresh database.

Usage (from gyaan_buddy_backend/):
    docker exec gyan-buddy-web-1 python setup_dev_data.py

Creates:
  - 1 teacher user       : teacher1 / teacher123
  - 1 school             : Dev School
  - 1 grade              : Grade 8
  - 1 class              : 8-A
  - 1 subject            : Science (SCI)
  - 1 module (chapter)   : MAGNETIC EFFECTS OF ELECTRIC CURRENT
  - 1 module chapter (topic): Magnetic Field and Field Lines
"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gyaan_buddy.settings.development')
django.setup()

from gyaan_buddy.users.models import User, School, Grade, Class
from gyaan_buddy.subjects.models import Subject, Module, ModuleChapter


def run():
    # ── Teacher user ──────────────────────────────────────────────────────────
    if User.objects.filter(username='teacher1').exists():
        print('teacher1 already exists, skipping user creation.')
        user = User.objects.get(username='teacher1')
    else:
        user = User.objects.create_user(
            username='teacher1',
            password='teacher123',
            email='teacher1@test.com',
        )
        print('Created user: teacher1 / teacher123')

    profile = user.profile
    profile.user_type = 'teacher'
    profile.save()
    school = profile.school
    print(f'School: {school.name} ({school.id})')

    # ── Grade ─────────────────────────────────────────────────────────────────
    grade, created = Grade.objects.get_or_create(name='Grade 8', school=school)
    print(f'{"Created" if created else "Found"} grade: {grade.name} ({grade.id})')

    # ── Class ─────────────────────────────────────────────────────────────────
    cls, created = Class.objects.get_or_create(name='8-A', school=school, defaults={'grade': grade})
    print(f'{"Created" if created else "Found"} class: {cls.name} ({cls.id})')

    # ── Subject ───────────────────────────────────────────────────────────────
    subject, created = Subject.objects.get_or_create(
        code='SCI', school=school,
        defaults={'name': 'Science'},
    )
    print(f'{"Created" if created else "Found"} subject: {subject.name} ({subject.id})')

    # ── Module (chapter) ──────────────────────────────────────────────────────
    module, created = Module.objects.get_or_create(
        name='MAGNETIC EFFECTS OF ELECTRIC CURRENT',
        subject=subject,
        class_instance=cls,
    )
    print(f'{"Created" if created else "Found"} module: {module.name} ({module.id})')

    # ── ModuleChapter (topic) ─────────────────────────────────────────────────
    topic, created = ModuleChapter.objects.get_or_create(
        title='Magnetic Field and Field Lines',
        module=module,
        defaults={
            'order': 1,
            'theory': (
                'Magnetic field lines are closed curves that emerge from the north pole '
                'and merge at the south pole. The direction of magnetic field at a point '
                'is the direction of the tangent to the field line at that point. '
                'Closer field lines indicate stronger magnetic field. '
                'A current-carrying conductor placed in a magnetic field experiences a force. '
                'The direction of this force is given by Fleming\'s Left Hand Rule.'
            ),
        },
    )
    print(f'{"Created" if created else "Found"} topic: {topic.title} ({topic.id})')

    # ── Summary ───────────────────────────────────────────────────────────────
    print()
    print('=' * 60)
    print('DEV DATA READY')
    print('=' * 60)
    print(f'Login          : teacher1 / teacher123')
    print(f'Class ID       : {cls.id}')
    print(f'Subject ID     : {subject.id}')
    print(f'Module ID      : {module.id}   ← use as chapter_id for PDF upload / generate')
    print(f'Topic ID       : {topic.id}   ← ModuleChapter (topic inside chapter)')
    print('=' * 60)
    print()
    print('Get a bearer token:')
    print('  curl -X POST http://localhost:8000/api/auth/login/ \\')
    print('    -H "Content-Type: application/json" \\')
    print('    -d \'{"username": "teacher1", "password": "teacher123", "type": "dashboard"}\'')
    print('=' * 60)


if __name__ == '__main__':
    run()
