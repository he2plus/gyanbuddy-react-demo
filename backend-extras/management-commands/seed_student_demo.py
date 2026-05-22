"""
Management command: seed_student_demo
=====================================

Layers a STUDENT-FACING demo dataset on top of `seed_test_data`.

Why a separate command?
-----------------------
`seed_test_data` is tuned for a teacher-dashboard analytics demo: students
have intentionally uneven enrollments and progress so weak-topic metrics
work. That makes the student-facing screens look thin — half the screens
show empty states for half the accounts.

This command makes every screen render fully for EVERY student in 9-A:

  - Cross-enrolls all 5 students in Math + Science + English so
    every account sees every subject on /home + /subjects.
  - Backfills `hint` + `explanation` on every existing Question so the
    quiz "Why" button shows real content.
  - Ensures each student has UserChapterProgress on every chapter, with
    a deterministic mix (some Done / some In Progress / some Not Started)
    so the journey page is interesting and never empty.
  - Creates daily missions for yesterday + today + tomorrow per student
    per enrolled subject, with completed status on yesterday + a fresh
    pending mission for today.
  - Bumps total_exp per student so the leaderboard ranks them
    distinctly (Alice top, Eve bottom).
  - Generates 5-6 notifications per student covering the test, mission,
    chapter-complete, and leaderboard categories so the bell isn't empty.

Usage
-----
    # Idempotent — safe to re-run
    python manage.py seed_student_demo

    # Wipe the demo-specific extras before re-applying
    python manage.py seed_student_demo --reset

Run this AFTER `seed_test_data --flush` for a clean slate.
"""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone as dt_timezone
import uuid

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from gyaan_buddy.users.models import (
    Account,
    Mission,
    MissionQuestion,
    Notification,
    Student,
    StudentSubjectEnrollment,
    UserChapterProgress,
    UserMissionProgress,
    UserModuleProgress,
    UserProfile,
)
from gyaan_buddy.subjects.models import Question, Subject, ModuleChapter


UTC = dt_timezone.utc

# Students from seed_test_data plus their "ranking" for XP distribution.
STUDENT_USERNAMES = [
    ("alice.sharma",   2180),  # rank 1
    ("diana.patel",    1890),  # rank 2
    ("bob.verma",      1544),  # rank 3
    ("charlie.nair",   1276),  # rank 4
    ("eve.gupta",       980),  # rank 5
]

