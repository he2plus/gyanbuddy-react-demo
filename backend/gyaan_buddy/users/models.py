from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.contrib.auth.models import PermissionsMixin
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from gyaan_buddy.base_models import SoftDeleteModel, TimeStampUUID
import logging

logger = logging.getLogger(__name__)


class School(SoftDeleteModel):
    
    name = models.CharField(
        max_length=200,
        help_text='Name of the school'
    )
    
    address = models.TextField(
        blank=True,
        help_text='Address of the school'
    )
    
    phone = models.CharField(
        max_length=20,
        blank=True,
        help_text='Phone number of the school'
    )
    
    email = models.EmailField(
        blank=True,
        help_text='Email address of the school'
    )
    
    website = models.URLField(
        blank=True,
        help_text='Website URL of the school'
    )
    
    password_prefix = models.CharField(
        max_length=20,
        blank=True,
        help_text='Prefix used when generating passwords for this school\'s users'
    )

    is_active = models.BooleanField(
        default=True,
        help_text='Whether this school is currently active'
    )
    
    class Meta:
        db_table = 'schools'
        verbose_name = 'School'
        verbose_name_plural = 'Schools'
        ordering = ['name']
        indexes = [
            models.Index(fields=['is_active'], name='school_is_active_idx'),
            models.Index(fields=['is_deleted'], name='school_is_deleted_idx'),
            models.Index(fields=['name'], name='school_name_idx'),
        ]
    
    def __str__(self):
        return self.name


class Level(models.Model):
    
    name = models.PositiveIntegerField(
        unique=True,
        help_text='Level number (1, 2, 3, etc.)'
    )
    
    min_exp = models.PositiveIntegerField(
        help_text='Minimum experience points required for this level'
    )
    
    max_exp = models.PositiveIntegerField(
        help_text='Maximum experience points for this level'
    )
    
    class Meta:
        db_table = 'levels'
        verbose_name = 'Level'
        verbose_name_plural = 'Levels'
        ordering = ['name']
        indexes = [
            models.Index(fields=['min_exp'], name='level_min_exp_idx'),
            models.Index(fields=['max_exp'], name='level_max_exp_idx'),
            models.Index(fields=['name'], name='level_name_idx'),
        ]
    
    def __str__(self):
        return f"Level {self.name} ({self.min_exp}-{self.max_exp} exp)"
    
    @classmethod
    def get_level_for_exp(cls, exp_points):
        """Get the level for a given experience point value."""
        level = cls.objects.filter(min_exp__lte=exp_points, max_exp__gte=exp_points).first()
        if level is None:
            level = cls.objects.filter(name=1).first()
        return level


class Account(AbstractUser, SoftDeleteModel):
    first_name = models.CharField(
        max_length=150,
        help_text='User first name (required)'
    )
    
    fcm_token = models.TextField(
        blank=True,
        null=True,
        help_text='Firebase Cloud Messaging token for push notifications'
    )
    
    logged_in_once = models.BooleanField(
        default=False,
        help_text='Whether the user has logged in at least once'
    )
    
    class Meta:
        db_table = 'accounts'
        verbose_name = 'Account'
        verbose_name_plural = 'Accounts'
        indexes = [
            models.Index(fields=['is_active'], name='account_is_active_idx'),
            models.Index(fields=['is_deleted'], name='account_is_deleted_idx'),
            models.Index(fields=['created_at'], name='account_created_at_idx'),
            models.Index(fields=['username'], name='account_username_idx'),
        ]
    
    def __str__(self):
        return f"{self.username} ({self.email})"
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip()
    
    def soft_delete(self):
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.is_active = False
        self.save(update_fields=['is_deleted', 'deleted_at', 'is_active'])
    
    def restore(self):
        self.is_deleted = False
        self.deleted_at = None
        self.is_active = True
        self.save(update_fields=['is_deleted', 'deleted_at', 'is_active'])


class UserProfile(SoftDeleteModel):
    USER_TYPE_CHOICES = [
        ('student', 'Student'),
        ('teacher', 'Teacher'),
        ('administrator', 'Administrator'),
    ]
    
    account = models.OneToOneField(
        Account,
        on_delete=models.CASCADE,
        related_name='profile',
        help_text='Account this profile belongs to'
    )
    
    school = models.ForeignKey(
        School,
        on_delete=models.CASCADE,
        related_name='user_profiles',
        help_text='School the user belongs to (required)'
    )
    
    user_type = models.CharField(
        max_length=15,
        choices=USER_TYPE_CHOICES,
        default='student',
        help_text='Type of user in the system'
    )
    
    phone_number = models.CharField(
        max_length=15,
        blank=True,
        null=True,
        help_text='User phone number'
    )
    
    date_of_birth = models.DateField(
        blank=True,
        null=True,
        help_text='User date of birth'
    )
    
    gender = models.CharField(
        max_length=20,
        choices=[
            ('male', 'Male'),
            ('female', 'Female'),
            ('other', 'Other'),
        ],
        blank=True,
        null=True,
        help_text='User gender'
    )
    
    profile_picture = models.ImageField(
        upload_to='profile_pictures/',
        blank=True,
        null=True,
        help_text='User profile picture'
    )
    
    bio = models.TextField(
        blank=True,
        help_text='User biography or description'
    )
    
    class Meta:
        db_table = 'user_profiles'
        verbose_name = 'User Profile'
        verbose_name_plural = 'User Profiles'
        indexes = [
            models.Index(fields=['user_type'], name='profile_user_type_idx'),
            models.Index(fields=['school'], name='profile_school_idx'),
            models.Index(fields=['is_deleted'], name='profile_is_deleted_idx'),
            models.Index(fields=['created_at'], name='profile_created_at_idx'),
            models.Index(fields=['school', 'user_type'], name='profile_school_type_idx'),
        ]
    
    def __str__(self):
        return f"{self.account.username} ({self.get_user_type_display()})"
    
    @property
    def full_name(self):
        return f"{self.account.first_name} {self.account.last_name}".strip()
    
    @property
    def total_exp(self):
        """Get total_exp from student if user is a student"""
        if self.user_type == 'student' and hasattr(self, 'student'):
            return self.student.total_exp
        return 0
    
    @property
    def rewards(self):
        """Get rewards from student if user is a student"""
        if self.user_type == 'student' and hasattr(self, 'student'):
            return self.student.rewards
        return 0
    
    @property
    def level(self):
        """Get level from student if user is a student"""
        if self.user_type == 'student' and hasattr(self, 'student'):
            return self.student.level
        return None
    
    def get_level(self):
        """Get level number from student if user is a student"""
        if self.user_type == 'student' and hasattr(self, 'student'):
            return self.student.get_level()
        return 1
    
    def get_exp_to_next_level(self):
        """Get exp to next level from student if user is a student"""
        if self.user_type == 'student' and hasattr(self, 'student'):
            return self.student.get_exp_to_next_level()
        return 0
    
    def add_exp(self, points):
        """Add experience points to student if user is a student"""
        if self.user_type == 'student' and hasattr(self, 'student'):
            self.student.add_exp(points)
    
    def add_rewards(self, points):
        """Add rewards to student if user is a student"""
        if self.user_type == 'student' and hasattr(self, 'student'):
            self.student.add_rewards(points)


