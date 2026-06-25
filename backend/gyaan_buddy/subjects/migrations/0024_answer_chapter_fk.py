"""
Migration 0024 — Answer.chapter FK + schema cleanup

Changes:
  1. Remove Module.due_date  (due dates live on chapters, not modules)
  2. Remove ModuleChapter.is_due  (replaced by @property: due_date is not None)
  3. Add Answer.chapter FK (nullable — populated by data migration)
  4. Data-migrate: populate Answer.chapter from question → ModuleContent → chapter
  5. Add composite indexes on Answer for dashboard query performance
  6. Add composite indexes on ModuleChapter
"""

import django.db.models.deletion
from django.db import migrations, models


def populate_answer_chapter(apps, schema_editor):
    """
    For every existing Answer, look up its chapter via:
        Answer.question → ModuleContent.question (first non-deleted, type=question) → chapter

    Uses raw SQL UPDATE for performance; avoids loading every Answer into Python.
    """
    db = schema_editor.connection
    # Local SQLite run: a fresh DB has no answers to populate, and this UPDATE
    # uses Postgres-only UPDATE…FROM / DISTINCT ON. Skip on non-Postgres.
    if db.vendor != 'postgresql':
        return
    with db.cursor() as cursor:
        cursor.execute("""
            UPDATE answers
            SET chapter_id = subq.chapter_id
            FROM (
                SELECT DISTINCT ON (mc.question_id)
                    mc.question_id,
                    mc.chapter_id
                FROM module_contents mc
                WHERE mc.content_type = 'question'
                  AND mc.is_deleted = false
                ORDER BY mc.question_id, mc.created_at ASC
            ) subq
            WHERE answers.question_id = subq.question_id
              AND answers.chapter_id IS NULL
        """)


def depopulate_answer_chapter(apps, schema_editor):
    """Reverse: clear chapter_id (column is dropped on rollback anyway)."""
    db = schema_editor.connection
    with db.cursor() as cursor:
        cursor.execute("UPDATE answers SET chapter_id = NULL")


class Migration(migrations.Migration):

    dependencies = [
        ('subjects', '0023_modulechapter_due_date'),
        ('users', '0017_clean_schema'),
    ]

    operations = [

        # ── 1. Remove Module.due_date ─────────────────────────────────────────
        migrations.RemoveField(
            model_name='module',
            name='due_date',
        ),

        # ── 2. Remove ModuleChapter.is_due (now a @property) ─────────────────
        migrations.RemoveField(
            model_name='modulechapter',
            name='is_due',
        ),

        # ── 3. Add Answer.chapter FK (nullable) ───────────────────────────────
        migrations.AddField(
            model_name='answer',
            name='chapter',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='answers',
                to='subjects.modulechapter',
                help_text='Chapter this answer belongs to (denormalized for fast dashboard queries)',
            ),
        ),

        # ── 4. Data migration: fill Answer.chapter ────────────────────────────
        migrations.RunPython(
            populate_answer_chapter,
            reverse_code=depopulate_answer_chapter,
        ),

        # ── 5. Indexes on Answer (dashboard-critical) ─────────────────────────
        migrations.AddIndex(
            model_name='answer',
            index=models.Index(fields=['chapter', 'user', 'is_correct'], name='answer_ch_user_correct_idx'),
        ),
        migrations.AddIndex(
            model_name='answer',
            index=models.Index(fields=['chapter', 'is_correct'], name='answer_ch_correct_idx'),
        ),
        migrations.AddIndex(
            model_name='answer',
            index=models.Index(fields=['user', 'chapter'], name='answer_user_chapter_idx'),
        ),

        # ── 6. Indexes on ModuleChapter ───────────────────────────────────────
        migrations.AddIndex(
            model_name='modulechapter',
            index=models.Index(fields=['module', 'due_date'], name='mc_module_due_idx'),
        ),
        migrations.AddIndex(
            model_name='modulechapter',
            index=models.Index(fields=['module', 'is_deleted'], name='mc_module_del_idx'),
        ),
        migrations.AddIndex(
            model_name='modulechapter',
            index=models.Index(fields=['due_date', 'is_deleted'], name='mc_due_del_idx'),
        ),
    ]
