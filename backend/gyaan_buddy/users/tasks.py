"""
Celery tasks for the users app.
"""

from celery import shared_task
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

@shared_task
def send_notification_email(user_id, message):
    """
    Send notification email to user.
    """
    try:
        from .models import User
        from gyaan_buddy.utils.firebase_notifications import firebase_notification_service

        user = User.objects.get(id=user_id)
        firebase_notification_service.send_notification_to_user(
            user, "Gyaan Buddy", message, triggered_by='auto'
        )
        logger.info(f"Notification sent to user {user_id}: {message}")
        return f"Notification sent to user {user_id}"

    except User.DoesNotExist:
        logger.error(f"User {user_id} not found")
        return f"User {user_id} not found"
    except Exception as e:
        logger.error(f"Error sending notification to user {user_id}: {str(e)}")
        raise

@shared_task
def calculate_user_level(user_id):
    """
    Calculate and update user level based on experience points.
    """
    try:
        from .models import User
        
        user = User.objects.get(id=user_id)
        old_level = user.level
        
        new_level = min(user.experience_points // 1000 + 1, 100)
        
        if new_level != old_level:
            user.level = new_level
            user.save()
            
            send_notification_email.delay(
                user_id, 
                f"Congratulations! You've reached level {new_level}!"
            )
            
            logger.info(f"User {user_id} leveled up from {old_level} to {new_level}")
            return f"User leveled up from {old_level} to {new_level}"
        else:
            return f"User {user_id} level unchanged: {old_level}"
            
    except User.DoesNotExist:
        logger.error(f"User {user_id} not found")
        return f"User {user_id} not found"
    except Exception as e:
        logger.error(f"Error calculating level for user {user_id}: {str(e)}")
        raise

@shared_task
def process_mission_completion(user_id, mission_id):
    """
    Process mission completion and update user progress.
    """
    try:
        from .models import User, UserMissionProgress
        from ..subjects.models import Mission
        
        user = User.objects.get(id=user_id)
        mission = Mission.objects.get(id=mission_id)
        
        experience_earned = mission.experience_multiplier * 100
        
        user.experience_points += experience_earned
        user.save()
        
        progress, created = UserMissionProgress.objects.get_or_create(
            account=user,
            mission=mission,
            defaults={'status': 'completed', 'percentage': 100}
        )
        
        if not created:
            progress.status = 'completed'
            progress.percentage = 100
            progress.save()
        
        calculate_user_level.delay(user_id)
        
        send_notification_email.delay(
            user_id,
            f"Mission '{mission.title}' completed! +{experience_earned} XP"
        )
        
        logger.info(f"Mission {mission_id} completed by user {user_id}")
        return f"Mission completed: {experience_earned} XP earned"
        
    except Exception as e:
        logger.error(f"Error processing mission completion: {str(e)}")
        raise

@shared_task
def cleanup_expired_sessions():
    """
    Clean up expired user sessions and tokens.
    """
    try:
        from django.contrib.sessions.models import Session
        from django.utils import timezone
        
        expired_sessions = Session.objects.filter(expire_date__lt=timezone.now())
        count = expired_sessions.count()
        expired_sessions.delete()
        
        logger.info(f"Cleaned up {count} expired sessions")
        return f"Cleaned up {count} expired sessions"
        
    except Exception as e:
        logger.error(f"Error cleaning up sessions: {str(e)}")
        raise