class Student(SoftDeleteModel):
    """Student-specific information linked to UserProfile"""
    
    user_profile = models.OneToOneField(
        UserProfile,
        on_delete=models.CASCADE,
        related_name='student',
        help_text='User profile this student belongs to'
    )
    
    admission_number = models.PositiveIntegerField(
        validators=[MinValueValidator(1)],
        blank=True,
        null=True,
        help_text='Admission number — unique within a school, not globally'
    )

    roll_number = models.PositiveIntegerField(
        blank=True,
        null=True,
        validators=[MinValueValidator(1)],
        help_text='Roll number — unique within a class, not globally'
    )
    
    class_instance = models.ForeignKey(
        'Class',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='enrolled_students',
        help_text='Class the student is currently enrolled in'
    )
    
    parent_name = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text='Parent or guardian name for students'
    )
    
    total_exp = models.PositiveIntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text='Total experience points earned by solving questions'
    )
    
    rewards = models.PositiveIntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text='Total rewards earned by the student'
    )
    
    level = models.ForeignKey(
        Level,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='students',
        help_text='Current level of the student'
    )
    
    class Meta:
        db_table = 'students'
        verbose_name = 'Student'
        verbose_name_plural = 'Students'
        # admission_number is unique per school (via user_profile__school)
        # roll_number is unique per class
        constraints = [
            models.UniqueConstraint(
                fields=['class_instance', 'roll_number'],
                condition=models.Q(roll_number__isnull=False),
                name='student_roll_unique_per_class',
            ),
        ]
        indexes = [
            models.Index(fields=['class_instance', 'is_deleted'], name='student_class_del_idx'),
            models.Index(fields=['admission_number'], name='student_admission_number_idx'),
            models.Index(fields=['roll_number'], name='student_roll_number_idx'),
            models.Index(fields=['class_instance'], name='student_class_instance_idx'),
            models.Index(fields=['total_exp'], name='student_total_exp_idx'),
            models.Index(fields=['level'], name='student_level_idx'),
            models.Index(fields=['is_deleted'], name='student_is_deleted_idx'),
        ]
    
    def __str__(self):
        return f"{self.user_profile.account.username} (Student)"
    
    @property
    def account(self):
        """Convenience property to access account"""
        return self.user_profile.account
    
    def add_exp(self, points):
        if points > 0:
            self.total_exp += points
            self.update_level()
            self.save(update_fields=['total_exp', 'level'])
    
    def add_rewards(self, points):
        if points > 0:
            self.rewards += points
            self.save(update_fields=['rewards'])
    
    def update_level(self):
        new_level = Level.get_level_for_exp(self.total_exp)
        if new_level and new_level != self.level:
            old_level = self.level
            self.level = new_level
            self._send_level_up_notification(old_level, new_level)
    
    def get_level(self):
        return self.level.name if self.level else 1
    
    def is_enrolled_in_class(self):
        return self.class_instance is not None
    
    def get_class_name(self):
        return self.class_instance.name if self.class_instance else None
    
    def get_exp_to_next_level(self):
        if not self.level:
            return 0
        
        next_level = Level.objects.filter(name=self.level.name + 1).first()
        if next_level:
            return max(0, next_level.min_exp - self.total_exp)
        return 0
    
    def _send_level_up_notification(self, old_level, new_level):
        """Send level up notification to student via Firebase."""
        try:
            logger.info(f"Attempting to send level up notification to student {self.account.username}: Level {old_level.name if old_level else 1} -> {new_level.name}")
            
            from gyaan_buddy.utils.firebase_notifications import firebase_notification_service
            
            if not self.account.fcm_token:
                logger.warning(f"Student {self.account.username} does not have FCM token, skipping level up notification")
                return
            
            title = "Level Up!"
            body = f"Congratulations! You've reached Level {new_level.name}! Keep up the great work!"
            
            data = {
                'type': 'level_up',
                'old_level': str(old_level.name) if old_level else '1',
                'new_level': str(new_level.name),
                'total_exp': str(self.total_exp),
                'action': 'view_profile'
            }
            
            logger.debug(f"Preparing level up notification for {self.account.username} - Title: {title}, Body: {body}, Data: {data}")
            
            success = firebase_notification_service.send_notification_to_user(
                self.account, title, body, data, notification_type='user', triggered_by='auto'
            )
            
            if success:
                logger.info(f"Level up notification sent successfully to student {self.account.username}: Level {old_level.name if old_level else 1} -> {new_level.name}")
            else:
                logger.warning(f"Level up notification failed to send to student {self.account.username}: Level {old_level.name if old_level else 1} -> {new_level.name}")
            
        except Exception as e:
            logger.error(f"Failed to send level up notification to student {self.account.username}: {str(e)}", exc_info=True)
    
    def clean(self):
        from django.core.exceptions import ValidationError
        
        super().clean()
        
        if self.class_instance and self.user_profile_id:
            try:
                if self.class_instance.school != self.user_profile.school:
                    raise ValidationError({
                        'class_instance': 'Class must belong to the same school as the student.'
                    })
            except UserProfile.DoesNotExist:
                pass
    
    def save(self, *args, **kwargs):
        skip_validation = kwargs.pop('skip_validation', False)
        
        if not self.level:
            self.update_level()
        
        if not skip_validation:
            self.clean()
        
        super().save(*args, **kwargs)


