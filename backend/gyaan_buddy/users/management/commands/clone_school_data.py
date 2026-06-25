"""
Clone all academic content (subjects, modules, chapters, questions, theories)
from one school to another. Student/teacher data is NOT cloned.

Usage:
    # Interactive
    python manage.py clone_school_data

    # Non-interactive
    python manage.py clone_school_data --old-school "DPS Delhi" --new-school "DPS Bangalore"

    # Preview without saving
    python manage.py clone_school_data --old-school "DPS Delhi" --new-school "DPS Bangalore" --dry-run
"""

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction


class Command(BaseCommand):
    help = "Clone subjects, modules, chapters, and questions from one school to another."

    def add_arguments(self, parser):
        parser.add_argument("--old-school", dest="old_school", default=None,
                            help="Name of the source school")
        parser.add_argument("--new-school", dest="new_school", default=None,
                            help="Name of the destination school")
        parser.add_argument("--dry-run", action="store_true",
                            help="Preview counts without saving anything")

    def _ask(self, prompt):
        value = input(f"{prompt}: ").strip()
        if not value:
            raise CommandError(f"'{prompt}' is required.")
        return value

    def _clone_question(self, old_q):
        """Create a fresh copy of a Question and all its Options."""
        from gyaan_buddy.subjects.models import Question, Option
        new_q = Question.objects.create(
            question_text=old_q.question_text,
            question_type=old_q.question_type,
            exp_points=old_q.exp_points,
            difficulty_level=old_q.difficulty_level,
            explanation=old_q.explanation,
            hint=old_q.hint,
            is_active=old_q.is_active,
            is_hots=old_q.is_hots,
            ai_generated=old_q.ai_generated,
            level=old_q.level,
        )
        for old_opt in old_q.options.all().order_by('order'):
            Option.objects.create(
                question=new_q,
                option_text=old_opt.option_text,
                is_correct=old_opt.is_correct,
                order=old_opt.order,
            )
        return new_q

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        if dry_run:
            self.stdout.write(self.style.WARNING("\n*** DRY-RUN — nothing will be saved ***\n"))

        old_name = options["old_school"] or self._ask("Old school name")
        new_name = options["new_school"] or self._ask("New school name")

        from gyaan_buddy.users.models import School, Class
        from gyaan_buddy.subjects.models import (
            Subject, Module, ModuleChapter, ModuleContent,
            Question, Option, Theory, ChapterHOTS,
        )

        # --- resolve schools ---
        try:
            old_school = School.objects.get(name__iexact=old_name)
        except School.DoesNotExist:
            raise CommandError(f"School '{old_name}' not found.")
        except School.MultipleObjectsReturned:
            raise CommandError(f"Multiple schools match '{old_name}'. Use a more specific name.")

        try:
            new_school = School.objects.get(name__iexact=new_name)
        except School.DoesNotExist:
            raise CommandError(f"School '{new_name}' not found.")
        except School.MultipleObjectsReturned:
            raise CommandError(f"Multiple schools match '{new_name}'. Use a more specific name.")

        if old_school.id == new_school.id:
            raise CommandError("Source and destination school are the same.")

        self.stdout.write(f"\nSource      : {old_school.name} (id={old_school.id})")
        self.stdout.write(f"Destination : {new_school.name} (id={new_school.id})\n")

        old_subjects = list(old_school.subjects.all())
        old_classes  = list(old_school.classes.all())

        # --- dry-run summary ---
        if dry_run:
            total_modules  = 0
            total_chapters = 0
            total_questions = 0
            total_theories  = 0
            for subj in old_subjects:
                for mod in subj.modules.all():
                    total_modules += 1
                    for chap in mod.chapters.filter(is_deleted=False):
                        total_chapters += 1
                        for content in chap.contents.filter(is_deleted=False):
                            if content.content_type == 'question':
                                total_questions += 1
                            else:
                                total_theories += 1
            self.stdout.write(f"  Subjects  : {len(old_subjects)}")
            self.stdout.write(f"  Classes   : {len(old_classes)}")
            self.stdout.write(f"  Modules   : {total_modules}")
            self.stdout.write(f"  Chapters  : {total_chapters}")
            self.stdout.write(f"  Questions : {total_questions}")
            self.stdout.write(f"  Theories  : {total_theories}")
            self.stdout.write(self.style.WARNING("\nDry-run complete — nothing saved."))
            return

        # --- begin clone ---
        stats = {
            'classes_created': 0, 'classes_reused': 0,
            'subjects_created': 0, 'subjects_reused': 0,
            'modules_created': 0,  'modules_reused': 0,
            'chapters_created': 0, 'chapters_reused': 0,
            'questions': 0, 'theories': 0, 'hots': 0,
        }

        with transaction.atomic():

            # Step 1: Map classes by name (create missing ones in new school)
            class_map = {}  # old_class.id → new Class
            for old_cls in old_classes:
                new_cls, created = Class.objects.get_or_create(
                    name=old_cls.name,
                    school=new_school,
                    defaults={
                        'description': old_cls.description,
                        'is_active': old_cls.is_active,
                        # class_teacher and grade are school-specific — not cloned
                    }
                )
                class_map[old_cls.id] = new_cls
                if created:
                    stats['classes_created'] += 1
                    self.stdout.write(f"  [Class] Created  '{new_cls.name}'")
                else:
                    stats['classes_reused'] += 1
                    self.stdout.write(f"  [Class] Exists   '{new_cls.name}'")

            # Step 2: Clone subjects
            for old_subj in old_subjects:
                new_subj, created = Subject.objects.get_or_create(
                    name=old_subj.name,
                    school=new_school,
                    defaults={
                        'code': old_subj.code,
                        'description': old_subj.description,
                        'logo_url': old_subj.logo_url,
                        'color': old_subj.color,
                        'is_active': old_subj.is_active,
                        'order': old_subj.order,
                    }
                )
                if created:
                    stats['subjects_created'] += 1
                    self.stdout.write(self.style.SUCCESS(f"\n  [Subject] Created '{new_subj.name}'"))
                else:
                    stats['subjects_reused'] += 1
                    self.stdout.write(f"\n  [Subject] Exists  '{new_subj.name}'")

                # Step 3: Clone modules for this subject
                for old_mod in old_subj.modules.all().order_by('order'):
                    new_cls = class_map.get(old_mod.class_instance_id)
                    if not new_cls:
                        self.stdout.write(self.style.WARNING(
                            f"    [Module] SKIP '{old_mod.name}' "
                            f"— class '{old_mod.class_instance}' not in class_map"
                        ))
                        continue

                    new_mod, created = Module.objects.get_or_create(
                        name=old_mod.name,
                        subject=new_subj,
                        class_instance=new_cls,
                        defaults={
                            'description': old_mod.description,
                            'order': old_mod.order,
                            'is_active': old_mod.is_active,
                            'is_enabled': old_mod.is_enabled,
                            'logo_url': old_mod.logo_url,
                        }
                    )
                    if created:
                        stats['modules_created'] += 1
                        self.stdout.write(f"    [Module] Created '{new_mod.name}'")
                    else:
                        stats['modules_reused'] += 1
                        self.stdout.write(f"    [Module] Exists  '{new_mod.name}'")

                    # Per-module maps to avoid duplicating a question shared
                    # across chapters within the same module
                    question_map = {}  # old_question.id → new Question
                    theory_map   = {}  # old_theory.id   → new Theory

                    # Step 4: Clone chapters
                    for old_chap in old_mod.chapters.filter(is_deleted=False).order_by('order'):
                        new_chap, created = ModuleChapter.objects.get_or_create(
                            module=new_mod,
                            order=old_chap.order,
                            defaults={
                                'title': old_chap.title,
                                'description': old_chap.description,
                                'is_enabled': old_chap.is_enabled,
                                'is_important': old_chap.is_important,
                                'has_hots': old_chap.has_hots,
                                'max_questions': old_chap.max_questions,
                                'theory': old_chap.theory,
                                # due_date intentionally not cloned (school-specific schedule)
                            }
                        )
                        if created:
                            stats['chapters_created'] += 1
                            self.stdout.write(f"      [Chapter] Created '{new_chap.title}'")
                        else:
                            stats['chapters_reused'] += 1
                            self.stdout.write(f"      [Chapter] Exists  '{new_chap.title}'")

                        # Step 5: Clone module contents (questions + theories)
                        for old_content in old_chap.contents.filter(is_deleted=False).order_by('order'):
                            if old_content.content_type == 'question' and old_content.question:
                                old_q = old_content.question
                                if old_q.id not in question_map:
                                    question_map[old_q.id] = self._clone_question(old_q)
                                    stats['questions'] += 1
                                new_q = question_map[old_q.id]
                                ModuleContent.objects.get_or_create(
                                    chapter=new_chap,
                                    order=old_content.order,
                                    defaults={
                                        'content_type': 'question',
                                        'question': new_q,
                                    }
                                )

                            elif old_content.content_type == 'theory' and old_content.theory:
                                old_t = old_content.theory
                                if old_t.id not in theory_map:
                                    theory_map[old_t.id] = Theory.objects.create(
                                        title=old_t.title,
                                        description=old_t.description,
                                    )
                                    stats['theories'] += 1
                                new_t = theory_map[old_t.id]
                                ModuleContent.objects.get_or_create(
                                    chapter=new_chap,
                                    order=old_content.order,
                                    defaults={
                                        'content_type': 'theory',
                                        'theory': new_t,
                                    }
                                )

                        # Step 6: Clone HOTS questions
                        for old_hots in old_chap.hots_questions.all().order_by('order'):
                            old_q = old_hots.question
                            if old_q.id not in question_map:
                                question_map[old_q.id] = self._clone_question(old_q)
                                stats['questions'] += 1
                            new_q = question_map[old_q.id]
                            ChapterHOTS.objects.get_or_create(
                                chapter=new_chap,
                                question=new_q,
                                defaults={'order': old_hots.order}
                            )
                            stats['hots'] += 1

        # Final summary
        self.stdout.write(self.style.SUCCESS(
            f"\n{'='*55}"
            f"\nClone complete: {old_school.name}  →  {new_school.name}"
            f"\n{'='*55}"
        ))
        self.stdout.write(f"  Classes   : {stats['classes_created']} created, {stats['classes_reused']} reused")
        self.stdout.write(f"  Subjects  : {stats['subjects_created']} created, {stats['subjects_reused']} reused")
        self.stdout.write(f"  Modules   : {stats['modules_created']} created, {stats['modules_reused']} reused")
        self.stdout.write(f"  Chapters  : {stats['chapters_created']} created, {stats['chapters_reused']} reused")
        self.stdout.write(f"  Questions : {stats['questions']} cloned")
        self.stdout.write(f"  Theories  : {stats['theories']} cloned")
        self.stdout.write(f"  HOTS links: {stats['hots']} cloned")
