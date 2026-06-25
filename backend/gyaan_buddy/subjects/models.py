import hashlib
import uuid
from django.conf import settings
from django.db import models
from django.core.validators import MinValueValidator
from gyaan_buddy.users.models import User, School
from gyaan_buddy.base_models import TimeStampUUID, SoftDeleteModel


class Subject(TimeStampUUID):
    school = models.ForeignKey(
        School,
        on_delete=models.CASCADE,
        related_name='subjects',
        help_text='School this subject belongs to'
    )

    name = models.CharField(
        max_length=100,
        help_text='Name of the subject'
    )

    code = models.CharField(
        max_length=10,
        help_text='Short code for the subject (unique per school)'
    )
    
    description = models.TextField(
        blank=True,
        help_text='Description of the subject'
    )
    
    logo = models.ImageField(
        upload_to='subject_logos/',
        blank=True,
        null=True,
        help_text='Logo image file for the subject (upload file)'
    )
    
    logo_url = models.URLField(
        blank=True,
        help_text='Logo URL for the subject (enter URL directly)'
    )
    
    color = models.CharField(
        max_length=6,
        default='0DA6F2',
        help_text='Hex color code for the subject (without #)'
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this subject is currently active'
    )
    
    order = models.IntegerField(
        default=0,
        help_text='Order of the subject for display'
    )
    
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_subjects',
        help_text='User who created this subject'
    )

    class Meta:
        db_table = 'subjects'
        verbose_name = 'Subject'
        verbose_name_plural = 'Subjects'
        ordering = ['order']
        unique_together = [['code', 'school']]
        indexes = [
            models.Index(fields=['school'], name='subject_school_idx'),
            models.Index(fields=['is_active'], name='subject_is_active_idx'),
            models.Index(fields=['name'], name='subject_name_idx'),
            models.Index(fields=['code'], name='subject_code_idx'),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.code})"

    @property
    def get_logo_url(self):
        if self.logo_url:
            return self.logo_url
        elif self.logo:
            return self.logo.url if hasattr(self.logo, 'url') else str(self.logo)
        return None

    @property
    def teacher_count(self):
        from gyaan_buddy.users.models import Teacher
        return Teacher.objects.filter(subject=self, is_deleted=False).values('teacher').distinct().count()

    @property
    def module_count(self):
        return self.modules.count()
    
    @property
    def class_count(self):
        return self.classes.count()

    @property
    def class_list(self):
        """Returns list of {id, name} for all classes that have this subject."""
        return list(self.classes.values('id', 'name'))


class Module(TimeStampUUID):
    name = models.CharField(
        max_length=100,
        help_text='Name of the module'
    )
    
    subject = models.ForeignKey(
        Subject,
        on_delete=models.CASCADE,
        related_name='modules',
        help_text='Subject this module belongs to'
    )

    class_instance = models.ForeignKey(
        'users.Class',
        on_delete=models.CASCADE,
        related_name='modules',
        help_text='Class this module belongs to'
    )

    description = models.TextField(
        blank=True,
        help_text='Description of the module'
    )
    
    order = models.PositiveIntegerField(
        default=1,
        help_text='Order of the module within the subject'
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this module is currently active'
    )
    
    logo = models.ImageField(
        upload_to='module_logos/',
        blank=True,
        null=True,
        help_text='Logo image file for the module (upload file)'
    )
    
    logo_url = models.URLField(
        blank=True,
        help_text='Logo URL for the module (enter URL directly)'
    )
    
    is_enabled = models.BooleanField(
        default=False,
        help_text='Whether this module is enabled for use'
    )
    # NOTE: due_date removed from Module — due dates belong to chapters, not modules.
    # To find "modules that have at least one due chapter", query:
    #   Module.objects.filter(chapters__due_date__isnull=False, chapters__is_deleted=False).distinct()

    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_modules',
        help_text='User who created this module'
    )
    
    class Meta:
        db_table = 'modules'
        verbose_name = 'Module'
        verbose_name_plural = 'Modules'
        ordering = ['subject', 'class_instance', 'order', 'name']
        unique_together = [['subject', 'class_instance', 'name']]
        indexes = [
            models.Index(fields=['subject'], name='module_subject_idx'),
            models.Index(fields=['class_instance'], name='module_class_idx'),
            models.Index(fields=['order'], name='module_order_idx'),
            models.Index(fields=['is_active'], name='module_is_active_idx'),
            models.Index(fields=['is_enabled'], name='module_is_enabled_idx'),
            models.Index(fields=['subject', 'order'], name='module_subject_order_idx'),
            models.Index(fields=['subject', 'is_active'], name='module_subject_active_idx'),
            models.Index(fields=['subject', 'is_enabled'], name='module_subject_enabled_idx'),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.subject.name}"
    
    @property
    def question_count(self):
        return ModuleContent.objects.filter(
            chapter__module=self,
            content_type='question',
            is_deleted=False
        ).count()
    
    @property
    def chapter_count(self):
        return self.chapters.count()
    
    @property
    def active_chapter_count(self):
        return self.chapters.filter(is_enabled=True, is_deleted=False).count()

    @property
    def due_chapter_count(self):
        return self.chapters.filter(due_date__isnull=False, is_deleted=False).count()

    @property
    def total_chapter_count(self):
        return self.chapters.filter(is_deleted=False).count()
    
    @property
    def get_logo_url(self):
        if self.logo_url:
            return self.logo_url
        elif self.logo:
            return self.logo.url if hasattr(self.logo, 'url') else str(self.logo)
        return None