class StudentSubjectEnrollment(TimeStampUUID):
    """
    Source of truth for which subject each student is enrolled in.

    Replaces the old Student.subjects ManyToManyField.
    Students in the same class can take different subjects. This table
    captures that per-student selection with full audit trail.

    A teacher whose TeacherAssignment covers (class=C, subject=S) sees
    exactly the students where:
        class_instance = C  AND  StudentSubjectEnrollment(subject=S, is_active=True) exists
    """
    student = models.ForeignKey(
        Student,
        on_delete=models.CASCADE,
        related_name='subject_enrollments',
        help_text='Student enrolled in this subject',
    )
    subject = models.ForeignKey(
        'subjects.Subject',
        on_delete=models.CASCADE,
        related_name='student_enrollments',
        help_text='Subject the student is enrolled in',
    )
    enrolled_by = models.ForeignKey(
        'Account',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='enrollments_created',
        help_text='Admin/teacher who created this enrollment',
    )
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this enrollment is currently active',
    )

    class Meta:
        db_table = 'student_subject_enrollments'
        verbose_name = 'Student Subject Enrollment'
        verbose_name_plural = 'Student Subject Enrollments'
        unique_together = ['student', 'subject']
        indexes = [
            models.Index(fields=['student', 'is_active'], name='sse_student_active_idx'),
            models.Index(fields=['subject', 'is_active'], name='sse_subject_active_idx'),
            models.Index(fields=['student', 'subject', 'is_active'], name='sse_student_subj_active_idx'),
        ]

    def __str__(self):
        return f"{self.student} → {self.subject} ({'active' if self.is_active else 'inactive'})"


class TeacherProfile(SoftDeleteModel):
    """Teacher-specific information linked to UserProfile"""
    
    user_profile = models.OneToOneField(
        UserProfile,
        on_delete=models.CASCADE,
        related_name='teacher_profile',
        help_text='User profile this teacher belongs to'
    )
    
    employee_id = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        unique=True,
        help_text='Employee ID for teachers'
    )
    
    is_class_teacher = models.BooleanField(
        default=False,
        help_text='Whether this teacher is a class teacher'
    )
    # NOTE: subjects M2M removed — derive from Teacher (TeacherAssignment) rows.
    # Use TeacherProfile.teacher_assignments.values('subject') for the list of subjects.

    class Meta:
        db_table = 'teacher_profiles'
        verbose_name = 'Teacher Profile'
        verbose_name_plural = 'Teacher Profiles'
        indexes = [
            models.Index(fields=['employee_id'], name='tchr_prof_emp_id_idx'),
            models.Index(fields=['is_class_teacher'], name='tchr_prof_cls_tchr_idx'),
            models.Index(fields=['is_deleted'], name='tchr_prof_del_idx'),
        ]
    
    def __str__(self):
        return f"{self.user_profile.account.username} (Teacher)"
    
    @property
    def account(self):
        """Convenience property to access account"""
        return self.user_profile.account


User = Account


@receiver(post_save, sender=Account)
def create_user_profile(sender, instance, created, **kwargs):
    if created and not hasattr(instance, 'profile'):
        if instance.is_superuser or instance.is_staff:
            user_type = 'administrator'
        else:
            user_type = 'student'
        
        from gyaan_buddy.users.models import School
        
        try:
            school = School.objects.first()
            if not school:
                school = School.objects.create(
                    name='Default School',
                    address='',
                    phone='',
                    email='',
                    website='',
                    is_active=True
                )
        except Exception:
            logger.warning(f"Could not create profile for {instance.username}: No school available")
            return
        
        try:
            profile = UserProfile.objects.create(
                account=instance,
                school=school,
                user_type=user_type
            )
            logger.info(f"Created profile for {instance.username} with user_type={user_type}")
        except Exception as e:
            logger.error(f"Failed to create profile for {instance.username}: {str(e)}")


class Class(TimeStampUUID):
    
    name = models.CharField(
        max_length=100,
        help_text='Name of the class'
    )
    
    school = models.ForeignKey(
        School,
        on_delete=models.CASCADE,
        related_name='classes',
        help_text='School this class belongs to'
    )
    
    description = models.TextField(
        blank=True,
        help_text='Description of the class'
    )
    
    class_teacher = models.ForeignKey(
        'TeacherProfile',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='classes_taught',
        help_text='Class teacher assigned to this class'
    )
    
    grade = models.ForeignKey(
        'Grade',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='classes',
        help_text='Grade this class belongs to (optional)'
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this class is currently active'
    )
    
    subjects = models.ManyToManyField(
        'subjects.Subject',
        related_name='classes',
        blank=True,
        help_text='Subjects taught in this class (one class can have multiple subjects)'
    )
    
    class Meta:
        db_table = 'classes'
        verbose_name = 'Class'
        verbose_name_plural = 'Classes'
        ordering = ['name']
        unique_together = [['name', 'school']]
        indexes = [
            models.Index(fields=['school'], name='class_school_idx'),
            models.Index(fields=['is_active'], name='class_is_active_idx'),
            models.Index(fields=['class_teacher'], name='class_teacher_idx'),
            models.Index(fields=['grade'], name='class_grade_idx'),
            models.Index(fields=['school', 'is_active'], name='class_school_active_idx'),
        ]
    
    def __str__(self):
        return f"{self.name}"


