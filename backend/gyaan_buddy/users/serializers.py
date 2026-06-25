import logging
import re
from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.utils import timezone
from datetime import datetime, timedelta, timezone as dt_utc
from zoneinfo import ZoneInfo

INDIAN_TZ = ZoneInfo('Asia/Kolkata')
import secrets
import string
from django.db.models import Count, Case, When, IntegerField
from .models import Account, UserProfile, Student, TeacherProfile, Class, School, Grade, Mission, Competition, UserMissionProgress, UserCompetitionProgress, UserModuleProgress, UserChapterProgress, Teacher, Test, TestModuleChapter, TestQuestion, UserTestProgress
from gyaan_buddy.subjects.models import Subject, ModuleChapter, Module, Question, Answer

logger = logging.getLogger(__name__)
User = Account


class UserSerializer(serializers.ModelSerializer):
    user_type = serializers.CharField(source='profile.user_type', read_only=True)
    school = serializers.UUIDField(source='profile.school.id', read_only=True)
    school_name = serializers.CharField(source='profile.school.name', read_only=True)
    admission_number = serializers.SerializerMethodField()
    roll_number = serializers.SerializerMethodField()
    total_exp = serializers.SerializerMethodField()
    rewards = serializers.SerializerMethodField()
    level = serializers.SerializerMethodField()
    level_name = serializers.SerializerMethodField()
    class_instance = serializers.SerializerMethodField()
    class_id = serializers.SerializerMethodField()
    class_name = serializers.SerializerMethodField()
    grade_id = serializers.SerializerMethodField()
    grade_name = serializers.SerializerMethodField()
    parent_name = serializers.SerializerMethodField()
    phone_number = serializers.CharField(source='profile.phone_number', allow_null=True, read_only=True)
    date_of_birth = serializers.DateField(source='profile.date_of_birth', allow_null=True, read_only=True)
    gender = serializers.CharField(source='profile.gender', allow_null=True, read_only=True)
    profile_picture = serializers.ImageField(source='profile.profile_picture', allow_null=True, read_only=True)
    bio = serializers.CharField(source='profile.bio', read_only=True)
    is_class_teacher = serializers.SerializerMethodField()
    employee_id = serializers.SerializerMethodField()
    subjects = serializers.SerializerMethodField()
    subject_ids = serializers.SerializerMethodField()
    teacher_assignments = serializers.SerializerMethodField()
    content_created = serializers.SerializerMethodField()
    weakTopics = serializers.SerializerMethodField()
    average_score = serializers.SerializerMethodField()
    attendance = serializers.SerializerMethodField()
    
    def get_weakTopics(self, obj):
        """Chapters where (incorrect / total questions for that chapter) * 100 > 50."""
        if not hasattr(obj, 'profile') or not getattr(obj.profile, 'user_type', None) == 'student':
            return []
        try:
            # Per-chapter: total answers and incorrect count for this user
            stats = (
                Answer.objects.filter(user=obj)
                .filter(question__module_contents__content_type='question')
                .values('question__module_contents__chapter')
                .annotate(
                    total=Count('id'),
                    incorrect=Count(Case(When(is_correct=False, then=1), output_field=IntegerField())),
                )
            )
            weak = []
            for row in stats:
                total = row['total'] or 0
                incorrect = row['incorrect'] or 0
                if total > 0 and (incorrect / total) * 100 > 50:
                    chapter_id = row.get('question__module_contents__chapter')
                    if chapter_id:
                        ch = ModuleChapter.objects.filter(id=chapter_id).values_list('title', flat=True).first()
                        if ch and ch not in weak:
                            weak.append(ch)
            return weak
        except Exception:
            return []

    def get_average_score(self, obj):
        """Correct answers / total answers * 100 for students; 0 for others."""
        if not hasattr(obj, 'profile') or getattr(obj.profile, 'user_type', None) != 'student':
            return 0
        try:
            total = Answer.objects.filter(user=obj).count()
            if total == 0:
                total_exp = obj.profile.student.total_exp if hasattr(obj.profile, 'student') else 0
                return min(100, round(total_exp / 10)) if total_exp else 0
            correct = Answer.objects.filter(user=obj, is_correct=True).count()
            return round((correct / total) * 100)
        except Exception:
            return 0

    def get_attendance(self, obj):
        """Active days in last 30 days / 30 * 100, based on Answer activity."""
        if not hasattr(obj, 'profile') or getattr(obj.profile, 'user_type', None) != 'student':
            return 0
        try:
            thirty_days_ago = timezone.now() - timedelta(days=30)
            active_days = (
                Answer.objects.filter(user=obj, created_at__gte=thirty_days_ago)
                .dates('created_at', 'day')
                .count()
            )
            return round((active_days / 30) * 100)
        except Exception:
            return 0

    def get_admission_number(self, obj):
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'student'):
            return obj.profile.student.admission_number
        return None
    
    def get_roll_number(self, obj):
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'student'):
            return obj.profile.student.roll_number
        return None
    
    def get_total_exp(self, obj):
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'student'):
            return obj.profile.student.total_exp
        return 0
    
    def get_rewards(self, obj):
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'student'):
            return obj.profile.student.rewards
        return 0
    
    def get_level(self, obj):
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'student') and obj.profile.student.level:
            return obj.profile.student.level.id
        return None
    
    def get_level_name(self, obj):
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'student') and obj.profile.student.level:
            return obj.profile.student.level.name
        return None
    
    def get_parent_name(self, obj):
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'student'):
            return obj.profile.student.parent_name
        return None
    
    def get_is_class_teacher(self, obj):
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'teacher_profile'):
            return obj.profile.teacher_profile.is_class_teacher
        return False
    
    def get_employee_id(self, obj):
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'teacher_profile'):
            return obj.profile.teacher_profile.employee_id
        return None
    
    def _get_class_instance(self, obj):
        """Get the class instance object for the user (student or teacher)"""
        if not hasattr(obj, 'profile'):
            return None
        
        if obj.profile.user_type == 'teacher':
            if hasattr(obj.profile, 'teacher_profile'):
                class_instance = Class.objects.filter(
                    class_teacher=obj.profile.teacher_profile
                ).select_related('grade').first()
                
                if class_instance:
                    return class_instance
            return None
        else:
            if hasattr(obj.profile, 'student') and obj.profile.student.class_instance:
                return obj.profile.student.class_instance
            return None
    
    def _get_class_data(self, obj):
        class_instance = self._get_class_instance(obj)
        if class_instance:
            return {
                'id': str(class_instance.id),
                'name': class_instance.name
            }
        return {'id': None, 'name': None}
    
    def _get_grade_data(self, obj):
        class_instance = self._get_class_instance(obj)
        if class_instance and class_instance.grade:
            return {
                'id': str(class_instance.grade.id),
                'name': class_instance.grade.name
            }
        return {'id': None, 'name': None}
    
    def get_class_instance(self, obj):
        return self._get_class_data(obj)['id']
    
    def get_class_id(self, obj):
        return self._get_class_data(obj)['id']
    
    def get_class_name(self, obj):
        return self._get_class_data(obj)['name']
    
    def get_grade_id(self, obj):
        return self._get_grade_data(obj)['id']
    
    def get_grade_name(self, obj):
        return self._get_grade_data(obj)['name']
    
    def get_subjects(self, obj):
        if hasattr(obj, 'profile'):
            if obj.profile.user_type == 'student' and hasattr(obj.profile, 'student'):
                student = obj.profile.student
                student_subjects = student.subjects.filter(is_active=True) if hasattr(student, 'subjects') else []
                if student_subjects:
                    return [{'id': str(s.id), 'name': s.name, 'code': getattr(s, 'code', '')} for s in student_subjects]
                if student.class_instance:
                    subjects = student.class_instance.subjects.filter(is_active=True)
                    return [{'id': str(s.id), 'name': s.name, 'code': getattr(s, 'code', '')} for s in subjects]
                return []
            if obj.profile.user_type == 'teacher' and hasattr(obj.profile, 'teacher_profile'):
                tpr = obj.profile.teacher_profile
                subjects_dict = {}
                for assignment in tpr.teacher_assignments.filter(is_deleted=False).select_related('subject'):
                    subject_id = str(assignment.subject.id)
                    if subject_id not in subjects_dict:
                        subjects_dict[subject_id] = {
                            'id': subject_id,
                            'name': assignment.subject.name,
                            'code': getattr(assignment.subject, 'code', ''),
                        }
                return list(subjects_dict.values())
        return []
    
    def get_subject_ids(self, obj):
        """Return list of subject IDs for teachers (especially class teachers)"""
        if hasattr(obj, 'profile') and obj.profile.user_type == 'teacher' and hasattr(obj.profile, 'teacher_profile'):
            tpr = obj.profile.teacher_profile
            if hasattr(tpr, 'subjects') and tpr.subjects.exists():
                return [str(s.id) for s in tpr.subjects.filter(is_active=True)]
            teacher_assignments = tpr.teacher_assignments.all()
            subject_ids = set()
            for assignment in teacher_assignments:
                subject_ids.add(str(assignment.subject.id))
            return list(subject_ids)
        elif hasattr(obj, 'profile') and hasattr(obj.profile, 'student'):
            student = obj.profile.student
            if hasattr(student, 'subjects') and student.subjects.exists():
                return [str(s.id) for s in student.subjects.filter(is_active=True)]
            if student.class_instance:
                subjects = student.class_instance.subjects.filter(is_active=True)
                return [str(s.id) for s in subjects]
            return []
        return []
    
    def get_teacher_assignments(self, obj):
        if hasattr(obj, 'profile') and obj.profile.user_type == 'teacher' and hasattr(obj.profile, 'teacher_profile'):
            teacher_assignments = obj.profile.teacher_profile.teacher_assignments.all()
            
            return [
                {
                    'class': {
                        'id': str(assignment.class_instance.id),
                        'name': assignment.class_instance.name
                    },
                    'subject': {
                        'id': str(assignment.subject.id),
                        'name': assignment.subject.name,
                        'code': assignment.subject.code
                    },
                    'isClassTeacher': assignment.class_instance.class_teacher == assignment.teacher if assignment.class_instance.class_teacher else False
                }
                for assignment in teacher_assignments
            ]
        return []
    
    def get_content_created(self, obj):
        """Calculate the sum of modules, chapters, and questions created by the user in the current month."""
        now = timezone.now()
        current_year = now.year
        current_month = now.month
        
        from django.db.models import Value, CharField
        from django.db.models.functions import Cast
        
        if hasattr(obj, '_content_created_count'):
            return obj._content_created_count
        
        date_filter = {
            'created_at__year': current_year,
            'created_at__month': current_month
        }
        
        total = (
            ModuleChapter.objects.filter(created_by=obj, **date_filter).count() +
            Module.objects.filter(created_by=obj, **date_filter).count() +
            Question.objects.filter(created_by=obj, **date_filter).count()
        )
        
        return total
    
    class Meta:
        model = Account
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 'user_type',
            'school', 'school_name', 'admission_number', 'roll_number', 'total_exp', 'rewards',
            'level', 'level_name', 'class_instance', 'class_id', 'class_name', 'grade_id', 'grade_name', 'phone_number', 
            'date_of_birth', 'parent_name', 'gender', 'profile_picture', 'bio', 'is_active', 'date_joined', 
            'logged_in_once', 'is_class_teacher', 'employee_id', 'subjects', 'subject_ids', 'teacher_assignments',
            'content_created', 'weakTopics', 'average_score', 'attendance',
            'fcm_token'
        ]
        read_only_fields = ['id', 'date_joined', 'logged_in_once']