class Theory(SoftDeleteModel):
    title = models.CharField(
        max_length=200,
        help_text='Title of the theory content'
    )
    
    description = models.TextField(
        help_text='Detailed description of the theory'
    )
    
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_theories',
        help_text='User who created this theory'
    )
    
    class Meta:
        db_table = 'theories'
        verbose_name = 'Theory'
        verbose_name_plural = 'Theories'
        ordering = ['title']
    
    def __str__(self):
        return self.title
    
    @property
    def description_preview(self):
        return self.description[:100] + '...' if len(self.description) > 100 else self.description


class Question(SoftDeleteModel):
    QUESTION_TYPE_CHOICES = [
        ('mcq_single', 'MCQ - Single Correct Answer'),
        ('mcq_multiple', 'MCQ - Multiple Correct Answers'),
        ('short_answer', 'Short Answer Question'),
        ('rearrange', 'Re-arrange'),
    ]
    
    question_text = models.TextField(
        help_text='The question text'
    )
    
    image = models.ImageField(
        upload_to='question_images/',
        blank=True,
        null=True,
        help_text='Optional image for the question'
    )
    
    question_type = models.CharField(
        max_length=20,
        choices=QUESTION_TYPE_CHOICES,
        default='mcq_single',
        help_text='Type of question'
    )
    
    exp_points = models.PositiveIntegerField(
        default=10,
        help_text='Experience points awarded for correct answer'
    )
    
    difficulty_level = models.CharField(
        max_length=10,
        choices=[
            ('easy', 'Easy'),
            ('medium', 'Medium'),
            ('hard', 'Hard'),
        ],
        default='medium',
        help_text='Difficulty level of the question'
    )
    
    explanation = models.TextField(
        blank=True,
        help_text='Explanation for the correct answer'
    )
    
    hint = models.TextField(
        blank=True,
        help_text='Hint to help the user answer the question'
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this question is currently active'
    )
    
    is_hots = models.BooleanField(
        default=False,
        help_text='Whether this question is a Higher Order Thinking Skills (HOTS) question'
    )
    
    ai_generated = models.BooleanField(
        default=False,
        help_text='Whether this question was generated by AI'
    )
    
    level = models.PositiveSmallIntegerField(
        choices=[
            (1, 'Level 1'),
            (2, 'Level 2'),
            (3, 'Level 3'),
            (4, 'Level 4'),
            (5, 'Level 5'),
        ],
        default=1,
        help_text='Question level (1-5)'
    )
    
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_questions',
        help_text='User who created this question'
    )
    
    class Meta:
        db_table = 'questions'
        verbose_name = 'Question'
        verbose_name_plural = 'Questions'
        ordering = ['difficulty_level', 'created_at']
    
    def __str__(self):
        return f"{self.question_text[:50]}..."
    
    @property
    def correct_answers_count(self):
        return self.options.filter(is_correct=True).count()

    @property
    def options_count(self):
        return self.options.count()


