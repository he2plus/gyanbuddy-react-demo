from django.db import migrations, models
import django.db.models.deletion


def clear_existing_modules(apps, schema_editor):
    """Delete all modules before adding the non-nullable class_instance FK."""
    Module = apps.get_model('subjects', 'Module')
    Module.objects.all().delete()


class Migration(migrations.Migration):

    atomic = False  # Avoid deferred FK trigger conflicts in PostgreSQL

    dependencies = [
        ('subjects', '0026_subject_school_fk'),
        ('users', '0001_initial'),
    ]

    operations = [
        # 1. Clear existing modules (they have no class_instance)
        migrations.RunPython(clear_existing_modules, migrations.RunPython.noop),

        # 2. Add class_instance as non-nullable (table is now empty)
        migrations.AddField(
            model_name='module',
            name='class_instance',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='modules',
                to='users.class',
                help_text='Class this module belongs to',
                default=None,
            ),
            preserve_default=False,
        ),

        # 3. Update unique_together to include class_instance
        migrations.AlterUniqueTogether(
            name='module',
            unique_together={('subject', 'class_instance', 'name')},
        ),

        # 4. Add index on class_instance
        migrations.AddIndex(
            model_name='module',
            index=models.Index(fields=['class_instance'], name='module_class_idx'),
        ),
    ]