class Grade(TimeStampUUID):
    
    name = models.CharField(
        max_length=100,
        help_text='Name of the grade'
    )
    
    school = models.ForeignKey(
        School,
        on_delete=models.CASCADE,
        related_name='grades',
        help_text='School this grade belongs to'
    )
    
    description = models.TextField(
        blank=True,
        help_text='Description of the grade'
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this grade is currently active'
    )
    
    class Meta:
        db_table = 'grades'
        verbose_name = 'Grade'
        verbose_name_plural = 'Grades'
        ordering = ['name']
        indexes = [
            models.Index(fields=['school'], name='grade_school_idx'),
            models.Index(fields=['is_active'], name='grade_is_active_idx'),
            models.Index(fields=['school', 'is_active'], name='grade_school_active_idx'),
        ]
    
    def __str__(self):
        return f"{self.name}"
    
    @property
    def class_count(self):
        """Return the number of classes in this grade."""
        return self.classes.count()


class Teacher(SoftDeleteModel):
    """
    Teacher–Class–Subject assignment table (one row per unique triplet).

    Changed from TimeStampUUID → SoftDeleteModel so that soft-deleting a
    TeacherProfile also surfaces through these assignments when is_deleted
    is checked. Always filter Teacher.objects.filter(is_deleted=False).
    """
    teacher = models.ForeignKey(
        'TeacherProfile',
        on_delete=models.CASCADE,
        related_name='teacher_assignments',
        help_text='Teacher (TeacherProfile) assigned to this class and subject'
    )
    
    class_instance = models.ForeignKey(
        Class,
        on_delete=models.CASCADE,
        related_name='teacher_assignments',
        help_text='Class the teacher is assigned to'
    )
    
    subject = models.ForeignKey(
        'subjects.Subject',
        on_delete=models.CASCADE,
        related_name='teacher_assignments',
        help_text='Subject the teacher teaches in this class'
    )
    
    class Meta:
        db_table = 'teachers'
        verbose_name = 'Teacher'
        verbose_name_plural = 'Teachers'
        unique_together = ['teacher', 'class_instance', 'subject']
        ordering = ['teacher', 'class_instance', 'subject']
        indexes = [
            models.Index(fields=['teacher'], name='teacher_teacher_idx'),
            models.Index(fields=['class_instance'], name='teacher_class_idx'),
            models.Index(fields=['subject'], name='teacher_subject_idx'),
            models.Index(fields=['teacher', 'class_instance'], name='teacher_tchr_cls_idx'),
            models.Index(fields=['class_instance', 'subject'], name='teacher_cls_subj_idx'),
            models.Index(fields=['teacher', 'subject', 'is_deleted'], name='teacher_tchr_subj_del_idx'),
            models.Index(fields=['teacher', 'is_deleted'], name='teacher_tchr_del_idx'),
        ]
    
    def __str__(self):
        return f"{self.teacher.account.username} - {self.class_instance.name} - {self.subject.name}"


class UserModuleProgress(TimeStampUUID):
    
    STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('in_progress', 'In Progress'),
        ('due', 'Due'),
        ('completed', 'Completed'),
    ]
    
    account = models.ForeignKey(
        Account,
        on_delete=models.CASCADE,
        related_name='module_progress',
        help_text='User tracking progress on this module'
    )
    
    @property
    def user(self):
        return self.account
    
    module = models.ForeignKey(
        'subjects.Module',
        on_delete=models.CASCADE,
        related_name='user_progress',
        help_text='Module being tracked'
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='not_started',
        help_text='Current status of the user on this module'
    )
    
    percentage = models.PositiveIntegerField(
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text='Completion percentage of the module for this user (0-100)'
    )
    
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user first started this module'
    )
    
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user completed this module'
    )
    
    last_accessed = models.DateTimeField(
        auto_now=True,
        help_text='Last time the user accessed this module'
    )
    
    current_question = models.ForeignKey(
        'subjects.Question',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='module_progress_current',
        help_text='Current question the user is working on in this module'
    )
    
    class Meta:
        db_table = 'user_module_progress'
        verbose_name = 'User Module Progress'
        verbose_name_plural = 'User Module Progress'
        unique_together = ['account', 'module']
        indexes = [
            models.Index(fields=['account'], name='ump_account_idx'),
            models.Index(fields=['module'], name='ump_module_idx'),
            models.Index(fields=['status'], name='ump_status_idx'),
            models.Index(fields=['percentage'], name='ump_percentage_idx'),
            models.Index(fields=['account', 'status'], name='ump_account_status_idx'),
            models.Index(fields=['module', 'status'], name='ump_module_status_idx'),
            models.Index(fields=['account', 'module'], name='ump_account_module_idx'),
        ]
    
    def __str__(self):
        return f"{self.account.username} - {self.module.name} ({self.status})"
    
    def save(self, *args, **kwargs):
        if self.status == 'in_progress' and not self.started_at:
            from django.utils import timezone
            self.started_at = timezone.now()
        
        if self.status == 'completed' and not self.completed_at:
            from django.utils import timezone
            self.completed_at = timezone.now()
        
        super().save(*args, **kwargs)
    
    @property
    def is_overdue(self):
        return self.status == 'due' and self.percentage < 100


