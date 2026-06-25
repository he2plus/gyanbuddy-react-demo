from django.utils import timezone
from .models import ModuleContent
from gyaan_buddy.users.models import UserChapterProgress, UserModuleProgress
import logging

logger = logging.getLogger(__name__)

VALID_QUESTION_TYPES = ('mcq_single', 'mcq_multiple', 'short_answer', 'rearrange')


def normalize_question_type(raw):
    if not raw or not isinstance(raw, str):
        return 'mcq_single'
    normalized = raw.strip().lower().replace('-', '').replace(' ', '_')
    if normalized == 'rearrange':
        return 'rearrange'
    if normalized in ('mcq_single', 'mcq_multiple', 'short_answer'):
        return normalized
    if normalized in ('mcqsingle', 'single', 'single_choice'):
        return 'mcq_single'
    if normalized in ('mcqmultiple', 'multiple', 'multiple_choice'):
        return 'mcq_multiple'
    if normalized in ('shortanswer', 'short'):
        return 'short_answer'
    return 'mcq_single'


def calculate_chapter_progress_percentage(chapter, current_content):
    total_content_count = ModuleContent.objects.filter(
        chapter=chapter,
        is_deleted=False
    ).count()
    
    if total_content_count > 0:
        return int((current_content.order / total_content_count) * 100)
    return 0


def update_chapter_progress(user, chapter, percentage, status):
    try:
        if status:
            correct_status = status
        else:
            if percentage == 100:
                correct_status = 'completed'
            elif percentage > 0:
                correct_status = 'in_progress'
            else:
                correct_status = 'not_started'

        if percentage == 100 and correct_status != 'completed':
            correct_status = 'completed'
        elif percentage > 0 and percentage < 100 and correct_status == 'completed':
            correct_status = 'in_progress'
        elif percentage == 0 and correct_status not in ['not_started', 'due']:
            correct_status = 'not_started'

        user_chapter_progress, created = UserChapterProgress.objects.get_or_create(
            account=user,
            chapter=chapter,
            defaults={
                'status': correct_status,
                'percentage': percentage,
                'started_at': timezone.now()
            }
        )
        
        logger.info(f"Chapter progress - Created: {created}, Current status: {user_chapter_progress.status}, Current percentage: {user_chapter_progress.percentage}, New percentage: {percentage}, New status: {correct_status}")

        if not created:
            user_chapter_progress.percentage = percentage
            user_chapter_progress.status = correct_status

            if correct_status == 'completed':
                if not user_chapter_progress.completed_at:
                    user_chapter_progress.completed_at = timezone.now()
                logger.info(f"Chapter '{chapter.title}' status updated to 'completed' for user {user.username}")
            elif correct_status == 'in_progress':
                if not user_chapter_progress.started_at:
                    user_chapter_progress.started_at = timezone.now()
                logger.info(f"Chapter '{chapter.title}' status updated to 'in_progress' for user {user.username}")
            elif correct_status == 'not_started':
                logger.info(f"Chapter '{chapter.title}' status updated to 'not_started' for user {user.username}")
            
            user_chapter_progress.save()
            logger.info(f"Chapter '{chapter.title}' saved with status: {user_chapter_progress.status}, percentage: {user_chapter_progress.percentage}")

            user_chapter_progress.refresh_from_db()
            logger.info(f"Chapter '{chapter.title}' after refresh - status: {user_chapter_progress.status}, percentage: {user_chapter_progress.percentage}")
        
        return user_chapter_progress, created

    except Exception as e:
        raise Exception(f"Error updating chapter progress for user {user.username}: {str(e)}")