# Hint + explanation lookup keyed by question_text. Filled in below for
# every question seed_test_data inserts so the quiz Why button is rich.
HINT_EXPLANATION_BY_QTEXT: dict[str, tuple[str, str]] = {
    # ── Math: Linear Equations ────────────────────────────────────────────
    "Solve: x + 5 = 10": (
        "Subtract 5 from both sides — the goal is to isolate x.",
        "x + 5 = 10  →  x = 10 - 5  →  x = 5. The trick with linear "
        "equations is to perform the same operation on both sides until x is alone.",
    ),
    "Solve: 2x = 8": (
        "Divide both sides by the coefficient of x (which is 2).",
        "2x = 8  →  x = 8 / 2  →  x = 4. Always reduce the coefficient on x "
        "to 1 by dividing both sides.",
    ),
    "Solve: x - 3 = 7": (
        "Add 3 to both sides to move the constant away from x.",
        "x - 3 = 7  →  x = 7 + 3  →  x = 10.",
    ),
    "Solve: 3x + 2 = 11": (
        "First subtract 2 from both sides, then divide by 3.",
        "3x + 2 = 11  →  3x = 9  →  x = 3.",
    ),
    # ── Math: Quadratic Equations ─────────────────────────────────────────
    "Solve: x^2 = 4": (
        "Take the square root of both sides — remember that the root has two signs.",
        "x^2 = 4  →  x = ±2. Both +2 and -2 satisfy the equation because squaring removes the sign.",
    ),
    "Solve: x^2 - 5x + 6 = 0": (
        "Factor: find two numbers whose product is 6 and sum is -5.",
        "x^2 - 5x + 6 = (x - 2)(x - 3) = 0, so x = 2 or x = 3.",
    ),
    "Solve: x^2 + x - 6 = 0": (
        "Factor: find two numbers whose product is -6 and sum is +1.",
        "x^2 + x - 6 = (x + 3)(x - 2) = 0, so x = -3 or x = 2.",
    ),
    # ── Math: Triangles ───────────────────────────────────────────────────
    "Sum of angles in a triangle?": (
        "Recall the basic angle-sum property taught in early geometry.",
        "The three interior angles of any triangle add up to exactly 180°. "
        "This is a foundational rule that powers most geometric proofs.",
    ),
    "Right triangle legs 3 and 4, hypotenuse = ?": (
        "Apply the Pythagorean theorem: a² + b² = c².",
        "3² + 4² = 9 + 16 = 25, so c = √25 = 5. This is the classic 3-4-5 right triangle.",
    ),
    "Area of triangle = ?": (
        "Think 'base times height' — but for a triangle, only half the rectangle is filled.",
        "Area = ½ × base × height. The factor of ½ accounts for the fact that a "
        "triangle fills half the rectangle of the same base and height.",
    ),
    "All-equal-sides triangle is called?": (
        "Equi + Lateral = equal sides.",
        "An equilateral triangle has three equal sides AND three 60° angles. "
        "An isosceles has only two equal sides; a scalene has all sides different.",
    ),
    "SSS congruence: SSS stands for?": (
        "Three letters, each representing one of a triangle's three sides.",
        "Side-Side-Side: if all three sides of one triangle equal all three "
        "sides of another, the triangles are congruent.",
    ),
    # ── Math: Circles ─────────────────────────────────────────────────────
    "Circumference of a circle = ?": (
        "Think 'distance around' — depends on the radius and π.",
        "C = 2πr. Equivalently, C = πd where d is the diameter.",
    ),
    "Area of a circle = ?": (
        "It involves r squared (not r), because area is 2-dimensional.",
        "A = πr². Surface measurements always scale with the square of the radius.",
    ),
    "Diameter = ?": (
        "Diameter is the straight line across the circle through the center.",
        "Diameter = 2 × radius. It's the longest possible chord.",
    ),
    # ── Science: Motion ───────────────────────────────────────────────────
    "Speed = ?": (
        "Speed describes how much ground is covered per unit of time.",
        "Speed = Distance / Time. It's a scalar — magnitude only, no direction.",
    ),
    "Unit of acceleration?": (
        "Acceleration is the rate of change of velocity. Velocity is m/s — divide by time again.",
        "Acceleration is measured in m/s² (metres per second squared).",
    ),
    "Uniform motion means?": (
        "Uniform = unchanging. What part of motion is staying the same?",
        "Uniform motion means constant velocity — neither speed nor direction is changing.",
    ),
    "Slope of distance-time graph = ?": (
        "Slope = rise over run = (change in distance) / (change in time).",
        "On a distance-time graph the slope equals speed. A steeper line = faster motion.",
    ),
    # ── Science: Force and Laws of Motion ─────────────────────────────────
    "Newton's First Law is also called?": (
        "Objects 'want' to keep doing what they're already doing.",
        "Newton's First Law is the Law of Inertia: a body at rest stays at rest, "
        "and a body in motion stays in motion at constant velocity, unless acted upon by a force.",
    ),
    "F = ma is Newton's?": (
        "This is the equation that relates force to mass and acceleration.",
        "F = ma is Newton's Second Law: the net force on an object equals its mass "
        "times its acceleration.",
    ),
    "SI unit of force?": (
        "Named after the scientist who discovered the laws of motion.",
        "The SI unit of force is the Newton (N). 1 N = 1 kg·m/s².",
    ),
    # ── Science: Atoms and Molecules ──────────────────────────────────────
    "Smallest particle of an element?": (
        "An element by definition can't be broken further while keeping its identity.",
        "The atom is the smallest particle of an element that retains its chemical properties.",
    ),
    "Chemical formula of water?": (
        "Two hydrogen atoms bonded to one oxygen atom.",
        "Water = H₂O — 2 hydrogens + 1 oxygen.",
    ),
    "Avogadro's number = ?": (
        "It's the number of particles in one mole of any substance.",
        "Avogadro's number is approximately 6.022 × 10²³.",
    ),
    "Atomic mass unit abbreviation?": (
        "Just the letter 'u' (lowercase) — for 'unified atomic mass unit'.",
        "1 u is defined as 1/12 the mass of a carbon-12 atom.",
    ),
    # ── Science: Structure of Atom ────────────────────────────────────────
    "Charge on an electron?": (
        "Electrons are negatively charged particles.",
        "An electron carries a -1 elementary charge (≈ -1.602 × 10⁻¹⁹ C).",
    ),
    "Protons are located in?": (
        "The dense, central region of the atom.",
        "Protons and neutrons sit in the nucleus. Electrons orbit around it.",
    ),
    "Atomic number = ?": (
        "It's a count of one specific kind of particle inside the nucleus.",
        "Atomic number Z = number of protons. It uniquely identifies the element.",
    ),
    # ── English: Nouns and Pronouns ───────────────────────────────────────
    "Which of the following is a proper noun?": (
        "Proper nouns are specific names and are always capitalised.",
        "'Delhi' is a proper noun (a specific city). 'City', 'book', 'happy' are common/adjective.",
    ),
    "'He' is a?": (
        "It replaces a specific male noun in a sentence.",
        "'He' is a personal pronoun — it stands in for a previously named noun.",
    ),
    "Collective noun for a group of lions?": (
        "Lions are royal — what's a regal collective noun?",
        "A group of lions is a 'pride'.",
    ),
    "Abstract noun from the word 'brave'?": (
        "Abstract nouns name qualities — add a suffix like '-ery' or '-ness'.",
        "Brave → bravery. Abstract nouns name ideas, qualities, or feelings.",
    ),
    # ── English: Tenses ───────────────────────────────────────────────────
    "'She is singing' is which tense?": (
        "Is + verb-ing = ongoing action happening now.",
        "'She is singing' uses 'is + present participle (singing)' — Present Continuous tense.",
    ),
    "Past tense of 'go'?": (
        "It's irregular — doesn't follow the usual '-ed' rule.",
        "go → went (simple past). gone is the past participle (used with have/has).",
    ),
    "'I will eat' is which tense?": (
        "'Will' is the marker — what time does that point to?",
        "'I will eat' is the Future Simple tense — describes an action yet to happen.",
    ),
    # ── English: Literature ───────────────────────────────────────────────
    "Author of 'The Fun They Had'?": (
        "An American science-fiction grandmaster.",
        "Isaac Asimov wrote 'The Fun They Had' — a short story about a future where children learn from robot teachers.",
    ),
    "Year 'The Fun They Had' is set in?": (
        "Far in the future — past the 22nd century.",
        "The story is set in 2157, when school is taught by a mechanical teacher at home.",
    ),
    "Margie's teacher is a?": (
        "It's a machine, not a person.",
        "Margie's teacher is a mechanical teacher (a computer/robot), not a human.",
    ),
    "Tommy found an old?": (
        "It's a relic from how kids used to learn before computers.",
        "Tommy found a real, physical book — a curiosity in their digital world.",
    ),
    "Evelyn Glennie is a famous?": (
        "She plays drums, cymbals, and tuned percussion.",
        "Evelyn Glennie is a world-class percussionist.",
    ),
    "Evelyn Glennie is?": (
        "She perceives music through vibrations rather than the usual sense.",
        "Evelyn Glennie is profoundly deaf — she 'feels' music through vibrations.",
    ),
    "Bismillah Khan's instrument?": (
        "A traditional Indian wind instrument played at weddings and temples.",
        "Bismillah Khan was a legendary shehnai player.",
    ),
}