class ModuleChapter(SoftDeleteModel):
    module = models.ForeignKey(
        Module,
        on_delete=models.CASCADE,
        related_name='chapters',
        help_text='Module this chapter belongs to'
    )
    
    title = models.CharField(
        max_length=200,
        help_text='Title of the chapter'
    )
    
    description = models.TextField(
        blank=True,
        help_text='Description of the chapter'
    )
    
    order = models.PositiveIntegerField(
        default=1,
        help_text='Order of the chapter within the module'
    )
    
    is_enabled = models.BooleanField(
        default=True,
        help_text='Whether this chapter is currently enabled'
    )

    is_important = models.BooleanField(
        default=False,
        help_text='Whether this chapter is marked as important'
    )

    due_date = models.DateField(
        blank=True,
        null=True,
        help_text='Due date for this assignment/chapter'
    )
    
    is_due = models.BooleanField(
        default=False,
        help_text='Whether this assignment/chapter is marked as due'
    )
    
    due_date = models.DateField(
        blank=True,
        null=True,
        help_text='Due date for this assignment/chapter'
    )
    
    has_hots = models.BooleanField(
        default=False,
        help_text='Whether this chapter has Higher Order Thinking Skills (HOTS) questions'
    )
    
    max_questions = models.PositiveIntegerField(
        default=10,
        help_text='Maximum number of questions to send for this chapter'
    )
    
    theory = models.TextField(
        blank=True,
        help_text='Theory content for this chapter'
    )
    
    logo = models.ImageField(
        upload_to='chapter_logos/',
        blank=True,
        null=True,
        help_text='Logo image for the chapter'
    )
    
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text='User who created this chapter'
    )
    
    class Meta:
        db_table = 'module_chapters'
        verbose_name = 'Module Chapter'
        verbose_name_plural = 'Module Chapters'
        ordering = ['module', 'order']
        unique_together = ['module', 'order']
        indexes = [
            models.Index(fields=['module', 'due_date'], name='mc_module_due_idx'),
            models.Index(fields=['module', 'is_deleted'], name='mc_module_del_idx'),
            models.Index(fields=['due_date', 'is_deleted'], name='mc_due_del_idx'),
        ]

    def __str__(self):
        return f"{self.title} - {self.module.name}"

    @property
    def is_due(self):
        """A chapter is due when it has a due_date set. Single source of truth."""
        return self.due_date is not None

    @property
    def content_count(self):
        return self.contents.count()


class ModuleContent(SoftDeleteModel):
    CONTENT_TYPE_CHOICES = [
        ('question', 'Question'),
        ('theory', 'Theory'),
    ]
    
    chapter = models.ForeignKey(
        ModuleChapter,
        on_delete=models.CASCADE,
        related_name='contents',
        help_text='Chapter this content belongs to'
    )
    
    content_type = models.CharField(
        max_length=20,
        choices=CONTENT_TYPE_CHOICES,
        help_text='Type of content (question or theory)'
    )
    
    order = models.PositiveIntegerField(
        default=1,
        help_text='Order of this content within the chapter'
    )

    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='module_contents',
        help_text='Question if content_type is "question"'
    )
    
    theory = models.ForeignKey(
        Theory,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='module_contents',
        help_text='Theory if content_type is "theory"'
    )
    
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_module_contents',
        help_text='User who created this content'
    )
    
    class Meta:
        db_table = 'module_contents'
        verbose_name = 'Module Content'
        verbose_name_plural = 'Module Contents'
        ordering = ['chapter', 'order']
        unique_together = ['chapter','order']
    
    def __str__(self):
        content_name = self.question.question_text[:50] if self.content_type == 'question' and self.question else \
                      self.theory.title if self.content_type == 'theory' and self.theory else 'Unknown'
        return f"{self.get_content_type_display()}: {content_name} - {self.chapter.module.name}"
    
    def clean(self):
        from django.core.exceptions import ValidationError
        
        if self.content_type == 'question' and not self.question:
            raise ValidationError('Question must be set when content_type is "question"')
        
        if self.content_type == 'theory' and not self.theory:
            raise ValidationError('Theory must be set when content_type is "theory"')
        
        if self.content_type == 'question' and self.theory:
            raise ValidationError('Theory should not be set when content_type is "question"')
        
        if self.content_type == 'theory' and self.question:
            raise ValidationError('Question should not be set when content_type is "theory"')
    
    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)
    
    @property
    def content_title(self):
        if self.content_type == 'question' and self.question:
            return self.question.question_text[:100] + '...' if len(self.question.question_text) > 100 else self.question.question_text
        elif self.content_type == 'theory' and self.theory:
            return self.theory.title
        return 'Unknown Content'
    
    @property
    def content_preview(self):
        if self.content_type == 'question' and self.question:
            return self.question.question_text[:100] + '...' if len(self.question.question_text) > 100 else self.question.question_text
        elif self.content_type == 'theory' and self.theory:
            return self.theory.description_preview
        return 'No content available'


