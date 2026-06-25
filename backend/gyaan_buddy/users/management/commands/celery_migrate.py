"""
Django management command to run Celery migrations.
"""

from django.core.management.base import BaseCommand
from django_celery_beat.models import PeriodicTask, CrontabSchedule, IntervalSchedule


class Command(BaseCommand):
    help = 'Create default Celery Beat periodic tasks'

    def handle(self, *args, **options):
        self.stdout.write('Creating default Celery Beat tasks...')
        
        cleanup_schedule, created = CrontabSchedule.objects.get_or_create(
            hour=2,
            minute=0,
            day_of_week='*',
            day_of_month='*',
            month_of_year='*',
        )
        
        cleanup_task, created = PeriodicTask.objects.get_or_create(
            name='Cleanup Expired Sessions',
            defaults={
                'task': 'gyaan_buddy.users.tasks.cleanup_expired_sessions',
                'crontab': cleanup_schedule,
                'enabled': True,
            }
        )
        
        if created:
            self.stdout.write(
                self.style.SUCCESS('Created cleanup expired sessions task')
            )
        else:
            self.stdout.write('Cleanup expired sessions task already exists')
        
        self.stdout.write(
            self.style.SUCCESS('Celery Beat tasks setup completed!')
        )
