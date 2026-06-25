from django.db import migrations, models
import django.db.models.deletion


def clear_existing_subjects(apps, schema_editor):
    """
    Delete all existing subjects before adding the non-nullable school FK.
    Subjects are structural/seed data — they will be re-created via
    `python manage.py add_subject` with a school specified.
    """
    Subject = apps.get_model('subjects', 'Subject')
    Subject.objects.all().delete()


class Migration(migrations.Migration):

    atomic = False  # Required: ALTER TABLE after DELETE conflicts with deferred FK triggers in PostgreSQL

    dependencies = [
        ('subjects', '0025_class_unique_per_school_mission_unique_per_day'),
        ('users', '0001_initial'),
    ]

    operations = [
        # 1. Clear existing subjects (they have no school assigned)
        migrations.RunPython(clear_existing_subjects, migrations.RunPython.noop),

        # 2. Remove the old global unique constraint on code
        migrations.AlterField(
            model_name='subject',
            name='code',
            field=models.CharField(
                max_length=10,
                help_text='Short code for the subject (unique per school)',
            ),
        ),

        # 3. Add school as non-nullable (safe now that table is empty)
        migrations.AddField(
            model_name='subject',
            name='school',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='subjects',
                to='users.school',
                help_text='School this subject belongs to',
                default=None,
            ),
            preserve_default=False,
        ),

        # 4. Add unique_together (code, school)
        migrations.AlterUniqueTogether(
            name='subject',
            unique_together={('code', 'school')},
        ),

        # 5. Add index on school
        migrations.AddIndex(
            model_name='subject',
            index=models.Index(fields=['school'], name='subject_school_idx'),
        ),
    ]
