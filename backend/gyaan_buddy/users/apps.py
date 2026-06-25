from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'gyaan_buddy.users'
    verbose_name = 'Users'
    
    def ready(self):
        """Import signals when the app is ready."""
        import gyaan_buddy.users.signals