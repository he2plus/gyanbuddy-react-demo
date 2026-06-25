from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0008_delete_old_mission_data'),
        ('subjects', '0019_module_due_date_question_hint'),
    ]

    operations = [
        migrations.RemoveIndex(
            model_name='mission',
            name='mission_module_idx',
        ),
        migrations.RemoveIndex(
            model_name='mission',
            name='mission_chapter_idx',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='module',
        ),
        migrations.RemoveField(
            model_name='mission',
            name='module_chapter',
        ),
        migrations.AddField(
            model_name='missionquestion',
            name='chapter',
            field=models.ForeignKey(
                blank=True,
                help_text='Chapter this question belongs to',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='mission_questions',
                to='subjects.modulechapter',
            ),
        ),
        migrations.AddIndex(
            model_name='missionquestion',
            index=models.Index(fields=['chapter'], name='mq_chapter_idx'),
        ),
    ]