def update_module_progress(user, module):
    try:
        completed_chapters = UserChapterProgress.objects.filter(
            account=user,
            chapter__module=module,
            status='completed'
        ).count()

        total_chapters = module.chapters.filter(is_deleted=False, is_enabled=True).count()
        logger.info(f"Module '{module.name}' - Completed chapters: {completed_chapters}, Total chapters: {total_chapters}")

        if total_chapters > 0:
            module_percentage = int((completed_chapters / total_chapters) * 100)
        else:
            module_percentage = 100

        logger.info(f"Calculated module percentage: {module_percentage}%")

        if module_percentage == 100:
            correct_status = 'completed'
        elif module_percentage > 0:
            correct_status = 'in_progress'
        else:
            correct_status = 'not_started'

        user_module_progress, created = UserModuleProgress.objects.get_or_create(
            account=user,
            module=module,
            defaults={
                'status': correct_status,
                'percentage': module_percentage,
                'started_at': timezone.now()
            }
        )

        logger.info(f"Module progress - Created: {created}, Current status: {user_module_progress.status}, Current percentage: {user_module_progress.percentage}, New percentage: {module_percentage}, Correct status: {correct_status}")

        if not created:
            user_module_progress.percentage = module_percentage
            user_module_progress.status = correct_status

            if correct_status == 'completed':
                user_module_progress.completed_at = timezone.now()
                logger.info(f"Module '{module.name}' status updated to 'completed' for user {user.username}")
            elif correct_status == 'in_progress' and user_module_progress.status == 'not_started':
                user_module_progress.started_at = timezone.now()
                logger.info(f"Module '{module.name}' status updated to 'in_progress' for user {user.username}")
            elif correct_status == 'not_started':
                logger.info(f"Module '{module.name}' status updated to 'not_started' for user {user.username}")
            
            user_module_progress.save()
            logger.info(f"Module '{module.name}' saved with status: {user_module_progress.status}, percentage: {user_module_progress.percentage}")

            user_module_progress.refresh_from_db()
            logger.info(f"Module '{module.name}' after refresh - status: {user_module_progress.status}, percentage: {user_module_progress.percentage}")
        
        if module_percentage == 100:
            logger.info(f"Module '{module.name}' marked as completed for user {user.username} after completing all chapters")
        else:
            logger.info(f"Module '{module.name}' progress updated to {module_percentage}% for user {user.username}")

        return user_module_progress, created, module_percentage

    except Exception as e:
        raise Exception(f"Error updating module progress for user {user.username}: {str(e)}")


def complete_chapter_and_update_module(user, chapter):
    try:
        update_chapter_progress(user, chapter, 100, 'completed')
        logger.info(f"Chapter '{chapter.title}' marked as completed for user {user.username}")

        module = chapter.module
        logger.info(f"Updating module progress for module '{module.name}' (ID: {module.id}) with {module.chapter_count} total chapters")

        user_module_progress, created, module_percentage = update_module_progress(user, module)
        
        logger.info(f"Module progress update completed - Final status: {user_module_progress.status}, Final percentage: {user_module_progress.percentage}")
        
        return user_module_progress, created, module_percentage
        
    except Exception as e:
        raise Exception(f"Error completing chapter for user {user.username}: {str(e)}")


def fix_existing_module_progress():
    try:
        from gyaan_buddy.users.models import UserModuleProgress, UserChapterProgress

        problematic_modules = UserModuleProgress.objects.filter(
            percentage=100,
            status='in_progress'
        )
        
        fixed_count = 0
        for progress in problematic_modules:
            progress.status = 'completed'
            progress.completed_at = timezone.now()
            progress.save()
            fixed_count += 1
            logger.info(f"Fixed module progress for user {progress.account.username} in module {progress.module.name}")
        
        logger.info(f"Fixed {fixed_count} problematic module progress records")
        return fixed_count
        
    except Exception as e:
        logger.error(f"Error fixing module progress records: {str(e)}")
        raise Exception(f"Error fixing module progress records: {str(e)}")


def fix_existing_chapter_progress():
    try:
        from gyaan_buddy.users.models import UserChapterProgress

        problematic_chapters = UserChapterProgress.objects.filter(
            percentage=100,
            status='in_progress'
        )
        
        fixed_count = 0
        for progress in problematic_chapters:
            progress.status = 'completed'
            progress.completed_at = timezone.now()
            progress.save()
            fixed_count += 1
            logger.info(f"Fixed chapter progress for user {progress.account.username} in chapter {progress.chapter.title}")
        
        logger.info(f"Fixed {fixed_count} problematic chapter progress records")
        return fixed_count
        
    except Exception as e:
        logger.error(f"Error fixing chapter progress records: {str(e)}")
        raise Exception(f"Error fixing chapter progress records: {str(e)}")