class Option(TimeStampUUID):
    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        related_name='options',
        help_text='Question this option belongs to'
    )
    
    option_text = models.CharField(
        max_length=500,
        help_text='The option text'
    )
    
    is_correct = models.BooleanField(
        default=False,
        help_text='Whether this option is correct'
    )
    
    order = models.PositiveIntegerField(
        default=1,
        help_text='Order of the option within the question'
    )
    
    class Meta:
        db_table = 'options'
        verbose_name = 'Option'
        verbose_name_plural = 'Options'
        ordering = ['question', 'order']
        unique_together = ['question', 'option_text']
    
    def __str__(self):
        return f"{self.option_text[:30]}... - {self.question.question_text[:30]}..."


class ChapterHOTS(TimeStampUUID):
    chapter = models.ForeignKey(
        ModuleChapter,
        on_delete=models.CASCADE,
        related_name='hots_questions',
        help_text='Chapter this HOTS question belongs to'
    )
    
    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        related_name='chapter_hots',
        help_text='HOTS question for this chapter'
    )
    
    order = models.PositiveIntegerField(
        default=1,
        help_text='Order of the HOTS question within the chapter'
    )
    
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_chapter_hots',
        help_text='User who created this HOTS question association'
    )
    
    class Meta:
        db_table = 'chapter_hots'
        verbose_name = 'Chapter HOTS'
        verbose_name_plural = 'Chapter HOTS'
        ordering = ['chapter', 'order']
        unique_together = ['chapter', 'question']
        indexes = [
            models.Index(fields=['chapter'], name='chapter_hots_chapter_idx'),
            models.Index(fields=['question'], name='chapter_hots_question_idx'),
            models.Index(fields=['chapter', 'order'], name='chapter_hots_chapter_order_idx'),
        ]
    
    def __str__(self):
        return f"{self.chapter.title} - {self.question.question_text[:50]}..."


