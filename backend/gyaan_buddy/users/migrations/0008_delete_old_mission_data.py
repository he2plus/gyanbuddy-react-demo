import django.core.validators
import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


def delete_old_data(apps, schema_editor):
    """Delete all old data before schema changes using raw SQL to avoid trigger issues."""
    # Local SQLite run: a fresh DB has nothing to delete, and SET CONSTRAINTS is
    # Postgres-only. Skip on non-Postgres backends.
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SET CONSTRAINTS ALL IMMEDIATE;")
        cursor.execute("DELETE FROM user_test_progress;")
        cursor.execute("DELETE FROM user_tests;")
        cursor.execute("DELETE FROM user_mission_progress;")
        cursor.execute("DELETE FROM mission_questions;")
        cursor.execute("DELETE FROM missions;")


class Migration(migrations.Migration):
    atomic = False

    dependencies = [
        ('users', '0007_add_user_test_models'),
        ('subjects', '0019_module_due_date_question_hint'),
    ]

    operations = [
        migrations.RunPython(delete_old_data, migrations.RunPython.noop),
        migrations.CreateModel(
            name='Test',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, help_text='Unique identifier for this record', primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Timestamp when this record was created')),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Timestamp when this record was last updated')),
                ('is_deleted', models.BooleanField(default=False, help_text='Whether this record has been soft deleted')),
                ('deleted_at', models.DateTimeField(blank=True, help_text='Timestamp when this record was soft deleted', null=True)),
                ('test_datetime', models.DateTimeField(help_text='Date and time when the test is scheduled')),
                ('duration', models.PositiveIntegerField(help_text='Duration of the test in minutes')),
                ('class_group', models.ForeignKey(help_text='Class this test is assigned to', on_delete=django.db.models.deletion.CASCADE, related_name='tests', to='users.class')),
                ('subject', models.ForeignKey(help_text='Subject this test is related to', on_delete=django.db.models.deletion.CASCADE, related_name='tests', to='subjects.subject')),
                ('module', models.ForeignKey(help_text='Module this test is related to', on_delete=django.db.models.deletion.CASCADE, related_name='tests', to='subjects.module')),
                ('module_chapter', models.ForeignKey(help_text='Chapter this test is related to', on_delete=django.db.models.deletion.CASCADE, related_name='tests', to='subjects.modulechapter')),
            ],
            options={
                'verbose_name': 'Test',
                'verbose_name_plural': 'Tests',
                'db_table': 'tests',
                'ordering': ['-test_datetime'],
            },
        ),
        migrations.CreateModel(
            name='TestQuestion',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, help_text='Unique identifier for this record', primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Timestamp when this record was created')),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Timestamp when this record was last updated')),
                ('order', models.PositiveIntegerField(default=1, help_text='Order of the question within the test')),
                ('test', models.ForeignKey(help_text='Test this question belongs to', on_delete=django.db.models.deletion.CASCADE, related_name='test_questions', to='users.test')),
                ('question', models.ForeignKey(help_text='Question in this test', on_delete=django.db.models.deletion.CASCADE, related_name='test_questions', to='subjects.question')),
            ],
            options={
                'verbose_name': 'Test Question',
                'verbose_name_plural': 'Test Questions',
                'db_table': 'test_questions',
                'ordering': ['order'],
                'unique_together': {('test', 'question')},
            },
        ),
        migrations.AddField(
            model_name='test',
            name='questions',
            field=models.ManyToManyField(help_text='Questions included in this test', related_name='tests', through='users.TestQuestion', to='subjects.question'),
        ),
        migrations.AddIndex(
            model_name='test',
            index=models.Index(fields=['test_datetime'], name='test_datetime_idx'),
        ),
        migrations.AddIndex(
            model_name='test',
            index=models.Index(fields=['class_group'], name='test_class_idx'),
        ),
        migrations.AddIndex(
            model_name='test',
            index=models.Index(fields=['subject'], name='test_subject_idx'),
        ),
        migrations.AddIndex(
            model_name='test',
            index=models.Index(fields=['module'], name='test_module_idx'),
        ),
        migrations.AddIndex(
            model_name='test',
            index=models.Index(fields=['module_chapter'], name='test_chapter_idx'),
        ),
        migrations.AddIndex(
            model_name='test',
            index=models.Index(fields=['is_deleted'], name='test_deleted_idx'),
        ),
        migrations.AddIndex(
            model_name='test',
            index=models.Index(fields=['class_group', 'test_datetime'], name='test_cls_datetime_idx'),
        ),
        migrations.AddIndex(
            model_name='testquestion',
            index=models.Index(fields=['test'], name='tq_test_idx'),
        ),
        migrations.AddIndex(
            model_name='testquestion',
            index=models.Index(fields=['question'], name='tq_question_idx'),
        ),
        migrations.AddIndex(
            model_name='testquestion',
            index=models.Index(fields=['order'], name='tq_order_idx'),
        ),
        migrations.AddIndex(
            model_name='testquestion',
            index=models.Index(fields=['test', 'order'], name='tq_test_order_idx'),
        ),
        migrations.RemoveIndex(
            model_name='mission',
            name='mission_active_idx',
        ),
        migrations.RemoveIndex(
            model_name='mission',
            name='mission_created_by_idx',
        ),
        migrations.RemoveIndex(
            model_name='mission',
            name='mission_class_idx',
        ),
        migrations.RemoveIndex(
            model_name='mission',
            name='mission_date_active_idx',
        ),
        migrations.RemoveIndex(
            model_name='mission',
            name='mission_class_active_idx',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='title',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='description',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='exp_multiplier',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='base_exp',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='duration',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='is_active',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='class_group',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='created_by',
        ),
        migrations.AddField(
            model_name='mission',
            name='account',
            field=models.ForeignKey(
                help_text='User assigned to this mission',
                on_delete=django.db.models.deletion.CASCADE,
                related_name='missions',
                to=settings.AUTH_USER_MODEL,
            ),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='mission',
            name='module',
            field=models.ForeignKey(
                help_text='Module this mission is related to',
                on_delete=django.db.models.deletion.CASCADE,
                related_name='missions',
                to='subjects.module',
            ),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='mission',
            name='module_chapter',
            field=models.ForeignKey(
                help_text='Chapter this mission is related to',
                on_delete=django.db.models.deletion.CASCADE,
                related_name='missions',
                to='subjects.modulechapter',
            ),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name='mission',
            name='subject',
            field=models.ForeignKey(
                help_text='Subject this mission is related to',
                on_delete=django.db.models.deletion.CASCADE,
                related_name='missions',
                to='subjects.subject',
            ),
        ),
        migrations.AlterModelOptions(
            name='mission',
            options={'ordering': ['-mission_date'], 'verbose_name': 'Mission', 'verbose_name_plural': 'Missions'},
        ),
        migrations.AddIndex(
            model_name='mission',
            index=models.Index(fields=['account'], name='mission_account_idx'),
        ),
        migrations.AddIndex(
            model_name='mission',
            index=models.Index(fields=['module'], name='mission_module_idx'),
        ),
        migrations.AddIndex(
            model_name='mission',
            index=models.Index(fields=['module_chapter'], name='mission_chapter_idx'),
        ),
        migrations.AddIndex(
            model_name='mission',
            index=models.Index(fields=['account', 'mission_date'], name='mission_acc_date_idx'),
        ),
        migrations.RemoveIndex(
            model_name='usermissionprogress',
            name='ump_mission_account_idx',
        ),
        migrations.RemoveIndex(
            model_name='usermissionprogress',
            name='ump_mission_account_status_idx',
        ),
        migrations.RemoveIndex(
            model_name='usermissionprogress',
            name='ump_mission_mission_status_idx',
        ),
        migrations.AlterUniqueTogether(
            name='usermissionprogress',
            unique_together=set(),
        ),
        migrations.RemoveField(
            model_name='usermissionprogress',
            name='account',
        ),
        migrations.AlterField(
            model_name='usermissionprogress',
            name='mission',
            field=models.OneToOneField(
                help_text='Mission being tracked',
                on_delete=django.db.models.deletion.CASCADE,
                related_name='progress',
                to='users.mission',
            ),
        ),
        migrations.AlterField(
            model_name='usermissionprogress',
            name='status',
            field=models.CharField(
                choices=[('not_started', 'Not Started'), ('in_progress', 'In Progress'), ('completed', 'Completed')],
                default='not_started',
                help_text='Current status on this mission',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='usermissionprogress',
            name='percentage',
            field=models.PositiveIntegerField(
                default=0,
                help_text='Completion percentage (0-100)',
                validators=[django.core.validators.MinValueValidator(0), django.core.validators.MaxValueValidator(100)],
            ),
        ),
        migrations.AddField(
            model_name='usermissionprogress',
            name='score',
            field=models.PositiveIntegerField(default=0, help_text='Score achieved'),
        ),
        migrations.AddField(
            model_name='usermissionprogress',
            name='total_questions',
            field=models.PositiveIntegerField(default=0, help_text='Total number of questions'),
        ),
        migrations.AddField(
            model_name='usermissionprogress',
            name='questions_attempted',
            field=models.PositiveIntegerField(default=0, help_text='Number of questions attempted'),
        ),
        migrations.AddField(
            model_name='usermissionprogress',
            name='correct_answers',
            field=models.PositiveIntegerField(default=0, help_text='Number of correct answers'),
        ),
        migrations.AddField(
            model_name='usermissionprogress',
            name='wrong_answers',
            field=models.PositiveIntegerField(default=0, help_text='Number of wrong answers'),
        ),
        migrations.AddField(
            model_name='usermissionprogress',
            name='last_accessed',
            field=models.DateTimeField(auto_now=True, help_text='Last time accessed'),
        ),
        migrations.AddField(
            model_name='usermissionprogress',
            name='time_spent_seconds',
            field=models.PositiveIntegerField(default=0, help_text='Total time spent in seconds'),
        ),
        migrations.AlterField(
            model_name='usermissionprogress',
            name='started_at',
            field=models.DateTimeField(blank=True, help_text='When the user started this mission', null=True),
        ),
        migrations.AlterField(
            model_name='usermissionprogress',
            name='exp_earned',
            field=models.PositiveIntegerField(default=0, help_text='Experience points earned'),
        ),
        migrations.AlterField(
            model_name='usermissionprogress',
            name='current_question',
            field=models.ForeignKey(
                blank=True,
                help_text='Current question being worked on',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='mission_progress_current',
                to='subjects.question',
            ),
        ),
        migrations.RenameIndex(
            model_name='usermissionprogress',
            new_name='umip_mission_idx',
            old_name='ump_mission_mission_idx',
        ),
        migrations.RenameIndex(
            model_name='usermissionprogress',
            new_name='umip_status_idx',
            old_name='ump_mission_status_idx',
        ),
        migrations.AddIndex(
            model_name='usermissionprogress',
            index=models.Index(fields=['percentage'], name='umip_percentage_idx'),
        ),
        migrations.AddIndex(
            model_name='usermissionprogress',
            index=models.Index(fields=['completed_at'], name='umip_completed_at_idx'),
        ),
        migrations.RemoveIndex(
            model_name='usertestprogress',
            name='utp_user_test_idx',
        ),
        migrations.RemoveField(
            model_name='usertestprogress',
            name='user_test',
        ),
        migrations.AddField(
            model_name='usertestprogress',
            name='account',
            field=models.ForeignKey(
                help_text='User taking this test',
                on_delete=django.db.models.deletion.CASCADE,
                related_name='test_progress',
                to=settings.AUTH_USER_MODEL,
            ),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='usertestprogress',
            name='test',
            field=models.ForeignKey(
                help_text='Test being tracked',
                on_delete=django.db.models.deletion.CASCADE,
                related_name='user_progress',
                to='users.test',
            ),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name='usertestprogress',
            name='status',
            field=models.CharField(
                choices=[('not_started', 'Not Started'), ('in_progress', 'In Progress'), ('completed', 'Completed'), ('abandoned', 'Abandoned')],
                default='not_started',
                help_text='Current status on this test',
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name='usertestprogress',
            name='percentage',
            field=models.PositiveIntegerField(
                default=0,
                help_text='Completion percentage (0-100)',
                validators=[django.core.validators.MinValueValidator(0), django.core.validators.MaxValueValidator(100)],
            ),
        ),
        migrations.AlterField(
            model_name='usertestprogress',
            name='score',
            field=models.PositiveIntegerField(default=0, help_text='Score achieved'),
        ),
        migrations.AlterField(
            model_name='usertestprogress',
            name='total_questions',
            field=models.PositiveIntegerField(default=0, help_text='Total number of questions'),
        ),
        migrations.AlterField(
            model_name='usertestprogress',
            name='exp_earned',
            field=models.PositiveIntegerField(default=0, help_text='Experience points earned'),
        ),
        migrations.AlterField(
            model_name='usertestprogress',
            name='time_spent_seconds',
            field=models.PositiveIntegerField(default=0, help_text='Total time spent in seconds'),
        ),
        migrations.AlterField(
            model_name='usertestprogress',
            name='last_accessed',
            field=models.DateTimeField(auto_now=True, help_text='Last time accessed'),
        ),
        migrations.AlterField(
            model_name='usertestprogress',
            name='current_question',
            field=models.ForeignKey(
                blank=True,
                help_text='Current question being worked on',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='test_progress_current',
                to='subjects.question',
            ),
        ),
        migrations.AlterUniqueTogether(
            name='usertestprogress',
            unique_together={('account', 'test')},
        ),
        migrations.AddIndex(
            model_name='usertestprogress',
            index=models.Index(fields=['account'], name='utp_account_idx'),
        ),
        migrations.AddIndex(
            model_name='usertestprogress',
            index=models.Index(fields=['test'], name='utp_test_idx'),
        ),
        migrations.AddIndex(
            model_name='usertestprogress',
            index=models.Index(fields=['account', 'test'], name='utp_account_test_idx'),
        ),
        migrations.AlterUniqueTogether(
            name='usertest',
            unique_together=set(),
        ),
        migrations.RemoveIndex(
            model_name='usertest',
            name='user_test_account_idx',
        ),
        migrations.RemoveIndex(
            model_name='usertest',
            name='user_test_mission_idx',
        ),
        migrations.RemoveIndex(
            model_name='usertest',
            name='user_test_active_idx',
        ),
        migrations.RemoveIndex(
            model_name='usertest',
            name='user_test_deleted_idx',
        ),
        migrations.RemoveIndex(
            model_name='usertest',
            name='user_test_due_date_idx',
        ),
        migrations.RemoveIndex(
            model_name='usertest',
            name='user_test_acc_active_idx',
        ),
        migrations.RemoveIndex(
            model_name='usertest',
            name='user_test_assigned_by_idx',
        ),
        migrations.DeleteModel(
            name='UserTest',
        ),
    ]
