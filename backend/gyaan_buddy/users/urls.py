from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserViewSet, AuthViewSet, ClassViewSet, SchoolViewSet, GradeViewSet,
    MissionViewSet, CompetitionViewSet, UserMissionProgressViewSet, UserCompetitionProgressViewSet,
    UserModuleProgressViewSet, UserChapterProgressViewSet, DashboardViewSet, ReportsViewSet, AIServiceViewSet,
    NotificationViewSet, StudentViewSet, TeacherViewSet, AnalyticsViewSet, TestViewSet
)

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'students', StudentViewSet, basename='student')
router.register(r'teachers', TeacherViewSet, basename='teacher')
router.register(r'auth', AuthViewSet, basename='auth')
router.register(r'classes', ClassViewSet)
router.register(r'schools', SchoolViewSet)
router.register(r'grades', GradeViewSet)

router.register(r'missions', MissionViewSet, basename='mission')
router.register(r'competitions', CompetitionViewSet, basename='competition')
router.register(r'user-missions', UserMissionProgressViewSet, basename='user-mission')
router.register(r'user-competitions', UserCompetitionProgressViewSet, basename='user-competition')
router.register(r'user-modules', UserModuleProgressViewSet, basename='user-module')
router.register(r'user-chapters', UserChapterProgressViewSet, basename='user-chapter')
router.register(r'dashboard', DashboardViewSet, basename='dashboard')
router.register(r'reports', ReportsViewSet, basename='reports')
router.register(r'ai', AIServiceViewSet, basename='ai')

router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'analytics', AnalyticsViewSet, basename='analytics')
router.register(r'tests', TestViewSet, basename='test')

app_name = 'users'

urlpatterns = [
    path('', include(router.urls)),
]
