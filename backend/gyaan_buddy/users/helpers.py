import logging
from django.utils import timezone
from .models import Mission, UserMissionProgress
from gyaan_buddy.subjects.models import Question
from gyaan_buddy.subjects.helpers import normalize_question_type
from gyaan_buddy.utils.firebase_notifications import firebase_notification_service

logger = logging.getLogger(__name__)


def get_first_question(mission):
    mission_question = mission.mission_questions.order_by('order').first()
    return mission_question.question if mission_question else None


def get_next_question(mission, current_question):
    current_mission_question = mission.mission_questions.filter(question=current_question).first()
    if not current_mission_question:
        return None
    next_mission_question = mission.mission_questions.filter(
        order__gt=current_mission_question.order
    ).order_by('order').first()
    
    return next_mission_question.question if next_mission_question else None


def update_mission_progress(user, mission, status='in_progress'):
    if mission.account != user:
        raise ValueError(f"Mission {mission.id} does not belong to user {user.username}")
    user_progress, created = UserMissionProgress.objects.get_or_create(
        mission=mission,
        defaults={
            'status': status,
            'started_at': timezone.now()
        }
    )

    if not created:
        user_progress.save()

    return user_progress, created


def complete_mission(user, mission):
    try:
        if mission.account != user:
            raise ValueError(f"Mission {mission.id} does not belong to user {user.username}")
        user_progress = mission.progress
        was_already_completed = user_progress.status == 'completed'

        user_progress.status = 'completed'
        user_progress.completed_at = timezone.now()
        user_progress.save()

        mission_desc = f"{mission.subject.name} - {mission.module_chapter.name}"

        if not was_already_completed:
            try:
                exp_earned = user_progress.exp_earned or 0
                title = "Mission Completed!"
                body = f"Congratulations! You've completed '{mission_desc}'! You earned {exp_earned} experience points."
                
                data = {
                    'type': 'mission_completed',
                    'mission_id': str(mission.id),
                    'mission_subject': mission.subject.name,
                    'mission_chapter': mission.module_chapter.name,
                    'exp_earned': str(exp_earned),
                    'action': 'view_mission'
                }
                success = firebase_notification_service.send_notification_to_user(
                    user, title, body, data, 
                    notification_type='mission', 
                    triggered_by='auto'
                )
                
                if success:
                    logger.info(f"Mission completion notification sent to user {user.username} for mission '{mission_desc}'")
                else:
                    logger.warning(f"Failed to send mission completion notification to user {user.username}")
            except Exception as e:
                logger.error(f"Error sending mission completion notification to user {user.username}: {str(e)}")
        
        return True
    except UserMissionProgress.DoesNotExist:
        logger.warning(f"UserMissionProgress not found for user {user.username} and mission '{mission.title}'")
        return False


def format_question_options(question):
    """Format question options for API response."""
    options = question.options.all().order_by('order')
    options_data = []
    for option in options:
        options_data.append({
            'id': option.id,
            'option_text': option.option_text,
            'order': option.order,
            'is_correct': option.is_correct
        })
    return options_data


def format_question_data(question, mission):
    """Format question data for API response."""
    mission_question = mission.mission_questions.filter(question=question).first()
    question_order = mission_question.order if mission_question else 1
    total_questions = mission.mission_questions.count()
    
    return {
        'question_id': question.id,
        'question_text': question.question_text,
        'question_type': normalize_question_type(question.question_type),
        'difficulty_level': question.difficulty_level,
        'exp_points': question.exp_points,
        'order': question_order,
        'total_questions': total_questions,
        'options': format_question_options(question),
        'is_last': question_order == total_questions
    }


def handle_first_question_request(request, mission, api_logger, success, validation_error):
    api_logger.info(f"Mission next content requested by {request.user.username} (ID: {request.user.id}) for mission '{mission.title}' (ID: {mission.id}) from {request.META.get('REMOTE_ADDR', 'unknown')}")

    user_progress, created = update_mission_progress(request.user, mission)

    if created:
        api_logger.info(f"Created new UserMissionProgress for user {request.user.username} in mission '{mission.title}'")
    else:
        api_logger.info(f"Updated UserMissionProgress for user {request.user.username} in mission '{mission.title}'")

    first_question = get_first_question(mission)
    
    if first_question:
        api_logger.info(f"First question '{first_question.question_text[:50]}...' retrieved for mission '{mission.title}'")
        
        return success(
            data=format_question_data(first_question, mission),
            message="First question retrieved successfully"
        )
    else:
        api_logger.info(f"No questions found in mission '{mission.title}'")
        return validation_error({"error": "No questions found in this mission"})


def handle_next_question_request(request, mission, question_id, api_logger, success, validation_error):
    try:
        if mission.account != request.user:
            return validation_error({"error": "Mission does not belong to this user"})

        try:
            user_progress = mission.progress
            if user_progress and user_progress.status == 'completed':
                api_logger.info(f"Mission '{mission.title}' already completed by user {request.user.username}")
                return success(
                    data={'is_completed': True},
                    message="Mission already completed"
                )
        except UserMissionProgress.DoesNotExist:
            pass

        current_question = mission.questions.filter(id=question_id).first()
        if not current_question:
            return validation_error({"error": "Question not found in this mission"})

        next_question = get_next_question(mission, current_question)

        if next_question:
            api_logger.info(f"Next question '{next_question.question_text[:50]}...' found for mission '{mission.title}'")
            UserMissionProgress.objects.update_or_create(
                mission=mission,
                defaults={
                    'current_question': current_question
                }
            )
            return success(
                data=format_question_data(next_question, mission),
                message="Next question retrieved successfully"
            )
        else:
            complete_mission(request.user, mission)
            api_logger.info(f"Mission '{mission.title}' completed by user {request.user.username}")
            return success(
                data={'is_last': True},
                message="No more questions available"
            )
            
    except Exception as e:
        api_logger.error(f"Error getting next question: {str(e)}")
        return validation_error({"error": f"Failed to get next question: {str(e)}"})