class UserCreateSerializer(serializers.ModelSerializer):
    user_type = serializers.ChoiceField(
        choices=[('student', 'Student'), ('teacher', 'Teacher'), ('admin', 'Administrator')],
        write_only=True,
        required=False,
        default='student'
    )
    admission_number = serializers.IntegerField(required=False, allow_null=True)
    roll_number = serializers.IntegerField(required=False, allow_null=True)
    phone_number = serializers.CharField(required=False, allow_null=True, allow_blank=True)
    date_of_birth = serializers.DateField(required=False, allow_null=True)
    parent_name = serializers.CharField(required=False, allow_null=True, allow_blank=True, max_length=255)
    gender = serializers.ChoiceField(
        choices=['male', 'female', 'other'],
        required=False,
        allow_null=True,
        allow_blank=True
    )
    profile_picture = serializers.ImageField(required=False, allow_null=True)
    bio = serializers.CharField(required=False, allow_blank=True, default='')
    class_id = serializers.UUIDField(required=False, allow_null=True, write_only=True)
    subject_ids = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        allow_empty=True,
        write_only=True
    )
    password = serializers.CharField(write_only=True, required=False, allow_blank=True)
    confirm_password = serializers.CharField(write_only=True, required=False, allow_blank=True)
    is_class_teacher = serializers.BooleanField(required=False, default=False)
    employee_id = serializers.CharField(required=False, allow_null=True, allow_blank=True, max_length=50)
    assignments = serializers.ListField(
        child=serializers.DictField(),
        required=False,
        allow_empty=True,
        write_only=True,
        help_text="List of {class, subjects[]} pairs for multi-class assignment"
    )

    class Meta:
        model = Account
        fields = [
            'username', 'email', 'first_name',
            'last_name', 'user_type', 'admission_number', 'roll_number',
            'phone_number', 'date_of_birth', 'parent_name', 'gender', 'profile_picture', 'bio',
            'class_id', 'subject_ids', 'password', 'confirm_password',
            'is_class_teacher', 'employee_id', 'assignments'
        ]
        extra_kwargs = {
            'username': {'required': False},
            'email': {'required': False},
        }
    
    @staticmethod
    def generate_random_password(length=12):
        alphabet = string.ascii_letters + string.digits + string.punctuation
        return ''.join(secrets.choice(alphabet) for _ in range(length))
    
    @staticmethod
    def generate_username(first_name, last_name):
        first = ''.join(first_name.lower().split())[:5] if first_name else ''
        last = ''.join(last_name.lower().split())[:5] if last_name else ''
        base_username = f"{first}{last}" if first and last else f"{first}{last}user"
        
        username = base_username
        counter = 1
        while Account.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1
        
        return username
    
    def validate(self, attrs):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            logger.warning("User creation attempted without authentication")
            raise serializers.ValidationError({"error": "User must be authenticated"})

        if not hasattr(request.user, 'profile') or not request.user.profile.school:
            logger.warning(f"User {request.user.username} attempted to create user without school")
            raise serializers.ValidationError({"error": "User must have a school associated"})

        school = request.user.profile.school

        password = attrs.get('password')
        confirm_password = attrs.get('confirm_password')
        if password and password.strip():
            if not confirm_password:
                raise serializers.ValidationError({"confirm_password": "Password confirmation is required when password is provided."})
            if password != confirm_password:
                raise serializers.ValidationError({"confirm_password": "Passwords do not match."})

        # Resolve multi-class assignments [{class, subjects[]}, ...]
        raw_assignments = attrs.pop('assignments', None) or []
        resolved_assignments = []  # list of (Class, [Subject])
        for idx, asn in enumerate(raw_assignments):
            raw_class = asn.get('class') or asn.get('class_id')
            if isinstance(raw_class, dict):
                raw_class = raw_class.get('id')
            if not raw_class:
                continue
            try:
                cls_obj = Class.objects.get(id=raw_class, school=school, is_active=True)
            except (Class.DoesNotExist, Exception):
                raise serializers.ValidationError({"assignments": f"Assignment {idx+1}: class not found or not in your school."})
            raw_subjects = asn.get('subjects', [])
            subj_ids = []
            for s in raw_subjects:
                subj_ids.append(s.get('id') if isinstance(s, dict) else s)
            subj_ids = [sid for sid in subj_ids if sid]
            if not subj_ids:
                continue
            subj_qs = Subject.objects.filter(id__in=subj_ids, is_active=True)
            if subj_qs.count() != len(subj_ids):
                raise serializers.ValidationError({"assignments": f"Assignment {idx+1}: one or more subjects are invalid."})
            resolved_assignments.append((cls_obj, list(subj_qs)))

        # Fall back to flat class_id / subject_ids if no assignments provided
        if not resolved_assignments:
            class_id = attrs.get('class_id')
            if class_id:
                try:
                    class_instance = Class.objects.get(id=class_id, school=school, is_active=True)
                    attrs['class_instance'] = class_instance
                except Class.DoesNotExist:
                    logger.warning(f"Class {class_id} not found for school {school.id}")
                    raise serializers.ValidationError({"class_id": "Class does not exist or does not belong to your school"})

            subject_ids = attrs.get('subject_ids', [])
            if subject_ids:
                subjects = Subject.objects.filter(id__in=subject_ids, is_active=True, school=school)
                if subjects.count() != len(subject_ids):
                    logger.warning(f"Invalid subjects provided: {subject_ids}")
                    raise serializers.ValidationError({"subject_ids": "One or more subjects are invalid, inactive, or not in your school"})
                attrs['subjects'] = list(subjects)
        else:
            attrs['resolved_assignments'] = resolved_assignments
            # Use the first assignment as primary class_instance for backwards compatibility
            attrs['class_instance'] = resolved_assignments[0][0]

        return attrs
    
    def create(self, validated_data):
        request = self.context['request']
        school = request.user.profile.school
        
        first_name = validated_data.pop('first_name', '')
        last_name = validated_data.pop('last_name', '')
        email = validated_data.pop('email', None)
        
        user_type = validated_data.pop('user_type', 'student')
        school_prefix = school.password_prefix or ''.join(
            w[0] for w in school.name.split() if w
        ).lower()

        username = validated_data.pop('username', None)
        if not username:
            if user_type == 'student':
                admission_number = validated_data.get('admission_number') or validated_data.get('roll_number')
                if admission_number:
                    base = f"{admission_number}@{school_prefix}"
                else:
                    full_name = f"{first_name} {last_name}".strip()
                    base = re.sub(r"[^a-z0-9]+", ".", full_name.lower()).strip(".")
                    base = re.sub(r"\.{2,}", ".", base) or 'student'
            else:
                phone = validated_data.get('phone_number')
                if phone:
                    base = str(phone).strip()
                else:
                    parts = [
                        re.sub(r'[^a-z0-9]+', '.', p.lower().strip()).strip('.')
                        for p in [first_name, last_name] if p.strip()
                    ]
                    base = '.'.join(parts) or 'teacher'

            candidate = base
            n = 2
            while Account.objects.filter(username=candidate).exists():
                candidate = f"{base}{n}"
                n += 1
            username = candidate
            logger.debug(f"Generated username: {username} for {first_name} {last_name}")

        password = validated_data.pop('password', None)
        validated_data.pop('confirm_password', None)
        if not password or (isinstance(password, str) and password.strip() == ''):
            if user_type == 'teacher':
                password = f"{school_prefix}.{first_name.strip().lower()}"
            else:
                admission_number = validated_data.get('admission_number') or validated_data.get('roll_number')
                if admission_number:
                    password = f"{admission_number}@{first_name.lower()}"
                else:
                    password = f"Gyan@{first_name.lower()}"
            logger.debug(f"Generated password for user {username}")
        else:
            validate_password(password)

        class_instance = validated_data.pop('class_instance', None)
        subjects = validated_data.pop('subjects', [])
        validated_data.pop('class_id', None)
        validated_data.pop('subject_ids', None)
        
        profile_data = {
            'user_type': user_type,
            'school_id': school.id,
            'phone_number': validated_data.pop('phone_number', None),
            'date_of_birth': validated_data.pop('date_of_birth', None),
            'gender': validated_data.pop('gender', None),
            'profile_picture': validated_data.pop('profile_picture', None),
            'bio': validated_data.pop('bio', ''),
        }
        
        student_data = {
            'admission_number': validated_data.pop('admission_number', None),
            'roll_number': validated_data.pop('roll_number', None),
            'class_instance': class_instance,
            'parent_name': validated_data.pop('parent_name', None),
        }
        
        teacher_data = {
            'is_class_teacher': validated_data.pop('is_class_teacher', False),
            'employee_id': validated_data.pop('employee_id', None),
        }
        resolved_assignments = validated_data.pop('resolved_assignments', None)

        account = Account.objects.create_user(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            password=password,
            **validated_data
        )
        
        logger.info(f"Created account: {username} (ID: {account.id})")
        
        if hasattr(account, 'profile'):
            profile = account.profile
            for key, value in profile_data.items():
                if value is not None:
                    setattr(profile, key, value)
            profile.save()
        else:
            profile = UserProfile.objects.create(account=account, **profile_data)
        
        if user_type == 'student':
            student = Student.objects.create(
                user_profile=profile,
                **{k: v for k, v in student_data.items() if v is not None}
            )
            logger.info(f"Created Student record for {account.username}")

            from gyaan_buddy.users.models import StudentSubjectEnrollment
            subjects_to_enroll = subjects if subjects else (
                list(class_instance.subjects.filter(is_active=True)) if class_instance else []
            )
            for subject in subjects_to_enroll:
                StudentSubjectEnrollment.objects.get_or_create(
                    student=student,
                    subject=subject,
                    defaults={'enrolled_by': account, 'is_active': True},
                )
            logger.info(f"Enrolled {len(subjects_to_enroll)} subjects for student {account.username}")
        
        elif user_type == 'teacher':
            teacher_profile = TeacherProfile.objects.create(
                user_profile=profile,
                **{k: v for k, v in teacher_data.items() if v is not None}
            )
            logger.info(f"Created TeacherProfile record for {account.username}")

            if resolved_assignments:
                # Multi-class assignment path
                is_class_teacher = teacher_data.get('is_class_teacher', False)
                first_cls = resolved_assignments[0][0]
                if is_class_teacher:
                    first_cls.class_teacher = teacher_profile
                    first_cls.save()
                    logger.debug(f"Set {account.username} as class teacher for {first_cls.name}")
                total_created = 0
                for cls_obj, subj_list in resolved_assignments:
                    for subject in subj_list:
                        _, created = Teacher.objects.get_or_create(
                            teacher=teacher_profile,
                            class_instance=cls_obj,
                            subject=subject
                        )
                        if created:
                            total_created += 1
                logger.info(f"Created {total_created} Teacher entries for {account.username} across {len(resolved_assignments)} classes")
            elif subjects and class_instance:
                # Legacy single-class path
                if teacher_data.get('is_class_teacher', False):
                    class_instance.class_teacher = teacher_profile
                    class_instance.save()
                    logger.debug(f"Set {account.username} as class teacher for {class_instance.name}")
                teacher_entries_created = []
                for subject in subjects:
                    teacher_entry, created = Teacher.objects.get_or_create(
                        teacher=teacher_profile,
                        class_instance=class_instance,
                        subject=subject
                    )
                    if created:
                        teacher_entries_created.append(teacher_entry)
                logger.info(f"Created {len(teacher_entries_created)} Teacher entries for teacher {account.username}")
        
        return account


class UserUpdateSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(required=False, allow_null=True, allow_blank=True)
    date_of_birth = serializers.DateField(required=False, allow_null=True)
    parent_name = serializers.CharField(required=False, allow_null=True, allow_blank=True, max_length=255)
    roll_number = serializers.IntegerField(required=False, allow_null=True)
    admission_number = serializers.IntegerField(required=False, allow_null=True)
    employee_id = serializers.CharField(required=False, allow_null=True, allow_blank=True, max_length=50)
    gender = serializers.ChoiceField(
        choices=['male', 'female', 'other'],
        required=False,
        allow_null=True,
        allow_blank=True
    )
    profile_picture = serializers.ImageField(required=False, allow_null=True)
    bio = serializers.CharField(required=False, allow_blank=True)
    class_id = serializers.UUIDField(required=False, allow_null=True, write_only=True)
    subject_ids = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        allow_empty=True,
        write_only=True
    )
    is_class_teacher = serializers.BooleanField(required=False, default=False)

    assignments = serializers.ListField(
        child=serializers.DictField(),
        required=False,
        allow_empty=True,
        write_only=True,
        help_text="List of assignments with class and subjects (alternative to class_id/subject_ids)"
    )

    class Meta:
        model = Account
        fields = [
            'email', 'first_name', 'last_name', 'phone_number',
            'date_of_birth', 'parent_name', 'roll_number', 'admission_number',
            'gender', 'profile_picture', 'bio',
            'class_id', 'subject_ids', 'is_class_teacher', 'employee_id', 'assignments'
        ]
    
    def validate(self, attrs):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            logger.warning("User update attempted without authentication")
            raise serializers.ValidationError({"error": "User must be authenticated"})
        
        if not hasattr(request.user, 'profile') or not request.user.profile.school:
            raise serializers.ValidationError({"error": "User must have a school associated"})
        
        school = request.user.profile.school
        
        raw_assignments = attrs.pop('assignments', None)
        if raw_assignments is not None and len(raw_assignments) > 0:
            resolved_assignments = []
            for idx, asn in enumerate(raw_assignments):
                # Support both {class, subjects} and {class_id, subject_ids} key formats
                raw_class = asn.get('class') or asn.get('class_id')
                if isinstance(raw_class, dict):
                    raw_class = raw_class.get('id')
                if not raw_class:
                    continue
                try:
                    cls_obj = Class.objects.get(id=raw_class, school=school, is_active=True)
                except (Class.DoesNotExist, Exception):
                    raise serializers.ValidationError({"assignments": f"Assignment {idx+1}: class not found or not in your school."})
                raw_subjects = asn.get('subjects') or asn.get('subject_ids') or []
                subj_ids = [s.get('id') if isinstance(s, dict) else s for s in raw_subjects]
                subj_ids = [sid for sid in subj_ids if sid]
                if not subj_ids:
                    continue
                subj_qs = Subject.objects.filter(id__in=subj_ids, is_active=True)
                if subj_qs.count() != len(subj_ids):
                    raise serializers.ValidationError({"assignments": f"Assignment {idx+1}: one or more subjects are invalid."})
                resolved_assignments.append((cls_obj, list(subj_qs)))

            if resolved_assignments:
                attrs['resolved_assignments'] = resolved_assignments
                # Populate class_id/subject_ids from first assignment for remaining validators
                first_cls, first_subjs = resolved_assignments[0]
                if 'class_id' not in attrs:
                    attrs['class_id'] = first_cls.id
                    logger.info(f"Extracted class_id from assignments: {first_cls.id}")
                if 'subject_ids' not in attrs:
                    attrs['subject_ids'] = [s.id for s in first_subjs]
                    logger.info(f"Extracted {len(first_subjs)} subject_ids from assignments")
        
        is_class_teacher = attrs.get('is_class_teacher', False)
        class_id = attrs.get('class_id')
        
        subject_ids = attrs.get('subject_ids')
        subject_ids_provided = subject_ids is not None and len(subject_ids) > 0
        
        if is_class_teacher and class_id is None:
            instance_id = self.instance.id if hasattr(self, 'instance') and self.instance else None
            if instance_id:
                try:
                    instance = Account.objects.get(id=instance_id)
                    if hasattr(instance, 'profile'):
                        profile = instance.profile
                        
                        if hasattr(profile, 'student') and profile.student.class_instance:
                            class_id = profile.student.class_instance.id
                            attrs['class_id'] = class_id
                            logger.info(f"Using existing class_id from student.class_instance: {class_id}")
                        elif profile.user_type == 'teacher' and hasattr(profile, 'teacher_profile'):
                            from .models import Teacher
                            existing_teacher_entry = Teacher.objects.filter(
                                teacher=profile.teacher_profile
                            ).select_related('class_instance').first()
                            
                            if existing_teacher_entry and existing_teacher_entry.class_instance:
                                class_id = existing_teacher_entry.class_instance.id
                                attrs['class_id'] = class_id
                                logger.info(f"Using existing class_id from Teacher entry: {class_id}")
                            elif subject_ids_provided:
                                raise serializers.ValidationError({
                                    "class_id": "class_id is required when is_class_teacher is true and creating new assignments. Please provide class_id."
                                })
                        else:
                            if subject_ids_provided:
                                raise serializers.ValidationError({
                                    "class_id": "class_id is required when is_class_teacher is true"
                                })
                except Account.DoesNotExist:
                    if subject_ids_provided:
                        raise serializers.ValidationError({
                            "class_id": "class_id is required when is_class_teacher is true"
                        })
            else:
                if subject_ids_provided:
                    raise serializers.ValidationError({
                        "class_id": "class_id is required when is_class_teacher is true"
                    })
        
        if class_id is not None:
            instance_id = self.instance.id if hasattr(self, 'instance') and self.instance else None
            if instance_id:
                try:
                    instance = Account.objects.get(id=instance_id)
                    if hasattr(instance, 'profile'):
                        profile = instance.profile
                        if profile.user_type not in ['student', 'teacher']:
                            raise serializers.ValidationError({
                                "class_id": "Only students and teachers can be associated with classes."
                            })
                except Account.DoesNotExist:
                    pass
            
            from .models import Class
            try:
                class_instance = Class.objects.get(id=class_id, school=school, is_active=True)
                attrs['class_instance'] = class_instance
            except Class.DoesNotExist:
                logger.warning(f"Class {class_id} not found for update")
                raise serializers.ValidationError({"class_id": "Class does not exist or does not belong to your school"})
        
        subject_ids = attrs.get('subject_ids')
        if subject_ids is not None:
            if len(subject_ids) == 0:
                attrs['subjects'] = []
            else:
                subjects = Subject.objects.filter(id__in=subject_ids, is_active=True)
                if subjects.count() != len(subject_ids):
                    raise serializers.ValidationError({"subject_ids": "One or more subjects are invalid or inactive"})
                attrs['subjects'] = list(subjects)
        
        return attrs
    
    def update(self, instance, validated_data):
        profile_fields = ['phone_number', 'date_of_birth', 'gender', 'profile_picture', 'bio']
        student_fields = ['parent_name', 'admission_number', 'roll_number']
        teacher_fields = ['is_class_teacher', 'employee_id']
        
        profile_data = {}
        student_data = {}
        teacher_data = {}
        
        for field in profile_fields:
            if field in validated_data:
                profile_data[field] = validated_data.pop(field)
        
        for field in student_fields:
            if field in validated_data:
                student_data[field] = validated_data.pop(field)
        
        for field in teacher_fields:
            if field in validated_data:
                teacher_data[field] = validated_data.pop(field)
        
        class_instance = validated_data.pop('class_instance', None)
        subjects = validated_data.pop('subjects', None)
        resolved_assignments = validated_data.pop('resolved_assignments', None)
        validated_data.pop('class_id', None)
        validated_data.pop('subject_ids', None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        logger.info(f"Updated account: {instance.username} (ID: {instance.id})")
        
        if hasattr(instance, 'profile'):
            profile = instance.profile
            
            for attr, value in profile_data.items():
                if value is not None:
                    setattr(profile, attr, value)
            if profile_data:
                profile.save()
            
            if profile.user_type == 'student':
                student, created = Student.objects.get_or_create(user_profile=profile)
                if created:
                    logger.info(f"Created Student record for {instance.username}")
                
                if class_instance is not None:
                    student_data['class_instance'] = class_instance

                for attr, value in student_data.items():
                    if value is not None:
                        setattr(student, attr, value)
                if student_data or class_instance is not None:
                    student.save()

                from gyaan_buddy.users.models import StudentSubjectEnrollment
                if subjects is not None:
                    # Explicit subject list provided — replace enrollments
                    StudentSubjectEnrollment.objects.filter(student=student).update(is_active=False)
                    for subject in subjects:
                        enrollment, _ = StudentSubjectEnrollment.objects.get_or_create(
                            student=student,
                            subject=subject,
                            defaults={'enrolled_by': instance, 'is_active': True}
                        )
                        if not enrollment.is_active:
                            enrollment.is_active = True
                            enrollment.save(update_fields=['is_active'])
                    logger.info(f"Updated subject enrollments for student {instance.username}: {len(subjects)} subjects")
                elif class_instance is not None:
                    # Class changed — auto-enroll in all active subjects of the new class
                    for subject in class_instance.subjects.filter(is_active=True):
                        enrollment, _ = StudentSubjectEnrollment.objects.get_or_create(
                            student=student,
                            subject=subject,
                            defaults={'enrolled_by': instance, 'is_active': True}
                        )
                        if not enrollment.is_active:
                            enrollment.is_active = True
                            enrollment.save(update_fields=['is_active'])
                    logger.info(f"Auto-enrolled student {instance.username} in subjects for class {class_instance.name}")
            
            elif profile.user_type == 'teacher':
                teacher_profile, created = TeacherProfile.objects.get_or_create(user_profile=profile)
                if created:
                    logger.info(f"Created TeacherProfile record for {instance.username}")

                is_class_teacher_updated = 'is_class_teacher' in teacher_data

                for attr, value in teacher_data.items():
                    if value is not None or attr == 'is_class_teacher':
                        setattr(teacher_profile, attr, value)
                if teacher_data:
                    teacher_profile.save()

                if resolved_assignments:
                    # Multi-class path: replace all Teacher entries with new assignments
                    Teacher.objects.filter(teacher=teacher_profile).delete()
                    first_cls = resolved_assignments[0][0]
                    if teacher_profile.is_class_teacher:
                        first_cls.class_teacher = teacher_profile
                        first_cls.save()
                    total_created = 0
                    for cls_obj, subj_list in resolved_assignments:
                        for subject in subj_list:
                            Teacher.objects.get_or_create(
                                teacher=teacher_profile,
                                class_instance=cls_obj,
                                subject=subject
                            )
                            total_created += 1
                    logger.info(f"Updated {total_created} Teacher entries for {instance.username} across {len(resolved_assignments)} classes")

                elif subjects is not None:
                    # Single-class path (legacy class_id + subject_ids)
                    target_class = class_instance
                    if not target_class:
                        existing = Teacher.objects.filter(teacher=teacher_profile).select_related('class_instance').first()
                        if existing:
                            target_class = existing.class_instance

                    if target_class:
                        if len(subjects) == 0:
                            deleted_count = Teacher.objects.filter(
                                teacher=teacher_profile, class_instance=target_class
                            ).delete()[0]
                            logger.info(f"Deleted {deleted_count} Teacher entries for {instance.username} in {target_class.name}")
                        else:
                            Teacher.objects.filter(teacher=teacher_profile).delete()
                            if teacher_profile.is_class_teacher:
                                target_class.class_teacher = teacher_profile
                                target_class.save()
                            elif target_class.class_teacher == teacher_profile:
                                target_class.class_teacher = None
                                target_class.save()
                            for subject in subjects:
                                Teacher.objects.create(teacher=teacher_profile, class_instance=target_class, subject=subject)
                            logger.info(f"Created {len(subjects)} Teacher entries for {instance.username}: {target_class.name}")

                elif is_class_teacher_updated:
                    target_class = class_instance
                    if not target_class:
                        existing = Teacher.objects.filter(teacher=teacher_profile).select_related('class_instance').first()
                        if existing:
                            target_class = existing.class_instance
                    if target_class:
                        if teacher_profile.is_class_teacher:
                            target_class.class_teacher = teacher_profile
                            target_class.save()
                        elif target_class.class_teacher == teacher_profile:
                            target_class.class_teacher = None
                            target_class.save()
                    else:
                        logger.warning(f"Cannot update class_teacher for {instance.username}: no class found")
        
        return instance


class UserPasswordChangeSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(write_only=True)
    
    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            logger.warning(f"Password change failed for user {user.username}: incorrect old password")
            raise serializers.ValidationError("Old password is incorrect")
        return value
    
    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError("New passwords don't match")
        return attrs
    
    def save(self, **kwargs):
        """Save the new password for the user."""
        user = self.context['request'].user
        user.set_password(self.validated_data['new_password'])
        user.save(update_fields=['password'])
        logger.info(f"Password changed successfully for user {user.username}")
        return user


class UserLoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)
    fcm_token = serializers.CharField(required=False, allow_blank=True, max_length=1000)
    type = serializers.CharField(
        required=False,
        default='mobile',
        help_text='Login type: "dashboard", "parent_dashboard", or "mobile" (default)'
    )
    
    def validate(self, attrs):
        username = attrs.get('username')
        password = attrs.get('password')
        login_type = attrs.get('type', 'mobile')
        
        if username and password:
            user = authenticate(username=username, password=password)
            if not user:
                logger.warning(f"Login failed for username: {username}")
                raise serializers.ValidationError('Invalid credentials')
            if not user.is_active:
                logger.warning(f"Login failed for inactive user: {username}")
                raise serializers.ValidationError('User account is disabled')
            
            if not hasattr(user, 'profile'):
                logger.warning(f"Login failed for user {username}: No profile found")
                raise serializers.ValidationError('User profile not found')
            
            user_type = user.profile.user_type
            
            if login_type == 'dashboard':
                if user_type == 'student':
                    logger.warning(f"Dashboard login denied for student user: {username}")
                    raise serializers.ValidationError('Dashboard login is not available for students')
            elif login_type == 'parent_dashboard':
                if user_type != 'student':
                    logger.warning(f"Parent dashboard login denied for non-student user: {username} ({user_type})")
                    raise serializers.ValidationError('Parent dashboard login is only available for student accounts')
            elif login_type == 'mobile':
                if user_type in ['teacher', 'administrator']:
                    logger.warning(f"Mobile login denied for {user_type} user: {username}")
                    raise serializers.ValidationError(f'Mobile login is not available for {user_type}s')
            else:
                raise serializers.ValidationError('Invalid login type')
            
            attrs['user'] = user
        else:
            raise serializers.ValidationError('Must include username and password')
        
        return attrs


