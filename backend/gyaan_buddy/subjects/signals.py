from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.db import transaction
from .models import Module
from gyaan_buddy.users.models import UserModuleProgress, User, Student
from gyaan_buddy.utils.firebase_notifications import firebase_notification_service


_old_module_values = {}

@receiver(pre_save, sender=Module)
def store_old_module_values(sender, instance, **kwargs):
    if instance.pk:
        try:
            old_instance = Module.objects.get(pk=instance.pk)
            _old_module_values[instance.pk] = {
                'is_enabled': old_instance.is_enabled
            }
        except Module.DoesNotExist:
            _old_module_values[instance.pk] = {'is_enabled': False}

@receiver(post_save, sender=Module)
def create_user_module_progress_on_enable(sender, instance, created, **kwargs):
    if not created and instance.is_enabled:
        old_values = _old_module_values.get(instance.pk, {})
        old_is_enabled = old_values.get('is_enabled', False)

        if not old_is_enabled and instance.is_enabled:
            create_progress_entries_for_all_users(instance)

        if instance.pk in _old_module_values:
            del _old_module_values[instance.pk]


def create_progress_entries_for_all_users(module):
    active_users = User.objects.filter(is_active=True, is_deleted=False)
    progress_entries = []

    for user in active_users:
        if not UserModuleProgress.objects.filter(account=user, module=module).exists():
            progress_entry = UserModuleProgress(
                account=user,
                module=module,
                status='due',
                percentage=0
            )
            progress_entries.append(progress_entry)

    if progress_entries:
        UserModuleProgress.objects.bulk_create(progress_entries, ignore_conflicts=True)


def send_module_enabled_notification_to_class_users(module):
    try:
        classes_with_subject = module.subject.classes.filter(is_active=True)

        if not classes_with_subject.exists():
            import logging
            logger = logging.getLogger(__name__)
            logger.info(f"No classes found for subject '{module.subject.name}', sending notification to all users")
            firebase_notification_service.send_module_enabled_notification(module, notification_type='module', triggered_by='auto')
            return

        students_in_classes = Student.objects.filter(
            class_instance__in=classes_with_subject,
            is_deleted=False,
            user_profile__account__is_active=True,
            user_profile__account__is_deleted=False
        ).select_related('user_profile', 'user_profile__account')

        class_users = [student.user_profile.account for student in students_in_classes]

        if not class_users:
            import logging
            logger = logging.getLogger(__name__)
            logger.info(f"No students found in classes for subject '{module.subject.name}'")
            return

        firebase_notification_service.send_module_enabled_notification(module, users=class_users, notification_type='module', triggered_by='auto')

        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"Module enabled notification sent to {len(class_users)} students from {classes_with_subject.count()} classes for subject '{module.subject.name}'")

    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Failed to send module enabled notification to class users: {str(e)}")
        try:
            firebase_notification_service.send_module_enabled_notification(module, notification_type='module', triggered_by='auto')
        except Exception as fallback_error:
            logger.error(f"Fallback notification also failed: {str(fallback_error)}")