class UserChapterProgress(TimeStampUUID):
    
    STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('in_progress', 'In Progress'),
        ('due', 'Due'),
        ('completed', 'Completed'),
    ]
    
    account = models.ForeignKey(
        Account,
        on_delete=models.CASCADE,
        related_name='chapter_progress',
        help_text='User tracking progress on this chapter'
    )
    
    @property
    def user(self):
        return self.account
    
    chapter = models.ForeignKey(
        'subjects.ModuleChapter',
        on_delete=models.CASCADE,
        related_name='user_progress',
        help_text='Chapter being tracked'
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='not_started',
        help_text='Current status of the user on this chapter'
    )
    
    percentage = models.PositiveIntegerField(
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text='Completion percentage of the chapter for this user (0-100)'
    )
    
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user first started this chapter'
    )
    
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user completed this chapter'
    )
    
    last_accessed = models.DateTimeField(
        auto_now=True,
        help_text='Last time the user accessed this chapter'
    )
    
    current_question = models.ForeignKey(
        'subjects.Question',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='chapter_progress_current',
        help_text='Current question the user is working on in this chapter'
    )
    
    class Meta:
        db_table = 'user_chapter_progress'
        verbose_name = 'User Chapter Progress'
        verbose_name_plural = 'User Chapter Progress'
        unique_together = ['account', 'chapter']
        ordering = ['-last_accessed']
    
    def __str__(self):
        return f"{self.account.username} - {self.chapter.title} ({self.status})"
    
    def save(self, *args, **kwargs):
        if self.status == 'in_progress' and not self.started_at:
            from django.utils import timezone
            self.started_at = timezone.now()
        
        if self.status == 'completed' and not self.completed_at:
            from django.utils import timezone
            self.completed_at = timezone.now()
        
        super().save(*args, **kwargs)
    
    @property
    def is_overdue(self):
        return self.status == 'due' and self.percentage < 100


class Mission(SoftDeleteModel):
    """
    Mission assigned to a specific user.
    Contains questions from a subject across all chapters.
    """
    
    mission_date = models.DateField(
        help_text='Date when the mission is scheduled'
    )
    
    account = models.ForeignKey(
        Account,
        on_delete=models.CASCADE,
        related_name='missions',
        help_text='User assigned to this mission'
    )
    
    @property
    def user(self):
        return self.account
    
    subject = models.ForeignKey(
        'subjects.Subject',
        on_delete=models.CASCADE,
        related_name='missions',
        help_text='Subject this mission is related to'
    )
    
    questions = models.ManyToManyField(
        'subjects.Question',
        through='MissionQuestion',
        related_name='missions',
        help_text='Questions included in this mission'
    )
    
    class Meta:
        db_table = 'missions'
        verbose_name = 'Mission'
        verbose_name_plural = 'Missions'
        ordering = ['-mission_date']
        unique_together = [['account', 'mission_date', 'subject']]
        indexes = [
            models.Index(fields=['mission_date'], name='mission_date_idx'),
            models.Index(fields=['account'], name='mission_account_idx'),
            models.Index(fields=['subject'], name='mission_subject_idx'),
            models.Index(fields=['is_deleted'], name='mission_deleted_idx'),
            models.Index(fields=['account', 'mission_date'], name='mission_acc_date_idx'),
        ]
    
    def __str__(self):
        return f"{self.account.username} - {self.subject.name} - {self.mission_date}"
    
    @property
    def title(self):
        """Backward-compatible property to get a display name for the mission."""
        return f"{self.subject.name} Daily Mission"
    
    @property
    def question_count(self):
        return self.questions.count()


class MissionQuestion(TimeStampUUID):
    """Links questions to missions with ordering and chapter info."""
    
    mission = models.ForeignKey(
        Mission,
        on_delete=models.CASCADE,
        related_name='mission_questions',
        help_text='Mission this question belongs to'
    )
    
    question = models.ForeignKey(
        'subjects.Question',
        on_delete=models.CASCADE,
        related_name='mission_questions',
        help_text='Question in this mission'
    )
    
    chapter = models.ForeignKey(
        'subjects.ModuleChapter',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='mission_questions',
        help_text='Chapter this question belongs to'
    )
    
    order = models.PositiveIntegerField(
        default=1,
        help_text='Order of the question within the mission'
    )
    
    class Meta:
        db_table = 'mission_questions'
        verbose_name = 'Mission Question'
        verbose_name_plural = 'Mission Questions'
        unique_together = ['mission', 'question']
        ordering = ['order']
        indexes = [
            models.Index(fields=['mission'], name='mq_mission_idx'),
            models.Index(fields=['question'], name='mq_question_idx'),
            models.Index(fields=['order'], name='mq_order_idx'),
            models.Index(fields=['mission', 'order'], name='mq_mission_order_idx'),
            models.Index(fields=['chapter'], name='mq_chapter_idx'),
        ]
    
    def __str__(self):
        return f"Mission {self.mission.id} - Q{self.order}"


class Test(SoftDeleteModel):
    """
    Test assigned to a class.
    Contains questions from a subject; can include multiple modules and chapters
    via TestModuleChapter (many-to-many module+chapter selection).
    """
    
    test_datetime = models.DateTimeField(
        help_text='Date and time when the test is scheduled (stored in UTC; API accepts/returns Indian time Asia/Kolkata)'
    )
    
    duration = models.PositiveIntegerField(
        help_text='Duration of the test in minutes'
    )
    
    class_group = models.ForeignKey(
        Class,
        on_delete=models.CASCADE,
        related_name='tests',
        null=True,
        blank=True,
        help_text='Primary class (first selected); used for backward compatibility. Use class_groups for multi-class tests.'
    )
    
    class_groups = models.ManyToManyField(
        Class,
        related_name='test_assignments',
        blank=True,
        help_text='Classes this test is assigned to (can be multiple). When set, class_group is set to the first class.'
    )
    
    subject = models.ForeignKey(
        'subjects.Subject',
        on_delete=models.CASCADE,
        related_name='tests',
        help_text='Subject this test is related to'
    )
    
    questions = models.ManyToManyField(
        'subjects.Question',
        through='TestQuestion',
        related_name='tests',
        help_text='Questions included in this test'
    )
    
    created_by = models.ForeignKey(
        Account,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_tests',
        help_text='User who created this test'
    )
    
    class Meta:
        db_table = 'tests'
        verbose_name = 'Test'
        verbose_name_plural = 'Tests'
        ordering = ['-test_datetime']
        indexes = [
            models.Index(fields=['test_datetime'], name='test_datetime_idx'),
            models.Index(fields=['class_group'], name='test_class_idx'),
            models.Index(fields=['subject'], name='test_subject_idx'),
            models.Index(fields=['is_deleted'], name='test_deleted_idx'),
            models.Index(fields=['created_by'], name='test_created_by_idx'),
            models.Index(fields=['class_group', 'test_datetime'], name='test_cls_datetime_idx'),
        ]
    
    def __str__(self):
        primary = self.class_group or (self.class_groups.first() if self.class_groups.exists() else None)
        cls_str = primary.name if primary else "No class"
        return f"{cls_str} - {self.subject.name} - {self.test_datetime}"
    
    def get_assigned_classes(self):
        """Return list of classes this test is assigned to (class_groups if set, else [class_group])."""
        if self.class_groups.exists():
            return list(self.class_groups.all())
        if self.class_group_id:
            return [self.class_group]
        return []
    
    @property
    def question_count(self):
        return self.questions.count()


