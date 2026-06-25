import django.core.validators
from django.db import migrations, models


def migrate_class_subject_relationships(apps, schema_editor):
    """Migrate existing Subject-Class relationships to the new Class.subjects field."""
    db_alias = schema_editor.connection.alias
    with schema_editor.connection.cursor() as cursor:
        try:
            cursor.execute("SELECT subject_id, class_id FROM subjects_classes")
            rows = cursor.fetchall()
        except Exception:
            rows = []
    if rows:
        Class = apps.get_model('users', 'Class')
        Subject = apps.get_model('subjects', 'Subject')
        
        for subject_id, class_id in rows:
            try:
                class_obj = Class.objects.using(db_alias).get(id=class_id)
                subject_obj = Subject.objects.using(db_alias).get(id=subject_id)
                class_obj.subjects.add(subject_obj)
            except (Class.DoesNotExist, Subject.DoesNotExist):
                pass


def reverse_migrate_class_subject_relationships(apps, schema_editor):
    """Reverse migration - move relationships back to Subject.classes."""
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('subjects', '0011_manualverificationanswer'),
        ('users', '0005_remove_teacher_teacher_is_cls_teach_idx_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='class',
            name='subjects',
            field=models.ManyToManyField(blank=True, help_text='Subjects taught in this class (one class can have multiple subjects)', related_name='classes', to='subjects.subject'),
        ),
        migrations.AlterField(
            model_name='userchapterprogress',
            name='percentage',
            field=models.PositiveIntegerField(default=0, help_text='Completion percentage of the chapter for this user (0-100)', validators=[django.core.validators.MinValueValidator(0), django.core.validators.MaxValueValidator(100)]),
        ),
        migrations.AlterField(
            model_name='usermoduleprogress',
            name='percentage',
            field=models.PositiveIntegerField(default=0, help_text='Completion percentage of the module for this user (0-100)', validators=[django.core.validators.MinValueValidator(0), django.core.validators.MaxValueValidator(100)]),
        ),
        migrations.RunPython(
            migrate_class_subject_relationships,
            reverse_migrate_class_subject_relationships,
        ),
    ]
