"""
Migration 0017 — Clean Schema

Changes:
  1. Create StudentSubjectEnrollment (replaces Student.subjects M2M)
  2. Data-migrate Student.subjects → StudentSubjectEnrollment
  3. Remove Student.subjects M2M table
  4. Remove TeacherProfile.subjects M2M table
  5. Add is_deleted / deleted_at to Teacher (it now inherits SoftDeleteModel)
  6. Remove global unique constraint from Student.admission_number
  7. Remove global unique constraint from Student.roll_number
  8. Add per-class unique constraint on Student.roll_number
"""

import uuid
import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models


def migrate_student_subjects(apps, schema_editor):
    """Copy existing Student.subjects M2M rows into StudentSubjectEnrollment."""
    StudentSubjectEnrollment = apps.get_model('users', 'StudentSubjectEnrollment')

    # Local SQLite run: a fresh DB has no legacy M2M rows, and the table probe
    # uses Postgres-only information_schema. Skip on non-Postgres.
    db = schema_editor.connection
    if db.vendor != 'postgresql':
        return
    with db.cursor() as cursor:
        # The auto-generated M2M table for Student.subjects is 'students_subjects'
        # (Django names it <app>_<model>_<field> from the old migration 0015).
        # We read directly from the table so we don't rely on a historical model.
        cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_name = 'students_subjects'")
        if cursor.fetchone() is None:
            return  # table was never created (fresh install)

        cursor.execute("SELECT student_id, subject_id FROM students_subjects")
        rows = cursor.fetchall()

    now = django.utils.timezone.now()
    enrollments = []
    for student_id, subject_id in rows:
        enrollments.append(
            StudentSubjectEnrollment(
                id=uuid.uuid4(),
                student_id=student_id,
                subject_id=subject_id,
                is_active=True,
                created_at=now,
                updated_at=now,
            )
        )
    if enrollments:
        StudentSubjectEnrollment.objects.bulk_create(enrollments, ignore_conflicts=True)


def migrate_student_subjects_reverse(apps, schema_editor):
    """On rollback, copy StudentSubjectEnrollment back into the M2M table."""
    db = schema_editor.connection
    with db.cursor() as cursor:
        cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_name = 'students_subjects'")
        if cursor.fetchone() is None:
            return

        StudentSubjectEnrollment = apps.get_model('users', 'StudentSubjectEnrollment')
        for sse in StudentSubjectEnrollment.objects.all():
            cursor.execute(
                "INSERT INTO students_subjects (student_id, subject_id) VALUES (%s, %s) ON CONFLICT DO NOTHING",
                [str(sse.student_id), str(sse.subject_id)],
            )


class Migration(migrations.Migration):

    dependencies = [
        ('subjects', '0023_modulechapter_due_date'),
        ('users', '0016_teacher_profile_subjects'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [

        # ── 1. Create StudentSubjectEnrollment ────────────────────────────────
        migrations.CreateModel(
            name='StudentSubjectEnrollment',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('is_active', models.BooleanField(default=True, help_text='Whether this enrollment is currently active')),
                ('student', models.ForeignKey(
                    help_text='Student enrolled in this subject',
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='subject_enrollments',
                    to='users.student',
                )),
                ('subject', models.ForeignKey(
                    help_text='Subject the student is enrolled in',
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='student_enrollments',
                    to='subjects.subject',
                )),
                ('enrolled_by', models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='enrollments_created',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                'verbose_name': 'Student Subject Enrollment',
                'verbose_name_plural': 'Student Subject Enrollments',
                'db_table': 'student_subject_enrollments',
            },
        ),
        migrations.AddConstraint(
            model_name='studentsubjectenrollment',
            constraint=models.UniqueConstraint(
                fields=['student', 'subject'],
                name='sse_student_subject_unique',
            ),
        ),
        migrations.AddIndex(
            model_name='studentsubjectenrollment',
            index=models.Index(fields=['student', 'is_active'], name='sse_student_active_idx'),
        ),
        migrations.AddIndex(
            model_name='studentsubjectenrollment',
            index=models.Index(fields=['subject', 'is_active'], name='sse_subject_active_idx'),
        ),
        migrations.AddIndex(
            model_name='studentsubjectenrollment',
            index=models.Index(fields=['student', 'subject', 'is_active'], name='sse_student_subj_active_idx'),
        ),

        # ── 2. Data migration: Student.subjects → StudentSubjectEnrollment ───
        migrations.RunPython(
            migrate_student_subjects,
            reverse_code=migrate_student_subjects_reverse,
        ),

        # ── 3. Remove Student.subjects M2M ───────────────────────────────────
        migrations.RemoveField(
            model_name='student',
            name='subjects',
        ),

        # ── 4. Remove TeacherProfile.subjects M2M ────────────────────────────
        migrations.RemoveField(
            model_name='teacherprofile',
            name='subjects',
        ),

        # ── 5. Add SoftDeleteModel fields to Teacher ──────────────────────────
        migrations.AddField(
            model_name='teacher',
            name='is_deleted',
            field=models.BooleanField(default=False, help_text='Whether this record has been soft deleted'),
        ),
        migrations.AddField(
            model_name='teacher',
            name='deleted_at',
            field=models.DateTimeField(blank=True, null=True, help_text='Timestamp when this record was soft deleted'),
        ),
        migrations.AddIndex(
            model_name='teacher',
            index=models.Index(fields=['teacher', 'subject', 'is_deleted'], name='teacher_tchr_subj_del_idx'),
        ),
        migrations.AddIndex(
            model_name='teacher',
            index=models.Index(fields=['teacher', 'is_deleted'], name='teacher_tchr_del_idx'),
        ),

        # ── 6 & 7. Fix admission_number / roll_number — remove global unique ──
        migrations.AlterField(
            model_name='student',
            name='admission_number',
            field=models.PositiveIntegerField(
                blank=True,
                null=True,
                help_text='Admission number — unique within a school, not globally',
            ),
        ),
        migrations.AlterField(
            model_name='student',
            name='roll_number',
            field=models.PositiveIntegerField(
                blank=True,
                null=True,
                help_text='Roll number — unique within a class, not globally',
            ),
        ),

        # ── 8. Add per-class unique constraint on roll_number ─────────────────
        migrations.AddConstraint(
            model_name='student',
            constraint=models.UniqueConstraint(
                fields=['class_instance', 'roll_number'],
                condition=models.Q(roll_number__isnull=False),
                name='student_roll_unique_per_class',
            ),
        ),
        migrations.AddIndex(
            model_name='student',
            index=models.Index(fields=['class_instance', 'is_deleted'], name='student_class_del_idx'),
        ),
    ]