class TestModuleChapter(TimeStampUUID):
    """Links a Test to (module, chapter) pairs. A test can have multiple modules and chapters."""
    
    test = models.ForeignKey(
        Test,
        on_delete=models.CASCADE,
        related_name='module_chapters',
        help_text='Test this selection belongs to'
    )
    
    module = models.ForeignKey(
        'subjects.Module',
        on_delete=models.CASCADE,
        related_name='test_module_chapters',
        help_text='Module included in this test'
    )
    
    module_chapter = models.ForeignKey(
        'subjects.ModuleChapter',
        on_delete=models.CASCADE,
        related_name='test_module_chapters',
        help_text='Chapter included in this test (must belong to the module)'
    )
    
    class Meta:
        db_table = 'test_module_chapters'
        verbose_name = 'Test Module Chapter'
        verbose_name_plural = 'Test Module Chapters'
        unique_together = ['test', 'module_chapter']
        ordering = ['module', 'module_chapter']
        indexes = [
            models.Index(fields=['test'], name='tmc_test_idx'),
            models.Index(fields=['module'], name='tmc_module_idx'),
            models.Index(fields=['module_chapter'], name='tmc_chapter_idx'),
            models.Index(fields=['test', 'module'], name='tmc_test_module_idx'),
        ]
    
    def __str__(self):
        return f"Test {self.test.id} - {self.module.name} - {self.module_chapter.title}"


class TestQuestion(TimeStampUUID):
    """Links questions to tests with ordering."""
    
    test = models.ForeignKey(
        Test,
        on_delete=models.CASCADE,
        related_name='test_questions',
        help_text='Test this question belongs to'
    )
    
    question = models.ForeignKey(
        'subjects.Question',
        on_delete=models.CASCADE,
        related_name='test_questions',
        help_text='Question in this test'
    )
    
    order = models.PositiveIntegerField(
        default=1,
        help_text='Order of the question within the test'
    )
    
    class Meta:
        db_table = 'test_questions'
        verbose_name = 'Test Question'
        verbose_name_plural = 'Test Questions'
        unique_together = ['test', 'question']
        ordering = ['order']
        indexes = [
            models.Index(fields=['test'], name='tq_test_idx'),
            models.Index(fields=['question'], name='tq_question_idx'),
            models.Index(fields=['order'], name='tq_order_idx'),
            models.Index(fields=['test', 'order'], name='tq_test_order_idx'),
        ]
    
    def __str__(self):
        return f"Test {self.test.id} - Q{self.order}"


class Competition(SoftDeleteModel):
    
    COMPETITION_TYPE_CHOICES = [
        ('subject', 'Subject Only'),
        ('subject_with_chapter', 'Subject with Chapter'),
        ('random', 'Random Questions'),
    ]
    
    STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
    ]
    
    title = models.CharField(
        max_length=200,
        help_text='Title of the competition'
    )
    
    description = models.TextField(
        blank=True,
        help_text='Description of the competition'
    )
    
    code = models.CharField(
        max_length=10,
        unique=True,
        help_text='Unique code for joining the competition'
    )
    
    competition_type = models.CharField(
        max_length=25,
        choices=COMPETITION_TYPE_CHOICES,
        default='subject',
        help_text='Type of competition'
    )
    
    subject = models.ForeignKey(
        'subjects.Subject',
        on_delete=models.CASCADE,
        related_name='competitions',
        help_text='Subject for this competition'
    )
    
    chapter = models.ForeignKey(
        'subjects.ModuleChapter',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='competitions',
        help_text='Specific chapter for this competition (optional)'
    )
    
    total_time = models.PositiveIntegerField(
        help_text='Total time allowed in minutes'
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='not_started',
        help_text='Current status of the competition'
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this competition is currently active'
    )
    
    created_by = models.ForeignKey(
        Account,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_competitions',
        help_text='User who created this competition'
    )
    
    questions = models.ManyToManyField(
        'subjects.Question',
        through='CompetitionQuestion',
        related_name='competitions',
        help_text='Questions included in this competition'
    )
    
    participants = models.ManyToManyField(
        Account,
        through='UserCompetitionProgress',
        related_name='joined_competitions',
        help_text='Users who joined this competition'
    )
    
    class Meta:
        db_table = 'competitions'
        verbose_name = 'Competition'
        verbose_name_plural = 'Competitions'
        ordering = ['-created_at', 'title']
        indexes = [
            models.Index(fields=['code'], name='comp_code_idx'),
            models.Index(fields=['competition_type'], name='comp_type_idx'),
            models.Index(fields=['subject'], name='comp_subject_idx'),
            models.Index(fields=['status'], name='comp_status_idx'),
            models.Index(fields=['is_active'], name='comp_active_idx'),
            models.Index(fields=['is_deleted'], name='comp_deleted_idx'),
            models.Index(fields=['created_by'], name='comp_created_by_idx'),
            models.Index(fields=['subject', 'status'], name='comp_subject_status_idx'),
            models.Index(fields=['competition_type', 'status'], name='comp_type_status_idx'),
        ]
    
    def __str__(self):
        return f"{self.title} ({self.code})"
    
    def save(self, *args, **kwargs):
        if not self.code:
            import random
            import string
            while True:
                code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
                if not Competition.objects.filter(code=code).exists():
                    self.code = code
                    break
        super().save(*args, **kwargs)
    
    @property
    def question_count(self):
        return self.questions.count()
    
    @property
    def participant_count(self):
        return self.participants.count()


