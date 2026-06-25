from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from django import forms
from .models import Account, UserProfile, Student, TeacherProfile, Level, Class, School, Teacher, Grade, StudentSubjectEnrollment

from .models import (
    Mission, Competition, UserMissionProgress, UserCompetitionProgress,
    MissionQuestion, CompetitionQuestion, UserModuleProgress, UserChapterProgress, Notification,
    Test, TestModuleChapter, TestQuestion, UserTestProgress
)



class StudentInline(admin.TabularInline):
    """Inline admin for managing students in a class."""
    from .models import Student
    model = Student
    fk_name = 'class_instance'
    extra = 0
    fields = ['user_profile', 'admission_number', 'roll_number']
    readonly_fields = ['user_profile']
    can_delete = True
    
    def has_add_permission(self, request, obj=None):
        """Allow adding new students to the class."""
        return True


class ClassInline(admin.TabularInline):
    """Inline admin for managing classes in a grade."""
    model = Class
    fk_name = 'grade'
    extra = 0
    fields = ['name', 'school', 'class_teacher', 'is_active']
    readonly_fields = []
    can_delete = False
    
    def has_add_permission(self, request, obj=None):
        """Allow adding new classes to the grade."""
        return True


@admin.register(Level)
class LevelAdmin(admin.ModelAdmin):
    """Admin interface for Level model."""
    
    list_display = [
        'name', 
        'min_exp', 
        'max_exp',
        'user_count'
    ]
    
    list_filter = [
        'name'
    ]
    
    search_fields = [
        'name'
    ]
    
    ordering = ['name']
    
    fieldsets = (
        ('Level Information', {
            'fields': (
                'name', 
                'min_exp', 
                'max_exp'
            )
        }),
    )
    
    def user_count(self, obj):
        """Display number of students at this level."""
        return obj.students.count()
    user_count.short_description = 'Students'


class AccountCreationForm(forms.ModelForm):
    """Custom form for creating new accounts with optional password."""
    password1 = forms.CharField(
        label='Password',
        widget=forms.PasswordInput,
        required=False,
        help_text='Leave blank to use default password: Test@123'
    )
    password2 = forms.CharField(
        label='Password confirmation',
        widget=forms.PasswordInput,
        required=False,
        help_text='Enter the same password as above, for verification.'
    )

    class Meta:
        model = Account
        fields = ('username', 'email', 'first_name', 'last_name')

    def clean_password2(self):
        password1 = self.cleaned_data.get('password1')
        password2 = self.cleaned_data.get('password2')
        if password1 and password2 and password1 != password2:
            raise forms.ValidationError("Passwords don't match")
        return password2

    def save(self, commit=True):
        user = super().save(commit=False)
        password = self.cleaned_data.get('password1')
        if password:
            user.set_password(password)
        else:
            user.set_password('Test@123')
        if commit:
            user.save()
        return user