class UserExpSerializer(serializers.Serializer):
    exp_points = serializers.IntegerField(min_value=1, max_value=1000)
    
    def save(self, **kwargs):
        """Add experience points to the user."""
        user = self.context['request'].user
        exp_points = self.validated_data['exp_points']
        if hasattr(user, 'profile'):
            user.profile.add_exp(exp_points)
            logger.info(f"Added {exp_points} exp to user {user.username}")
        return user


class UserListSerializer(serializers.ModelSerializer):
    school_name = serializers.SerializerMethodField()
    level_name = serializers.SerializerMethodField()
    class_name = serializers.SerializerMethodField()
    class_id = serializers.SerializerMethodField()
    grade_name = serializers.SerializerMethodField()
    grade_id = serializers.SerializerMethodField()
    user_type = serializers.SerializerMethodField()
    admission_number = serializers.SerializerMethodField()
    roll_number = serializers.SerializerMethodField()
    total_exp = serializers.SerializerMethodField()
    rewards = serializers.SerializerMethodField()
    date_of_birth = serializers.SerializerMethodField()
    parent_name = serializers.SerializerMethodField()
    gender = serializers.SerializerMethodField()
    average_score = serializers.FloatField(read_only=True, allow_null=True)
    subjects = serializers.SerializerMethodField()
    progress_module_count = serializers.SerializerMethodField()
    
    def _get_profile(self, obj):
        """Safely get the user profile"""
        try:
            return obj.profile
        except (UserProfile.DoesNotExist, AttributeError):
            return None
    
    def _get_student(self, obj):
        """Safely get the student object from profile"""
        profile = self._get_profile(obj)
        if profile is None:
            return None
        try:
            return profile.student
        except (Student.DoesNotExist, AttributeError):
            return None
    
    def get_school_name(self, obj):
        profile = self._get_profile(obj)
        if profile and profile.school:
            return profile.school.name
        return None
    
    def get_user_type(self, obj):
        profile = self._get_profile(obj)
        if profile:
            return profile.user_type
        return None
    
    def get_date_of_birth(self, obj):
        profile = self._get_profile(obj)
        if profile:
            return profile.date_of_birth
        return None
    
    def get_gender(self, obj):
        profile = self._get_profile(obj)
        if profile:
            return profile.gender
        return None
    
    def get_level_name(self, obj):
        student = self._get_student(obj)
        if student and student.level:
            return student.level.name
        return None
    
    def get_admission_number(self, obj):
        student = self._get_student(obj)
        if student:
            return student.admission_number
        return None
    
    def get_roll_number(self, obj):
        student = self._get_student(obj)
        if student:
            return student.roll_number
        return None
    
    def get_total_exp(self, obj):
        student = self._get_student(obj)
        if student:
            return student.total_exp
        return 0
    
    def get_rewards(self, obj):
        student = self._get_student(obj)
        if student:
            return student.rewards
        return 0
    
    def get_parent_name(self, obj):
        student = self._get_student(obj)
        if student:
            return student.parent_name
        return None
    
    def _get_class_instance(self, obj):
        """Get the class instance object for the user (student or teacher)"""
        profile = self._get_profile(obj)
        if profile is None:
            return None
        
        if profile.user_type == 'teacher':
            try:
                teacher_profile = profile.teacher_profile
                class_instance = Class.objects.filter(
                    class_teacher=teacher_profile
                ).select_related('grade').first()
                return class_instance
            except (TeacherProfile.DoesNotExist, AttributeError):
                return None
        else:
            student = self._get_student(obj)
            if student and student.class_instance:
                return student.class_instance
            return None
    
    def _get_class_data(self, obj):
        class_instance = self._get_class_instance(obj)
        if class_instance:
            return {
                'id': str(class_instance.id),
                'name': class_instance.name
            }
        return {'id': None, 'name': None}
    
    def get_class_id(self, obj):
        return self._get_class_data(obj)['id']
    
    def get_class_name(self, obj):
        return self._get_class_data(obj)['name']
    
    def _get_grade_data(self, obj):
        class_instance = self._get_class_instance(obj)
        if class_instance and class_instance.grade:
            return {
                'id': str(class_instance.grade.id),
                'name': class_instance.grade.name
            }
        return {'id': None, 'name': None}
    
    def get_grade_id(self, obj):
        return self._get_grade_data(obj)['id']
    
    def get_grade_name(self, obj):
        return self._get_grade_data(obj)['name']
    
    def _build_subject_data(self, subject, assignment_info, class_instance=None, teacher_profile=None):
        assignments = assignment_info.get('assignments', [])
        is_class_teacher = any((a['class'].class_teacher == teacher_profile if a['class'].class_teacher and teacher_profile else False) for a in assignments)
        class_assignment = next((a for a in assignments if (a['class'].class_teacher == teacher_profile if a['class'].class_teacher and teacher_profile else False)), assignments[0] if assignments else None)
        
        class_data = None
        if class_assignment:
            class_data = {
                'id': str(class_assignment['class'].id),
                'name': class_assignment['class'].name
            }
        elif class_instance:
            class_data = {
                'id': str(class_instance.id),
                'name': class_instance.name
            }
        
        return {
            'id': str(subject.id),
            'name': subject.name,
            'is_class_teacher': is_class_teacher,
            'class': class_data
        }
    
    def get_subjects(self, obj):
        if not hasattr(obj, 'profile'):
            return []
        
        if obj.profile.user_type == 'student' and hasattr(obj.profile, 'student'):
            student = obj.profile.student
            if student.class_instance:
                class_instance = student.class_instance
                if hasattr(class_instance, '_prefetched_objects_cache') and 'subjects' in class_instance._prefetched_objects_cache:
                    subjects_qs = [s for s in class_instance._prefetched_objects_cache['subjects'] if s.is_active]
                else:
                    subjects_qs = class_instance.subjects.filter(is_active=True)
            else:
                return []
            class_instance = student.class_instance
            class_data = {
                'id': str(class_instance.id),
                'name': class_instance.name
            } if class_instance else None
            return [{
                'id': str(subject.id),
                'name': subject.name,
                'is_class_teacher': False,
                'class': class_data
            } for subject in subjects_qs]
        
        if obj.profile.user_type == 'teacher' and hasattr(obj.profile, 'teacher_profile'):
            teacher_profile = obj.profile.teacher_profile
            subjects_dict = {}
            teacher_assignments = Teacher.objects.filter(
                teacher=teacher_profile,
                is_deleted=False,
            ).select_related('class_instance', 'subject')
            
            subject_assignments_map = {}
            for assignment in teacher_assignments:
                subject_id = str(assignment.subject.id)
                if subject_id not in subject_assignments_map:
                    subject_assignments_map[subject_id] = {
                        'subject': assignment.subject,
                        'assignments': []
                    }
                subject_assignments_map[subject_id]['assignments'].append({
                    'class': assignment.class_instance,
                    'is_class_teacher': assignment.class_instance.class_teacher == assignment.teacher if assignment.class_instance.class_teacher else False
                })
            
            class_instance = Class.objects.filter(
                class_teacher=teacher_profile
            ).first()
            
            if class_instance:
                if hasattr(class_instance, '_prefetched_objects_cache') and 'subjects' in class_instance._prefetched_objects_cache:
                    class_subjects = [s for s in class_instance._prefetched_objects_cache['subjects'] if s.is_active]
                else:
                    class_subjects = class_instance.subjects.filter(is_active=True)
                
                for subject in class_subjects:
                    subject_id = str(subject.id)
                    if subject_id not in subjects_dict:
                        assignment_info = subject_assignments_map.get(subject_id, {})
                        subjects_dict[subject_id] = self._build_subject_data(subject, assignment_info, class_instance, teacher_profile)
            
            try:
                created_modules = obj.created_modules.all()
                for module in created_modules:
                    if hasattr(module, 'subject'):
                        subject = module.subject
                        if subject and subject.is_active:
                            subject_id = str(subject.id)
                            if subject_id not in subjects_dict:
                                assignment_info = subject_assignments_map.get(subject_id, {})
                                subjects_dict[subject_id] = self._build_subject_data(subject, assignment_info, None, teacher_profile)
            except (AttributeError, TypeError):
                from gyaan_buddy.subjects.models import Subject
                module_subjects = Subject.objects.filter(
                    modules__created_by=obj,
                    is_active=True
                ).distinct()
                for subject in module_subjects:
                    subject_id = str(subject.id)
                    if subject_id not in subjects_dict:
                        assignment_info = subject_assignments_map.get(subject_id, {})
                        subjects_dict[subject_id] = self._build_subject_data(subject, assignment_info, None, teacher_profile)
            
            try:
                created_subjects = obj.created_subjects.all()
                for subject in created_subjects:
                    if subject.is_active:
                        subject_id = str(subject.id)
                        if subject_id not in subjects_dict:
                            assignment_info = subject_assignments_map.get(subject_id, {})
                            subjects_dict[subject_id] = self._build_subject_data(subject, assignment_info, None, teacher_profile)
            except (AttributeError, TypeError):
                from gyaan_buddy.subjects.models import Subject
                created_subjects = Subject.objects.filter(
                    created_by=obj,
                    is_active=True
                )
                for subject in created_subjects:
                    subject_id = str(subject.id)
                    if subject_id not in subjects_dict:
                        assignment_info = subject_assignments_map.get(subject_id, {})
                        subjects_dict[subject_id] = self._build_subject_data(subject, assignment_info, None, teacher_profile)
            
            return list(subjects_dict.values())
        
        return []
    
    def get_progress_module_count(self, obj):
        """Get the count of modules the user has made progress on."""
        return UserModuleProgress.objects.filter(account=obj,status='in_progress').count()
    
    class Meta:
        model = Account
        fields = [
            'id', 'username', 'first_name', 'last_name', 'email', 'user_type',
            'school_name', 'admission_number', 'roll_number',
            'class_name', 'class_id', 'grade_name', 'grade_id', 'total_exp', 'rewards', 'level_name',
            'date_of_birth', 'parent_name', 'gender', 'average_score', 'subjects', 'progress_module_count', 'is_active', 'date_joined'
        ]