class CompetitionQuestion(TimeStampUUID):
    
    competition = models.ForeignKey(
        Competition,
        on_delete=models.CASCADE,
        related_name='competition_questions',
        help_text='Competition this question belongs to'
    )
    
    question = models.ForeignKey(
        'subjects.Question',
        on_delete=models.CASCADE,
        related_name='competition_questions',
        help_text='Question in this competition'
    )
    
    order = models.PositiveIntegerField(
        default=1,
        help_text='Order of the question within the competition'
    )
    
    points = models.PositiveIntegerField(
        default=1,
        help_text='Points awarded for this question'
    )
    
    class Meta:
        db_table = 'competition_questions'
        verbose_name = 'Competition Question'
        verbose_name_plural = 'Competition Questions'
        unique_together = ['competition', 'question']
        ordering = ['order']
        indexes = [
            models.Index(fields=['competition'], name='cq_competition_idx'),
            models.Index(fields=['question'], name='cq_question_idx'),
            models.Index(fields=['order'], name='cq_order_idx'),
            models.Index(fields=['competition', 'order'], name='cq_comp_order_idx'),
        ]
    
    def __str__(self):
        return f"{self.competition.title} - Q{self.order}: {self.question.question_text[:50]}..."


class UserMissionProgress(TimeStampUUID):
    """Tracks user progress on a mission."""
    
    STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
    ]
    
    mission = models.OneToOneField(
        Mission,
        on_delete=models.CASCADE,
        related_name='progress',
        help_text='Mission being tracked'
    )
    
    @property
    def user(self):
        return self.mission.account
    
    @property
    def account(self):
        return self.mission.account
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='not_started',
        help_text='Current status on this mission'
    )
    
    percentage = models.PositiveIntegerField(
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text='Completion percentage (0-100)'
    )
    
    score = models.PositiveIntegerField(
        default=0,
        help_text='Score achieved'
    )
    
    total_questions = models.PositiveIntegerField(
        default=0,
        help_text='Total number of questions'
    )
    
    questions_attempted = models.PositiveIntegerField(
        default=0,
        help_text='Number of questions attempted'
    )
    
    correct_answers = models.PositiveIntegerField(
        default=0,
        help_text='Number of correct answers'
    )
    
    wrong_answers = models.PositiveIntegerField(
        default=0,
        help_text='Number of wrong answers'
    )
    
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user started this mission'
    )
    
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user completed this mission'
    )
    
    last_accessed = models.DateTimeField(
        auto_now=True,
        help_text='Last time accessed'
    )
    
    time_spent_seconds = models.PositiveIntegerField(
        default=0,
        help_text='Total time spent in seconds'
    )
    
    exp_earned = models.PositiveIntegerField(
        default=0,
        help_text='Experience points earned'
    )
    
    current_question = models.ForeignKey(
        'subjects.Question',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='mission_progress_current',
        help_text='Current question being worked on'
    )
    
    class Meta:
        db_table = 'user_mission_progress'
        verbose_name = 'User Mission Progress'
        verbose_name_plural = 'User Mission Progress'
        indexes = [
            models.Index(fields=['mission'], name='umip_mission_idx'),
            models.Index(fields=['status'], name='umip_status_idx'),
            models.Index(fields=['percentage'], name='umip_percentage_idx'),
            models.Index(fields=['completed_at'], name='umip_completed_at_idx'),
        ]
    
    def __str__(self):
        return f"{self.mission.account.username} - Mission {self.mission.id} ({self.status})"
    
    def save(self, *args, **kwargs):
        if self.status == 'in_progress' and not self.started_at:
            self.started_at = timezone.now()
        if self.status == 'completed' and not self.completed_at:
            self.completed_at = timezone.now()
        if self.total_questions > 0:
            self.percentage = int((self.questions_attempted / self.total_questions) * 100)
        super().save(*args, **kwargs)
    
    @property
    def accuracy(self):
        if self.questions_attempted > 0:
            return round((self.correct_answers / self.questions_attempted) * 100, 2)
        return 0.0


class UserCompetitionProgress(TimeStampUUID):
    
    STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
    ]
    
    account = models.ForeignKey(
        Account,
        on_delete=models.CASCADE,
        related_name='competition_progress',
        help_text='User participating in this competition'
    )
    
    @property
    def user(self):
        return self.account
    
    competition = models.ForeignKey(
        Competition,
        on_delete=models.CASCADE,
        related_name='user_progress',
        help_text='Competition being participated in'
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='not_started',
        help_text='Current status of the user in this competition'
    )
    
    score = models.PositiveIntegerField(
        default=0,
        help_text='User score in this competition'
    )
    
    time_taken = models.PositiveIntegerField(
        default=0,
        help_text='Time taken in seconds'
    )
    
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user started this competition'
    )
    
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user completed this competition'
    )
    
    exp_earned = models.PositiveIntegerField(
        default=0,
        help_text='Experience points earned from this competition'
    )
    
    current_question = models.ForeignKey(
        'subjects.Question',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='competition_progress_current',
        help_text='Current question the user is working on in this competition'
    )
    
    class Meta:
        db_table = 'user_competition_progress'
        verbose_name = 'User Competition Progress'
        verbose_name_plural = 'User Competition Progress'
        unique_together = ['account', 'competition']
        indexes = [
            models.Index(fields=['account'], name='ucp_account_idx'),
            models.Index(fields=['competition'], name='ucp_competition_idx'),
            models.Index(fields=['status'], name='ucp_status_idx'),
            models.Index(fields=['score'], name='ucp_score_idx'),
            models.Index(fields=['account', 'status'], name='ucp_account_status_idx'),
            models.Index(fields=['competition', 'status'], name='ucp_comp_status_idx'),
            models.Index(fields=['account', 'competition'], name='ucp_account_comp_idx'),
        ]
    
    def __str__(self):
        return f"{self.account.username} - {self.competition.title} ({self.status})"


