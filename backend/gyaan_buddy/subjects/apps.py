from django.apps import AppConfig


class SubjectsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'gyaan_buddy.subjects'
    verbose_name = 'Subjects'

    def ready(self):
        """Import signals when the app is ready."""
        import gyaan_buddy.subjects.signals
