"""
Seed parent-dashboard friendly demo data for local development.

Usage:
  python manage.py seed_parent_demo_data
  python manage.py seed_parent_demo_data --username student1 --password student123
  python manage.py seed_parent_demo_data --days 30 --tests 10 --dry-run
"""

from __future__ import annotations

import random
from datetime import timedelta

from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from gyaan_buddy.subjects.models import Answer, Module, ModuleChapter, ModuleContent, Question, Subject
from gyaan_buddy.users.models import (
    Account,
    Student,
    Test,
    TestModuleChapter,
    UserChapterProgress,
    UserProfile,
    UserTestProgress,
)


class Command(BaseCommand):
    help = "Seed local demo data for parent dashboard (student, classmates, tests, progress, answers)."

    def add_arguments(self, parser):
        parser.add_argument("--username", default="student1", help="Primary demo student username")
        parser.add_argument("--password", default="student123", help="Primary demo student password")
        parser.add_argument("--days", type=int, default=30, help="Days of answer trends to generate")
        parser.add_argument("--tests", type=int, default=10, help="Minimum tests to ensure for student's class")
        parser.add_argument("--dry-run", action="store_true", help="Preview only; do not write changes")

    def handle(self, *args, **options):
        username = options["username"]
        password = options["password"]
        days = max(7, int(options["days"]))
        min_tests = max(4, int(options["tests"]))
        dry_run = options["dry_run"]

        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN mode: no data will be written."))

        now = timezone.now()

        with transaction.atomic():
            student_user = self._ensure_primary_student(username=username, password=password, dry_run=dry_run)
            student = student_user.profile.student
            class_instance = student.class_instance
            school = student_user.profile.school

            if not class_instance:
                raise CommandError("Primary student has no class assigned. Assign a class first.")
            if not school:
                raise CommandError("Primary student profile has no school assigned.")

            self._ensure_classmates(class_instance=class_instance, school=school, dry_run=dry_run)

            subjects = list(Subject.objects.filter(school=school, is_active=True).order_by("name")[:6])
            if not subjects:
                subjects = list(Subject.objects.filter(is_active=True).order_by("name")[:6])
            if not subjects:
                raise CommandError("No active subjects found. Please seed curriculum first.")

            tests = self._ensure_tests(
                class_instance=class_instance,
                created_by=student_user,
                subjects=subjects,
                min_tests=min_tests,
                now=now,
                dry_run=dry_run,
            )

            self._ensure_test_progress_for_class(
                tests=tests,
                class_instance=class_instance,
                now=now,
                dry_run=dry_run,
            )

            answers_created, answers_updated = self._ensure_answer_history(
                student_user=student_user,
                subjects=subjects,
                days=days,
                now=now,
                dry_run=dry_run,
            )

            self._ensure_chapter_progress(student_user=student_user, subjects=subjects, dry_run=dry_run)

            if dry_run:
                transaction.set_rollback(True)

        completed_tests = UserTestProgress.objects.filter(account=student_user, status="completed").count()
        answers_30 = Answer.objects.filter(
            user=student_user,
            created_at__gte=now - timedelta(days=30),
        ).count()

        self.stdout.write(self.style.SUCCESS("\nSeed completed."))
        self.stdout.write(f"Primary student: {student_user.username} ({student_user.get_full_name() or student_user.username})")
        self.stdout.write(f"Class: {class_instance.name}")
        self.stdout.write(f"Total class tests: {len(tests)}")
        self.stdout.write(f"Completed tests (primary student): {completed_tests}")
        self.stdout.write(f"Answers last 30 days (primary student): {answers_30}")
        self.stdout.write(f"Answers created/updated this run: {answers_created}/{answers_updated}")

    def _ensure_primary_student(self, username: str, password: str, dry_run: bool):
        user = Account.objects.filter(username=username).first()
        if user is None:
            user = Account(
                username=username,
                first_name="Mridul",
                last_name="Sharma",
                email=f"{username}@example.com",
                is_active=True,
            )
            user.password = make_password(password)
            if not dry_run:
                user.save()

        # profile and student must exist for dashboard APIs
        if not hasattr(user, "profile"):
            school = UserProfile.objects.order_by("created_at").values_list("school_id", flat=True).first()
            if school is None:
                raise CommandError("No school found. Create a school/admin first.")
            if not dry_run:
                UserProfile.objects.create(account=user, school_id=school, user_type="student")

        profile = user.profile
        profile.user_type = "student"
        if not dry_run:
            profile.save(update_fields=["user_type"])

        if not hasattr(profile, "student"):
            cls_id = Student.objects.exclude(class_instance__isnull=True).values_list("class_instance_id", flat=True).first()
            if cls_id is None:
                raise CommandError("No class found. Create at least one class before seeding.")
            if not dry_run:
                Student.objects.create(user_profile=profile, class_instance_id=cls_id, total_exp=1200, parent_name="Meera Patel")

        student = profile.student
        if not student.parent_name:
            student.parent_name = "Meera Patel"
        student.total_exp = max(student.total_exp, 1200)
        if not dry_run:
            student.save(update_fields=["parent_name", "total_exp"])

        return user

    def _ensure_classmates(self, class_instance, school, dry_run: bool):
        classmates = [
            ("student2", "Aarav", "Kapoor", 980),
            ("student3", "Priya", "Sharma", 1120),
            ("student4", "Rohan", "Verma", 860),
        ]
        for username, first_name, last_name, total_exp in classmates:
            user = Account.objects.filter(username=username).first()
            if user is None:
                user = Account(
                    username=username,
                    first_name=first_name,
                    last_name=last_name,
                    email=f"{username}@example.com",
                    is_active=True,
                )
                user.password = make_password("student123")
                if not dry_run:
                    user.save()

            if not hasattr(user, "profile"):
                if not dry_run:
                    UserProfile.objects.create(account=user, school=school, user_type="student")

            profile = user.profile
            if profile.school_id != school.id or profile.user_type != "student":
                profile.school = school
                profile.user_type = "student"
                if not dry_run:
                    profile.save(update_fields=["school", "user_type"])

            if not hasattr(profile, "student"):
                if not dry_run:
                    Student.objects.create(user_profile=profile, class_instance=class_instance, total_exp=total_exp, parent_name="Parent")
            else:
                s = profile.student
                s.class_instance = class_instance
                s.total_exp = max(s.total_exp, total_exp)
                if not s.parent_name:
                    s.parent_name = "Parent"
                if not dry_run:
                    s.save(update_fields=["class_instance", "total_exp", "parent_name"])

    def _ensure_tests(self, class_instance, created_by, subjects, min_tests: int, now, dry_run: bool):
        tests = list(
            Test.objects.filter(Q(class_group=class_instance) | Q(class_groups=class_instance), is_deleted=False)
            .distinct()
            .order_by("-test_datetime")
        )

        def create_test(subject, dt, duration):
            test = Test(
                test_datetime=dt,
                duration=duration,
                class_group=class_instance,
                subject=subject,
                created_by=created_by,
            )
            if not dry_run:
                test.save()
                test.class_groups.set([class_instance])
                modules = list(Module.objects.filter(subject=subject).order_by("name")[:2])
                for module in modules:
                    chapter = (
                        ModuleChapter.objects.filter(module=module, is_deleted=False)
                        .order_by("order", "created_at")
                        .first()
                    )
                    if chapter:
                        TestModuleChapter.objects.get_or_create(test=test, module=module, module_chapter=chapter)
            return test

        if len(tests) < min_tests:
            need = min_tests - len(tests)
            for i in range(need):
                subject = subjects[i % len(subjects)]
                create_test(subject=subject, dt=now - timedelta(days=(i + 1) * 7), duration=40 + (i % 3) * 10)

        # Ensure at least two upcoming tests for the deadlines card
        future_count = Test.objects.filter(
            Q(class_group=class_instance) | Q(class_groups=class_instance),
            is_deleted=False,
            test_datetime__gte=now,
        ).distinct().count()
        for i in range(max(0, 2 - future_count)):
            subject = subjects[(i + 2) % len(subjects)]
            create_test(subject=subject, dt=now + timedelta(days=(i + 1) * 6), duration=45)

        return list(
            Test.objects.filter(Q(class_group=class_instance) | Q(class_groups=class_instance), is_deleted=False)
            .distinct()
            .order_by("-test_datetime")[: max(min_tests, 10)]
        )

    def _ensure_test_progress_for_class(self, tests, class_instance, now, dry_run: bool):
        students = Student.objects.filter(class_instance=class_instance, is_deleted=False).select_related("user_profile__account")
        accounts = [s.user_profile.account for s in students if s.user_profile and s.user_profile.account]
        score_pattern = [92, 86, 74, 68, 88, 79, 83, 71, 95, 65, 90, 77]

        for test_index, test in enumerate(tests):
            for user_index, account in enumerate(accounts):
                pct = max(35, min(98, score_pattern[(test_index + user_index * 2) % len(score_pattern)] - (user_index * 4)))
                total_q = max(8, int(getattr(test, "question_count", 0) or 10))
                correct = max(0, round((pct / 100) * total_q))
                wrong = max(0, total_q - correct)
                exp = max(25, correct * 9)
                dt = test.test_datetime if test.test_datetime else now - timedelta(days=(test_index + 1) * 4)

                defaults = {
                    "status": "completed",
                    "percentage": pct,
                    "score": correct,
                    "total_questions": total_q,
                    "questions_attempted": total_q,
                    "correct_answers": correct,
                    "wrong_answers": wrong,
                    "started_at": dt - timedelta(minutes=35),
                    "completed_at": dt,
                    "time_spent_seconds": max(900, min(5400, total_q * 85)),
                    "exp_earned": exp,
                }

                progress = UserTestProgress.objects.filter(account=account, test=test).first()
                if progress is None:
                    if not dry_run:
                        UserTestProgress.objects.create(account=account, test=test, **defaults)
                else:
                    for field, value in defaults.items():
                        setattr(progress, field, value)
                    if not dry_run:
                        progress.save()

    def _ensure_answer_history(self, student_user, subjects, days: int, now, dry_run: bool):
        chapter_question_sets = []
        for subject in subjects:
            chapters = ModuleChapter.objects.filter(module__subject=subject, is_deleted=False).order_by("created_at")[:6]
            for chapter in chapters:
                qids = list(
                    ModuleContent.objects.filter(chapter=chapter, content_type="question", is_deleted=False)
                    .values_list("question_id", flat=True)[:20]
                )
                qids = [qid for qid in qids if qid]
                if qids:
                    chapter_question_sets.append((subject, chapter, qids))

        if not chapter_question_sets:
            fallback = list(Question.objects.filter(is_deleted=False).values_list("id", flat=True)[:50])
            if not fallback:
                raise CommandError("No questions found to generate answer trends.")
            chapter_question_sets = [(subjects[0], None, fallback)]

        created = 0
        updated = 0
        exp_cursor = max(0, student_user.profile.student.total_exp - 700)

        for day in range(1, days + 1):
            points_today = 2 + (day % 3)
            day_dt = now - timedelta(days=day)
            for i in range(points_today):
                subject, chapter, qids = chapter_question_sets[(day + i) % len(chapter_question_sets)]
                qid = qids[(day * 5 + i) % len(qids)]
                question = Question.objects.get(id=qid)

                weak_subject_id = subjects[-1].id
                is_correct = random.random() < (0.48 if subject.id == weak_subject_id else 0.74)
                gain = 12 if is_correct else 2
                prev = exp_cursor
                exp_cursor += gain

                answer = Answer.objects.filter(user=student_user, question=question, test__isnull=True).first()
                if answer is None:
                    answer = Answer(
                        user=student_user,
                        question=question,
                        test=None,
                    )
                    created += 1
                else:
                    updated += 1

                answer.is_correct = is_correct
                answer.answer = "seeded answer"
                answer.tries = 1 if is_correct else 2
                answer.prev_exp = prev
                answer.current_Exp = exp_cursor
                answer.from_mission = False
                answer.chapter = chapter

                if not dry_run:
                    answer.save()
                    Answer.objects.filter(id=answer.id).update(created_at=day_dt + timedelta(minutes=i * 11))

        return created, updated

    def _ensure_chapter_progress(self, student_user, subjects, dry_run: bool):
        for subject in subjects:
            chapters = ModuleChapter.objects.filter(module__subject=subject, is_deleted=False).order_by("created_at")[:4]
            for index, chapter in enumerate(chapters):
                percent = max(35, min(100, 55 + (index * 12)))
                status = "completed" if percent >= 95 else "in_progress"

                row = UserChapterProgress.objects.filter(account=student_user, chapter=chapter).first()
                if row is None:
                    row = UserChapterProgress(account=student_user, chapter=chapter)

                row.status = status
                row.percentage = percent
                if not dry_run:
                    row.save()