class Answer(TimeStampUUID):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='answers',
        help_text='User who answered the question'
    )
    
    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        related_name='user_answers',
        help_text='Question that was answered'
    )
    
    is_correct = models.BooleanField(
        default=False,
        help_text='Whether the answer is correct'
    )
    
    answer = models.TextField(
        help_text='The answer text provided by the user'
    )
    
    tries = models.PositiveIntegerField(
        default=1,
        help_text='Number of attempts made for this question'
    )
    
    prev_exp = models.PositiveIntegerField(
        default=0,
        help_text='Previous experience points before answering this question'
    )
    
    current_Exp = models.PositiveIntegerField(
        default=0,
        db_column='current_exp',
        help_text='Current experience points after answering this question'
    )
    
    from_mission = models.BooleanField(
        default=False,
        help_text='Whether this answer was submitted from a mission'
    )
    
    test = models.ForeignKey(
        'users.Test',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='answers',
        help_text='Test this answer was submitted for (null if mission/practice)'
    )

    chapter = models.ForeignKey(
        ModuleChapter,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='answers',
        help_text='Chapter this answer belongs to (denormalized from question→ModuleContent→chapter for fast dashboard queries)',
    )

    class Meta:
        db_table = 'answers'
        verbose_name = 'Answer'
        verbose_name_plural = 'Answers'
        ordering = ['-created_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'question'],
                condition=models.Q(test__isnull=True),
                name='answer_user_question_non_test_unique',
            ),
            models.UniqueConstraint(
                fields=['user', 'question', 'test'],
                condition=models.Q(test__isnull=False),
                name='answer_user_question_test_unique',
            ),
        ]
        indexes = [
            models.Index(fields=['user'], name='answer_user_idx'),
            models.Index(fields=['question'], name='answer_question_idx'),
            models.Index(fields=['user', 'question'], name='answer_user_question_idx'),
            models.Index(fields=['is_correct'], name='answer_is_correct_idx'),
            # Dashboard-critical: all 6 metrics query through chapter + user + is_correct
            models.Index(fields=['chapter', 'user', 'is_correct'], name='answer_ch_user_correct_idx'),
            models.Index(fields=['chapter', 'is_correct'], name='answer_ch_correct_idx'),
            models.Index(fields=['user', 'chapter'], name='answer_user_chapter_idx'),
        ]

    def save(self, *args, **kwargs):
        # Auto-populate chapter from question → ModuleContent → chapter.
        # This denormalization lets dashboard queries avoid the 3-hop reverse join.
        if not self.chapter_id and self.question_id:
            try:
                content = ModuleContent.objects.filter(
                    question_id=self.question_id,
                    content_type='question',
                    is_deleted=False,
                ).values('chapter_id').first()
                if content:
                    self.chapter_id = content['chapter_id']
            except Exception:
                pass
        super().save(*args, **kwargs)

    @classmethod
    def bulk_create_with_chapter(cls, answers, **kwargs):
        """
        Drop-in replacement for Answer.objects.bulk_create() that ensures
        chapter_id is populated on every answer before insert.

        bulk_create() skips save(), so the auto-populate logic above is never
        called. This method resolves missing chapter_ids in a single bulk query
        before delegating to bulk_create().

        Usage:
            Answer.bulk_create_with_chapter(answer_objects, ignore_conflicts=True)
        """
        # Collect question_ids that still need a chapter resolved
        missing = [a for a in answers if not a.chapter_id and a.question_id]
        if missing:
            question_ids = list({a.question_id for a in missing})
            mapping = dict(
                ModuleContent.objects.filter(
                    question_id__in=question_ids,
                    content_type='question',
                    is_deleted=False,
                ).values_list('question_id', 'chapter_id')
            )
            for a in missing:
                chapter_id = mapping.get(a.question_id)
                if chapter_id:
                    a.chapter_id = chapter_id

        return cls.objects.bulk_create(answers, **kwargs)

    def __str__(self):
        return f"{self.user.username} - {self.question.question_text[:50]}... - {'Correct' if self.is_correct else 'Incorrect'}"


class ManualVerificationAnswer(TimeStampUUID):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='manual_verification_answers',
        help_text='User who provided the answer'
    )
    
    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        related_name='manual_verification_answers',
        help_text='Question that was answered'
    )
    
    answer = models.TextField(
        help_text='The answer text provided by the user that needs manual verification'
    )
    
    class Meta:
        db_table = 'manual_verification_answers'
        verbose_name = 'Manual Verification Answer'
        verbose_name_plural = 'Manual Verification Answers'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user'], name='mva_user_idx'),
            models.Index(fields=['question'], name='mva_question_idx'),
            models.Index(fields=['user', 'question'], name='mva_user_question_idx'),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.question.question_text[:50]}... - {self.answer[:30]}..."


# ── Assessment Generator Models ───────────────────────────────────────────────

