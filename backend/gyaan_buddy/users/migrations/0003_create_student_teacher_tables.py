import django.core.validators
import django.db.models.deletion
import uuid
from django.db import migrations, models


def migrate_userprofile_to_student_teacher(apps, schema_editor):
    """Migrate data from UserProfile to Student and TeacherProfile tables."""
    UserProfile = apps.get_model('users', 'UserProfile')
    Student = apps.get_model('users', 'Student')
    TeacherProfile = apps.get_model('users', 'TeacherProfile')
    Teacher = apps.get_model('users', 'Teacher')
    
    for profile in UserProfile.objects.filter(user_type='student'):
        if not Student.objects.filter(user_profile=profile).exists():
            Student.objects.create(
                user_profile=profile,
                admission_number=getattr(profile, 'admission_number', None),
                roll_number=getattr(profile, 'roll_number', None),
                class_instance=getattr(profile, 'class_instance', None),
                parent_name=getattr(profile, 'parent_name', None),
                total_exp=getattr(profile, 'total_exp', 0),
                rewards=getattr(profile, 'rewards', 0),
                level=getattr(profile, 'level', None),
            )
    
    # Migrate teachers and create mapping for updating Teacher records
    teacher_profile_map = {}  # Map old UserProfile ID to new TeacherProfile ID
    
    # First, get all UserProfiles that are referenced in Teacher records
    teacher_user_profile_ids = set(Teacher.objects.values_list('teacher_id', flat=True).distinct())
    
    # Create TeacherProfile for all teacher UserProfiles
    for profile in UserProfile.objects.filter(user_type='teacher'):
        # Check if TeacherProfile already exists (in case migration is run multiple times)
        teacher_profile, created = TeacherProfile.objects.get_or_create(
            user_profile=profile,
            defaults={
                'employee_id': getattr(profile, 'employee_id', None),
                'is_class_teacher': getattr(profile, 'is_class_teacher', False),
            }
        )
        teacher_profile_map[profile.id] = teacher_profile.id
    for profile_id in teacher_user_profile_ids:
        if profile_id not in teacher_profile_map:
            try:
                profile = UserProfile.objects.get(id=profile_id)
                if profile.user_type == 'teacher':
                    teacher_profile, created = TeacherProfile.objects.get_or_create(
                        user_profile=profile,
                        defaults={
                            'employee_id': getattr(profile, 'employee_id', None),
                            'is_class_teacher': getattr(profile, 'is_class_teacher', False),
                        }
                    )
                    teacher_profile_map[profile.id] = teacher_profile.id
            except UserProfile.DoesNotExist:
                # Skip if UserProfile doesn't exist
                pass
    
    # Delete ALL Teacher records before changing the constraint
    # We'll recreate them after the constraint is changed
    # This is necessary because we can't update them to TeacherProfile IDs while
    # the constraint still expects UserProfile IDs
    with schema_editor.connection.cursor() as cursor:
        # Store Teacher records data before deleting (for valid ones)
        cursor.execute("""
            SELECT id, teacher_id, class_instance_id, subject_id, is_class_teacher, created_at, updated_at
            FROM teachers
        """)
        all_teachers = cursor.fetchall()
        
        # Store valid teacher records data
        teacher_records_data = []
        for teacher_id, old_teacher_id, class_instance_id, subject_id, is_class_teacher, created_at, updated_at in all_teachers:
            if old_teacher_id in teacher_profile_map:
                teacher_records_data.append({
                    'new_teacher_profile_id': teacher_profile_map[old_teacher_id],
                    'class_instance_id': class_instance_id,
                    'subject_id': subject_id,
                    'is_class_teacher': is_class_teacher,
                    'created_at': created_at,
                    'updated_at': updated_at,
                })
        
        # Delete ALL Teacher records
        cursor.execute("DELETE FROM teachers")
        
        # Store the data for later recreation
        import sys
        if not hasattr(sys.modules[__name__], '_teacher_records_data'):
            sys.modules[__name__]._teacher_records_data = []
        sys.modules[__name__]._teacher_records_data = teacher_records_data


def update_teacher_records_to_teacherprofile(apps, schema_editor):
    """Recreate Teacher records pointing to TeacherProfile instead of UserProfile."""
    # Get the stored teacher records data
    import sys
    teacher_records_data = getattr(sys.modules[__name__], '_teacher_records_data', [])
    
    # Recreate Teacher records with TeacherProfile IDs
    with schema_editor.connection.cursor() as cursor:
        for record_data in teacher_records_data:
            try:
                # Verify the class and subject still exist
                cursor.execute("SELECT id FROM classes WHERE id = %s", [record_data['class_instance_id']])
                if not cursor.fetchone():
                    continue
                
                cursor.execute("SELECT id FROM subjects WHERE id = %s", [record_data['subject_id']])
                if not cursor.fetchone():
                    continue
                
                # Verify TeacherProfile exists
                cursor.execute("SELECT id FROM teacher_profiles WHERE id = %s", [record_data['new_teacher_profile_id']])
                if not cursor.fetchone():
                    continue
                
                # Insert the Teacher record with TeacherProfile ID
                import uuid
                cursor.execute("""
                    INSERT INTO teachers (id, teacher_id, class_instance_id, subject_id, is_class_teacher, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """, [
                    uuid.uuid4(),
                    record_data['new_teacher_profile_id'],
                    record_data['class_instance_id'],
                    record_data['subject_id'],
                    record_data['is_class_teacher'],
                    record_data['created_at'],
                    record_data['updated_at'],
                ])
            except Exception as e:
                # Skip if there's an error (e.g., duplicate, missing FK)
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"Failed to recreate Teacher record: {e}")
                continue


