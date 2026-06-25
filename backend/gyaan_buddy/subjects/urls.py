from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    SubjectViewSet, ModuleViewSet, ModuleChapterViewSet,
    QuestionViewSet, OptionViewSet, generate_ai_questions, deactivate_ai_questions,
    activate_ai_questions, generate_ai_questions_gemini, generate_ai_questions_vertex,
    generate_chapter_image, execute_matplotlib_image,
    # Chapter PDF
    PdfUploadView, PdfListView, PdfDeleteView, PdfReactivateView,
    PdfPermanentDeleteView, PdfDownloadView,
    # Assessment Generator
    AssessmentGenerateView, AssessmentModifyView,
    # Question Bank
    QuestionBankView, QuestionBankAddToChapterView,
)

router = DefaultRouter()
router.register(r'subjects', SubjectViewSet)
router.register(r'modules', ModuleViewSet)
router.register(r'module_chapters', ModuleChapterViewSet)
router.register(r'questions', QuestionViewSet)
router.register(r'options', OptionViewSet)



app_name = 'subjects'

urlpatterns = [
    path('', include(router.urls)),
    path('ai/generate-questions/', generate_ai_questions, name='ai-generate-questions'),
    path('ai/generate-questions-gemini/', generate_ai_questions_gemini, name='ai-generate-questions-gemini'),
    path('ai/generate-questions-vertex/', generate_ai_questions_vertex, name='ai-generate-questions-vertex'),
    path('ai/deactivate-questions/', deactivate_ai_questions, name='ai-deactivate-questions'),
    path('ai/activate-questions/', activate_ai_questions, name='ai-activate-questions'),
    path('ai/generate-chapter-image/', generate_chapter_image, name='ai-generate-chapter-image'),
    path('ai/execute-matplotlib-image/', execute_matplotlib_image, name='ai-execute-matplotlib-image'),

    # ── Chapter PDF ────────────────────────────────────────────────────────────
    path('chapter-pdf/upload/', PdfUploadView.as_view(), name='chapter-pdf-upload'),
    path('chapter-pdf/', PdfListView.as_view(), name='chapter-pdf-list'),
    path('chapter-pdf/<uuid:pdf_id>/', PdfDeleteView.as_view(), name='chapter-pdf-delete'),
    path('chapter-pdf/<uuid:pdf_id>/reactivate/', PdfReactivateView.as_view(), name='chapter-pdf-reactivate'),
    path('chapter-pdf/<uuid:pdf_id>/permanent/', PdfPermanentDeleteView.as_view(), name='chapter-pdf-permanent-delete'),
    path('chapter-pdf/<uuid:pdf_id>/download/', PdfDownloadView.as_view(), name='chapter-pdf-download'),

    # ── Assessment Generator ───────────────────────────────────────────────────
    path('assessment/generate/', AssessmentGenerateView.as_view(), name='assessment-generate'),
    path('assessment/modify/', AssessmentModifyView.as_view(), name='assessment-modify'),

    # ── Question Bank ──────────────────────────────────────────────────────────
    path('question-bank/', QuestionBankView.as_view(), name='question-bank'),
    path('question-bank/add-to-chapter/', QuestionBankAddToChapterView.as_view(), name='question-bank-add-to-chapter'),
]
