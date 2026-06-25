import logging
from zoneinfo import ZoneInfo
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from .models import Mission, Test, Student

INDIAN_TZ = ZoneInfo('Asia/Kolkata')
from gyaan_buddy.utils.firebase_notifications import firebase_notification_service

logger = logging.getLogger(__name__)


@receiver(post_save, sender=Mission)
def send_mission_created_notification(sender, instance, created, **kwargs):
    if created and not instance.is_deleted:
        send_mission_notification_to_user(instance)


@receiver(post_save, sender=Test)
def send_test_created_notification(sender, instance, created, **kwargs):
    if created and not instance.is_deleted:
        send_test_notification_to_class_users(instance)


def send_mission_notification_to_user(mission):
    try:
        user = mission.account
        if not user or not user.is_active or user.is_deleted:
            logger.info(f"User not active for mission {mission.id}")
            return
        
        title = "🎯 Your next mission is ready"
        body = f"'{mission.title}' mission for {mission.mission_date} is now available!"
        
        data = {
            'type': 'mission_created',
            'mission_id': str(mission.id),
            'mission_title': mission.title,
            'mission_date': mission.mission_date.isoformat(),
            'subject_name': mission.subject.name if mission.subject else '',
            'chapter_name': mission.module_chapter.name if mission.module_chapter else '',
            'action': 'open_mission'
        }
        
        success = firebase_notification_service.send_notification_to_user(
            user, title, body, data, 
            notification_type='mission', 
            triggered_by='auto'
        )
        
        if success:
            logger.info(f"Mission notification sent to user {user.username} for mission '{mission.title}'")
        else:
            logger.warning(f"Failed to send mission notification to user {user.username}")
        
    except Exception as e:
        logger.error(f"Failed to send mission notification: {str(e)}")


def send_test_notification_to_class_users(test):
    try:
        assigned_classes = getattr(test, 'get_assigned_classes', lambda: [])() or []
        if not assigned_classes and getattr(test, 'class_group', None):
            assigned_classes = [test.class_group]
        active_classes = [c for c in assigned_classes if c and getattr(c, 'is_active', True)]
        if not active_classes:
            logger.info(f"No active classes for test {test.id}")
            return

        class_ids = [c.id for c in active_classes]
        students_in_class = Student.objects.filter(
            class_instance_id__in=class_ids,
            is_deleted=False,
            user_profile__account__is_active=True,
            user_profile__account__is_deleted=False
        ).select_related('user_profile', 'user_profile__account')

        if not students_in_class.exists():
            logger.info(f"No students found in assigned classes for test {test.id}")
            return

        class_users = [student.user_profile.account for student in students_in_class]

        dt = test.test_datetime
        if timezone.is_naive(dt):
            dt = timezone.make_aware(dt, timezone.utc)
        dt_ist = dt.astimezone(INDIAN_TZ)
        test_datetime_str = dt_ist.strftime('%d %b %Y at %I:%M %p')
        
        title = "📝 New Test Upcoming!"
        subject_name = test.subject.name if test.subject else "Test"
        date_str = dt_ist.strftime('%-d %B %Y')
        body = f"{subject_name} test on {date_str}—start preparing now! 💪"
        
        class_names = ', '.join(c.name for c in active_classes)
        data = {
            'type': 'test_created',
            'test_id': str(test.id),
            'subject_name': test.subject.name if test.subject else '',
            'module_chapters_count': str(test.module_chapters.count()),
            'test_datetime': dt_ist.isoformat(),
            'duration': str(test.duration),
            'class_name': class_names,
            'action': 'open_test'
        }

        results = firebase_notification_service.send_notification_to_multiple_users(
            class_users, title, body, data,
            notification_type='test',
            triggered_by='auto'
        )
        
        logger.info(f"Test notification sent to {results['success']} students in classes '{class_names}' for test {test.id}. Failed: {results['failed']}")
        
    except Exception as e:
        logger.error(f"Failed to send test notification: {str(e)}")