class Notification(TimeStampUUID):
    """Model for storing user notifications."""
    
    TYPE_CHOICES = [
        ('module', 'Module'),
        ('subject', 'Subject'),
        ('user', 'User'),
        ('mission', 'Mission'),
        ('competition', 'Competition'),
        ('test', 'Test'),
    ]
    
    TRIGGERED_BY_CHOICES = [
        ('auto', 'Auto'),
        ('user', 'User'),
        ('manual', 'Manual'),
    ]
    
    user = models.ForeignKey(
        Account,
        on_delete=models.CASCADE,
        related_name='notifications',
        help_text='User who receives this notification'
    )
    
    notification_id = models.CharField(
        max_length=255,
        help_text='Unique identifier for this notification'
    )
    
    data = models.JSONField(
        default=dict,
        blank=True,
        help_text='Notification data payload (JSON)'
    )
    
    type = models.CharField(
        max_length=20,
        choices=TYPE_CHOICES,
        help_text='Type of notification'
    )
    
    triggered_by = models.CharField(
        max_length=10,
        choices=TRIGGERED_BY_CHOICES,
        default='auto',
        help_text='How this notification was triggered'
    )
    
    is_read = models.BooleanField(
        default=False,
        help_text='Whether the notification has been read by the user'
    )
    
    read_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Timestamp when the notification was read'
    )
    
    class Meta:
        db_table = 'notifications'
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user'], name='notification_user_idx'),
            models.Index(fields=['type'], name='notification_type_idx'),
            models.Index(fields=['triggered_by'], name='notification_triggered_by_idx'),
            models.Index(fields=['is_read'], name='notification_is_read_idx'),
            models.Index(fields=['user', 'is_read'], name='notification_user_read_idx'),
            models.Index(fields=['user', 'type'], name='notification_user_type_idx'),
            models.Index(fields=['notification_id'], name='notification_id_idx'),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.get_type_display()} - {self.notification_id}"
    
    def mark_as_read(self):
        """Mark the notification as read."""
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])
    
    def mark_as_unread(self):
        """Mark the notification as unread."""
        if self.is_read:
            self.is_read = False
            self.read_at = None
            self.save(update_fields=['is_read', 'read_at'])


class UserTestProgress(TimeStampUUID):
    """Tracks user progress on a test."""
    
    STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('abandoned', 'Abandoned'),
    ]
    
    account = models.ForeignKey(
        Account,
        on_delete=models.CASCADE,
        related_name='test_progress',
        help_text='User taking this test'
    )
    
    @property
    def user(self):
        return self.account
    
    test = models.ForeignKey(
        Test,
        on_delete=models.CASCADE,
        related_name='user_progress',
        help_text='Test being tracked'
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='not_started',
        help_text='Current status on this test'
    )
    
    percentage = models.PositiveIntegerField(
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text='Completion percentage (0-100)'
    )
    
    score = models.PositiveIntegerField(
        default=0,
        help_text='Score achieved'
    )
    
    total_questions = models.PositiveIntegerField(
        default=0,
        help_text='Total number of questions'
    )
    
    questions_attempted = models.PositiveIntegerField(
        default=0,
        help_text='Number of questions attempted'
    )
    
    correct_answers = models.PositiveIntegerField(
        default=0,
        help_text='Number of correct answers'
    )
    
    wrong_answers = models.PositiveIntegerField(
        default=0,
        help_text='Number of wrong answers'
    )
    
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user started this test'
    )
    
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the user completed this test'
    )
    
    last_accessed = models.DateTimeField(
        auto_now=True,
        help_text='Last time accessed'
    )
    
    time_spent_seconds = models.PositiveIntegerField(
        default=0,
        help_text='Total time spent in seconds'
    )
    
    exp_earned = models.PositiveIntegerField(
        default=0,
        help_text='Experience points earned'
    )
    
    current_question = models.ForeignKey(
        'subjects.Question',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='test_progress_current',
        help_text='Current question being worked on'
    )
    
    class Meta:
        db_table = 'user_test_progress'
        verbose_name = 'User Test Progress'
        verbose_name_plural = 'User Test Progress'
        unique_together = ['account', 'test']
        indexes = [
            models.Index(fields=['account'], name='utp_account_idx'),
            models.Index(fields=['test'], name='utp_test_idx'),
            models.Index(fields=['status'], name='utp_status_idx'),
            models.Index(fields=['percentage'], name='utp_percentage_idx'),
            models.Index(fields=['score'], name='utp_score_idx'),
            models.Index(fields=['completed_at'], name='utp_completed_at_idx'),
            models.Index(fields=['account', 'test'], name='utp_account_test_idx'),
        ]
    
    def __str__(self):
        return f"{self.account.username} - Test {self.test.id} ({self.status})"
    
    def save(self, *args, **kwargs):
        if self.status == 'in_progress' and not self.started_at:
            self.started_at = timezone.now()
        if self.status == 'completed' and not self.completed_at:
            self.completed_at = timezone.now()
        if self.total_questions > 0:
            self.percentage = int((self.questions_attempted / self.total_questions) * 100)
        super().save(*args, **kwargs)
    
    @property
    def accuracy(self):
        if self.questions_attempted > 0:
            return round((self.correct_answers / self.questions_attempted) * 100, 2)
        return 0.0
    
    @property
    def is_passed(self):
        return self.accuracy >= 60.0
