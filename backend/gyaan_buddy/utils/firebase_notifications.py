"""
Firebase Cloud Messaging (FCM) Service for Gyaan Buddy

This module provides functionality to send push notifications using Firebase Cloud Messaging.
"""

import os
import json
import logging
import uuid
from typing import List, Dict, Optional
from django.conf import settings
from django.contrib.auth import get_user_model
import firebase_admin
from firebase_admin import credentials, messaging
from firebase_admin.exceptions import FirebaseError

logger = logging.getLogger(__name__)
User = get_user_model()


class FirebaseNotificationService:
    """
    Service class for sending Firebase Cloud Messaging notifications.
    Uses lazy initialization to avoid blocking worker startup.
    """
    
    def __init__(self):
        """Initialize the Firebase notification service."""
        self._app = None
        self._initialized = False
    
    def _initialize_firebase(self):
        """Initialize Firebase Admin SDK for messaging (lazy initialization)."""
        if self._initialized and self._app is not None:
            return
        
        try:
            if firebase_admin._apps:
                try:
                    self._app = firebase_admin.get_app('fcm_app')
                    logger.info("Using existing Firebase app")
                    self._initialized = True
                    return
                except ValueError:
                    pass
            
            project_id = getattr(settings, 'FIREBASE_PROJECT_ID', None)
            if not project_id:
                raise Exception("Firebase project ID is not configured. Please set FIREBASE_PROJECT_ID in settings.")
            
            if hasattr(settings, 'FIREBASE_SERVICE_ACCOUNT_INFO') and settings.FIREBASE_SERVICE_ACCOUNT_INFO:
                service_account_info = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_INFO)
                cred = credentials.Certificate(service_account_info)
            elif hasattr(settings, 'FIREBASE_SERVICE_ACCOUNT_KEY_PATH') and os.path.exists(settings.FIREBASE_SERVICE_ACCOUNT_KEY_PATH):
                cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_KEY_PATH)
            else:
                cred = credentials.ApplicationDefault()
            
            options = {'projectId': project_id}
            self._app = firebase_admin.initialize_app(cred, options=options, name='fcm_app')
            self._initialized = True
            logger.info(f"Firebase Admin SDK initialized successfully for FCM with project ID: {project_id}")
            
        except Exception as e:
            logger.error(f"Failed to initialize Firebase Admin SDK: {str(e)}")
            raise Exception(f"Failed to initialize Firebase: {str(e)}")
    
    @property
    def app(self):
        """Lazy initialization property for Firebase app."""
        if not self._initialized:
            self._initialize_firebase()
        return self._app
    
    def send_notification_to_user(self, user: User, title: str, body: str, 
                                 data: Optional[Dict] = None, notification_type: Optional[str] = None,
                                 triggered_by: str = 'auto') -> bool:
        """
        Send a notification to a specific user.
        
        Args:
            user: The user to send notification to
            title: Notification title
            body: Notification body
            data: Optional data payload
            notification_type: Type of notification (module, subject, user, mission, competition). 
                              If None, will be inferred from data['type']
            triggered_by: How this notification was triggered (auto, user, manual). Default: 'auto'
            
        Returns:
            bool: True if notification was sent successfully, False otherwise
        """
        try:
            fcm_token = getattr(user, 'fcm_token', None)
            
            if not fcm_token:
                logger.warning(f"User {user.username} does not have an FCM token")
                self._create_notification_entry(user, title, body, data, notification_type, triggered_by)
                return False
            
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                token=fcm_token,
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1
                        )
                    )
                ),
                android=messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        sound='default',
                        default_vibrate_timings=True
                    )
                )
            )
            
            response = messaging.send(message, app=self.app)
            logger.info(f"Successfully sent notification to user {user.username}: {response}")
            
            self._create_notification_entry(user, title, body, data, notification_type, triggered_by)
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to send notification to user {user.username}: {str(e)}")
            try:
                self._create_notification_entry(user, title, body, data, notification_type, triggered_by)
            except Exception as entry_error:
                logger.error(f"Failed to create notification entry for user {user.username}: {str(entry_error)}")
            return False
    
    def _create_notification_entry(self, user: User, title: str, body: str, 
                                   data: Optional[Dict] = None, notification_type: Optional[str] = None,
                                   triggered_by: str = 'auto'):
        """
        Create a notification entry in the Notification table.
        
        Args:
            user: The user to create notification for
            title: Notification title
            body: Notification body
            data: Optional data payload
            notification_type: Type of notification. If None, inferred from data['type']
            triggered_by: How this notification was triggered
        """
        try:
            from gyaan_buddy.users.models import Notification
            
            if notification_type:
                notif_type = notification_type
            elif data and 'type' in data:
                data_type = data.get('type', '')
                type_mapping = {
                    'level_up': 'user',
                    'module_enabled': 'module',
                    'module_due': 'module',
                    'chapter_due': 'module',
                    'mission_created': 'mission',
                    'mission_completed': 'mission',
                    'test_created': 'test',
                    'competition_created': 'competition',
                    'competition_started': 'competition',
                    'competition_completed': 'competition',
                }
                notif_type = type_mapping.get(data_type, 'user')
            else:
                notif_type = 'user'

            valid_types = ['module', 'subject', 'user', 'mission', 'competition', 'test']
            if notif_type not in valid_types:
                logger.warning(f"Invalid notification type '{notif_type}', defaulting to 'user'")
                notif_type = 'user'
            
            notification_id = str(uuid.uuid4())
            
            notification_data = data.copy() if data else {}
            notification_data['title'] = title
            notification_data['body'] = body
            
            Notification.objects.create(
                user=user,
                notification_id=notification_id,
                data=notification_data,
                type=notif_type,
                triggered_by=triggered_by
            )
            
            logger.debug(f"Created notification entry for user {user.username}: type={notif_type}, id={notification_id}")
            
        except Exception as e:
            logger.error(f"Failed to create notification entry for user {user.username}: {str(e)}")
    
    def send_notification_to_multiple_users(self, users: List[User], title: str, 
                                          body: str, data: Optional[Dict] = None,
                                          notification_type: Optional[str] = None,
                                          triggered_by: str = 'auto') -> Dict[str, int]:
        """
        Send notifications to multiple users.
        
        Args:
            users: List of users to send notifications to
            title: Notification title
            body: Notification body
            data: Optional data payload
            notification_type: Type of notification (module, subject, user, mission, competition)
            triggered_by: How this notification was triggered (auto, user, manual). Default: 'auto'
            
        Returns:
            Dict with 'success' and 'failed' counts
        """
        results = {'success': 0, 'failed': 0}
        
        for user in users:
            if self.send_notification_to_user(user, title, body, data, notification_type, triggered_by):
                results['success'] += 1
            else:
                results['failed'] += 1
        
        logger.info(f"Notification batch results: {results}")
        return results
    
    def send_notification_to_topic(self, topic: str, title: str, body: str, 
                                  data: Optional[Dict] = None) -> bool:
        """
        Send a notification to all users subscribed to a topic.
        
        Args:
            topic: The topic name
            title: Notification title
            body: Notification body
            data: Optional data payload
            
        Returns:
            bool: True if notification was sent successfully, False otherwise
        """
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                topic=topic,
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1
                        )
                    )
                ),
                android=messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        sound='default',
                        default_vibrate_timings=True
                    )
                )
            )
            
            response = messaging.send(message, app=self.app)
            logger.info(f"Successfully sent notification to topic {topic}: {response}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send notification to topic {topic}: {str(e)}")
            return False
    
    def send_module_enabled_notification(self, module, users: List[User] = None,
                                        notification_type: str = 'module', triggered_by: str = 'auto'):
        """
        Send notification when a module is enabled.
        
        Args:
            module: The Module instance that was enabled
            users: Optional list of users to notify. If None, notifies all active users.
            notification_type: Type of notification (default: 'module')
            triggered_by: How this notification was triggered (default: 'auto')
        """
        try:
            if users is None:
                users = User.objects.filter(is_active=True, is_deleted=False)
            
            title = "New Chapter Available!"
            body = f"'{module.name}' chapter in {module.subject.name} is now available for learning!"
            
            data = {
                'type': 'module_enabled',
                'module_id': str(module.id),
                'module_name': module.name,
                'subject_name': module.subject.name,
                'action': 'open_module'
            }
            
            results = self.send_notification_to_multiple_users(
                users, title, body, data, 
                notification_type=notification_type, 
                triggered_by=triggered_by
            )
            
            logger.info(f"Module enabled notification sent for '{module.name}': {results}")
            return results
            
        except Exception as e:
            logger.error(f"Failed to send module enabled notification: {str(e)}")
            return {'success': 0, 'failed': 0}


firebase_notification_service = FirebaseNotificationService()


def send_module_enabled_notification(module, users=None):
    """
    Convenience function to send module enabled notification.
    
    Args:
        module: The Module instance that was enabled
        users: Optional list of users to notify
    """
    return firebase_notification_service.send_module_enabled_notification(module, users)