def fix_all_progress_records():
    try:
        logger.info("Starting to fix all progress records...")

        chapter_fixed = fix_existing_chapter_progress()
        module_fixed = fix_existing_module_progress()
        
        total_fixed = chapter_fixed + module_fixed
        logger.info(f"Total progress records fixed: {total_fixed} (Chapters: {chapter_fixed}, Modules: {module_fixed})")
        
        return {
            'chapters_fixed': chapter_fixed,
            'modules_fixed': module_fixed,
            'total_fixed': total_fixed
        }
        
    except Exception as e:
        logger.error(f"Error fixing all progress records: {str(e)}")
        raise Exception(f"Error fixing all progress records: {str(e)}")


def get_first_content(chapter):
    return ModuleContent.objects.filter(
        is_deleted=False,
        chapter=chapter
    ).order_by('order').first()


def get_next_content(chapter, current_content):
    return ModuleContent.objects.filter(
        chapter=chapter,
        is_deleted=False,
        order__gt=current_content.order
    ).order_by('order').first()


def handle_first_content_request(request, chapter, api_logger, success, ModuleContentSerializer):
    api_logger.info(f"Next content requested with null content ID for chapter '{chapter.title}' by {request.user.username} - returning first content")
    
    first_content = get_first_content(chapter)
    
    if first_content:
        try:
            update_chapter_progress(request.user, chapter, 0, 'in_progress')
        except Exception as e:
            api_logger.error(str(e))
            
        serializer = ModuleContentSerializer(first_content, context={'request': request})
        api_logger.info(f"Returned first content (order: {first_content.order}) from chapter '{chapter.title}' for user {request.user.username}")
        return success(
            data=serializer.data,
            message="First content retrieved successfully"
        )
    else:
        api_logger.info(f"No content found in chapter '{chapter.title}' for user {request.user.username}")
        try:
            complete_chapter_and_update_module(request.user, chapter)
        except Exception as e:
            api_logger.error(str(e))
            
        return success(
            data=None,
            message="No more content available in this chapter"
        )


def handle_next_content_request(request, chapter, content_id, api_logger, success, validation_error, ModuleContentSerializer):
    try:
        current_content = ModuleContent.objects.get(id=content_id, is_deleted=False, chapter=chapter)
        api_logger.info(f"Next content requested after content ID {content_id} in chapter '{chapter.title}' by {request.user.username}")

        current_percentage = calculate_chapter_progress_percentage(chapter, current_content)
        try:
            update_chapter_progress(request.user, chapter, current_percentage, 'in_progress')
        except Exception as e:
            api_logger.error(str(e))

        next_content = get_next_content(chapter, current_content)
        
        if next_content:
            serializer = ModuleContentSerializer(next_content, context={'request': request})
            api_logger.info(f"Returned next content (order: {next_content.order}) after content ID {content_id} in chapter '{chapter.title}' for user {request.user.username}")
            return success(
                data=serializer.data,
                message="Next content retrieved successfully"
            )
        else:
            api_logger.info(f"No next content found after content ID {content_id} (order: {current_content.order}) in chapter '{chapter.title}' for user {request.user.username}")
            try:
                complete_chapter_and_update_module(request.user, chapter)
            except Exception as e:
                api_logger.error(str(e))
                
            return success(
                data=None,
                message="No more content available in this chapter"
            )
            
    except ModuleContent.DoesNotExist:
        api_logger.warning(f"Content with ID {content_id} not found in chapter '{chapter.title}' for user {request.user.username}")
        return validation_error({"error": "Content not found in this chapter"})

    except Exception as e:
        api_logger.error(f"Error processing next content request: {str(e)}")
        return validation_error({"error": "Failed to process next content request"})