class Command(BaseCommand):
    help = "Layer student-facing demo data on top of seed_test_data."

    def add_arguments(self, parser):
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Drop the extras created by THIS command before re-seeding.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write(self.style.MIGRATE_HEADING(
            "\n═══ Layering student-facing demo data ═══\n"
        ))

        accounts = self._load_students()
        if not accounts:
            self.stdout.write(self.style.ERROR(
                "  No seeded students found — run `seed_test_data --flush` first."
            ))
            return

        # Subjects exist per-school — seed_test_data creates a 2nd school
        # ("St. Mary's") with the SAME codes. Scope to the school our test
        # students are in to avoid duplicating missions / enrollments.
        first_acc = next(iter(accounts.values()))
        first_profile = UserProfile.objects.filter(account=first_acc).first()
        school = first_profile.school if first_profile else None
        if not school:
            self.stdout.write(self.style.ERROR(
                "  Could not resolve school for the seeded students."
            ))
            return

        subjects = list(Subject.objects.filter(
            code__in=["MATH", "SCI", "ENG"],
            school=school,
        ).order_by("order"))
        if not subjects:
            self.stdout.write(self.style.ERROR(
                "  No subjects found for school — run `seed_test_data --flush` first."
            ))
            return

        if options["reset"]:
            self._reset_extras(accounts, subjects)

        self._bump_total_exp(accounts)
        self._cross_enroll(accounts, subjects)
        self._backfill_question_content()
        self._level_chapter_progress(accounts, subjects)
        self._seed_daily_missions(accounts, subjects)
        self._seed_notifications(accounts, subjects)
        self._dedup_answer_rows()

        self.stdout.write(self.style.SUCCESS(
            "\n✔  Student demo data layered.\n"
            "    Every student in 9-A now sees:\n"
            "      • all 3 subjects on /home and /subjects\n"
            "      • a mix of Done / In Progress / Not Started chapters\n"
            "      • completed mission yesterday, fresh mission today, "
            "upcoming mission tomorrow\n"
            "      • hints + explanations on every quiz question\n"
            "      • 5+ notifications waiting in the bell\n"
            "      • distinct XP so the leaderboard is realistic\n\n"
            "    Login: any of alice.sharma / bob.verma / charlie.nair / "
            "diana.patel / eve.gupta\n"
            "    Password: Test@1234\n"
        ))

    # ─────────────────────────────────────────────────────────────────────
    # Helpers
    # ─────────────────────────────────────────────────────────────────────

    def _load_students(self) -> dict[str, Account]:
        return {
            acc.username: acc
            for acc in Account.objects.filter(
                username__in=[u for u, _ in STUDENT_USERNAMES]
            )
        }

    def _reset_extras(self, accounts: dict[str, Account], subjects: list[Subject]):
        self.stdout.write("  ↻ Resetting demo extras…")
        # Wipe missions on the surrounding 3 days so we don't accumulate
        today = timezone.now().date()
        window = [today - timedelta(days=1), today, today + timedelta(days=1)]
        Mission.objects.filter(
            account__in=accounts.values(),
            mission_date__in=window,
        ).delete()
        # Wipe notifications generated by this command (flagged via notification_id prefix)
        Notification.objects.filter(
            user__in=accounts.values(),
            notification_id__startswith="demo:",
        ).delete()
        self.stdout.write("    extras cleared.")

    def _bump_total_exp(self, accounts: dict[str, Account]):
        # total_exp is stored on the Student model (UserProfile.total_exp is a
        # property that proxies through). Write to Student directly.
        self.stdout.write("  • Distinct XP per student for leaderboard ranking…")
        for username, exp in STUDENT_USERNAMES:
            acc = accounts.get(username)
            if not acc:
                continue
            student = Student.objects.filter(user_profile__account=acc).first()
            if student and student.total_exp != exp:
                student.total_exp = exp
                student.save(update_fields=["total_exp"])

    def _cross_enroll(self, accounts: dict[str, Account], subjects: list[Subject]):
        self.stdout.write("  • Cross-enrolling all 5 students in all 3 subjects…")
        created = 0
        for username, _ in STUDENT_USERNAMES:
            acc = accounts.get(username)
            if not acc:
                continue
            student = Student.objects.filter(user_profile__account=acc).first()
            if not student:
                continue
            for subj in subjects:
                _, was_created = StudentSubjectEnrollment.objects.get_or_create(
                    student=student, subject=subj,
                    defaults={"is_active": True},
                )
                if was_created:
                    created += 1
        self.stdout.write(f"    {created} new enrollment(s) added.")

    def _backfill_question_content(self):
        self.stdout.write("  • Backfilling hint + explanation on every question…")
        updated = 0
        for q in Question.objects.all():
            entry = HINT_EXPLANATION_BY_QTEXT.get(q.question_text.strip())
            if not entry:
                continue
            hint, explanation = entry
            changed = False
            if not (q.hint or "").strip():
                q.hint = hint
                changed = True
            if not (q.explanation or "").strip():
                q.explanation = explanation
                changed = True
            if changed:
                q.save(update_fields=["hint", "explanation"])
                updated += 1
        self.stdout.write(f"    {updated} question(s) enriched.")

    def _level_chapter_progress(
        self, accounts: dict[str, Account], subjects: list[Subject],
    ):
        """
        Each student gets a mix of Done / In Progress / Not Started chapters.
        Distribution per student varies so the leaderboard "X days streak"
        and per-chapter status chips show realistic variation.
        """
        self.stdout.write("  • Levelling chapter progress per student…")
        now = timezone.now()

        # status pattern per student rank: [done, done, in_progress, not_started, …]
        # cycles through every chapter found in the school
        patterns = {
            "alice.sharma":   ["completed", "completed", "completed", "in_progress", "in_progress", "not_started"],
            "diana.patel":    ["completed", "completed", "in_progress", "not_started", "not_started", "not_started"],
            "bob.verma":      ["completed", "in_progress", "in_progress", "not_started", "not_started", "not_started"],
            "charlie.nair":   ["completed", "in_progress", "not_started", "not_started", "not_started", "not_started"],
            "eve.gupta":      ["in_progress", "not_started", "not_started", "not_started", "not_started", "not_started"],
        }

        chapters = list(ModuleChapter.objects.filter(
            module__subject__in=subjects,
        ).order_by("module__subject_id", "module__order", "order"))

        records_touched = 0
        for username, pattern in patterns.items():
            acc = accounts.get(username)
            if not acc:
                continue
            for i, chap in enumerate(chapters):
                status = pattern[i % len(pattern)]
                pct = {"completed": 100, "in_progress": 60, "not_started": 0}[status]
                started_at = now - timedelta(days=2) if status != "not_started" else None
                completed_at = now - timedelta(days=1) if status == "completed" else None

                obj, _ = UserChapterProgress.objects.update_or_create(
                    account=acc,
                    chapter=chap,
                    defaults={
                        "status": status,
                        "percentage": pct,
                        "started_at": started_at,
                        "completed_at": completed_at,
                    },
                )
                records_touched += 1

            # Roll module-level progress up from chapters
            from gyaan_buddy.subjects.models import Module
            for module in Module.objects.filter(subject__in=subjects):
                module_chapters = [c for c in chapters if c.module_id == module.id]
                if not module_chapters:
                    continue
                statuses = [
                    UserChapterProgress.objects.filter(account=acc, chapter=c).first()
                    for c in module_chapters
                ]
                statuses = [s for s in statuses if s]
                if not statuses:
                    continue
                completed = sum(1 for s in statuses if s.status == "completed")
                pct = round(100 * completed / len(statuses))
                if completed == len(statuses):
                    mstatus = "completed"
                elif any(s.status in ("in_progress", "completed") for s in statuses):
                    mstatus = "in_progress"
                else:
                    mstatus = "not_started"
                UserModuleProgress.objects.update_or_create(
                    account=acc, module=module,
                    defaults={
                        "status": mstatus,
                        "percentage": pct,
                        "started_at": now - timedelta(days=2) if mstatus != "not_started" else None,
                        "completed_at": now - timedelta(days=1) if mstatus == "completed" else None,
                    },
                )

        self.stdout.write(f"    {records_touched} chapter-progress record(s) written.")

    def _seed_daily_missions(
        self, accounts: dict[str, Account], subjects: list[Subject],
    ):
        """
        Per student per subject:
          - yesterday's mission → completed
          - today's mission     → not started (the actionable one)
          - tomorrow's mission  → upcoming/locked
        """
        self.stdout.write("  • Seeding 3-day mission window (yesterday/today/tomorrow)…")
        today = timezone.now().date()
        dates = [today - timedelta(days=1), today, today + timedelta(days=1)]

        # Pick the first 3 questions per subject (via ModuleContent join).
        # Question doesn't have a direct chapter FK — it's reached through
        # ModuleContent.
        from gyaan_buddy.subjects.models import ModuleContent
        questions_by_subject: dict[str, list[Question]] = {}
        for subj in subjects:
            qids = list(
                ModuleContent.objects.filter(
                    chapter__module__subject=subj,
                    content_type="question",
                    question__isnull=False,
                    question__is_active=True,
                )
                .order_by("chapter__order", "order")
                .values_list("question_id", flat=True)[:3]
            )
            questions_by_subject[subj.code] = list(
                Question.objects.filter(id__in=qids)
            )

        created = 0
        for username, _ in STUDENT_USERNAMES:
            acc = accounts.get(username)
            if not acc:
                continue
            for subj in subjects:
                qs = questions_by_subject.get(subj.code, [])
                if not qs:
                    continue
                for d in dates:
                    mission, was_created = Mission.objects.get_or_create(
                        account=acc,
                        subject=subj,
                        mission_date=d,
                    )
                    if was_created:
                        for order_idx, q in enumerate(qs, start=1):
                            MissionQuestion.objects.create(
                                mission=mission,
                                question=q,
                                order=order_idx,
                            )
                        created += 1
                    # Progress: yesterday completed, today fresh, tomorrow not_started.
                    # UserMissionProgress is one-to-one on Mission — no
                    # account/mission_date on the row itself (it derives them).
                    if d < today:
                        UserMissionProgress.objects.update_or_create(
                            mission=mission,
                            defaults={
                                "status": "completed",
                                "percentage": 100,
                                "score": 30,
                                "total_questions": len(qs),
                                "questions_attempted": len(qs),
                                "correct_answers": max(0, len(qs) - 1),
                                "wrong_answers": min(1, len(qs)),
                                "exp_earned": 20,
                                "started_at": timezone.now() - timedelta(days=1, hours=1),
                                "completed_at": timezone.now() - timedelta(days=1),
                                "time_spent_seconds": 180,
                            },
                        )
                    elif d == today:
                        UserMissionProgress.objects.update_or_create(
                            mission=mission,
                            defaults={
                                "status": "not_started",
                                "percentage": 0,
                                "total_questions": len(qs),
                            },
                        )
        self.stdout.write(f"    {created} mission(s) created (idempotent across re-runs).")

    def _dedup_answer_rows(self):
        """
        The backend's `check_answer` view uses Answer.objects.get_or_create()
        keyed on (user, question), which throws MultipleObjectsReturned ->
        HTTP 500 if duplicate Answer rows exist. Running seed_test_data
        twice (without --flush in between) produces exactly that situation
        because the seed isn't idempotent on Answer creation.

        Defensive cleanup: for every (user, question) pair with >1 Answer
        row, keep the most recent and delete the rest. Safe to run any
        number of times.
        """
        self.stdout.write("  • De-duplicating Answer rows (defence vs. backend 500)…")
        from gyaan_buddy.subjects.models import Answer
        from django.db.models import Count
        dups = (
            Answer.objects
            .values('user_id', 'question_id')
            .annotate(c=Count('id'))
            .filter(c__gt=1)
        )
        deleted = 0
        for d in dups:
            rows = list(
                Answer.objects
                .filter(user_id=d['user_id'], question_id=d['question_id'])
                .order_by('-created_at')
            )
            for r in rows[1:]:
                r.delete()
                deleted += 1
        self.stdout.write(f"    {deleted} duplicate Answer row(s) removed.")

    def _seed_notifications(
        self, accounts: dict[str, Account], subjects: list[Subject],
    ):
        self.stdout.write("  • Generating notifications per student…")
        now = timezone.now()
        created = 0
        for username, _ in STUDENT_USERNAMES:
            acc = accounts.get(username)
            if not acc:
                continue
            # Skip if we already have demo notifications for this user
            if Notification.objects.filter(
                user=acc, notification_id__startswith="demo:"
            ).exists():
                continue

            samples = [
                {
                    "type": "mission",
                    "minutes_ago": 25,
                    "data": {
                        "title": "🎯 New mission unlocked",
                        "body": f"Daily {subjects[0].name} mission is ready for you.",
                        "type": "mission_created",
                        "action": "open_mission",
                        "subject_name": subjects[0].name,
                    },
                    "is_read": False,
                },
                {
                    "type": "test",
                    "minutes_ago": 90,
                    "data": {
                        "title": "📝 Upcoming test",
                        "body": "English test in 2 days — start preparing now.",
                        "type": "test_created",
                        "action": "open_test",
                        "subject_name": "English",
                    },
                    "is_read": False,
                },
                {
                    "type": "user",
                    "minutes_ago": 60 * 4,
                    "data": {
                        "title": "🏆 New personal best!",
                        "body": "You earned XP today. Keep the streak going.",
                        "type": "level_up",
                        "action": "open_profile",
                    },
                    "is_read": False,
                },
                {
                    "type": "module",
                    "minutes_ago": 60 * 10,
                    "data": {
                        "title": "📚 Chapter completed",
                        "body": "Mathematics · Algebra · Linear Equations — well done!",
                        "type": "chapter_complete",
                        "action": "open_chapter",
                        "subject_name": "Mathematics",
                    },
                    "is_read": True,
                },
                {
                    "type": "user",
                    "minutes_ago": 60 * 30,
                    "data": {
                        "title": "📈 Leaderboard climb",
                        "body": "You moved up 2 ranks this week in Class 9-A.",
                        "type": "rank_change",
                        "action": "open_leaderboard",
                    },
                    "is_read": True,
                },
            ]

            for i, s in enumerate(samples):
                n = Notification.objects.create(
                    user=acc,
                    notification_id=f"demo:{username}:{i}:{uuid.uuid4().hex[:8]}",
                    type=s["type"],
                    triggered_by="auto",
                    data=s["data"],
                    is_read=s["is_read"],
                )
                # Backdate created_at so timestamps look natural in the list
                n.created_at = now - timedelta(minutes=s["minutes_ago"])
                n.save(update_fields=["created_at"])
                created += 1

        self.stdout.write(f"    {created} notification(s) created.")
