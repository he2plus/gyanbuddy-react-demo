from django.contrib import admin
from django.utils.safestring import mark_safe
from .models import (
    Subject, Module, Question, Option, Theory, ModuleContent, ModuleChapter, ChapterHOTS, Answer, ManualVerificationAnswer
)


@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = [
        'name', 
        'code', 
        'order',
        'logo_display',
        'color_display',
        'is_active', 
        'teacher_count',
        'class_count',
        'module_count',
        'created_by'
    ]
    
    list_display_links = ['name']
    
    list_filter = [
        'classes__school',
        'is_active',
        'created_at'
    ]

    search_fields = [
        'name',
        'code',
        'description'
    ]

    ordering = ['order']

    raw_id_fields = ['created_by']

    fieldsets = (
        ('Basic Information', {
            'fields': (
                'school',
                'name',
                'code',
                'description',
                'order',
                'logo',
                'logo_url',
                'color'
            )
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    readonly_fields = ['created_at', 'updated_at']

    def teacher_count(self, obj):
        return obj.teacher_count
    teacher_count.short_description = 'Teachers'
    
    def class_count(self, obj):
        return obj.class_count
    class_count.short_description = 'Classes'
    
    def module_count(self, obj):
        return obj.module_count
    module_count.short_description = 'Modules'
    
    def logo_display(self, obj):
        logo_url = None
        if obj.logo_url:
            logo_url = obj.logo_url
        elif obj.logo:
            logo_url = obj.logo.url if hasattr(obj.logo, 'url') else str(obj.logo)
        if logo_url:
            return mark_safe(
                f'<div style="display: flex; align-items: center; gap: 8px;">'
                f'<img src="{logo_url}" width="40" height="40" style="object-fit: contain; border-radius: 4px; border: 1px solid #ddd;" />'
                f'<a href="{logo_url}" target="_blank" style="font-size: 11px; color: #0066cc;">View</a>'
                f'</div>'
            )
        return "-"
    logo_display.short_description = 'Logo'

    def color_display(self, obj):
        if obj.color:
            color_code = f"#{obj.color}" if not obj.color.startswith('#') else obj.color
            return mark_safe(
                f'<div style="display: flex; align-items: center; gap: 8px;">'
                f'<div style="width: 30px; height: 30px; background-color: {color_code}; border: 1px solid #ddd; border-radius: 4px;"></div>'
                f'<span>{obj.color}</span>'
                f'</div>'
            )
        return "-"
    color_display.short_description = 'Color'
    
    def get_queryset(self, request):
        return super().get_queryset(request)
    
    actions = ['activate_subjects', 'deactivate_subjects']
    
    def activate_subjects(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} subjects were successfully activated.')
    activate_subjects.short_description = "Activate selected subjects"
    
    def deactivate_subjects(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} subjects were successfully deactivated.')
    deactivate_subjects.short_description = "Deactivate selected subjects"


@admin.register(Module)
class ModuleAdmin(admin.ModelAdmin):
    list_display = [
        'name',
        'subject',
        'class_instance',
        'order',
        'logo_display',
        'is_active',
        'is_enabled',
        'question_count',
        'chapter_count',
        'created_by'
    ]

    list_filter = [
        'subject__classes__school',
        'subject',
        'class_instance',
        'is_active',
        'is_enabled',
        'created_at'
    ]

    search_fields = [
        'name',
        'description',
        'subject__name',
        'class_instance__name'
    ]

    ordering = ['subject', 'order']

    raw_id_fields = ['subject', 'class_instance', 'created_by']

    fieldsets = (
        ('Basic Information', {
            'fields': (
                'name',
                'subject',
                'class_instance',
                'description',
                'order'
            )
        }),
        ('Media & Branding', {
            'fields': (
                'logo',
                'logo_url'
            )
        }),
        ('Status & Schedule', {
            'fields': (
                'is_active',
                'is_enabled',
            )
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def question_count(self, obj):
        return obj.question_count
    question_count.short_description = 'Questions'
    
    def logo_display(self, obj):
        logo_url = None
        if obj.logo_url:
            logo_url = obj.logo_url
        elif obj.logo:
            logo_url = obj.logo.url if hasattr(obj.logo, 'url') else str(obj.logo)
        if logo_url:
            return mark_safe(
                f'<div style="display: flex; align-items: center; gap: 8px;">'
                f'<img src="{logo_url}" width="40" height="40" style="object-fit: contain; border-radius: 4px; border: 1px solid #ddd;" />'
                f'<a href="{logo_url}" target="_blank" style="font-size: 11px; color: #0066cc;">View</a>'
                f'</div>'
            )
        return "-"
    logo_display.short_description = 'Logo'

    actions = ['activate_modules', 'deactivate_modules', 'enable_modules', 'disable_modules']
    
    def activate_modules(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} modules were successfully activated.')
    activate_modules.short_description = "Activate selected modules"
    
    def deactivate_modules(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} modules were successfully deactivated.')
    deactivate_modules.short_description = "Deactivate selected modules"
    
    def enable_modules(self, request, queryset):
        modules_to_enable = queryset.filter(is_enabled=False)
        updated = modules_to_enable.count()
        for module in modules_to_enable:
            module.is_enabled = True
            module.save()
        
        self.message_user(request, f'{updated} modules were successfully enabled.')
    enable_modules.short_description = "Enable selected modules"
    
    def disable_modules(self, request, queryset):
        updated = queryset.update(is_enabled=False)
        self.message_user(request, f'{updated} modules were successfully disabled.')
    disable_modules.short_description = "Disable selected modules"





@admin.register(Theory)
class TheoryAdmin(admin.ModelAdmin):
    list_display = [
        'title',
        'created_by',
        'description_preview',
        'created_at',
        'updated_at'
    ]
    
    list_filter = [
        'created_by',
        'created_at',
        'updated_at'
    ]
    
    search_fields = [
        'title',
        'description'
    ]
    
    ordering = ['title']
    
    raw_id_fields = ['created_by']
    
    fieldsets = (
        ('Content', {
            'fields': (
                'title',
                'description'
            )
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def description_preview(self, obj):
        return obj.description_preview
    description_preview.short_description = 'Description Preview'


@admin.register(ModuleChapter)
class ModuleChapterAdmin(admin.ModelAdmin):
    list_display = [
        'title',
        'module',
        'order',
        'is_enabled',
        'is_important',
        'has_hots',
        'max_questions',
        'content_count',
        'module_remaining',
        'due_days_remaining',
        'created_by'
    ]
    
    list_filter = [
        'module__subject__classes__school',
        'module__subject',
        'is_enabled',
        'is_important',
        'has_hots',
        'created_at'
    ]

    search_fields = [
        'title',
        'description',
        'module__name',
        'module__subject__name',
        'module__subject__id',
        'module__id',
    ]
    
    ordering = ['module', 'order']
    
    raw_id_fields = ['module', 'created_by']
    
    fieldsets = (
        ('Chapter Information', {
            'fields': (
                'title',
                'description',
                'order',
                'is_enabled',
                'is_important',
                'has_hots',
                'max_questions',
                'logo',
                'theory'
            )
        }),
        ('Module', {
            'fields': ('module', 'module_remaining', 'due_days_remaining')
        }),
        ('Schedule', {
            'fields': ('is_due', 'due_date')
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at', 'module_remaining', 'due_days_remaining', 'is_due']
    
    def content_count(self, obj):
        return obj.content_count
    content_count.short_description = 'Content Items'
    
    def module_remaining(self, obj):
        """Number of chapters remaining in the module after this one."""
        total = obj.module.chapters.filter(is_deleted=False).count()
        return max(0, total - obj.order)
    module_remaining.short_description = 'Chapters remaining in module'
    
    def due_days_remaining(self, obj):
        """Days remaining until due date, or overdue by X days."""
        if not obj.due_date:
            return '-'
        from django.utils import timezone
        today = timezone.now().date()
        delta = (obj.due_date - today).days
        if delta > 0:
            return f'{delta} days'
        if delta == 0:
            return 'Due today'
        return f'Overdue by {abs(delta)} days'
    due_days_remaining.short_description = 'Due'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('module', 'module__subject', 'created_by')
    
    actions = ['enable_chapters', 'disable_chapters']
    
    def enable_chapters(self, request, queryset):
        updated = queryset.update(is_enabled=True)
        self.message_user(request, f'{updated} chapters were successfully enabled.')
    enable_chapters.short_description = "Enable selected chapters"
    
    def disable_chapters(self, request, queryset):
        updated = queryset.update(is_enabled=False)
        self.message_user(request, f'{updated} chapters were successfully disabled.')
    disable_chapters.short_description = "Disable selected chapters"


@admin.register(ModuleContent)
class ModuleContentAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'content_type',
        'order',
        'module_info',
        'content_title',
        'created_by'
    ]
    
    list_filter = [
        'chapter__module__subject__classes__school',
        'content_type',
        'chapter__module',
        'chapter__module__subject',
        'created_at'
    ]

    search_fields = [
        'id',
        'question__question_text',
        'question__id',
        'theory__title',
        'theory__id',
        'chapter__id',
        'chapter__title',
        'chapter__module__name',
        'chapter__module__subject__name',
        'created_by__username',
        'created_by__email'
    ]
    
    ordering = ['order']
    
    raw_id_fields = ['chapter', 'question', 'theory', 'created_by']
    
    fieldsets = (
        ('Content Information', {
            'fields': (
                'chapter',
                'content_type',
                'order'
            )
        }),
        ('Content Links', {
            'fields': (
                'question',
                'theory'
            ),
            'description': 'Select either question or theory based on content type'
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def module_info(self, obj):
        if obj.chapter and obj.chapter.module:
            return f"{obj.chapter.module.name} ({obj.chapter.module.subject.name})"
        return "-"
    module_info.short_description = 'Module'
    
    def content_title(self, obj):
        return obj.content_title
    content_title.short_description = 'Content Title'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
             'question', 'theory', 'created_by', 'chapter', 'chapter__module', 'chapter__module__subject'
        )


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'question_text_short', 
        'image_preview',
        'question_type', 
        'difficulty_level',
        'level',
        'exp_points',
        'is_active',
        'is_hots',
        'ai_generated',
        'correct_answers_count',
        'options_count',
        'created_by'
    ]
    
    list_filter = [
        'question_type', 
        'difficulty_level', 
        'level',
        'is_active',
        'is_hots',
        'ai_generated',
        'created_at'
    ]
    
    search_fields = [
        'question_text',
        'id', 
    ]
    
    ordering = ['difficulty_level']
    
    raw_id_fields = ['created_by']
    
    fieldsets = (
        ('Question Information', {
            'fields': (
                'question_text', 
                'image',
                'question_type', 
                'difficulty_level',
                'level',
                'exp_points',
                'explanation',
                'hint'
            )
        }),
        ('Status', {
            'fields': ('is_active', 'is_hots', 'ai_generated')
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def question_text_short(self, obj):
        return obj.question_text[:50] + "..." if len(obj.question_text) > 50 else obj.question_text
    question_text_short.short_description = 'Question'
    
    def image_preview(self, obj):
        if obj.image:
            return mark_safe(f'<img src="{obj.image.url}" width="50" height="50" style="border-radius: 5px;" />')
        return "No Image"
    image_preview.short_description = 'Image'
    
    def correct_answers_count(self, obj):
        return obj.correct_answers_count
    correct_answers_count.short_description = 'Correct Answers'
    
    def options_count(self, obj):
        return obj.options_count
    options_count.short_description = 'Options'
    
    actions = ['activate_questions', 'deactivate_questions']
    
    def activate_questions(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} questions were successfully activated.')
    activate_questions.short_description = "Activate selected questions"
    
    def deactivate_questions(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} questions were successfully deactivated.')
    deactivate_questions.short_description = "Deactivate selected questions"


@admin.register(Option)
class OptionAdmin(admin.ModelAdmin):
    list_display = [
        'id',  
        'option_text_short', 
        'question_short', 
        'is_correct', 
        'order'
    ]
    
    list_filter = [
        'is_correct', 
        'question__question_type'
    ]
    
    search_fields = [
        'id',  
        'option_text', 
        'question__id',  
    ]
    
    ordering = ['question', 'order']
    
    raw_id_fields = ['question']
    
    fieldsets = (
        ('Option Information', {
            'fields': (
                'question', 
                'option_text', 
                'is_correct', 
                'order'
            )
        }),
    )
    
    def option_text_short(self, obj):
        return obj.option_text[:30] + "..." if len(obj.option_text) > 30 else obj.option_text
    option_text_short.short_description = 'Option'
    
    def question_short(self, obj):
        return obj.question.question_text[:30] + "..." if len(obj.question.question_text) > 30 else obj.question.question_text
    question_short.short_description = 'Question'


@admin.register(ChapterHOTS)
class ChapterHOTSAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'chapter',
        'question_short',
        'order',
        'created_by',
        'created_at'
    ]
    
    list_filter = [
        'chapter__module__subject__classes__school',
        'chapter__module__subject',
        'chapter__module',
        'created_at'
    ]

    search_fields = [
        'id',
        'chapter__title',
        'chapter__id',
        'question__question_text',
        'question__id',
        'chapter__module__name',
        'chapter__module__subject__name'
    ]

    ordering = ['chapter', 'order']

    raw_id_fields = ['chapter', 'question', 'created_by']

    fieldsets = (
        ('HOTS Question Information', {
            'fields': (
                'chapter',
                'question',
                'order'
            )
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def question_short(self, obj):
        return obj.question.question_text[:50] + "..." if len(obj.question.question_text) > 50 else obj.question.question_text
    question_short.short_description = 'Question'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'chapter', 'chapter__module', 'chapter__module__subject', 'question', 'created_by'
        )


@admin.register(Answer)
class AnswerAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'user',
        'test',
        'question_short',
        'answer_short',
        'is_correct',
        'tries',
        'prev_exp',
        'current_Exp',
        'from_mission',
        'created_at'
    ]
    
    list_filter = [
        'user__profile__school',
        'test',
        'is_correct',
        'tries',
        'from_mission',
        'created_at',
        'question__question_type',
        'question__difficulty_level'
    ]

    search_fields = [
        'id',
        'user__username',
        'user__email',
        'question__question_text',
        'question__id',
        'answer',
        'test__id',
        'test__subject__name'
    ]

    ordering = ['-created_at']

    raw_id_fields = ['user', 'question', 'test']

    fieldsets = (
        ('Answer Information', {
            'fields': (
                'user',
                'question',
                'test',
                'answer',
                'is_correct',
                'tries'
            )
        }),
        ('Experience Points', {
            'fields': (
        'prev_exp',
        'current_Exp'
            )
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def question_short(self, obj):
        return obj.question.question_text[:50] + "..." if len(obj.question.question_text) > 50 else obj.question.question_text
    question_short.short_description = 'Question'
    
    def answer_short(self, obj):
        return obj.answer[:50] + "..." if len(obj.answer) > 50 else obj.answer
    answer_short.short_description = 'Answer'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'user', 'question', 'test', 'test__subject'
        )


@admin.register(ManualVerificationAnswer)
class ManualVerificationAnswerAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'user',
        'question_short',
        'answer_short',
        'created_at'
    ]
    
    list_filter = [
        'user__profile__school',
        'created_at',
        'question__question_type',
        'question__difficulty_level'
    ]

    search_fields = [
        'id',
        'user__username',
        'user__email',
        'question__question_text',
        'question__id',
        'answer'
    ]

    ordering = ['-created_at']

    raw_id_fields = ['user', 'question']

    fieldsets = (
        ('Answer Information', {
            'fields': (
                'user',
                'question',
                'answer'
            )
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    readonly_fields = ['created_at', 'updated_at']

    def question_short(self, obj):
        return obj.question.question_text[:50] + "..." if len(obj.question.question_text) > 50 else obj.question.question_text
    question_short.short_description = 'Question'

    def answer_short(self, obj):
        return obj.answer[:50] + "..." if len(obj.answer) > 50 else obj.answer
    answer_short.short_description = 'Answer'

    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'user', 'question'
        )
