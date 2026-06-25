from django.db.models import Max
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers
from rest_framework.serializers import empty
from rest_framework.exceptions import ValidationError
import logging
from .models import (
    Subject, Module, Question, Option, Theory, ModuleContent, ModuleChapter, PdfReference,
)
from .helpers import normalize_question_type
from gyaan_buddy.users.models import User
from gyaan_buddy.users.serializers import UserSerializer

logger = logging.getLogger('gyaan_buddy.subjects')


class SafeImageField(serializers.ImageField):
    def to_representation(self, value):
        if not value:
            return None
        try:
            return super().to_representation(value)
        except Exception:
            return None


class SubjectSerializer(serializers.ModelSerializer):
    teacher_count = serializers.ReadOnlyField()
    class_count = serializers.ReadOnlyField()
    class_list = serializers.SerializerMethodField()
    module_count = serializers.ReadOnlyField()
    logo = SafeImageField(required=False, allow_null=True)
    logo_url = serializers.URLField(required=False, allow_blank=True)
    effective_logo_url = serializers.SerializerMethodField()
    has_due_module = serializers.SerializerMethodField()
    code = serializers.CharField(required=False, allow_blank=True)
    school_name = serializers.CharField(source='school.name', read_only=True)

    class Meta:
        model = Subject
        fields = [
            'id', 'name', 'code', 'description', 'logo', 'logo_url', 'effective_logo_url', 'color', 'is_active',
            'order', 'school', 'school_name', 'teacher_count', 'class_count', 'class_list', 'module_count', 'has_due_module',
            'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'school', 'created_at', 'updated_at', 'teacher_count', 'class_count', 'module_count', 'effective_logo_url', 'has_due_module']
    
    def validate(self, attrs):
        if not attrs.get('code') and attrs.get('name'):
            attrs['code'] = attrs['name'][:3].upper()
        return attrs
    
    def get_class_list(self, obj):
        request = self.context.get('request')
        if (request and hasattr(request.user, 'profile') and request.user.profile
                and request.user.profile.user_type == 'teacher'
                and hasattr(request.user.profile, 'teacher_profile')):
            from gyaan_buddy.users.models import Teacher as TeacherAssignment
            return list(
                TeacherAssignment.objects.filter(
                    teacher=request.user.profile.teacher_profile,
                    subject=obj,
                    is_deleted=False,
                ).values('class_instance__id', 'class_instance__name').distinct()
            )
        return obj.class_list

    def get_effective_logo_url(self, obj):
        return obj.get_logo_url

    def get_has_due_module(self, obj):
        # Return True if any active module has a due chapter that the user hasn't completed yet
        from gyaan_buddy.users.models import UserChapterProgress
        from gyaan_buddy.subjects.models import ModuleChapter
        request = self.context.get('request')

        qs_filter = dict(
            module__subject=obj,
            module__is_active=True,
            due_date__isnull=False,
            is_deleted=False,
        )

        # Narrow to the student's enrolled class so due chapters from other classes don't bleed through
        if (request and request.user.is_authenticated
                and hasattr(request.user, 'profile')
                and request.user.profile
                and hasattr(request.user.profile, 'student')
                and request.user.profile.student.class_instance_id):
            qs_filter['module__class_instance_id'] = request.user.profile.student.class_instance_id

        due_chapters_qs = ModuleChapter.objects.filter(**qs_filter)

        if not request or not request.user.is_authenticated:
            return due_chapters_qs.exists()

        completed_chapter_ids = UserChapterProgress.objects.filter(
            account=request.user,
            chapter__in=due_chapters_qs,
            status='completed',
        ).values_list('chapter_id', flat=True)
        return due_chapters_qs.exclude(id__in=completed_chapter_ids).exists()


class ModuleSerializer(serializers.ModelSerializer):
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    class_instance_name = serializers.CharField(source='class_instance.name', read_only=True)
    question_count = serializers.ReadOnlyField()
    chapter_count = serializers.ReadOnlyField()
    active_chapter_count = serializers.ReadOnlyField()
    due_chapter_count = serializers.ReadOnlyField()
    total_chapter_count = serializers.ReadOnlyField()
    status = serializers.SerializerMethodField()
    user_percentage = serializers.SerializerMethodField()
    current_question_id = serializers.SerializerMethodField()
    logo = serializers.SerializerMethodField()
    is_due = serializers.SerializerMethodField()
    due_date = serializers.SerializerMethodField()

    class Meta:
        model = Module
        fields = [
            'id', 'name', 'subject', 'subject_name', 'class_instance', 'class_instance_name',
            'description', 'order', 'logo',
            'is_active', 'is_enabled', 'is_due', 'due_date', 'question_count', 'chapter_count', 'active_chapter_count', 'due_chapter_count', 'total_chapter_count', 'status', 'user_percentage', 'current_question_id', 'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'question_count', 'chapter_count', 'active_chapter_count', 'due_chapter_count', 'total_chapter_count', 'status', 'user_percentage', 'current_question_id', 'is_due', 'due_date']

    def get_logo(self, obj):
        return obj.get_logo_url

    def get_is_due(self, obj):
        # due_date lives on Chapter, not Module
        return obj.chapters.filter(due_date__isnull=False, is_deleted=False).exists()

    def get_due_date(self, obj):
        # Return the earliest active chapter due_date for this module
        earliest = obj.chapters.filter(
            due_date__isnull=False, is_deleted=False
        ).order_by('due_date').values_list('due_date', flat=True).first()
        return str(earliest) if earliest else None
    
    def _get_module_progress(self, obj):
        if not hasattr(self, '_module_progress_cache'):
            self._module_progress_cache = {}
        
        module_id = obj.id
        if module_id not in self._module_progress_cache:
            request = self.context.get('request')
            if request and request.user.is_authenticated:
                try:
                    from gyaan_buddy.users.models import UserModuleProgress
                    progress = UserModuleProgress.objects.filter(
                        account=request.user,
                        module=obj
                    ).select_related('current_question').first()
                    self._module_progress_cache[module_id] = progress
                except Exception:
                    self._module_progress_cache[module_id] = None
            else:
                self._module_progress_cache[module_id] = None
        
        return self._module_progress_cache[module_id]
    
    def get_status(self, obj):
        progress = self._get_module_progress(obj)
        return progress.status if progress else 'not_started'
    
    def get_user_percentage(self, obj):
        progress = self._get_module_progress(obj)
        return progress.percentage if progress else 0
    
    def get_current_question_id(self, obj):
        progress = self._get_module_progress(obj)
        if progress and progress.current_question:
            return progress.current_question.id
        return None


class ModuleChapterSerializer(serializers.ModelSerializer):
    content_count = serializers.ReadOnlyField()
    status = serializers.SerializerMethodField()
    current_question_id = serializers.SerializerMethodField()
    logo = SafeImageField(required=False, allow_null=True)
    module = serializers.PrimaryKeyRelatedField(queryset=Module.objects.all(), required=False)
    is_due = serializers.SerializerMethodField()
    
    class Meta:
        model = ModuleChapter
        fields = [
            'id', 'module', 'title', 'description', 'theory', 'order', 'is_enabled', 'is_important', 'is_due', 'due_date', 'max_questions', 'logo', 'content_count',
            'status', 'current_question_id', 'created_by', 'created_at', 'updated_at', 'has_hots',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'content_count', 'status', 'current_question_id', 'created_by', 'is_due']
    
    def get_is_due(self, obj):
        return obj.due_date is not None
    
    def update(self, instance, validated_data):
        from django.utils import timezone
        if 'due_date' not in self.initial_data and self.initial_data.get('is_due') is not None:
            is_due = self.initial_data.get('is_due')
            validated_data['due_date'] = timezone.now().date() if is_due else None
        updated = super().update(instance, validated_data)
        return updated

    def _ensure_unique_module_order(self, attrs):
        """Set order to next available for the module when (module, order) would conflict. Call before run_validators."""
        module = attrs.get('module')
        if self.instance:
            module = module if module is not None else self.instance.module
        if module is None:
            return attrs
        order = attrs.get('order')
        if self.instance and order is None:
            order = self.instance.order
        qs = ModuleChapter.objects.filter(module=module, is_deleted=False)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if order is None or qs.filter(order=order).exists():
            max_order = ModuleChapter.objects.filter(
                module=module, is_deleted=False
            ).aggregate(Max('order'))['order__max'] or 0
            attrs['order'] = max_order + 1
        return attrs

    def run_validation(self, data=empty):
        """Apply order fix after to_internal_value and before run_validators so (module, order) never conflicts."""
        (is_empty_value, data) = self.validate_empty_values(data)
        if is_empty_value:
            if self.required:
                raise self.fail('required')
            return self.get_initial()
        value = self.to_internal_value(data)
        value = self._ensure_unique_module_order(value)
        try:
            self.run_validators(value)  # runs validators in place; does not return value
            value = self.validate(value)
            return value
        except (ValidationError, DjangoValidationError) as exc:
            raise serializers.ValidationError(
                detail=serializers.as_serializer_error(exc)
            )

    def validate(self, attrs):
        """Optional extra validation; order already ensured by _ensure_unique_module_order."""
        return attrs
    
    def _get_chapter_progress(self, obj):
        if not hasattr(self, '_chapter_progress_cache'):
            self._chapter_progress_cache = {}
        
        chapter_id = obj.id
        if chapter_id not in self._chapter_progress_cache:
            request = self.context.get('request')
            if request and request.user.is_authenticated:
                try:
                    from gyaan_buddy.users.models import UserChapterProgress
                    progress = UserChapterProgress.objects.filter(
                        account=request.user,
                        chapter=obj
                    ).select_related('current_question').first()
                    self._chapter_progress_cache[chapter_id] = progress
                except Exception:
                    self._chapter_progress_cache[chapter_id] = None
            else:
                self._chapter_progress_cache[chapter_id] = None
        
        return self._chapter_progress_cache[chapter_id]
    
    def get_status(self, obj):
        progress = self._get_chapter_progress(obj)
        return progress.status if progress else 'not_started'
    
    def get_current_question_id(self, obj):
        progress = self._get_chapter_progress(obj)
        if progress and progress.current_question:
            return progress.current_question.id
        return None


class ModuleWithProgressSerializer(ModuleSerializer):
    user_status = serializers.SerializerMethodField(help_text='User progress status for this module')
    user_percentage = serializers.SerializerMethodField(help_text='User completion percentage (0-100)')
    started_at = serializers.SerializerMethodField(help_text='When user started this module')
    last_accessed = serializers.SerializerMethodField(help_text='Last time user accessed this module')
    
    class Meta(ModuleSerializer.Meta):
        fields = ModuleSerializer.Meta.fields + [
            'user_status', 'user_percentage', 'started_at', 'last_accessed'
        ]
    
    def _get_user_progress(self, obj):
        if not hasattr(self, '_user_progress_cache'):
            self._user_progress_cache = {}
        
        module_id = obj.id
        if module_id not in self._user_progress_cache:
            request = self.context.get('request')
            if request and request.user.is_authenticated:
                try:
                    user_progress = obj.user_progress.filter(account=request.user).first()
                    self._user_progress_cache[module_id] = user_progress
                except Exception:
                    self._user_progress_cache[module_id] = None
            else:
                self._user_progress_cache[module_id] = None
        
        return self._user_progress_cache[module_id]
    
    def get_user_status(self, obj):
        request = self.context.get('request')
        user_progress = obj.user_progress.filter(account=request.user).first()
        return user_progress.status if user_progress else 'not_started'
    
    def get_user_percentage(self, obj):
        user_progress = self._get_user_progress(obj)
        return user_progress.percentage if user_progress else 0
    
    def get_started_at(self, obj):
        user_progress = self._get_user_progress(obj)
        return user_progress.started_at if user_progress else None
    
    def get_last_accessed(self, obj):
        user_progress = self._get_user_progress(obj)
        return user_progress.last_accessed if user_progress else None


class OptionSerializer(serializers.ModelSerializer):
    question_text = serializers.CharField(source='question.question_text', read_only=True)
    
    class Meta:
        model = Option
        fields = [
            'id', 'question', 'question_text', 'option_text', 'is_correct',
            'order'
        ]
        read_only_fields = ['id']


class TheorySerializer(serializers.ModelSerializer):
    description_preview = serializers.ReadOnlyField()
    
    class Meta:
        model = Theory
        fields = [
            'id', 'title', 'description', 'description_preview',
            'created_by'
        ]
        read_only_fields = ['id', 'description_preview']


class QuestionSerializer(serializers.ModelSerializer):
    correct_answers_count = serializers.ReadOnlyField()
    options_count = serializers.ReadOnlyField()
    options = OptionSerializer(many=True, read_only=True)
    image = SafeImageField(required=False, allow_null=True)

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['question_type'] = normalize_question_type(instance.question_type)
        return data

    class Meta:
        model = Question
        fields = [
            'id', 'question_text', 'image', 'question_type', 'exp_points', 'difficulty_level', 'level', 'explanation',
            'hint', 'correct_answers_count', 'options_count', 'options', 'is_hots', 'ai_generated', 'is_active',
            'created_by'
        ]
        read_only_fields = ['id', 'correct_answers_count', 'options_count']


class ModuleContentSerializer(serializers.ModelSerializer):
    question = QuestionSerializer(read_only=True)
    theory = TheorySerializer(read_only=True)
    content_type_display = serializers.CharField(source='get_content_type_display', read_only=True)
    module_name = serializers.CharField(source='chapter.module.name', read_only=True)
    
    class Meta:
        model = ModuleContent
        fields = [
            'id', 'chapter', 'content_type', 'content_type_display', 'order',
            'question', 'theory', 'module_name', 'created_by'
        ]
        read_only_fields = ['id', 'content_type_display', 'module_name']


# ── Question Bank Serializer ──────────────────────────────────────────────────

class QuestionBankSerializer(QuestionSerializer):
    """QuestionSerializer extended with per-request context fields."""
    created_by_you = serializers.SerializerMethodField()
    your_school = serializers.SerializerMethodField()

    class Meta(QuestionSerializer.Meta):
        fields = QuestionSerializer.Meta.fields + ['created_by_you', 'your_school']

    def get_created_by_you(self, obj):
        request = self.context.get('request')
        if not request or not obj.created_by_id:
            return False
        return obj.created_by_id == request.user.id

    def get_your_school(self, obj):
        request = self.context.get('request')
        if not request:
            return False
        user = request.user
        user_school = getattr(getattr(user, 'profile', None), 'school_id', None)
        if not user_school or not obj.created_by_id:
            return False
        creator_school = getattr(getattr(obj.created_by, 'profile', None), 'school_id', None)
        return creator_school == user_school


# ── Assessment Generator Serializers ─────────────────────────────────────────

class PdfReferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = PdfReference
        fields = ['id', 'file_name', 'total_pages', 'embedding_status', 'is_default', 'created_at']
        read_only_fields = ['id', 'total_pages', 'embedding_status', 'created_at']