def reverse_migrate_student_teacher_to_userprofile(apps, schema_editor):
    """Reverse migration - move data back to UserProfile (for rollback)."""
    # Note: We can't restore the fields since they're removed from UserProfile
    # This is just for migration structure - actual rollback would require schema changes
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0002_alter_userprofile_gender'),
    ]

    operations = [
        migrations.CreateModel(
            name='Student',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, help_text='Unique identifier for this record', primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Timestamp when this record was created')),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Timestamp when this record was last updated')),
                ('is_deleted', models.BooleanField(default=False, help_text='Whether this record has been soft deleted')),
                ('deleted_at', models.DateTimeField(blank=True, help_text='Timestamp when this record was soft deleted', null=True)),
                ('admission_number', models.PositiveIntegerField(blank=True, help_text='Unique admission number for the student', null=True, unique=True, validators=[django.core.validators.MinValueValidator(1)])),
                ('roll_number', models.PositiveIntegerField(blank=True, help_text='Roll number for students (must be a positive integer)', null=True, unique=True, validators=[django.core.validators.MinValueValidator(1)])),
                ('parent_name', models.CharField(blank=True, help_text='Parent or guardian name for students', max_length=255, null=True)),
                ('total_exp', models.PositiveIntegerField(default=0, help_text='Total experience points earned by solving questions', validators=[django.core.validators.MinValueValidator(0)])),
                ('rewards', models.PositiveIntegerField(default=0, help_text='Total rewards earned by the student', validators=[django.core.validators.MinValueValidator(0)])),
            ],
            options={
                'verbose_name': 'Student',
                'verbose_name_plural': 'Students',
                'db_table': 'students',
            },
        ),
        migrations.CreateModel(
            name='TeacherProfile',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, help_text='Unique identifier for this record', primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Timestamp when this record was created')),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Timestamp when this record was last updated')),
                ('is_deleted', models.BooleanField(default=False, help_text='Whether this record has been soft deleted')),
                ('deleted_at', models.DateTimeField(blank=True, help_text='Timestamp when this record was soft deleted', null=True)),
                ('employee_id', models.CharField(blank=True, help_text='Employee ID for teachers', max_length=50, null=True, unique=True)),
                ('is_class_teacher', models.BooleanField(default=False, help_text='Whether this teacher is a class teacher')),
            ],
            options={
                'verbose_name': 'Teacher Profile',
                'verbose_name_plural': 'Teacher Profiles',
                'db_table': 'teacher_profiles',
            },
        ),
        migrations.AddField(
            model_name='student',
            name='class_instance',
            field=models.ForeignKey(blank=True, help_text='Class the student is currently enrolled in', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='enrolled_students', to='users.class'),
        ),
        migrations.AddField(
            model_name='student',
            name='level',
            field=models.ForeignKey(blank=True, help_text='Current level of the student', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='students', to='users.level'),
        ),
        migrations.AddField(
            model_name='student',
            name='user_profile',
            field=models.OneToOneField(help_text='User profile this student belongs to', on_delete=django.db.models.deletion.CASCADE, related_name='student', to='users.userprofile'),
        ),
        migrations.AddField(
            model_name='teacherprofile',
            name='user_profile',
            field=models.OneToOneField(help_text='User profile this teacher belongs to', on_delete=django.db.models.deletion.CASCADE, related_name='teacher_profile', to='users.userprofile'),
        ),
        migrations.RunPython(
            migrate_userprofile_to_student_teacher,
            reverse_migrate_student_teacher_to_userprofile,
        ),
        migrations.RemoveIndex(
            model_name='userprofile',
            name='profile_total_exp_idx',
        ),
        migrations.RemoveIndex(
            model_name='userprofile',
            name='profile_class_instance_idx',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='admission_number',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='class_instance',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='employee_id',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='is_class_teacher',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='level',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='parent_name',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='rewards',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='roll_number',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='total_exp',
        ),
        migrations.AlterField(
            model_name='class',
            name='class_teacher',
            field=models.ForeignKey(blank=True, help_text='Class teacher assigned to this class', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='classes_taught', to='users.teacherprofile'),
        ),
        migrations.AlterField(
            model_name='teacher',
            name='teacher',
            field=models.ForeignKey(help_text='Teacher (TeacherProfile) assigned to this class and subject', on_delete=django.db.models.deletion.CASCADE, related_name='teacher_assignments', to='users.teacherprofile'),
        ),
        migrations.RunPython(
            update_teacher_records_to_teacherprofile,
            migrations.RunPython.noop,
        ),
        migrations.AddIndex(
            model_name='student',
            index=models.Index(fields=['admission_number'], name='student_admission_number_idx'),
        ),
        migrations.AddIndex(
            model_name='student',
            index=models.Index(fields=['roll_number'], name='student_roll_number_idx'),
        ),
        migrations.AddIndex(
            model_name='student',
            index=models.Index(fields=['class_instance'], name='student_class_instance_idx'),
        ),
        migrations.AddIndex(
            model_name='student',
            index=models.Index(fields=['total_exp'], name='student_total_exp_idx'),
        ),
        migrations.AddIndex(
            model_name='student',
            index=models.Index(fields=['level'], name='student_level_idx'),
        ),
        migrations.AddIndex(
            model_name='student',
            index=models.Index(fields=['is_deleted'], name='student_is_deleted_idx'),
        ),
        migrations.AddIndex(
            model_name='teacherprofile',
            index=models.Index(fields=['employee_id'], name='tchr_prof_emp_id_idx'),
        ),
        migrations.AddIndex(
            model_name='teacherprofile',
            index=models.Index(fields=['is_class_teacher'], name='tchr_prof_cls_tchr_idx'),
        ),
        migrations.AddIndex(
            model_name='teacherprofile',
            index=models.Index(fields=['is_deleted'], name='tchr_prof_del_idx'),
        ),
    ]