class PdfReference(TimeStampUUID):
    """Tracks uploaded PDFs per chapter and their Qdrant embedding status.

    Storage layout (no triple storage):
    - GCS:        original PDF binary (read once during processing)
    - Qdrant:     vectors + chunk text in payload (text lives here, not in DB)
    - PostgreSQL: only this metadata row
    """

    EMBEDDING_STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('PROCESSING', 'Processing'),
        ('COMPLETED', 'Completed'),
        ('FAILED', 'Failed'),
    ]

    chapter = models.ForeignKey(
        'Module',
        on_delete=models.CASCADE,
        related_name='pdfs',
    )
    file_name = models.CharField(max_length=255)
    gcs_path = models.CharField(
        max_length=500,
        help_text='GCS path: gs://gyaanbuddy-media/pdfs/{class}/{subject}/{chapter}/{filename}.pdf',
    )
    file_hash = models.CharField(
        max_length=64,
        blank=True,
        help_text='SHA-256 of file bytes — used to skip duplicate uploads',
    )
    total_pages = models.IntegerField(null=True, blank=True)
    embedding_status = models.CharField(
        max_length=20,
        choices=EMBEDDING_STATUS_CHOICES,
        default='PENDING',
    )
    is_active = models.BooleanField(default=True)
    is_default = models.BooleanField(default=False, help_text='Default PDF for this chapter — cannot be deleted.')

    class Meta:
        db_table = 'pdf_references'
        verbose_name = 'PDF Reference'
        verbose_name_plural = 'PDF References'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.file_name} — {self.chapter.name} ({self.embedding_status})"


class AssessmentSession(models.Model):
    """Metadata record for a single MCQ generation request.

    Questions are stateless — returned as JSON and held by the UI.
    Only generation metadata is stored here for analytics and audit.
    """

    STATUS_CHOICES = [
        ('CREATED', 'Created'),
        ('GENERATING', 'Generating'),
        ('COMPLETED', 'Completed'),
        ('FAILED', 'Failed'),
    ]

    session_id = models.CharField(
        max_length=80,
        primary_key=True,
        help_text='Format: asmt_{uuid4}',
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='assessment_sessions',
    )
    class_ref = models.ForeignKey(
        'users.Class',
        on_delete=models.CASCADE,
        related_name='assessment_sessions',
    )
    subject = models.ForeignKey(
        'Subject',
        on_delete=models.CASCADE,
        related_name='assessment_sessions',
    )
    chapter = models.ForeignKey(
        'Module',
        on_delete=models.CASCADE,
        related_name='assessment_sessions',
    )
    topic_name = models.CharField(max_length=255, blank=True)
    num_questions_requested = models.IntegerField()
    num_questions_returned = models.IntegerField(
        null=True, blank=True,
        help_text='Actual number of valid questions the AI returned',
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='CREATED',
    )
    ai_model_used = models.CharField(max_length=50, blank=True)
    generation_time_ms = models.IntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'assessment_sessions'
        verbose_name = 'Assessment Session'
        verbose_name_plural = 'Assessment Sessions'
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if not self.session_id:
            self.session_id = f"asmt_{uuid.uuid4()}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.session_id} ({self.status})"


class QuestionModification(models.Model):
    """Audit log — one row each time the teacher modifies a generated question.

    Questions are stateless (held by the UI), so there is no FK to a question
    table. The question is identified by its client-side question_id string, and
    full before/after snapshots are stored in JSON fields.
    """

    MODIFICATION_TYPE_CHOICES = [
        ('REPHRASE', 'Rephrase'),
        ('CHANGE_DIFFICULTY', 'Change Difficulty'),
        ('CHANGE_OPTIONS', 'Change Options'),
        ('REGENERATE', 'Regenerate'),
        ('CUSTOM', 'Custom'),
    ]

    session = models.ForeignKey(
        AssessmentSession,
        on_delete=models.CASCADE,
        related_name='modifications',
    )
    question_id = models.CharField(
        max_length=80,
        help_text='Client-side question identifier (e.g. q_<uuid4> assigned by ai-service)',
    )
    modification_type = models.CharField(
        max_length=20,
        choices=MODIFICATION_TYPE_CHOICES,
    )
    user_instruction = models.TextField(blank=True)
    original_snapshot = models.JSONField(
        help_text='Full question JSON before modification',
    )
    modified_snapshot = models.JSONField(
        help_text='Full question JSON after modification',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'question_modifications'
        verbose_name = 'Question Modification'
        verbose_name_plural = 'Question Modifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['session', 'question_id'], name='qmod_session_q_idx'),
        ]

    def __str__(self):
        return f"{self.modification_type} on {self.question_id} at {self.created_at}"