@admin.register(Account)
class AccountAdmin(BaseUserAdmin):
    """Admin interface for Account model."""
    
    add_form = AccountCreationForm
    
    list_display = [
        'username', 
        'full_name', 
        'email', 
        'is_active', 
        'date_joined',
        'logged_in_once',
        'fcm_token'
    ]
    
    list_filter = [
        'is_active',
        'is_staff',
        'is_superuser',
        'profile__school',
        'date_joined',
        'created_at',
        'logged_in_once'
    ]
    
    search_fields = [
        'username',
        'first_name',
        'last_name',
        'email'
    ]
    
    ordering = ['-date_joined']
    
    fieldsets = (
        (None, {
            'fields': ('username', 'password')
        }),
        ('Personal Information', {
            'fields': (
                'first_name',
                'last_name',
                'email',
                'fcm_token',
                'logged_in_once'
            )
        }),
        ('User Type & Permissions', {
            'fields': (
                'is_active',
                'is_staff',
                'is_superuser',
                'groups',
                'user_permissions',
            )
        }),
        ('Important Dates', {
            'fields': ('last_login', 'date_joined', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': (
                'username',
                'email',
                'password1',
                'password2',
                'first_name',
                'last_name',
                'fcm_token',
                'is_active',
                'is_staff',
                'is_superuser'
            ),
            'description': 'Leave password fields blank to use default password: Test@123'
        }),
    )
    
    readonly_fields = [
        'last_login',
        'date_joined',
        'created_at',
        'updated_at',
    ]
    
    def full_name(self, obj):
        """Return the user's full name."""
        return obj.full_name
    full_name.short_description = 'Full Name'
    
    def get_queryset(self, request):
        """Optimize queryset for admin."""
        return super().get_queryset(request).select_related('profile')


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    """Admin interface for UserProfile model."""
    
    list_display = [
        'account',
        'school',
        'user_type', 
        'get_admission_number',
        'get_roll_number', 
        'get_class_instance',
        'total_exp',
        'rewards',   
        'level',
    ]
    
    list_filter = [
        'user_type',
        'student__class_instance',
        'school',
        'created_at',
    ]
    
    search_fields = [
        'account__username',
        'account__first_name',
        'account__last_name',
        'account__email',
        'student__admission_number',
        'student__roll_number',
    ]
    
    ordering = ['-created_at']
    
    fieldsets = (
        ('Account', {
            'fields': ('account',)
        }),
        ('Academic Information', {
            'fields': (
                'school',
                'user_type',
            )
        }),
        ('Personal Information', {
            'fields': (
                'phone_number',
                'date_of_birth',
                'profile_picture',
                'bio',
            )
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def get_queryset(self, request):
        """Optimize queryset for admin."""
        return super().get_queryset(request).select_related('account', 'school', 'student__level', 'student__class_instance')
    
    def get_admission_number(self, obj):
        """Get admission number from student if user is a student."""
        if obj.user_type == 'student' and hasattr(obj, 'student'):
            return obj.student.admission_number
        return None
    get_admission_number.short_description = 'Admission Number'
    
    def get_roll_number(self, obj):
        """Get roll number from student if user is a student."""
        if obj.user_type == 'student' and hasattr(obj, 'student'):
            return obj.student.roll_number
        return None
    get_roll_number.short_description = 'Roll Number'
    
    def get_class_instance(self, obj):
        """Get class instance from student if user is a student."""
        if obj.user_type == 'student' and hasattr(obj, 'student'):
            return obj.student.class_instance
        return None
    get_class_instance.short_description = 'Class'


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    """Admin interface for Student model."""
    
    list_display = [
        'user_profile',
        'admission_number',
        'roll_number',
        'class_instance',
        'parent_name',
        'total_exp',
        'rewards',
        'level',
        'created_at'
    ]
    
    list_filter = [
        'user_profile__school',
        'class_instance',
        'level',
        'created_at',
        'is_deleted'
    ]

    search_fields = [
        'user_profile__account__username',
        'user_profile__account__first_name',
        'user_profile__account__last_name',
        'user_profile__account__email',
        'admission_number',
        'roll_number',
        'parent_name'
    ]
    
    ordering = ['-created_at']

    fieldsets = (
        ('User Profile', {
            'fields': ('user_profile',)
        }),
        ('Academic Information', {
            'fields': (
                'admission_number',
                'roll_number',
                'class_instance',
                'parent_name',
            )
        }),
        ('Game Data', {
            'fields': (
                'total_exp',
                'rewards',
                'level',
            )
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def get_queryset(self, request):
        """Optimize queryset for admin."""
        return super().get_queryset(request).select_related(
            'user_profile',
            'user_profile__account',
            'user_profile__school',
            'class_instance',
            'level'
        )


@admin.register(TeacherProfile)
class TeacherProfileAdmin(admin.ModelAdmin):
    """Admin interface for TeacherProfile model."""
    
    list_display = [
        'user_profile',
        'employee_id',
        'is_class_teacher',
        'get_school',
        'get_assignment_count',
        'get_classes_taught_count',
        'created_at'
    ]
    
    list_filter = [
        'is_class_teacher',
        'user_profile__school',
        'created_at',
        'is_deleted'
    ]
    
    search_fields = [
        'user_profile__account__username',
        'user_profile__account__first_name',
        'user_profile__account__last_name',
        'user_profile__account__email',
        'employee_id'
    ]
    
    ordering = ['-created_at']

    fieldsets = (
        ('User Profile', {
            'fields': ('user_profile',)
        }),
        ('Teacher Information', {
            'fields': (
                'employee_id',
                'is_class_teacher',
            )
        }),
        ('Assignments', {
            'fields': ('get_assignments_list',),
            'classes': ('collapse',),
            'description': 'Classes and subjects this teacher is assigned to'
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at', 'get_assignments_list']
    
    def get_queryset(self, request):
        """Optimize queryset for admin."""
        return super().get_queryset(request).select_related(
            'user_profile',
            'user_profile__account',
            'user_profile__school'
        ).prefetch_related('teacher_assignments', 'teacher_assignments__class_instance', 'teacher_assignments__subject', 'classes_taught')
    
    def get_school(self, obj):
        """Get school from user profile."""
        return obj.user_profile.school if obj.user_profile else None
    get_school.short_description = 'School'
    
    def get_assignment_count(self, obj):
        """Get number of teacher assignments."""
        return obj.teacher_assignments.count()
    get_assignment_count.short_description = 'Assignments'
    
    def get_classes_taught_count(self, obj):
        """Get number of classes taught."""
        return obj.classes_taught.count()
    get_classes_taught_count.short_description = 'Classes Taught'
    
    def get_assignments_list(self, obj):
        """Display list of teacher assignments."""
        assignments = obj.teacher_assignments.all()
        if assignments:
            return format_html('<br>'.join([
                f"• {assignment.class_instance.name} - {assignment.subject.name} ({'Class Teacher' if assignment.class_instance.class_teacher == assignment.teacher else 'Subject Teacher'})" 
                for assignment in assignments
            ]))
        return "No assignments"
    get_assignments_list.short_description = 'Teacher Assignments'


@admin.register(Class)
class ClassAdmin(admin.ModelAdmin):
    """Admin interface for Class model."""
    
    inlines = [StudentInline]
    
    list_display = [
        'name', 
        'school',
        'grade',
        'class_teacher',
        'description',
        'enrolled_students_count',
        'is_active',
        'created_at'
    ]
    
    list_filter = [
        'is_active', 
        'created_at',
        'school',
        'grade',
        'class_teacher',
        ('enrolled_students', admin.EmptyFieldListFilter),
    ]
    
    search_fields = [
        'name', 
        'description',
        'class_teacher__user_profile__account__username',
        'class_teacher__user_profile__account__first_name',
        'class_teacher__user_profile__account__last_name',
    ]
    
    ordering = ['name']
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'name',
                'school',
                'grade',
                'description'
            )
        }),
        ('Teacher Assignment', {
            'fields': ('class_teacher',)
        }),
        ('Subjects', {
            'fields': ('subjects',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    readonly_fields = ['created_at', 'updated_at']
    filter_horizontal = ['subjects']

    def get_queryset(self, request):
        """Optimize queryset for admin."""
        return super().get_queryset(request).select_related('school', 'grade', 'class_teacher', 'class_teacher__user_profile', 'class_teacher__user_profile__account').prefetch_related('enrolled_students', 'subjects')
    
    def enrolled_students_count(self, obj):
        """Display number of students enrolled in this class."""
        return obj.enrolled_students.count()
    enrolled_students_count.short_description = 'Enrolled Students'
    
    def enrolled_students_list(self, obj):
        """Display list of enrolled students."""
        students = obj.enrolled_students.all()
        if students:
            return format_html('<br>'.join([
                f"• {student.user_profile.account.username} ({student.user_profile.full_name})" 
                for student in students
            ]))
        return "No students enrolled"
    enrolled_students_list.short_description = 'Enrolled Students'
    


@admin.register(Teacher)
class TeacherAdmin(admin.ModelAdmin):
    """Admin interface for Teacher model."""
    
    list_display = [
        'teacher',
        'class_instance',
        'subject',
        'is_class_teacher_display',
        'created_at'
    ]
    
    list_filter = [
        'class_instance__school',
        'class_instance__class_teacher',
        'class_instance',
        'subject',
        'created_at'
    ]

    search_fields = [
        'teacher__account__username',
        'teacher__account__first_name',
        'teacher__account__last_name',
        'class_instance__name',
        'subject__name'
    ]
    
    ordering = ['teacher', 'class_instance', 'subject']
    
    fieldsets = (
        ('Teacher Assignment', {
            'fields': (
                'teacher',
                'class_instance',
                'subject',
            )
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def is_class_teacher_display(self, obj):
        """Display whether this teacher is the class teacher for the class."""
        if obj.class_instance and obj.class_instance.class_teacher:
            return obj.class_instance.class_teacher == obj.teacher
        return False
    is_class_teacher_display.boolean = True
    is_class_teacher_display.short_description = 'Is Class Teacher'
    
    def get_queryset(self, request):
        """Optimize queryset for admin."""
        return super().get_queryset(request).select_related('teacher', 'teacher__user_profile', 'teacher__user_profile__account', 'class_instance', 'class_instance__class_teacher', 'subject')


@admin.register(School)
class SchoolAdmin(admin.ModelAdmin):
    """Admin interface for School model."""
    
    list_display = [
        'name', 
        'phone', 
        'email',
        'is_active',
        'created_at'
    ]
    
    list_filter = [
        'is_active', 
        'created_at'
    ]
    
    search_fields = [
        'name', 
        'address',
        'phone',
        'email'
    ]
    
    ordering = ['name']
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'name',
                'address',
                'phone',
                'email',
                'website',
                'password_prefix'
            )
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']


@admin.register(Grade)
class GradeAdmin(admin.ModelAdmin):
    """Admin interface for Grade model."""
    
    inlines = [ClassInline]
    
    list_display = [
        'name',
        'school',
        'class_count',
        'classes_list',
        'description',
        'is_active',
        'created_at'
    ]
    
    list_filter = [
        'school',
        'is_active',
        'created_at'
    ]
    
    search_fields = [
        'name',
        'description',
        'school__name'
    ]
    
    ordering = ['school', 'name']
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'name',
                'school',
                'description'
            )
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def get_queryset(self, request):
        """Optimize queryset for admin."""
        return super().get_queryset(request).select_related('school').prefetch_related('classes')
    
    def class_count(self, obj):
        """Display number of classes in this grade."""
        return obj.class_count
    class_count.short_description = 'Classes Count'
    
    def classes_list(self, obj):
        """Display list of classes in this grade."""
        classes = obj.classes.filter(is_active=True)
        if classes:
            return format_html('<br>'.join([
                f"• {cls.name} ({cls.school.name})" 
                for cls in classes[:10]
            ]) + (f'<br><em>... and {classes.count() - 10} more</em>' if classes.count() > 10 else ''))
        return "No classes"
    classes_list.short_description = 'Classes'


@admin.register(UserModuleProgress)
class UserModuleProgressAdmin(admin.ModelAdmin):
    """Admin interface for UserModuleProgress model."""
    list_display = ['user', 'module', 'status', 'percentage', 'module_remaining', 'current_question_preview', 'started_at', 'completed_at', 'last_accessed']
    list_filter = ['account__profile__school', 'status', 'percentage', 'started_at', 'completed_at', 'last_accessed']
    search_fields = ['account__username', 'account__email', 'module__name', 'module__subject__name', 'current_question__question_text']
    readonly_fields = ['last_accessed', 'current_question_preview', 'module_remaining']
    date_hierarchy = 'last_accessed'
    
    fieldsets = (
        ('User & Module', {
            'fields': ('account', 'module')
        }),
        ('Progress', {
            'fields': ('status', 'percentage', 'module_remaining', 'current_question')
        }),
        ('Current Question Details', {
            'fields': ('current_question_preview',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('started_at', 'completed_at', 'last_accessed'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('account', 'module', 'module__subject', 'current_question')
    
    def module_remaining(self, obj):
        """Remaining percentage of the module (100 - percentage)."""
        return 100 - obj.percentage
    module_remaining.short_description = 'Remaining %'
    
    def current_question_preview(self, obj):
        """Display current question preview."""
        if obj.current_question:
            question_text = obj.current_question.question_text
            preview = question_text[:100] + '...' if len(question_text) > 100 else question_text
            return format_html(
                '<strong>Question:</strong> {}<br><strong>Type:</strong> {}<br><strong>Difficulty:</strong> {}',
                preview,
                obj.current_question.get_question_type_display(),
                obj.current_question.get_difficulty_level_display()
            )
        return "No current question"
    current_question_preview.short_description = 'Current Question'


@admin.register(UserChapterProgress)
class UserChapterProgressAdmin(admin.ModelAdmin):
    """Admin interface for UserChapterProgress model."""
    list_display = ['user', 'chapter', 'status', 'percentage', 'current_question_preview', 'started_at', 'completed_at', 'last_accessed']
    list_filter = ['account__profile__school', 'status', 'percentage', 'started_at', 'completed_at', 'last_accessed']
    search_fields = ['account__username', 'account__email', 'chapter__title', 'chapter__module__name', 'current_question__question_text']
    readonly_fields = ['last_accessed', 'current_question_preview']
    date_hierarchy = 'last_accessed'
    
    fieldsets = (
        ('User & Chapter', {
            'fields': ('account', 'chapter')
        }),
        ('Progress', {
            'fields': ('status', 'percentage', 'current_question')
        }),
        ('Current Question Details', {
            'fields': ('current_question_preview',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('started_at', 'completed_at', 'last_accessed'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('account', 'chapter', 'chapter__module', 'current_question')
    
    def current_question_preview(self, obj):
        """Display current question preview."""
        if obj.current_question:
            question_text = obj.current_question.question_text
            preview = question_text[:100] + '...' if len(question_text) > 100 else question_text
            return format_html(
                '<strong>Question:</strong> {}<br><strong>Type:</strong> {}<br><strong>Difficulty:</strong> {}',
                preview,
                obj.current_question.get_question_type_display(),
                obj.current_question.get_difficulty_level_display()
            )
        return "No current question"
    current_question_preview.short_description = 'Current Question'


@admin.register(UserMissionProgress)
class UserMissionProgressAdmin(admin.ModelAdmin):
    """Admin configuration for UserMissionProgress model."""
    
    list_display = [
        'id', 'get_user', 'get_mission_date', 'get_subject', 'status', 
        'percentage', 'score', 'get_accuracy', 'exp_earned', 'started_at', 'completed_at'
    ]
    list_filter = ['mission__account__profile__school', 'status', 'started_at', 'completed_at', 'mission__subject']
    search_fields = [
        'mission__account__username', 'mission__account__first_name', 
        'mission__subject__name'
    ]
    readonly_fields = ['started_at', 'completed_at', 'last_accessed', 'percentage']
    ordering = ['-last_accessed']
    
    fieldsets = (
        ('Mission Information', {
            'fields': ('mission',)
        }),
        ('Progress Status', {
            'fields': ('status', 'percentage', 'current_question')
        }),
        ('Score & Answers', {
            'fields': ('score', 'total_questions', 'questions_attempted', 'correct_answers', 'wrong_answers')
        }),
        ('Time & Rewards', {
            'fields': ('time_spent_seconds', 'exp_earned')
        }),
        ('Timestamps', {
            'fields': ('started_at', 'completed_at', 'last_accessed'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'mission', 'mission__account', 'mission__subject', 'current_question'
        )
    
    def get_user(self, obj):
        return obj.mission.account.username
    get_user.short_description = 'User'
    
    def get_mission_date(self, obj):
        return obj.mission.mission_date
    get_mission_date.short_description = 'Mission Date'
    
    def get_subject(self, obj):
        return obj.mission.subject.name if obj.mission.subject else '-'
    get_subject.short_description = 'Subject'
    
    def get_accuracy(self, obj):
        return f"{obj.accuracy}%"
    get_accuracy.short_description = 'Accuracy'


@admin.register(Mission)
class MissionAdmin(admin.ModelAdmin):
    """Admin configuration for Mission model."""
    
    list_display = [
        'id', 'get_user', 'mission_date', 'subject',
        'question_count', 'get_progress_status', 'created_at'
    ]
    list_filter = ['account__profile__school', 'mission_date', 'subject', 'is_deleted']
    search_fields = [
        'id', 'account__username', 'account__first_name', 
        'subject__name'
    ]
    readonly_fields = ['question_count', 'created_at', 'updated_at']
    ordering = ['-mission_date', '-created_at']
    
    fieldsets = (
        ('Mission Assignment', {
            'fields': ('account', 'mission_date')
        }),
        ('Content', {
            'fields': ('subject',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'account', 'subject'
        ).prefetch_related('progress')
    
    def get_user(self, obj):
        return obj.account.username
    get_user.short_description = 'User'
    
    def get_progress_status(self, obj):
        if hasattr(obj, 'progress'):
            return obj.progress.status
        return 'No progress'
    get_progress_status.short_description = 'Progress'


@admin.register(MissionQuestion)
class MissionQuestionAdmin(admin.ModelAdmin):
    """Admin configuration for MissionQuestion model."""
    
    list_display = ['id', 'mission', 'question', 'chapter', 'order', 'is_question_active']
    list_filter = ['mission__account__profile__school', 'mission__subject', 'chapter', 'order']
    search_fields = ['mission__id', 'question__question_text', 'chapter__title']
    ordering = ['mission', 'order']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('mission', 'question', 'chapter')
    
    def is_question_active(self, obj):
        return obj.question.is_active if obj.question else False
    is_question_active.boolean = True
    is_question_active.short_description = 'Question Active'


class TestModuleChapterInline(admin.TabularInline):
    """Inline for Test's module/chapter selections."""
    model = TestModuleChapter
    extra = 0
    autocomplete_fields = ['module', 'module_chapter']
    ordering = ['module', 'module_chapter']


@admin.register(Test)
class TestAdmin(admin.ModelAdmin):
    """Admin configuration for Test model (supports multiple modules/chapters)."""
    
    list_display = [
        'id', 'class_group', 'test_datetime', 'duration', 'subject',
        'module_chapters_summary', 'question_count', 'created_by', 'created_at'
    ]
    list_filter = ['class_group__school', 'test_datetime', 'class_group', 'subject', 'is_deleted', 'created_by']
    search_fields = [
        'id', 'class_group__name', 'subject__name', 'created_by__username'
    ]
    readonly_fields = ['question_count', 'created_at', 'updated_at', 'created_by']
    ordering = ['-test_datetime', '-created_at']
    inlines = [TestModuleChapterInline]
    
    fieldsets = (
        ('Test Schedule', {
            'fields': ('test_datetime', 'duration', 'class_group')
        }),
        ('Content', {
            'fields': ('subject',)
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'class_group', 'subject', 'created_by'
        ).prefetch_related('module_chapters__module', 'module_chapters__module_chapter')
    
    def module_chapters_summary(self, obj):
        tmc = obj.module_chapters.select_related('module', 'module_chapter').order_by('module', 'module_chapter')[:3]
        parts = [f"{m.module.name}: {m.module_chapter.title}" for m in tmc]
        return "; ".join(parts) + ("..." if obj.module_chapters.count() > 3 else "")
    module_chapters_summary.short_description = 'Modules & Chapters'


@admin.register(TestQuestion)
class TestQuestionAdmin(admin.ModelAdmin):
    """Admin configuration for TestQuestion model."""
    
    list_display = ['id', 'test', 'question', 'order', 'is_question_active']
    list_filter = ['test__class_group__school', 'test__subject', 'order']
    search_fields = ['test__id', 'question__question_text']
    ordering = ['test', 'order']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('test', 'question')
    
    def is_question_active(self, obj):
        return obj.question.is_active if obj.question else False
    is_question_active.boolean = True
    is_question_active.short_description = 'Question Active'


@admin.register(Competition)
class CompetitionAdmin(admin.ModelAdmin):
    """Admin configuration for Competition model."""
    
    list_display = ['title', 'code', 'competition_type', 'subject', 'status', 'is_active', 'created_by', 'question_count', 'participant_count']
    list_filter = ['created_by__profile__school', 'competition_type', 'status', 'is_active', 'subject', 'created_by']
    search_fields = ['title', 'description', 'code']
    readonly_fields = ['code', 'question_count', 'participant_count']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'description', 'code')
        }),
        ('Competition Settings', {
            'fields': ('competition_type', 'subject', 'chapter', 'total_time')
        }),
        ('Status', {
            'fields': ('status', 'is_active', 'created_by')
        }),
    )


@admin.register(CompetitionQuestion)
class CompetitionQuestionAdmin(admin.ModelAdmin):
    """Admin configuration for CompetitionQuestion model."""
    
    list_display = ['competition', 'question', 'order', 'points']
    list_filter = ['competition__created_by__profile__school', 'competition', 'order', 'points']
    search_fields = ['competition__title', 'question__question_text']
    ordering = ['competition', 'order']


@admin.register(UserCompetitionProgress)
class UserCompetitionProgressAdmin(admin.ModelAdmin):
    """Admin configuration for UserCompetitionProgress model."""
    
    list_display = ['user', 'competition', 'status', 'score', 'time_taken', 'exp_earned', 'current_question_preview', 'started_at', 'completed_at']
    list_filter = ['account__profile__school', 'status', 'started_at', 'completed_at']
    search_fields = ['account__username', 'account__first_name', 'account__last_name', 'competition__title', 'current_question__question_text']
    readonly_fields = ['started_at', 'completed_at', 'exp_earned', 'current_question_preview']
    
    fieldsets = (
        ('User Information', {
            'fields': ('account', 'competition')
        }),
        ('Progress Status', {
            'fields': ('status', 'started_at', 'completed_at', 'current_question')
        }),
        ('Current Question Details', {
            'fields': ('current_question_preview',),
            'classes': ('collapse',)
        }),
        ('Results', {
            'fields': ('score', 'time_taken', 'exp_earned')
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('account', 'competition', 'current_question')
    
    def current_question_preview(self, obj):
        """Display current question preview."""
        if obj.current_question:
            question_text = obj.current_question.question_text
            preview = question_text[:100] + '...' if len(question_text) > 100 else question_text
            return format_html(
                '<strong>Question:</strong> {}<br><strong>Type:</strong> {}<br><strong>Difficulty:</strong> {}',
                preview,
                obj.current_question.get_question_type_display(),
                obj.current_question.get_difficulty_level_display()
            )
        return "No current question"
    current_question_preview.short_description = 'Current Question'


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """Admin interface for Notification model."""
    
    list_display = [
        'id',
        'user',
        'notification_id',
        'type',
        'triggered_by',
        'is_read',
        'read_at',
        'created_at'
    ]
    
    list_filter = [
        'user__profile__school',
        'type',
        'triggered_by',
        'is_read',
        'created_at',
        'read_at'
    ]

    search_fields = [
        'id',
        'user__username',
        'user__email',
        'notification_id',
        'data'
    ]
    
    ordering = ['-created_at']
    
    fieldsets = (
        ('Notification Information', {
            'fields': (
                'user',
                'notification_id',
                'type',
                'triggered_by'
            )
        }),
        ('Notification Data', {
            'fields': ('data',)
        }),
        ('Read Status', {
            'fields': (
                'is_read',
                'read_at'
            )
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at', 'read_at']
    
    actions = ['mark_as_read', 'mark_as_unread']
    
    def mark_as_read(self, request, queryset):
        """Mark selected notifications as read."""
        from django.utils import timezone
        updated = queryset.update(is_read=True, read_at=timezone.now())
        self.message_user(request, f'{updated} notifications were marked as read.')
    mark_as_read.short_description = "Mark selected notifications as read"
    
    def mark_as_unread(self, request, queryset):
        """Mark selected notifications as unread."""
        updated = queryset.update(is_read=False, read_at=None)
        self.message_user(request, f'{updated} notifications were marked as unread.')
    mark_as_unread.short_description = "Mark selected notifications as unread"
    
    def get_queryset(self, request):
        """Optimize queryset with select_related."""
        return super().get_queryset(request).select_related('user')


@admin.register(UserTestProgress)
class UserTestProgressAdmin(admin.ModelAdmin):
    """Admin interface for UserTestProgress model."""
    
    list_display = [
        'id', 'get_user', 'get_test_info', 'status', 'percentage', 'score',
        'get_accuracy', 'questions_attempted', 'correct_answers', 'wrong_answers',
        'exp_earned', 'started_at', 'completed_at'
    ]
    
    list_filter = ['test__class_group__school', 'status', 'started_at', 'completed_at', 'test__class_group', 'test__subject']
    
    search_fields = [
        'account__username', 'account__first_name', 'account__last_name',
        'test__class_group__name', 'test__subject__name'
    ]
    
    ordering = ['-last_accessed']
    
    fieldsets = (
        ('Test Information', {
            'fields': ('account', 'test')
        }),
        ('Progress Status', {
            'fields': ('status', 'percentage', 'current_question')
        }),
        ('Score & Answers', {
            'fields': ('score', 'total_questions', 'questions_attempted', 'correct_answers', 'wrong_answers')
        }),
        ('Time & Rewards', {
            'fields': ('time_spent_seconds', 'exp_earned')
        }),
        ('Timestamps', {
            'fields': ('started_at', 'completed_at', 'last_accessed'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['last_accessed', 'started_at', 'completed_at', 'percentage']
    
    def get_user(self, obj):
        return obj.account.username
    get_user.short_description = 'User'
    
    def get_test_info(self, obj):
        return f"{obj.test.class_group.name} - {obj.test.subject.name}"
    get_test_info.short_description = 'Test'
    
    def get_accuracy(self, obj):
        return f"{obj.accuracy}%"
    get_accuracy.short_description = 'Accuracy'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'account', 'test', 'test__class_group', 'test__subject', 'current_question'
        )


@admin.register(StudentSubjectEnrollment)
class StudentSubjectEnrollmentAdmin(admin.ModelAdmin):
    """Admin interface for StudentSubjectEnrollment model."""

    list_display = [
        'id',
        'student',
        'subject',
        'is_active',
        'enrolled_by',
        'created_at',
        'updated_at',
    ]

    list_filter = [
        'is_active',
        'subject',
        'student__user_profile__school',
        'created_at',
    ]

    search_fields = [
        'student__user_profile__account__username',
        'student__user_profile__account__first_name',
        'student__user_profile__account__last_name',
        'student__admission_number',
        'subject__name',
        'subject__code',
    ]

    ordering = ['student', 'subject']

    raw_id_fields = ['student', 'subject', 'enrolled_by']

    fieldsets = (
        ('Enrollment', {
            'fields': ('student', 'subject', 'is_active')
        }),
        ('Audit', {
            'fields': ('enrolled_by',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    readonly_fields = ['created_at', 'updated_at']

    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'student', 'student__user_profile', 'student__user_profile__account',
            'student__user_profile__school', 'subject', 'enrolled_by'
        )


@admin.register(TestModuleChapter)
class TestModuleChapterAdmin(admin.ModelAdmin):
    """Admin interface for TestModuleChapter model."""

    list_display = [
        'id',
        'test',
        'module',
        'module_chapter',
        'created_at',
    ]

    list_filter = [
        'test__class_group__school',
        'module__subject',
        'module',
        'created_at',
    ]

    search_fields = [
        'test__id',
        'module__name',
        'module_chapter__title',
        'test__class_group__name',
    ]

    ordering = ['test', 'module', 'module_chapter']

    raw_id_fields = ['test', 'module', 'module_chapter']

    fieldsets = (
        ('Test Content', {
            'fields': ('test', 'module', 'module_chapter')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    readonly_fields = ['created_at', 'updated_at']

    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'test', 'test__class_group', 'module', 'module__subject', 'module_chapter'
        )
