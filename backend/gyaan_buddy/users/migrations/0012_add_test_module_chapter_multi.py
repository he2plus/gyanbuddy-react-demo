# Migration: Add TestModuleChapter for multi module/chapter per test;
# migrate existing Test.module and Test.module_chapter into TestModuleChapter;
# remove module and module_chapter from Test.

import uuid
from django.db import migrations, models
import django.db.models.deletion


def copy_test_module_chapters(apps, schema_editor):
    """Copy each Test's module and module_chapter into TestModuleChapter, then we remove FKs from Test."""
    Test = apps.get_model('users', 'Test')
    TestModuleChapter = apps.get_model('users', 'TestModuleChapter')
    for test in Test.objects.all():
        if hasattr(test, 'module_id') and test.module_id and hasattr(test, 'module_chapter_id') and test.module_chapter_id:
            TestModuleChapter.objects.get_or_create(
                test=test,
                module_id=test.module_id,
                module_chapter_id=test.module_chapter_id,
                defaults={'id': uuid.uuid4()}
            )


def reverse_copy(apps, schema_editor):
    """On reverse: set Test.module and Test.module_chapter from first TestModuleChapter per test (cannot restore multiple)."""
    Test = apps.get_model('users', 'Test')
    TestModuleChapter = apps.get_model('users', 'TestModuleChapter')
    for test in Test.objects.all():
        tmc = TestModuleChapter.objects.filter(test=test).order_by('created_at').first()
        if tmc:
            test.module_id = tmc.module_id
            test.module_chapter_id = tmc.module_chapter_id
            test.save()


class Migration(migrations.Migration):

    dependencies = [
        ('subjects', '0019_module_due_date_question_hint'),
        ('users', '0011_alter_test_test_datetime'),
    ]

    operations = [
        migrations.CreateModel(
            name='TestModuleChapter',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Timestamp when this record was created')),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Timestamp when this record was last updated')),
                ('test', models.ForeignKey(help_text='Test this selection belongs to', on_delete=django.db.models.deletion.CASCADE, related_name='module_chapters', to='users.test')),
                ('module', models.ForeignKey(help_text='Module included in this test', on_delete=django.db.models.deletion.CASCADE, related_name='test_module_chapters', to='subjects.module')),
                ('module_chapter', models.ForeignKey(help_text='Chapter included in this test (must belong to the module)', on_delete=django.db.models.deletion.CASCADE, related_name='test_module_chapters', to='subjects.modulechapter')),
            ],
            options={
                'verbose_name': 'Test Module Chapter',
                'verbose_name_plural': 'Test Module Chapters',
                'db_table': 'test_module_chapters',
                'ordering': ['module', 'module_chapter'],
            },
        ),
        migrations.AddIndex(
            model_name='testmodulechapter',
            index=models.Index(fields=['test'], name='tmc_test_idx'),
        ),
        migrations.AddIndex(
            model_name='testmodulechapter',
            index=models.Index(fields=['module'], name='tmc_module_idx'),
        ),
        migrations.AddIndex(
            model_name='testmodulechapter',
            index=models.Index(fields=['module_chapter'], name='tmc_chapter_idx'),
        ),
        migrations.AddIndex(
            model_name='testmodulechapter',
            index=models.Index(fields=['test', 'module'], name='tmc_test_module_idx'),
        ),
        migrations.AlterUniqueTogether(
            name='testmodulechapter',
            unique_together={('test', 'module_chapter')},
        ),
        migrations.RunPython(copy_test_module_chapters, reverse_copy),
        migrations.RemoveIndex(
            model_name='test',
            name='test_module_idx',
        ),
        migrations.RemoveIndex(
            model_name='test',
            name='test_chapter_idx',
        ),
        migrations.RemoveField(
            model_name='test',
            name='module',
        ),
        migrations.RemoveField(
            model_name='test',
            name='module_chapter',
        ),
    ]
