# Add test FK to Answer for test-scoped answers (enables correct % per question in test results)

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0012_add_test_module_chapter_multi'),
        ('subjects', '0019_module_due_date_question_hint'),
    ]

    operations = [
        migrations.AddField(
            model_name='answer',
            name='test',
            field=models.ForeignKey(
                blank=True,
                help_text='Test this answer was submitted for (null if mission/practice)',
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='answers',
                to='users.test',
            ),
        ),
        migrations.AlterUniqueTogether(
            name='answer',
            unique_together=set(),
        ),
        migrations.AddConstraint(
            model_name='answer',
            constraint=models.UniqueConstraint(
                condition=models.Q(test__isnull=True),
                fields=('user', 'question'),
                name='answer_user_question_non_test_unique',
            ),
        ),
        migrations.AddConstraint(
            model_name='answer',
            constraint=models.UniqueConstraint(
                condition=models.Q(test__isnull=False),
                fields=('user', 'question', 'test'),
                name='answer_user_question_test_unique',
            ),
        ),
    ]