class ClassSerializer(serializers.ModelSerializer):
    school_name = serializers.CharField(read_only=True, source='school.name')
    name = serializers.CharField(required=True)
    
    class Meta:
        model = Class
        fields = '__all__'
        extra_kwargs = {
            'school': {'read_only': True}
        }
    
    def create(self, validated_data):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            raise serializers.ValidationError({"error": "User must be authenticated to create a class"})
        
        if not hasattr(request.user, 'profile') or not request.user.profile.school:
            raise serializers.ValidationError({"error": "User must have a school associated to create a class"})
        
        validated_data['school'] = request.user.profile.school
        logger.info(f"Creating class {validated_data.get('name')} for school {request.user.profile.school.id}")
        return super().create(validated_data)


class ClassListSerializer(serializers.ModelSerializer):
    school_name = serializers.CharField(source='school.name', read_only=True)
    student_count = serializers.SerializerMethodField()
    class_teacher = serializers.SerializerMethodField()
    
    class Meta:
        model = Class
        fields = ['id', 'name', 'school_name', 'student_count', 'class_teacher', 'created_at']
    
    def get_student_count(self, obj):
        return obj.enrolled_students.filter(is_deleted=False, user_profile__account__is_active=True).count()
    
    def get_class_teacher(self, obj):
        if not obj.class_teacher:
            return None
        
        teacher_profile = obj.class_teacher
        
        if teacher_profile.is_deleted or not (hasattr(teacher_profile, 'user_profile') and hasattr(teacher_profile.user_profile, 'account') and teacher_profile.user_profile.account.is_active):
            return None
        
        account = teacher_profile.user_profile.account
        return {
            'id': str(account.id),
            'username': account.username,
            'first_name': account.first_name,
            'last_name': account.last_name,
            'email': account.email,
            'employee_id': teacher_profile.employee_id,
        }


class SchoolSerializer(serializers.ModelSerializer):
    class Meta:
        model = School
        fields = '__all__'


class SchoolListSerializer(serializers.ModelSerializer):
    user_count = serializers.SerializerMethodField()
    
    class Meta:
        model = School
        fields = ['id', 'name', 'address', 'phone', 'email', 'website', 'user_count', 'created_at']
    
    def get_user_count(self, obj):
        """Return the count of user profiles associated with this school."""
        return obj.user_profiles.filter(account__is_active=True).count()


class GradeSerializer(serializers.ModelSerializer):
    school_name = serializers.CharField(read_only=True, source='school.name')
    class_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Grade
        fields = '__all__'
        extra_kwargs = {
            'school': {'read_only': True}
        }
    
    def get_class_count(self, obj):
        return obj.classes.filter(is_active=True).count()
    
    def create(self, validated_data):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            raise serializers.ValidationError({"error": "User must be authenticated to create a grade"})
        
        if not hasattr(request.user, 'profile') or not request.user.profile.school:
            raise serializers.ValidationError({"error": "User must have a school associated to create a grade"})
        
        validated_data['school'] = request.user.profile.school
        logger.info(f"Creating grade {validated_data.get('name')} for school {request.user.profile.school.id}")
        return super().create(validated_data)


class GradeListSerializer(serializers.ModelSerializer):
    school_name = serializers.CharField(source='school.name', read_only=True)
    class_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Grade
        fields = ['id', 'name', 'school_name', 'description', 'class_count', 'is_active', 'created_at']
    
    def get_class_count(self, obj):
        return obj.classes.filter(is_active=True).count()


