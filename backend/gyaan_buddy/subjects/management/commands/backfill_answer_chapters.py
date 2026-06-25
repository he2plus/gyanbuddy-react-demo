"""
Management command to backfill Answer.chapter for existing answers where chapter is null.
Looks up the chapter via ModuleContent (question → ModuleContent → chapter).
"""
from django.core.management.base import BaseCommand
from gyaan_buddy.subjects.models import Answer, ModuleContent


class Command(BaseCommand):
    help = 'Backfill Answer.chapter for existing answers where chapter is null'

    def add_arguments(self, parser):
        parser.add_argument('--dry-run', action='store_true', help='Print counts without saving')
        parser.add_argument('--batch-size', type=int, default=500, help='Batch size for updates')

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        batch_size = options['batch_size']

        null_answers = Answer.objects.filter(chapter__isnull=True).select_related('question')
        total = null_answers.count()
        self.stdout.write(f'Found {total} answers with chapter=null')

        # Build a question_id → chapter mapping from ModuleContent
        mc_map = {}
        for mc in ModuleContent.objects.filter(
            content_type='question',
            is_deleted=False,
            question__isnull=False,
        ).select_related('chapter'):
            mc_map[mc.question_id] = mc.chapter

        updated = 0
        to_update = []
        for answer in null_answers.iterator(chunk_size=batch_size):
            chapter = mc_map.get(answer.question_id)
            if chapter:
                answer.chapter = chapter
                to_update.append(answer)
                updated += 1
            if len(to_update) >= batch_size:
                if not dry_run:
                    Answer.objects.bulk_update(to_update, ['chapter'])
                to_update = []

        if to_update and not dry_run:
            Answer.objects.bulk_update(to_update, ['chapter'])

        action = 'Would update' if dry_run else 'Updated'
        self.stdout.write(self.style.SUCCESS(f'{action} {updated} of {total} answers'))
