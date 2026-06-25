"""
Enroll all students in every subject assigned to their class.

For each active student who has a class_instance, this command looks up
the subjects on that class (Class.subjects M2M) and creates a
StudentSubjectEnrollment row for each pair that doesn't already exist.

Usage:
    # All schools, dry-run preview:
    python manage.py enroll_students_in_class_subjects --dry-run

    # A specific school:
    python manage.py enroll_students_in_class_subjects --school "Delhi Public School"

    # A specific class only:
    python manage.py enroll_students_in_class_subjects --class-name "9A" --school "DPS"

    # Actually save:
    python manage.py enroll_students_in_class_subjects
"""

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from gyaan_buddy.users.models import Student, StudentSubjectEnrollment


class Command(BaseCommand):
    help = 'Enroll all students in all subjects assigned to their class'

    def add_arguments(self, parser):
        parser.add_argument(
            '--school',
            type=str,
            default=None,
            help='Limit to students whose school matches this name (case-insensitive)',
        )
        parser.add_argument(
            '--class-name',
            type=str,
            default=None,
            help='Limit to a specific class name (e.g. "9A")',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Preview what would be created without saving anything',
        )

    def handle(self, *args, **options):
        school_filter = options['school']
        class_name_filter = options['class_name']
        dry_run = options['dry_run']

        # Build student queryset
        qs = (
            Student.objects
            .filter(is_deleted=False, class_instance__isnull=False)
            .select_related('class_instance', 'user_profile__school')
            .prefetch_related('class_instance__subjects', 'subject_enrollments')
        )

        if school_filter:
            qs = qs.filter(user_profile__school__name__iexact=school_filter)

        if class_name_filter:
            qs = qs.filter(class_instance__name__iexact=class_name_filter)

        students = list(qs)
        if not students:
            self.stdout.write(self.style.WARNING('No students found matching the given filters.'))
            return

        created_count = 0
        skipped_count = 0
        no_subjects_count = 0
        to_create = []

        for student in students:
            class_subjects = list(student.class_instance.subjects.filter(is_active=True))

            if not class_subjects:
                no_subjects_count += 1
                continue

            existing_subject_ids = set(
                student.subject_enrollments.values_list('subject_id', flat=True)
            )

            for subject in class_subjects:
                if subject.id in existing_subject_ids:
                    skipped_count += 1
                    continue

                to_create.append(
                    StudentSubjectEnrollment(
                        student=student,
                        subject=subject,
                        is_active=True,
                    )
                )
                created_count += 1

                if dry_run:
                    self.stdout.write(
                        f'  [DRY RUN] Would enroll {student.user_profile.full_name} '
                        f'(class: {student.class_instance.name}) → {subject.name}'
                    )

        self.stdout.write(f'\nStudents processed : {len(students)}')
        self.stdout.write(f'Enrollments to create : {created_count}')
        self.stdout.write(f'Already enrolled (skipped): {skipped_count}')
        self.stdout.write(f'Students with no class subjects: {no_subjects_count}')

        if dry_run:
            self.stdout.write(self.style.WARNING('\nDry run — nothing saved.'))
            return

        if not to_create:
            self.stdout.write(self.style.SUCCESS('Nothing to do — all students already enrolled.'))
            return

        with transaction.atomic():
            StudentSubjectEnrollment.objects.bulk_create(to_create, ignore_conflicts=True)

        self.stdout.write(
            self.style.SUCCESS(f'\nDone. Created {created_count} enrollment(s).')
        )