class MissionSerializer(serializers.ModelSerializer):
    """Serializer for Mission model."""
    user = serializers.CharField(source='account.username', read_only=True)
    user_id = serializers.UUIDField(source='account.id', read_only=True)
    title = serializers.ReadOnlyField()
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    subject_color = serializers.CharField(source='subject.color', read_only=True, allow_null=True)
    subject_logo = serializers.SerializerMethodField()
    question_count = serializers.IntegerField(read_only=True)
    progress = serializers.SerializerMethodField()
    user_completed = serializers.SerializerMethodField()
    user_started = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()

    class Meta:
        model = Mission
        fields = [
            'id', 'title', 'mission_date', 'account', 'user', 'user_id',
            'subject', 'subject_name', 'subject_color', 'subject_logo',
            'question_count', 'progress', 'user_completed', 'user_started', 'status', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_subject_logo(self, obj):
        if obj.subject:
            return obj.subject.get_logo_url
        return None
    
    def get_progress(self, obj):
        if hasattr(obj, 'progress'):
            return UserMissionProgressSerializer(obj.progress).data
        return None
    
    def get_user_completed(self, obj):
        """Return whether the mission is completed based on progress status."""
        if hasattr(obj, 'progress') and obj.progress:
            return obj.progress.status == 'completed'
        return False
    
    def get_user_started(self, obj):
        """Return whether the mission has been started based on progress status."""
        if hasattr(obj, 'progress') and obj.progress:
            return obj.progress.status in ['in_progress', 'completed']
        return False
    
    def get_status(self, obj):
        """Return the mission status based on progress."""
        if hasattr(obj, 'progress') and obj.progress:
            return obj.progress.status
        return 'not_started'


class MissionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating Mission."""
    
    class Meta:
        model = Mission
        fields = ['mission_date', 'account', 'subject']


class MissionListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing missions."""
    user = serializers.CharField(source='account.username', read_only=True)
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    progress_status = serializers.SerializerMethodField()
    
    class Meta:
        model = Mission
        fields = [
            'id', 'mission_date', 'user', 'subject_name', 
            'progress_status'
        ]
    
    def get_progress_status(self, obj):
        if hasattr(obj, 'progress'):
            return obj.progress.status
        return 'not_started'


class CompetitionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Competition
        fields = '__all__'


class CompetitionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Competition
        fields = [
            'title', 'description', 'competition_type', 'subject',
            'chapter', 'total_time', 'status', 'is_active'
        ]


class CompetitionJoinSerializer(serializers.Serializer):
    competition_id = serializers.IntegerField()


class UserMissionProgressSerializer(serializers.ModelSerializer):
    """Serializer for UserMissionProgress model."""
    user = serializers.CharField(source='mission.account.username', read_only=True)
    user_id = serializers.UUIDField(source='mission.account.id', read_only=True)
    mission_date = serializers.DateField(source='mission.mission_date', read_only=True)
    subject_name = serializers.CharField(source='mission.subject.name', read_only=True)
    current_question_text = serializers.CharField(source='current_question.question_text', read_only=True, allow_null=True)
    current_question_id = serializers.UUIDField(source='current_question.id', read_only=True, allow_null=True)
    accuracy = serializers.FloatField(read_only=True)

    class Meta:
        model = UserMissionProgress
        fields = [
            'id', 'mission', 'user', 'user_id', 'mission_date',
            'subject_name',
            'status', 'percentage', 'score', 'total_questions',
            'questions_attempted', 'correct_answers', 'wrong_answers',
            'started_at', 'completed_at', 'last_accessed', 'time_spent_seconds',
            'exp_earned', 'current_question', 'current_question_id',
            'current_question_text', 'accuracy', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'last_accessed']


class UserCompetitionProgressSerializer(serializers.ModelSerializer):
    current_question_text = serializers.CharField(source='current_question.question_text', read_only=True)
    current_question_id = serializers.UUIDField(source='current_question.id', read_only=True)
    competition_title = serializers.CharField(source='competition.title', read_only=True)
    competition_code = serializers.CharField(source='competition.code', read_only=True)
    user = serializers.CharField(source='account.username', read_only=True)
    
    class Meta:
        model = UserCompetitionProgress
        fields = '__all__'


class UserModuleProgressSerializer(serializers.ModelSerializer):
    current_question_text = serializers.CharField(source='current_question.question_text', read_only=True)
    current_question_id = serializers.UUIDField(source='current_question.id', read_only=True)
    module_name = serializers.CharField(source='module.name', read_only=True)
    subject_name = serializers.CharField(source='module.subject.name', read_only=True)
    
    class Meta:
        model = UserModuleProgress
        fields = '__all__'


class UserChapterProgressSerializer(serializers.ModelSerializer):
    current_question_text = serializers.CharField(source='current_question.question_text', read_only=True)
    current_question_id = serializers.UUIDField(source='current_question.id', read_only=True)
    chapter_title = serializers.CharField(source='chapter.title', read_only=True)
    module_name = serializers.CharField(source='chapter.module.name', read_only=True)
    subject_name = serializers.CharField(source='chapter.module.subject.name', read_only=True)
    
    class Meta:
        model = UserChapterProgress
        fields = '__all__'


class UserTestProgressSerializer(serializers.ModelSerializer):
    """Serializer for UserTestProgress model."""
    user = serializers.CharField(source='account.username', read_only=True)
    user_id = serializers.UUIDField(source='account.id', read_only=True)
    current_question_text = serializers.CharField(source='current_question.question_text', read_only=True, allow_null=True)
    current_question_id = serializers.UUIDField(source='current_question.id', read_only=True, allow_null=True)
    accuracy = serializers.FloatField(read_only=True)
    is_passed = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = UserTestProgress
        fields = [
            'id', 'account', 'user', 'user_id', 'test', 'status', 'percentage', 'score', 
            'total_questions', 'questions_attempted', 'correct_answers', 'wrong_answers',
            'started_at', 'completed_at', 'last_accessed', 'time_spent_seconds',
            'exp_earned', 'current_question', 'current_question_id', 
            'current_question_text', 'accuracy', 'is_passed',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'last_accessed']


class IndianDateTimeField(serializers.DateTimeField):
    """
    DateTime field that accepts input in Indian time (Asia/Kolkata).
    Subtracts 5.5 hours from the payload time (IST) then saves in UTC (Django USE_TZ).
    Output is returned in Indian time.
    """
    def to_internal_value(self, value):
        if value is None:
            return None
        parsed = super().to_internal_value(value)
        if parsed is None:
            return None
        if timezone.is_naive(parsed):
            parsed = parsed.replace(tzinfo=INDIAN_TZ)
        parsed = parsed - timedelta(hours=5.5)
        return parsed.astimezone(dt_utc.utc)

    def to_representation(self, value):
        if value is None:
            return None
        if timezone.is_naive(value):
            value = timezone.make_aware(value, dt_utc.utc)
        ist_value = value.astimezone(INDIAN_TZ)
        return ist_value.isoformat()


class TestSerializer(serializers.ModelSerializer):
    """Serializer for Test model. Supports multiple modules and chapters via module_chapters."""
    test_datetime = IndianDateTimeField(help_text='Date and time in Indian time (Asia/Kolkata)')
    class_group_name = serializers.SerializerMethodField()
    class_groups = serializers.SerializerMethodField()
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    subject_color = serializers.CharField(source='subject.color', read_only=True, allow_null=True)
    subject_logo = serializers.SerializerMethodField()
    module_chapters = serializers.SerializerMethodField()
    question_count = serializers.IntegerField(read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True, allow_null=True)
    
    class Meta:
        model = Test
        fields = [
            'id', 'test_datetime', 'duration', 'class_group', 'class_group_name', 'class_groups',
            'subject', 'subject_name', 'subject_color', 'subject_logo',
            'module_chapters',
            'question_count', 'created_by', 'created_by_username', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'created_by']

    def get_class_group_name(self, obj):
        primary = obj.class_group or (obj.class_groups.first() if getattr(obj, 'class_groups', None) and obj.class_groups.exists() else None)
        return primary.name if primary else None

    def get_class_groups(self, obj):
        classes = obj.get_assigned_classes() if hasattr(obj, 'get_assigned_classes') else []
        return [{'id': str(c.id), 'name': c.name} for c in classes]
    
    def get_subject_logo(self, obj):
        if obj.subject:
            if obj.subject.logo_url:
                return obj.subject.logo_url
            elif obj.subject.logo:
                return obj.subject.logo.url
        return None
    
    def get_module_chapters(self, obj):
        """Return list of { module_id, module_name, chapters: [{ id, title }] } grouped by module."""
        qs = getattr(obj, '_prefetched_objects_cache', {}).get('module_chapters')
        if qs is None:
            qs = TestModuleChapter.objects.filter(test=obj).select_related('module', 'module_chapter').order_by('module', 'module_chapter')
        else:
            qs = sorted(qs, key=lambda t: (str(t.module_id), str(t.module_chapter_id)))
        by_module = {}
        for tmc in qs:
            mid = str(tmc.module.id)
            if mid not in by_module:
                by_module[mid] = {
                    'module_id': mid,
                    'module_name': tmc.module.name,
                    'chapters': []
                }
            by_module[mid]['chapters'].append({
                'id': str(tmc.module_chapter.id),
                'title': tmc.module_chapter.title
            })
        return list(by_module.values())


class TestCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating Test. Provide test_datetime in Indian time (Asia/Kolkata).
    Accepts either:
    - class_group: single class (legacy), or class_groups: list of class UUIDs (multi-class).
    - module_chapters: list of { module: uuid, chapters: [uuid] } (new format), or
    - module + module_chapter: single module and chapter (legacy format)."""
    test_datetime = IndianDateTimeField(help_text='Date and time in Indian time (Asia/Kolkata)')
    class_groups = serializers.ListField(
        child=serializers.UUIDField(),
        write_only=True,
        required=False,
        allow_empty=False,
        help_text='List of class UUIDs this test is assigned to (optional; use class_group for single class)'
    )
    module_chapters = serializers.ListField(
        child=serializers.DictField(),
        write_only=True,
        required=False,
        allow_empty=True,
        help_text='List of { module: uuid, chapters: [uuid] }'
    )
    module = serializers.UUIDField(write_only=True, required=False, allow_null=True)
    module_chapter = serializers.UUIDField(write_only=True, required=False, allow_null=True)

    class Meta:
        model = Test
        fields = ['test_datetime', 'duration', 'class_group', 'class_groups', 'subject', 'module_chapters', 'module', 'module_chapter', 'created_by']
        read_only_fields = ['created_by']

    def _validate_module_chapters_list(self, value):
        """Validate and return module_chapters list."""
        if not value or not isinstance(value, list):
            raise serializers.ValidationError('At least one module with chapters is required.')
        from gyaan_buddy.subjects.models import ModuleChapter
        for item in value:
            if not isinstance(item, dict):
                raise serializers.ValidationError('Each item must be { module: uuid, chapters: [uuid] }.')
            module_id = item.get('module')
            chapters = item.get('chapters')
            if not module_id or not chapters or not isinstance(chapters, list):
                raise serializers.ValidationError('Each item must have module and chapters (non-empty list).')
            for ch_id in chapters:
                try:
                    ch = ModuleChapter.objects.get(id=ch_id)
                    if str(ch.module_id) != str(module_id):
                        raise serializers.ValidationError(
                            f'Chapter {ch_id} does not belong to module {module_id}.'
                        )
                except ModuleChapter.DoesNotExist:
                    raise serializers.ValidationError(f'Chapter {ch_id} does not exist.')
        return value

    def validate(self, attrs):
        class_group = attrs.get('class_group')
        class_groups = attrs.get('class_groups')
        if class_groups is not None and len(class_groups) > 0:
            from gyaan_buddy.users.models import Class
            try:
                classes = list(Class.objects.filter(id__in=class_groups, is_active=True))
                if len(classes) != len(class_groups):
                    raise serializers.ValidationError({'class_groups': 'One or more class IDs are invalid or inactive.'})
                attrs['_class_groups_list'] = classes
            except Exception as e:
                if isinstance(e, serializers.ValidationError):
                    raise
                raise serializers.ValidationError({'class_groups': 'Invalid class IDs.'})
        elif not class_group:
            raise serializers.ValidationError('Provide either class_group (single class) or class_groups (list of class UUIDs).')
        module_chapters = attrs.get('module_chapters')
        module = attrs.get('module')
        module_chapter = attrs.get('module_chapter')
        if module_chapters is not None and len(module_chapters) > 0:
            attrs['module_chapters'] = self._validate_module_chapters_list(module_chapters)
        elif module and module_chapter:
            from gyaan_buddy.subjects.models import ModuleChapter
            try:
                ch = ModuleChapter.objects.get(id=module_chapter)
                if str(ch.module_id) != str(module):
                    raise serializers.ValidationError(
                        {'module_chapter': 'Chapter does not belong to the given module.'}
                    )
            except ModuleChapter.DoesNotExist:
                raise serializers.ValidationError({'module_chapter': 'Chapter does not exist.'})
            attrs['module_chapters'] = [{'module': str(module), 'chapters': [str(module_chapter)]}]
            attrs.pop('module', None)
            attrs.pop('module_chapter', None)
        else:
            raise serializers.ValidationError(
                'Provide either module_chapters (list of { module, chapters }) or legacy module and module_chapter.'
            )
        return attrs

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user:
            validated_data['created_by'] = request.user
        validated_data.pop('module', None)
        validated_data.pop('module_chapter', None)
        class_groups_list = validated_data.pop('_class_groups_list', None)
        validated_data.pop('class_groups', None)
        module_chapters_data = validated_data.pop('module_chapters')
        # When multiple class_groups are provided, create one test per class so each class gets its own test.
        if class_groups_list and len(class_groups_list) > 1:
            created_tests = []
            for class_instance in class_groups_list:
                test_data = validated_data.copy()
                test_data['class_group'] = class_instance
                test = Test.objects.create(**test_data)
                test.class_groups.set([class_instance])
                for item in module_chapters_data:
                    module_id = item['module']
                    for chapter_id in item['chapters']:
                        TestModuleChapter.objects.create(
                            test=test,
                            module_id=module_id,
                            module_chapter_id=chapter_id
                        )
                created_tests.append(test)
            # Store list so view can return all; serializer contract returns first for backward compat.
            self._created_tests = created_tests
            return created_tests[0]
        if class_groups_list:
            validated_data['class_group'] = class_groups_list[0]
        test = Test.objects.create(**validated_data)
        if class_groups_list:
            test.class_groups.set(class_groups_list)
        elif validated_data.get('class_group'):
            test.class_groups.set([validated_data['class_group']])
        for item in module_chapters_data:
            module_id = item['module']
            for chapter_id in item['chapters']:
                TestModuleChapter.objects.create(
                    test=test,
                    module_id=module_id,
                    module_chapter_id=chapter_id
                )
        return test


class TestUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating Test. Accepts module_chapters and optionally class_groups."""
    test_datetime = IndianDateTimeField(help_text='Date and time in Indian time (Asia/Kolkata)', required=False)
    class_groups = serializers.ListField(
        child=serializers.UUIDField(),
        write_only=True,
        required=False,
        allow_empty=False,
        help_text='List of class UUIDs this test is assigned to'
    )
    module_chapters = serializers.ListField(
        child=serializers.DictField(),
        write_only=True,
        required=False,
        help_text='List of { module: uuid, chapters: [uuid] }'
    )

    class Meta:
        model = Test
        fields = ['test_datetime', 'duration', 'class_group', 'class_groups', 'subject', 'module_chapters']
    
    def validate(self, attrs):
        class_groups = attrs.get('class_groups')
        if class_groups is not None and len(class_groups) > 0:
            from gyaan_buddy.users.models import Class
            try:
                classes = list(Class.objects.filter(id__in=class_groups, is_active=True))
                if len(classes) != len(class_groups):
                    raise serializers.ValidationError({'class_groups': 'One or more class IDs are invalid or inactive.'})
                attrs['_class_groups_list'] = classes
            except serializers.ValidationError:
                raise
            except Exception:
                raise serializers.ValidationError({'class_groups': 'Invalid class IDs.'})
        return super().validate(attrs)

    def validate_module_chapters(self, value):
        if value is None:
            return value
        if not isinstance(value, list):
            raise serializers.ValidationError('module_chapters must be a list.')
        for item in value:
            if not isinstance(item, dict):
                raise serializers.ValidationError('Each item must be { module: uuid, chapters: [uuid] }.')
            module_id = item.get('module')
            chapters = item.get('chapters')
            if not module_id or not chapters or not isinstance(chapters, list):
                raise serializers.ValidationError('Each item must have module and chapters (non-empty list).')
            from gyaan_buddy.subjects.models import ModuleChapter
            for ch_id in chapters:
                try:
                    ch = ModuleChapter.objects.get(id=ch_id)
                    if str(ch.module_id) != str(module_id):
                        raise serializers.ValidationError(
                            f'Chapter {ch_id} does not belong to module {module_id}.'
                        )
                except ModuleChapter.DoesNotExist:
                    raise serializers.ValidationError(f'Chapter {ch_id} does not exist.')
        return value
    
    def update(self, instance, validated_data):
        module_chapters_data = validated_data.pop('module_chapters', None)
        class_groups_list = validated_data.pop('_class_groups_list', None)
        validated_data.pop('class_groups', None)  # M2M — handled via class_groups_list
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if class_groups_list is not None:
            instance.class_groups.set(class_groups_list)
            instance.class_group = class_groups_list[0]
        instance.save()
        if module_chapters_data is not None:
            TestModuleChapter.objects.filter(test=instance).delete()
            for item in module_chapters_data:
                module_id = item['module']
                for chapter_id in item['chapters']:
                    TestModuleChapter.objects.create(
                        test=instance,
                        module_id=module_id,
                        module_chapter_id=chapter_id
                    )
        return instance


class TestListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing tests."""
    test_datetime = IndianDateTimeField(read_only=True)
    class_group_name = serializers.SerializerMethodField()
    class_groups = serializers.SerializerMethodField()
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    name = serializers.SerializerMethodField(help_text='Display name: subject + class name')
    module_chapters_summary = serializers.SerializerMethodField()
    question_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Test
        fields = [
            'id', 'name', 'test_datetime', 'duration', 'class_group_name', 'class_groups',
            'subject_name', 'module_chapters_summary', 'question_count'
        ]

    def get_class_group_name(self, obj):
        primary = obj.class_group or (obj.class_groups.first() if getattr(obj, 'class_groups', None) and obj.class_groups.exists() else None)
        return primary.name if primary else None

    def get_class_groups(self, obj):
        classes = obj.get_assigned_classes() if hasattr(obj, 'get_assigned_classes') else []
        return [{'id': str(c.id), 'name': c.name} for c in classes]
    
    def get_name(self, obj):
        subject_name = obj.subject.name if obj.subject else ''
        classes = obj.get_assigned_classes() if hasattr(obj, 'get_assigned_classes') else []
        class_names = ', '.join(c.name for c in classes) if classes else (obj.class_group.name if obj.class_group else '')
        return f"{subject_name} {class_names}".strip() or 'Test'
    
    def get_module_chapters_summary(self, obj):
        qs = getattr(obj, '_prefetched_objects_cache', {}).get('module_chapters')
        if qs is None:
            qs = TestModuleChapter.objects.filter(test=obj).select_related('module', 'module_chapter').order_by('module', 'module_chapter')
        else:
            qs = sorted(qs, key=lambda t: (str(t.module_id), str(t.module_chapter_id)))
        return [f"{tmc.module.name}: {tmc.module_chapter.title}" for tmc in qs]


class TestWithProgressSerializer(serializers.ModelSerializer):
    """Serializer for Test with user progress. Supports multiple modules/chapters."""
    test_datetime = IndianDateTimeField(read_only=True)
    class_group_name = serializers.SerializerMethodField()
    class_groups = serializers.SerializerMethodField()
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    name = serializers.SerializerMethodField(help_text='Display name: subject + class name')
    subject_color = serializers.CharField(source='subject.color', read_only=True, allow_null=True)
    subject_logo = serializers.SerializerMethodField()
    module_chapters = serializers.SerializerMethodField()
    question_count = serializers.IntegerField(read_only=True)
    user_progress = serializers.SerializerMethodField()
    
    class Meta:
        model = Test
        fields = [
            'id', 'name', 'test_datetime', 'duration', 'class_group', 'class_group_name', 'class_groups',
            'subject', 'subject_name', 'subject_color', 'subject_logo',
            'module_chapters',
            'question_count', 'user_progress', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_class_group_name(self, obj):
        primary = obj.class_group or (obj.class_groups.first() if getattr(obj, 'class_groups', None) and obj.class_groups.exists() else None)
        return primary.name if primary else None

    def get_class_groups(self, obj):
        classes = obj.get_assigned_classes() if hasattr(obj, 'get_assigned_classes') else []
        return [{'id': str(c.id), 'name': c.name} for c in classes]
    
    def get_name(self, obj):
        subject_name = obj.subject.name if obj.subject else ''
        classes = obj.get_assigned_classes() if hasattr(obj, 'get_assigned_classes') else []
        class_names = ', '.join(c.name for c in classes) if classes else (obj.class_group.name if obj.class_group else '')
        return f"{subject_name} {class_names}".strip() or 'Test'
    
    def get_subject_logo(self, obj):
        if obj.subject:
            if obj.subject.logo_url:
                return obj.subject.logo_url
            elif obj.subject.logo:
                return obj.subject.logo.url
        return None
    
    def get_module_chapters(self, obj):
        """Same as TestSerializer."""
        qs = getattr(obj, '_prefetched_objects_cache', {}).get('module_chapters')
        if qs is None:
            qs = TestModuleChapter.objects.filter(test=obj).select_related('module', 'module_chapter').order_by('module', 'module_chapter')
        else:
            qs = sorted(qs, key=lambda t: (str(t.module_id), str(t.module_chapter_id)))
        by_module = {}
        for tmc in qs:
            mid = str(tmc.module.id)
            if mid not in by_module:
                by_module[mid] = {
                    'module_id': mid,
                    'module_name': tmc.module.name,
                    'chapters': []
                }
            by_module[mid]['chapters'].append({
                'id': str(tmc.module_chapter.id),
                'title': tmc.module_chapter.title
            })
        return list(by_module.values())
    
    def get_user_progress(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            try:
                progress = UserTestProgress.objects.get(account=request.user, test=obj)
                return UserTestProgressSerializer(progress).data
            except UserTestProgress.DoesNotExist:
                return None
        return None


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for Notification model."""
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    triggered_by_display = serializers.CharField(source='get_triggered_by_display', read_only=True)
    
    class Meta:
        from .models import Notification
        model = Notification
        fields = [
            'id', 'user', 'user_name', 'username', 'notification_id', 
            'data', 'type', 'type_display', 'triggered_by', 'triggered_by_display',
            'is_read', 'read_at', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class NotificationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating notifications."""
    
    class Meta:
        from .models import Notification
        model = Notification
        fields = ['user', 'notification_id', 'data', 'type', 'triggered_by']



class StudentPerformanceAnalyticsSerializer(serializers.Serializer):
    """Serializer for individual student performance analytics."""
    student_id = serializers.UUIDField()
    student_name = serializers.CharField()
    username = serializers.CharField()
    roll_number = serializers.IntegerField(allow_null=True)
    class_name = serializers.CharField(allow_null=True)
    
    total_questions_attempted = serializers.IntegerField()
    correct_answers = serializers.IntegerField()
    wrong_answers = serializers.IntegerField()
    accuracy_percentage = serializers.FloatField()
    avg_attempts_per_question = serializers.FloatField()
    first_attempt_success_rate = serializers.FloatField()
    
    modules_completed = serializers.IntegerField()
    modules_in_progress = serializers.IntegerField()
    total_modules = serializers.IntegerField()
    avg_module_completion = serializers.FloatField()
    chapters_completed = serializers.IntegerField()
    chapters_in_progress = serializers.IntegerField()
    
    total_exp = serializers.IntegerField()
    current_level = serializers.IntegerField(allow_null=True)
    exp_to_next_level = serializers.IntegerField()
    rewards = serializers.IntegerField()
    
    easy_accuracy = serializers.FloatField()
    medium_accuracy = serializers.FloatField()
    hard_accuracy = serializers.FloatField()
    
    hots_attempted = serializers.IntegerField()
    hots_correct = serializers.IntegerField()
    hots_accuracy = serializers.FloatField()


class SubjectPerformanceSerializer(serializers.Serializer):
    """Serializer for subject-wise performance."""
    subject_id = serializers.UUIDField()
    subject_name = serializers.CharField()
    subject_code = serializers.CharField()
    
    total_questions = serializers.IntegerField()
    attempted_questions = serializers.IntegerField()
    correct_answers = serializers.IntegerField()
    accuracy_percentage = serializers.FloatField()
    
    modules_total = serializers.IntegerField()
    modules_completed = serializers.IntegerField()
    avg_module_progress = serializers.FloatField()
    
    chapters_total = serializers.IntegerField()
    chapters_completed = serializers.IntegerField()
    avg_chapter_progress = serializers.FloatField()
    
    total_exp_earned = serializers.IntegerField()
    
    easy_total = serializers.IntegerField()
    easy_correct = serializers.IntegerField()
    medium_total = serializers.IntegerField()
    medium_correct = serializers.IntegerField()
    hard_total = serializers.IntegerField()
    hard_correct = serializers.IntegerField()


class ClassPerformanceSerializer(serializers.Serializer):
    """Serializer for class-wise performance."""
    class_id = serializers.UUIDField()
    class_name = serializers.CharField()
    grade_name = serializers.CharField(allow_null=True)
    
    total_students = serializers.IntegerField()
    active_students = serializers.IntegerField()
    
    avg_accuracy = serializers.FloatField()
    avg_exp = serializers.FloatField()
    avg_level = serializers.FloatField()
    
    total_questions_attempted = serializers.IntegerField()
    total_modules_completed = serializers.IntegerField()
    
    top_performer_name = serializers.CharField(allow_null=True)
    top_performer_accuracy = serializers.FloatField(allow_null=True)
    
    students_needing_attention = serializers.IntegerField()


class MissionAnalyticsSerializer(serializers.Serializer):
    """Serializer for mission analytics (user-specific missions)."""
    mission_id = serializers.UUIDField()
    mission_title = serializers.CharField()
    mission_date = serializers.DateField()
    account_username = serializers.CharField()
    account_name = serializers.CharField()
    subject_name = serializers.CharField(allow_null=True)
    module_name = serializers.CharField(allow_null=True)
    chapter_name = serializers.CharField(allow_null=True)
    
    status = serializers.CharField()
    is_started = serializers.BooleanField()
    is_completed = serializers.BooleanField()
    
    completion_percentage = serializers.FloatField()
    accuracy = serializers.FloatField()
    
    exp_earned = serializers.IntegerField()
    total_questions = serializers.IntegerField()
    questions_answered = serializers.IntegerField()
    correct_answers = serializers.IntegerField()


class MissionQuestionAnalyticsSerializer(serializers.Serializer):
    """Serializer for mission question-wise analytics."""
    question_id = serializers.UUIDField()
    question_text = serializers.CharField()
    question_order = serializers.IntegerField()
    difficulty = serializers.CharField()
    question_type = serializers.CharField()
    
    total_attempts = serializers.IntegerField()
    correct_attempts = serializers.IntegerField()
    accuracy = serializers.FloatField()
    avg_tries = serializers.FloatField()


class CompetitionAnalyticsSerializer(serializers.Serializer):
    """Serializer for competition analytics."""
    competition_id = serializers.UUIDField()
    competition_title = serializers.CharField()
    competition_code = serializers.CharField()
    subject_name = serializers.CharField()
    status = serializers.CharField()
    
    total_participants = serializers.IntegerField()
    completed_participants = serializers.IntegerField()
    
    avg_score = serializers.FloatField()
    max_score = serializers.IntegerField()
    min_score = serializers.IntegerField()
    
    avg_time_seconds = serializers.FloatField()
    avg_exp_earned = serializers.FloatField()
    
    total_questions = serializers.IntegerField()


class LeaderboardEntrySerializer(serializers.Serializer):
    """Serializer for leaderboard entries."""
    rank = serializers.IntegerField()
    student_id = serializers.UUIDField()
    student_name = serializers.CharField()
    username = serializers.CharField()
    profile_picture = serializers.URLField(allow_null=True)
    
    score = serializers.IntegerField()
    time_taken_seconds = serializers.IntegerField()
    accuracy = serializers.FloatField()
    exp_earned = serializers.IntegerField()


class SchoolOverviewSerializer(serializers.Serializer):
    """Serializer for school overview analytics."""
    school_id = serializers.UUIDField()
    school_name = serializers.CharField()
    
    total_students = serializers.IntegerField()
    total_teachers = serializers.IntegerField()
    total_classes = serializers.IntegerField()
    total_grades = serializers.IntegerField()
    total_subjects = serializers.IntegerField()
    
    avg_student_exp = serializers.FloatField()
    avg_student_level = serializers.FloatField()
    avg_accuracy = serializers.FloatField()
    
    total_questions_attempted = serializers.IntegerField()
    total_modules_completed = serializers.IntegerField()
    
    active_missions = serializers.IntegerField()
    active_competitions = serializers.IntegerField()


class GradePerformanceSerializer(serializers.Serializer):
    """Serializer for grade-wise performance."""
    grade_id = serializers.UUIDField()
    grade_name = serializers.CharField()
    
    total_classes = serializers.IntegerField()
    total_students = serializers.IntegerField()
    
    avg_accuracy = serializers.FloatField()
    avg_exp = serializers.FloatField()
    avg_level = serializers.FloatField()
    
    top_class_name = serializers.CharField(allow_null=True)
    top_class_accuracy = serializers.FloatField(allow_null=True)


class WeakAreaSerializer(serializers.Serializer):
    """Serializer for identifying weak areas."""
    area_type = serializers.CharField()
    area_id = serializers.UUIDField(allow_null=True)
    area_name = serializers.CharField()
    
    total_questions = serializers.IntegerField()
    correct_answers = serializers.IntegerField()
    accuracy = serializers.FloatField()
    
    recommendation = serializers.CharField()


class AnswerTrendSerializer(serializers.Serializer):
    """Serializer for answer trends over time."""
    date = serializers.DateField()
    total_answers = serializers.IntegerField()
    correct_answers = serializers.IntegerField()
    accuracy = serializers.FloatField()
    exp_earned = serializers.IntegerField()


class ProgressTrendSerializer(serializers.Serializer):
    """Serializer for progress trends over time."""
    date = serializers.DateField()
    modules_completed = serializers.IntegerField()
    chapters_completed = serializers.IntegerField()
    total_exp = serializers.IntegerField()
    level = serializers.IntegerField(allow_null=True)
