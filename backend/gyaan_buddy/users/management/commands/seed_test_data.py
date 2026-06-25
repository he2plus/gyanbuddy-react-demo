"""
Management command: seed_test_data  (v2 — full coverage)
==========================================================

Creates a deterministic, realistic dataset for testing every major feature.

Usage:
    python manage.py seed_test_data            # create fresh data (skips already-existing records)
    python manage.py seed_test_data --flush    # wipe seed data and recreate

WARNING: --flush deletes schools/subjects by the test names/codes below.
         Only run this on development/staging databases.

════════════════════════════════════════════════════════════════
SCHOOL 1 — Delhi Public School (DPS)
  Grade   : Grade 9
  Class   : 9-A

  Subjects: Mathematics (MATH), Science (SCI), English (ENG)

  Teacher : Ramesh Kumar  (ramesh.kumar / Test@1234)
    Teaches Mathematics + Science in 9-A

  Students (all in 9-A, different subject enrollments):
    alice.sharma   → Mathematics, Science
    bob.verma      → Mathematics
    charlie.nair   → Science, English
    diana.patel    → Mathematics, Science, English
    eve.gupta      → English

  Content per subject: 2 modules × 2 chapters each (3 with due_date, 1 without)

  Tests (one per subject, assigned to class 9-A):
    Math Test    — 7 Q from Linear Equations + Quadratic Equations
    Science Test — 7 Q from Motion + Force and Laws
    English Test — 7 Q from Nouns and Pronouns + Tenses

  Missions (daily mission per student per enrolled subject):
    alice  → Math mission + Science mission
    bob    → Math mission
    charlie→ Science mission + English mission
    diana  → Math mission + Science mission + English mission
    eve    → English mission

  Competitions:
    Math Championship  (MATHCHMP) — 5 Q from Triangles   — alice, bob, diana
    Science Bowl       (SCIBOWL1) — 4 Q from Motion + 1 from Force — alice, charlie, diana

SCHOOL 2 — St. Mary's School (SMS)  [isolation data]
  Teacher : sms.teacher
  Students: sms.student1, sms.student2
  Answers for the SAME math questions — MUST NOT appear in DPS dashboard.

Expected Teacher Dashboard (Ramesh, subject=Mathematics)
─────────────────────────────────────────────────────────
  Total Students               3    (Alice, Bob, Diana)
  Chapters Covered             3/4  (Linear Eq, Quadratic Eq, Triangles have due_date)
  Last Assignment Attempt Rate 67%  (Triangles: Alice+Diana attempted / 3 total)
  Attempt Rate                 89%  ((100+67+100)/3)
  Overall Student %            35%  (see module docstring above)
  Weak Topics                  2    (Quadratic Eq 37.5%, Triangles 30%)
════════════════════════════════════════════════════════════════
"""
from __future__ import annotations

from datetime import date, datetime, timezone as dt_timezone

from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from gyaan_buddy.users.models import (
    Account,
    Class,
    Competition,
    CompetitionQuestion,
    Grade,
    Level,
    Mission,
    MissionQuestion,
    School,
    Student,
    StudentSubjectEnrollment,
    Teacher,
    TeacherProfile,
    Test,
    TestModuleChapter,
    TestQuestion,
    UserChapterProgress,
    UserCompetitionProgress,
    UserMissionProgress,
    UserModuleProgress,
    UserProfile,
    UserTestProgress,
)
from gyaan_buddy.subjects.models import (
    Answer,
    Module,
    ModuleChapter,
    ModuleContent,
    Option,
    Question,
    Subject,
)

# ── Constants ──────────────────────────────────────────────────────────────────
UTC = dt_timezone.utc
PASSWORD = "Test@1234"
T, F = True, False  # shorthand for answer plans

SCHOOL_NAMES = ["Delhi Public School", "St. Mary's School"]

SUBJECTS_DEF = [
    {"name": "Mathematics", "code": "MATH", "color": "4CAF50", "order": 1},
    {"name": "Science",     "code": "SCI",  "color": "2196F3", "order": 2},
    {"name": "English",     "code": "ENG",  "color": "FF9800", "order": 3},
]

# ── Content fixtures ───────────────────────────────────────────────────────────
#  Each entry: module_name → {order, chapters: [{title, order, due_date, questions}]}
#  Each question: {text, correct (0-based index), options [list of 4]}

MATH_CONTENT = {
    "Algebra": {
        "order": 1,
        "chapters": [
            {
                "title": "Linear Equations",
                "order": 1,
                "due_date": date(2025, 11, 1),
                "questions": [
                    {"text": "Solve: x + 5 = 10", "correct": 0,
                     "options": ["x = 5", "x = 15", "x = 2", "x = 50"]},
                    {"text": "Solve: 2x = 8", "correct": 1,
                     "options": ["x = 2", "x = 4", "x = 16", "x = 6"]},
                    {"text": "Solve: x - 3 = 7", "correct": 2,
                     "options": ["x = 4", "x = 3", "x = 10", "x = 21"]},
                    {"text": "Solve: 3x + 2 = 11", "correct": 3,
                     "options": ["x = 4", "x = 5", "x = 2", "x = 3"]},
                ],
            },
            {
                "title": "Quadratic Equations",
                "order": 2,
                "due_date": date(2025, 11, 15),
                "questions": [
                    {"text": "Solve: x^2 = 4", "correct": 0,
                     "options": ["x = +/-2", "x = 2", "x = 4", "x = 16"]},
                    {"text": "Solve: x^2 - 5x + 6 = 0", "correct": 1,
                     "options": ["x = 1,6", "x = 2,3", "x = -2,-3", "x = 5,1"]},
                    {"text": "Solve: x^2 + x - 6 = 0", "correct": 2,
                     "options": ["x = 3,2", "x = -3,2", "x = 2,-3", "x = 1,-6"]},
                ],
            },
        ],
    },
    "Geometry": {
        "order": 2,
        "chapters": [
            {
                "title": "Triangles",
                "order": 1,
                "due_date": date(2025, 12, 1),
                "questions": [
                    {"text": "Sum of angles in a triangle?", "correct": 0,
                     "options": ["180 deg", "360 deg", "90 deg", "270 deg"]},
                    {"text": "Right triangle legs 3 and 4, hypotenuse = ?", "correct": 1,
                     "options": ["6", "5", "7", "4"]},
                    {"text": "Area of triangle = ?", "correct": 2,
                     "options": ["b x h", "2 x b x h", "0.5 x b x h", "b squared"]},
                    {"text": "All-equal-sides triangle is called?", "correct": 3,
                     "options": ["Isosceles", "Scalene", "Right", "Equilateral"]},
                    {"text": "SSS congruence: SSS stands for?", "correct": 0,
                     "options": ["Side-Side-Side", "Sum-Side-Side", "Side-Sum-Sum", "Sum-Sum-Sum"]},
                ],
            },
            {
                "title": "Circles",
                "order": 2,
                "due_date": None,
                "questions": [
                    {"text": "Circumference of a circle = ?", "correct": 0,
                     "options": ["2*pi*r", "pi*r^2", "pi*r", "2*pi*r^2"]},
                    {"text": "Area of a circle = ?", "correct": 1,
                     "options": ["2*pi*r", "pi*r^2", "pi*r", "2*pi*r^2"]},
                    {"text": "Diameter = ?", "correct": 2,
                     "options": ["r/2", "r", "2r", "pi*r"]},
                ],
            },
        ],
    },
}

SCI_CONTENT = {
    "Physics": {
        "order": 1,
        "chapters": [
            {
                "title": "Motion",
                "order": 1,
                "due_date": date(2025, 11, 5),
                "questions": [
                    {"text": "Speed = ?", "correct": 0,
                     "options": ["Distance/Time", "Distance x Time", "Time/Distance", "Force/Mass"]},
                    {"text": "Unit of acceleration?", "correct": 1,
                     "options": ["m/s", "m/s^2", "m", "kg"]},
                    {"text": "Uniform motion means?", "correct": 2,
                     "options": ["Variable speed", "Zero displacement", "Constant velocity", "Increasing speed"]},
                    {"text": "Slope of distance-time graph = ?", "correct": 3,
                     "options": ["Acceleration", "Displacement", "Force", "Speed"]},
                ],
            },
            {
                "title": "Force and Laws of Motion",
                "order": 2,
                "due_date": date(2025, 11, 20),
                "questions": [
                    {"text": "Newton's First Law is also called?", "correct": 0,
                     "options": ["Law of Inertia", "Law of Action", "Law of Gravity", "Law of Momentum"]},
                    {"text": "F = ma is Newton's?", "correct": 1,
                     "options": ["First Law", "Second Law", "Third Law", "Fourth Law"]},
                    {"text": "SI unit of force?", "correct": 2,
                     "options": ["kg", "m/s", "Newton", "Joule"]},
                ],
            },
        ],
    },
    "Chemistry": {
        "order": 2,
        "chapters": [
            {
                "title": "Atoms and Molecules",
                "order": 1,
                "due_date": date(2025, 12, 10),
                "questions": [
                    {"text": "Smallest particle of an element?", "correct": 0,
                     "options": ["Atom", "Molecule", "Electron", "Proton"]},
                    {"text": "Chemical formula of water?", "correct": 1,
                     "options": ["HO", "H2O", "H2O2", "OH"]},
                    {"text": "Avogadro's number = ?", "correct": 2,
                     "options": ["6.022 x 10^22", "3.011 x 10^23", "6.022 x 10^23", "6.022 x 10^24"]},
                    {"text": "Atomic mass unit abbreviation?", "correct": 3,
                     "options": ["g", "kg", "mg", "u"]},
                ],
            },
            {
                "title": "Structure of Atom",
                "order": 2,
                "due_date": None,
                "questions": [
                    {"text": "Charge on an electron?", "correct": 0,
                     "options": ["-1", "+1", "0", "+2"]},
                    {"text": "Protons are located in?", "correct": 1,
                     "options": ["Orbit", "Nucleus", "Shell", "Electron cloud"]},
                    {"text": "Atomic number = ?", "correct": 2,
                     "options": ["Protons + Neutrons", "Neutrons only", "Protons only", "Electrons only"]},
                ],
            },
        ],
    },
}

ENG_CONTENT = {
    "Grammar": {
        "order": 1,
        "chapters": [
            {
                "title": "Nouns and Pronouns",
                "order": 1,
                "due_date": date(2025, 11, 10),
                "questions": [
                    {"text": "Which of the following is a proper noun?", "correct": 0,
                     "options": ["Delhi", "city", "book", "happy"]},
                    {"text": "'He' is a?", "correct": 1,
                     "options": ["Noun", "Pronoun", "Verb", "Adjective"]},
                    {"text": "Collective noun for a group of lions?", "correct": 2,
                     "options": ["Pack", "Flock", "Pride", "Herd"]},
                    {"text": "Abstract noun from the word 'brave'?", "correct": 3,
                     "options": ["Braver", "Braving", "Braved", "Bravery"]},
                ],
            },
            {
                "title": "Tenses",
                "order": 2,
                "due_date": date(2025, 11, 25),
                "questions": [
                    {"text": "'She is singing' is which tense?", "correct": 0,
                     "options": ["Present Continuous", "Past Simple", "Future Simple", "Present Perfect"]},
                    {"text": "Past tense of 'go'?", "correct": 1,
                     "options": ["Goed", "Went", "Gone", "Going"]},
                    {"text": "'I will eat' is which tense?", "correct": 2,
                     "options": ["Present Simple", "Past Simple", "Future Simple", "Past Perfect"]},
                ],
            },
        ],
    },
    "Literature": {
        "order": 2,
        "chapters": [
            {
                "title": "The Fun They Had",
                "order": 1,
                "due_date": date(2025, 12, 5),
                "questions": [
                    {"text": "Author of 'The Fun They Had'?", "correct": 0,
                     "options": ["Isaac Asimov", "Shakespeare", "Rabindranath Tagore", "Premchand"]},
                    {"text": "Year 'The Fun They Had' is set in?", "correct": 1,
                     "options": ["2055", "2157", "1857", "2023"]},
                    {"text": "Margie's teacher is a?", "correct": 2,
                     "options": ["Human teacher", "Robot", "Computer", "Mechanical teacher"]},
                    {"text": "Tommy found an old?", "correct": 3,
                     "options": ["Diary", "Map", "Photograph", "Book"]},
                ],
            },
            {
                "title": "The Sound of Music",
                "order": 2,
                "due_date": None,
                "questions": [
                    {"text": "Evelyn Glennie is a famous?", "correct": 0,
                     "options": ["Percussionist", "Violinist", "Pianist", "Singer"]},
                    {"text": "Evelyn Glennie is?", "correct": 1,
                     "options": ["Blind", "Deaf", "Mute", "Visually impaired"]},
                    {"text": "Bismillah Khan's instrument?", "correct": 2,
                     "options": ["Tabla", "Sitar", "Shehnai", "Flute"]},
                ],
            },
        ],
    },
}

SUBJECT_CONTENT = {
    "Mathematics": MATH_CONTENT,
    "Science":     SCI_CONTENT,
    "English":     ENG_CONTENT,
}

# ── Student definitions ────────────────────────────────────────────────────────
# (username, first, last, roll, enrolled_subject_names)
STUDENT_DEFS = [
    ("alice.sharma",  "Alice",   "Sharma", 1, ["Mathematics", "Science"]),
    ("bob.verma",     "Bob",     "Verma",  2, ["Mathematics"]),
    ("charlie.nair",  "Charlie", "Nair",   3, ["Science", "English"]),
    ("diana.patel",   "Diana",   "Patel",  4, ["Mathematics", "Science", "English"]),
    ("eve.gupta",     "Eve",     "Gupta",  5, ["English"]),
]

# ── Practice answer plans ──────────────────────────────────────────────────────
# chapter_title → {student_idx: [(question_idx, is_correct), ...]}
# student_idx is relative to subject's student list:
#   math_students  = [alice(0), bob(1), diana(2)]
#   sci_students   = [alice(0), charlie(1), diana(2)]
#   eng_students   = [charlie(0), diana(1), eve(2)]

MATH_ANSWER_PLAN = {
    "Linear Equations": {
        0: [(0,T),(1,T),(2,T),(3,F)],               # alice:  3/4
        1: [(0,T),(1,F),(2,F),(3,F)],               # bob:    1/4
        2: [(0,T),(1,T),(2,T),(3,T)],               # diana:  4/4
    },
    "Quadratic Equations": {
        0: [(0,F),(1,F),(2,T)],                     # alice:  1/3
        1: [(0,F),(1,F)],                           # bob:    0/2 (partial)
        2: [(0,T),(1,T),(2,F)],                     # diana:  2/3
    },
    "Triangles": {
        0: [(0,T),(1,F),(2,F),(3,F),(4,F)],         # alice:  1/5
        # bob: not attempted
        2: [(0,T),(1,T),(2,F),(3,F),(4,F)],         # diana:  2/5
    },
    "Circles": {                                    # NOT DUE — excluded from dashboard
        0: [(0,T),(1,T)],
        2: [(0,T)],
    },
}

SCI_ANSWER_PLAN = {
    "Motion": {
        0: [(0,T),(1,T),(2,F),(3,T)],               # alice:  3/4
        1: [(0,T),(1,F),(2,F),(3,F)],               # charlie: 1/4
        2: [(0,T),(1,T),(2,T),(3,T)],               # diana:  4/4
    },
    "Force and Laws of Motion": {
        0: [(0,T),(1,F),(2,T)],                     # alice:  2/3
        1: [(0,F),(1,F)],                           # charlie: 0/2
        2: [(0,T),(1,T),(2,T)],                     # diana:  3/3
    },
    "Atoms and Molecules": {
        0: [(0,T),(1,T),(2,F),(3,F)],               # alice:  2/4
        1: [(0,T),(1,F),(2,F),(3,T)],               # charlie: 2/4
        2: [(0,T),(1,T),(2,T),(3,F)],               # diana:  3/4
    },
    "Structure of Atom": {                          # NOT DUE
        0: [(0,T),(1,T)],
        2: [(0,T)],
    },
}

ENG_ANSWER_PLAN = {
    "Nouns and Pronouns": {
        0: [(0,T),(1,T),(2,F),(3,T)],               # charlie: 3/4
        1: [(0,T),(1,T),(2,T),(3,T)],               # diana:   4/4
        2: [(0,F),(1,T),(2,F),(3,F)],               # eve:     1/4
    },
    "Tenses": {
        0: [(0,T),(1,F),(2,T)],                     # charlie: 2/3
        1: [(0,T),(1,T),(2,T)],                     # diana:   3/3
        2: [(0,F),(1,F)],                           # eve:     0/2
    },
    "The Fun They Had": {
        0: [(0,T),(1,F),(2,F),(3,T)],               # charlie: 2/4
        1: [(0,T),(1,T),(2,T),(3,T)],               # diana:   4/4
        2: [(0,T),(1,F),(2,F),(3,F)],               # eve:     1/4
    },
    "The Sound of Music": {                         # NOT DUE
        0: [(0,T),(1,T)],
        1: [(0,T)],
    },
}

SUBJECT_ANSWER_PLANS = {
    "Mathematics": MATH_ANSWER_PLAN,
    "Science":     SCI_ANSWER_PLAN,
    "English":     ENG_ANSWER_PLAN,
}

# ── Test answer plans ──────────────────────────────────────────────────────────
# Each list maps to test questions in order (same order as TEST_CHAPTER_CONFIGS).
# True = answered correctly, False = answered incorrectly.
# student_idx same ordering as practice answer plans per subject.

MATH_TEST_PLAN = {
    # 7 Q: 4 from LinearEq + 3 from QuadraticEq
    0: [T,T,T,F, T,T,F],    # alice:  5/7
    1: [T,F,F,F, F,F,T],    # bob:    2/7
    2: [T,T,T,T, T,T,F],    # diana:  6/7
}
SCI_TEST_PLAN = {
    # 7 Q: 4 from Motion + 3 from Force
    0: [T,T,F,T, T,F,T],    # alice:  5/7
    1: [T,F,F,F, F,T,F],    # charlie: 2/7
    2: [T,T,T,T, T,T,T],    # diana:  7/7
}
ENG_TEST_PLAN = {
    # 7 Q: 4 from Nouns + 3 from Tenses
    0: [T,T,F,T, T,F,T],    # charlie: 5/7
    1: [T,T,T,T, T,T,T],    # diana:   7/7
    2: [F,T,F,F, F,F,F],    # eve:     1/7
}

# ── Mission configs ────────────────────────────────────────────────────────────
# First 5 questions of each subject (Q0-Q2 from ch1 + Q0-Q1 from ch2).
# stats: (correct, attempted, total_q=5)
MISSION_STATS = {
    "Mathematics": {
        0: (3, 5),   # alice: 3/5
        1: (1, 5),   # bob:   1/5
        2: (5, 5),   # diana: 5/5
    },
    "Science": {
        0: (4, 5),   # alice:   4/5
        1: (1, 5),   # charlie: 1/5
        2: (5, 5),   # diana:   5/5
    },
    "English": {
        0: (3, 5),   # charlie: 3/5
        1: (5, 5),   # diana:   5/5
        2: (1, 5),   # eve:     1/5
    },
}

# ── Competition configs ────────────────────────────────────────────────────────
COMPETITION_CONFIGS = [
    {
        "title": "Math Championship",
        "code": "MATHCHMP",
        "subject": "Mathematics",
        "chapter": "Triangles",        # competition_type = subject_with_chapter
        "participant_scores": {
            0: (40, "completed"),       # alice:   40 pts (4 correct × 10)
            1: (10, "completed"),       # bob:     10 pts (1 correct × 10)
            2: (50, "completed"),       # diana:   50 pts (5 correct × 10)
        },
        "student_list": "math",        # which subject student list to use
    },
    {
        "title": "Science Bowl",
        "code": "SCIBOWL1",
        "subject": "Science",
        "chapter": "Motion",
        "participant_scores": {
            0: (30, "completed"),       # alice:   30 pts
            1: (10, "in_progress"),     # charlie: 10 pts
            2: (40, "completed"),       # diana:   40 pts
        },
        "student_list": "sci",
    },
]

# ── Test usernames (for flush) ─────────────────────────────────────────────────
SEED_USERNAMES = [
    "ramesh.kumar", "alice.sharma", "bob.verma",
    "charlie.nair", "diana.patel", "eve.gupta",
    "sms.teacher", "sms.student1", "sms.student2",
]


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_account(username, first_name, last_name, user_type, school):
    account, _ = Account.objects.get_or_create(
        username=username,
        defaults={
            "first_name": first_name,
            "last_name": last_name,
            "email": f"{username}@test.edu",
            "password": make_password(PASSWORD),
            "is_active": True,
        },
    )
    profile, _ = UserProfile.objects.get_or_create(
        account=account,
        defaults={"school": school, "user_type": user_type},
    )
    if profile.school_id != school.pk or profile.user_type != user_type:
        profile.school = school
        profile.user_type = user_type
        profile.save(update_fields=["school", "user_type"])
    return account, profile


def _ensure_level():
    level, _ = Level.objects.get_or_create(
        name=1, defaults={"min_exp": 0, "max_exp": 499}
    )
    return level


def _pick_option(question, is_correct):
    """Return the option text for correct or incorrect answer."""
    qs = question.options.filter(is_correct=is_correct)
    opt = qs.first()
    return opt.option_text if opt else ("correct" if is_correct else "wrong")


# ═════════════════════════════════════════════════════════════════════════════
class Command(BaseCommand):
    help = "Seed deterministic test data covering all models (Test, Mission, Competition, Progress)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--flush",
            action="store_true",
            help="Delete existing seed data before re-seeding.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        if options["flush"]:
            self.stdout.write(self.style.WARNING("⚠  Flushing seed data…"))
            self._flush()

        self.stdout.write(self.style.MIGRATE_HEADING("\n═══ Seeding full test data ═══\n"))

        level = _ensure_level()
        school1, school2 = self._create_schools()

        # ── School 1 ──
        subjects = self._create_subjects(school1)
        grade1 = self._create_grade(school1)
        class_9a = self._create_class(school1, grade1, "9-A", subjects)

        teacher_acc, teacher_up = self._create_teacher(school1)
        teacher_profile = teacher_up.teacher_profile
        self._create_teacher_assignments(
            teacher_profile, class_9a, subjects, ["Mathematics", "Science"]
        )

        all_students = self._create_students(school1, class_9a, subjects, level)
        # Derive per-subject student lists (order matters for answer plan indices)
        math_students  = [all_students[0], all_students[1], all_students[3]]  # alice, bob, diana
        sci_students   = [all_students[0], all_students[2], all_students[3]]  # alice, charlie, diana
        eng_students   = [all_students[2], all_students[3], all_students[4]]  # charlie, diana, eve

        subject_students = {
            "Mathematics": math_students,
            "Science":     sci_students,
            "English":     eng_students,
        }

        # ── Content ──
        content = {}
        for subj_name, subj_def in SUBJECT_CONTENT.items():
            self.stdout.write(f"\n  Creating {subj_name} content…")
            content[subj_name] = self._create_subject_content(subjects[subj_name], subj_def, class_9a)

        # ── Practice answers ──
        self.stdout.write("\n  Creating practice answers…")
        for subj_name, answer_plan in SUBJECT_ANSWER_PLANS.items():
            self._create_practice_answers(
                students=subject_students[subj_name],
                content=content[subj_name],
                answer_plan=answer_plan,
            )

        # ── Tests ──
        self.stdout.write("\n  Creating tests…")
        math_test = self._create_test(
            class_instance=class_9a,
            teacher_acc=teacher_acc,
            subject=subjects["Mathematics"],
            content=content["Mathematics"],
            chapter_titles=["Linear Equations", "Quadratic Equations"],
            students=math_students,
            test_plan=MATH_TEST_PLAN,
            test_dt=datetime(2025, 11, 20, 4, 30, tzinfo=UTC),
        )
        sci_test = self._create_test(
            class_instance=class_9a,
            teacher_acc=teacher_acc,
            subject=subjects["Science"],
            content=content["Science"],
            chapter_titles=["Motion", "Force and Laws of Motion"],
            students=sci_students,
            test_plan=SCI_TEST_PLAN,
            test_dt=datetime(2025, 11, 27, 4, 30, tzinfo=UTC),
        )
        eng_test = self._create_test(
            class_instance=class_9a,
            teacher_acc=teacher_acc,
            subject=subjects["English"],
            content=content["English"],
            chapter_titles=["Nouns and Pronouns", "Tenses"],
            students=eng_students,
            test_plan=ENG_TEST_PLAN,
            test_dt=datetime(2025, 12, 4, 4, 30, tzinfo=UTC),
        )

        # ── Missions ──
        self.stdout.write("\n  Creating missions…")
        mission_date = date(2025, 11, 15)
        for subj_name, students in subject_students.items():
            self._create_missions(
                subject=subjects[subj_name],
                content=content[subj_name],
                students=students,
                mission_stats=MISSION_STATS[subj_name],
                mission_date=mission_date,
            )

        # ── Competitions ──
        self.stdout.write("\n  Creating competitions…")
        for comp_cfg in COMPETITION_CONFIGS:
            students_for_comp = (
                math_students if comp_cfg["student_list"] == "math" else sci_students
            )
            self._create_competition(
                cfg=comp_cfg,
                subject=subjects[comp_cfg["subject"]],
                content=content[comp_cfg["subject"]],
                students=students_for_comp,
                created_by=teacher_acc,
            )

        # ── Progress ──
        self.stdout.write("\n  Creating module/chapter progress…")
        self._create_progress(all_students)

        # ── School 2 isolation data ──
        self.stdout.write("\n  Creating School 2 isolation data…")
        self._create_school2_data(school2, level)

        self._print_summary(
            school1, class_9a, teacher_acc, all_students,
            content["Mathematics"], math_test, sci_test, eng_test,
        )

    # ═══════════════════════════════════════════════════════════════════════════
    # Data creation helpers
    # ═══════════════════════════════════════════════════════════════════════════

    def _flush(self):
        Account.objects.filter(username__in=SEED_USERNAMES).delete()
        School.objects.filter(name__in=SCHOOL_NAMES).delete()
        Subject.objects.filter(school__name__in=SCHOOL_NAMES).delete()
        Competition.objects.filter(code__in=["MATHCHMP", "SCIBOWL1"]).delete()
        self.stdout.write("  Flush complete.")

    def _create_subjects(self, school):
        subjects = {}
        for s in SUBJECTS_DEF:
            subj, created = Subject.objects.get_or_create(
                code=s["code"],
                school=school,
                defaults={"name": s["name"], "is_active": True, "order": s["order"], "color": s["color"]},
            )
            subjects[s["name"]] = subj
            if created:
                self.stdout.write(f"  [+] Subject: {subj.name} ({subj.code}) @ {school.name}")
        return subjects

    def _create_schools(self):
        s1, _ = School.objects.get_or_create(name=SCHOOL_NAMES[0], defaults={"is_active": True})
        s2, _ = School.objects.get_or_create(name=SCHOOL_NAMES[1], defaults={"is_active": True})
        self.stdout.write(f"  [+] Schools: {s1.name} | {s2.name}")
        return s1, s2

    def _create_grade(self, school):
        grade, _ = Grade.objects.get_or_create(
            school=school, name="Grade 9", defaults={"is_active": True}
        )
        return grade

    def _create_class(self, school, grade, name, subjects):
        cls, created = Class.objects.get_or_create(
            school=school, name=name,
            defaults={"grade": grade, "is_active": True},
        )
        for subj in subjects.values():
            cls.subjects.add(subj)
        if created:
            self.stdout.write(f"  [+] Class: {school.name} / {name}")
        return cls

    def _create_teacher(self, school):
        acc, profile = _make_account("ramesh.kumar", "Ramesh", "Kumar", "teacher", school)
        TeacherProfile.objects.get_or_create(
            user_profile=profile,
            defaults={"employee_id": "EMP001", "is_class_teacher": True},
        )
        self.stdout.write(f"  [+] Teacher: {acc.get_full_name()} ({acc.username})")
        return acc, profile

    def _create_teacher_assignments(self, teacher_profile, class_instance, subjects, subject_names):
        for name in subject_names:
            Teacher.objects.get_or_create(
                teacher=teacher_profile,
                class_instance=class_instance,
                subject=subjects[name],
                defaults={"is_deleted": False},
            )
        self.stdout.write(f"  [+] Assignments: Ramesh → {', '.join(subject_names)}")

    def _create_students(self, school, class_instance, subjects, level):
        all_students = []
        for uname, first, last, roll, enrolled in STUDENT_DEFS:
            acc, profile = _make_account(uname, first, last, "student", school)
            student, _ = Student.objects.get_or_create(
                user_profile=profile,
                defaults={
                    "class_instance": class_instance,
                    "roll_number": roll,
                    "total_exp": roll * 50,
                    "level": level,
                },
            )
            if student.class_instance_id != class_instance.pk:
                student.class_instance = class_instance
                student.save(update_fields=["class_instance"])
            for subj_name in enrolled:
                StudentSubjectEnrollment.objects.get_or_create(
                    student=student,
                    subject=subjects[subj_name],
                    defaults={"is_active": True},
                )
            all_students.append(acc)
            self.stdout.write(f"  [+] Student: {first} {last} → {', '.join(enrolled)}")
        return all_students

    def _create_subject_content(self, subject, content_def, class_instance):
        """
        Creates Modules, ModuleChapters, Questions, Options, ModuleContent.
        Returns {chapter_title: {"chapter": ch, "questions": [q, ...], "module": m}}
        """
        result = {}
        for module_name, module_data in content_def.items():
            module, _ = Module.objects.get_or_create(
                subject=subject,
                class_instance=class_instance,
                name=module_name,
                defaults={
                    "order": module_data["order"],
                    "is_active": True,
                    "is_enabled": True,
                    "description": f"{module_name} for {subject.name}",
                },
            )
            for chap_data in module_data["chapters"]:
                chapter, _ = ModuleChapter.objects.get_or_create(
                    module=module,
                    order=chap_data["order"],
                    defaults={
                        "title": chap_data["title"],
                        "due_date": chap_data["due_date"],
                        "is_enabled": True,
                        "max_questions": len(chap_data["questions"]),
                    },
                )
                if chapter.due_date != chap_data["due_date"]:
                    chapter.due_date = chap_data["due_date"]
                    chapter.save(update_fields=["due_date"])

                chapter_questions = []
                for q_idx, q_data in enumerate(chap_data["questions"]):
                    question, _ = Question.objects.get_or_create(
                        question_text=q_data["text"],
                        defaults={
                            "question_type": "mcq_single",
                            "difficulty_level": "medium",
                            "exp_points": 10,
                            "is_active": True,
                        },
                    )
                    for opt_idx, opt_text in enumerate(q_data["options"]):
                        Option.objects.get_or_create(
                            question=question,
                            option_text=opt_text,
                            defaults={
                                "order": opt_idx + 1,
                                "is_correct": (opt_idx == q_data["correct"]),
                            },
                        )
                    ModuleContent.objects.get_or_create(
                        chapter=chapter,
                        order=q_idx + 1,
                        defaults={"content_type": "question", "question": question},
                    )
                    chapter_questions.append(question)

                result[chap_data["title"]] = {
                    "chapter": chapter,
                    "questions": chapter_questions,
                    "module": module,
                }
                due_label = chap_data["due_date"].strftime("%Y-%m-%d") if chap_data["due_date"] else "no due"
                self.stdout.write(
                    f"    [+] {chapter.title} ({due_label}, {len(chapter_questions)} Q)"
                )
        return result

    def _create_practice_answers(self, students, content, answer_plan):
        """Creates Answer objects for chapter practice (test=None)."""
        for chapter_title, student_answers in answer_plan.items():
            chapter_data = content[chapter_title]
            chapter = chapter_data["chapter"]
            questions = chapter_data["questions"]
            for student_idx, qa_list in student_answers.items():
                acc = students[student_idx]
                for q_idx, is_correct in qa_list:
                    question = questions[q_idx]
                    Answer.objects.get_or_create(
                        user=acc,
                        question=question,
                        test=None,
                        defaults={
                            "is_correct": is_correct,
                            "answer": _pick_option(question, is_correct),
                            "chapter": chapter,
                            "tries": 1,
                        },
                    )

    def _create_test(
        self, class_instance, teacher_acc, subject, content,
        chapter_titles, students, test_plan, test_dt,
    ):
        """Creates Test, TestModuleChapter, TestQuestion, Answer (test-linked), UserTestProgress."""
        test, created = Test.objects.get_or_create(
            class_group=class_instance,
            subject=subject,
            test_datetime=test_dt,
            defaults={"duration": 30, "created_by": teacher_acc},
        )
        if created:
            test.class_groups.set([class_instance])

        # Collect ordered (question, chapter, module) for the test
        test_q_list = []
        for ch_title in chapter_titles:
            ch_data = content[ch_title]
            module = ch_data["module"]
            chapter = ch_data["chapter"]
            TestModuleChapter.objects.get_or_create(
                test=test, module_chapter=chapter,
                defaults={"module": module},
            )
            for q in ch_data["questions"]:
                test_q_list.append((q, chapter))

        for order, (q, _) in enumerate(test_q_list, start=1):
            TestQuestion.objects.get_or_create(
                test=test, question=q, defaults={"order": order}
            )

        for student_idx, result_list in test_plan.items():
            acc = students[student_idx]
            n_total = len(test_q_list)
            n_attempted = len(result_list)
            n_correct = sum(result_list)

            for order, (is_correct) in enumerate(result_list):
                q, ch = test_q_list[order]
                Answer.objects.get_or_create(
                    user=acc,
                    question=q,
                    test=test,
                    defaults={
                        "is_correct": is_correct,
                        "answer": _pick_option(q, is_correct),
                        "chapter": ch,
                        "tries": 1,
                    },
                )

            UserTestProgress.objects.get_or_create(
                account=acc,
                test=test,
                defaults={
                    "status": "completed",
                    "total_questions": n_total,
                    "questions_attempted": n_attempted,
                    "correct_answers": n_correct,
                    "wrong_answers": n_attempted - n_correct,
                    "score": n_correct * 10,
                    "time_spent_seconds": n_attempted * 45,
                    "exp_earned": n_correct * 5,
                    "started_at": test_dt,
                    "completed_at": test_dt,
                },
            )

        subject_label = subject.name
        self.stdout.write(
            f"  [+] Test: {subject_label} — {len(test_q_list)} Q,"
            f" {len(test_plan)} students took it"
        )
        return test

    def _create_missions(self, subject, content, students, mission_stats, mission_date):
        """Creates Mission, MissionQuestion, UserMissionProgress per student."""
        # Pick first 5 questions across the first two chapters
        mission_questions = []
        for ch_title, ch_data in content.items():
            for q in ch_data["questions"]:
                mission_questions.append((q, ch_data["chapter"]))
            if len(mission_questions) >= 5:
                break
        mission_questions = mission_questions[:5]

        for student_idx, (n_correct, n_attempted) in mission_stats.items():
            acc = students[student_idx]
            status = "completed" if n_attempted == 5 and n_correct >= 3 else (
                "in_progress" if n_attempted > 0 else "not_started"
            )
            mission, created = Mission.objects.get_or_create(
                account=acc,
                subject=subject,
                mission_date=mission_date,
                defaults={"is_deleted": False},
            )
            for order, (q, ch) in enumerate(mission_questions, start=1):
                MissionQuestion.objects.get_or_create(
                    mission=mission,
                    question=q,
                    defaults={"chapter": ch, "order": order},
                )
            UserMissionProgress.objects.get_or_create(
                mission=mission,
                defaults={
                    "status": status,
                    "total_questions": 5,
                    "questions_attempted": n_attempted,
                    "correct_answers": n_correct,
                    "wrong_answers": n_attempted - n_correct,
                    "score": n_correct * 10,
                    "exp_earned": n_correct * 5,
                    "time_spent_seconds": n_attempted * 30,
                    "started_at": timezone.now() if n_attempted > 0 else None,
                    "completed_at": timezone.now() if status == "completed" else None,
                },
            )

        self.stdout.write(
            f"  [+] Missions: {subject.name} — {len(mission_stats)} missions created"
        )

    def _create_competition(self, cfg, subject, content, students, created_by):
        """Creates Competition, CompetitionQuestion, UserCompetitionProgress."""
        chapter_data = content[cfg["chapter"]]
        chapter = chapter_data["chapter"]
        comp_questions = chapter_data["questions"]

        comp, created = Competition.objects.get_or_create(
            code=cfg["code"],
            defaults={
                "title": cfg["title"],
                "competition_type": "subject_with_chapter",
                "subject": subject,
                "chapter": chapter,
                "total_time": 30,
                "status": "completed",
                "is_active": True,
                "created_by": created_by,
            },
        )

        for order, q in enumerate(comp_questions, start=1):
            CompetitionQuestion.objects.get_or_create(
                competition=comp,
                question=q,
                defaults={"order": order, "points": 10},
            )

        for student_idx, (score, status) in cfg["participant_scores"].items():
            acc = students[student_idx]
            UserCompetitionProgress.objects.get_or_create(
                account=acc,
                competition=comp,
                defaults={
                    "status": status,
                    "score": score,
                    "time_taken": 900,
                    "exp_earned": score // 2,
                    "started_at": timezone.now(),
                    "completed_at": timezone.now() if status == "completed" else None,
                },
            )

        self.stdout.write(
            f"  [+] Competition: {comp.title} ({comp.code}) — "
            f"{len(cfg['participant_scores'])} participants"
        )
        return comp

    def _create_progress(self, all_students):
        """
        Creates UserChapterProgress and UserModuleProgress for every student
        based on their actual Answer records (test=None practice answers).
        """
        for acc in all_students:
            # Gather all chapters this student answered
            chapter_ids = (
                Answer.objects
                .filter(user=acc, test=None, chapter__isnull=False)
                .values_list("chapter_id", flat=True)
                .distinct()
            )
            module_ids_seen = set()
            for ch_id in chapter_ids:
                try:
                    chapter = ModuleChapter.objects.get(pk=ch_id)
                except ModuleChapter.DoesNotExist:
                    continue
                total_q = ModuleContent.objects.filter(
                    chapter=chapter, content_type="question", is_deleted=False
                ).count()
                answered_q = Answer.objects.filter(
                    user=acc, chapter=chapter, test=None
                ).count()
                pct = int(answered_q / total_q * 100) if total_q else 0
                status = "completed" if pct == 100 else "in_progress"

                UserChapterProgress.objects.get_or_create(
                    account=acc,
                    chapter=chapter,
                    defaults={"status": status, "percentage": pct, "started_at": timezone.now()},
                )
                module_ids_seen.add(chapter.module_id)

            for mod_id in module_ids_seen:
                try:
                    module = Module.objects.get(pk=mod_id)
                except Module.DoesNotExist:
                    continue
                total_q = ModuleContent.objects.filter(
                    chapter__module=module, content_type="question", is_deleted=False
                ).count()
                answered_q = Answer.objects.filter(
                    user=acc, chapter__module=module, test=None
                ).count()
                pct = int(answered_q / total_q * 100) if total_q else 0
                status = "completed" if pct == 100 else "in_progress"

                UserModuleProgress.objects.get_or_create(
                    account=acc,
                    module=module,
                    defaults={"status": status, "percentage": pct, "started_at": timezone.now()},
                )

        self.stdout.write(
            f"  [+] Progress records created for {len(all_students)} students"
        )

    def _create_school2_data(self, school2, level):
        """
        Creates School 2 teacher + 2 students who answer the same math questions.
        Their data MUST NOT appear in School 1 (DPS) teacher dashboard.
        """
        subjects2 = self._create_subjects(school2)
        grade2 = self._create_grade(school2)
        class2 = self._create_class(school2, grade2, "9-A", subjects2)

        # School 2 math content (same question objects via get_or_create, different modules/chapters)
        math_content2 = self._create_subject_content(subjects2["Mathematics"], MATH_CONTENT, class2)

        _, t_profile = _make_account("sms.teacher", "SMS", "Teacher", "teacher", school2)
        tp, _ = TeacherProfile.objects.get_or_create(
            user_profile=t_profile,
            defaults={"employee_id": "EMP999"},
        )
        Teacher.objects.get_or_create(
            teacher=tp,
            class_instance=class2,
            subject=subjects2["Mathematics"],
            defaults={"is_deleted": False},
        )

        for i, (uname, first, last) in enumerate([
            ("sms.student1", "SMS", "Student1"),
            ("sms.student2", "SMS", "Student2"),
        ], start=1):
            s_acc, s_profile = _make_account(uname, first, last, "student", school2)
            student, _ = Student.objects.get_or_create(
                user_profile=s_profile,
                defaults={"class_instance": class2, "roll_number": i, "level": level},
            )
            StudentSubjectEnrollment.objects.get_or_create(
                student=student,
                subject=subjects2["Mathematics"],
                defaults={"is_active": True},
            )
            # Answer questions from all Math chapters (isolation check)
            for ch_title, ch_data in math_content2.items():
                chapter = ch_data["chapter"]
                for q in ch_data["questions"][:2]:
                    is_correct = (i % 2 == 0)
                    Answer.objects.get_or_create(
                        user=s_acc,
                        question=q,
                        test=None,
                        defaults={
                            "is_correct": is_correct,
                            "answer": _pick_option(q, is_correct),
                            "chapter": chapter,
                            "tries": 1,
                        },
                    )

        self.stdout.write(
            f"  [+] Isolation data: {school2.name} — teacher + 2 students + answers"
        )

    # ═══════════════════════════════════════════════════════════════════════════
    # Summary
    # ═══════════════════════════════════════════════════════════════════════════

    def _print_summary(self, school, class_9a, teacher_acc, all_students, math_content, math_test, sci_test, eng_test):
        w = self.style.SUCCESS
        h = self.style.MIGRATE_HEADING

        self.stdout.write(h("\n╔══════════════════════════════════════════════════════════════════╗"))
        self.stdout.write(h("║                    SEED DATA SUMMARY                            ║"))
        self.stdout.write(h("╚══════════════════════════════════════════════════════════════════╝"))

        self.stdout.write(w("\n── Login credentials (password: Test@1234) ────────────────────────"))
        self.stdout.write(f"  Teacher  : ramesh.kumar   / {PASSWORD}")
        for acc in all_students:
            self.stdout.write(f"  Student  : {acc.username:<22} / {PASSWORD}")
        self.stdout.write(f"  SMS Test : sms.teacher   / {PASSWORD}  (school 2 isolation)")

        self.stdout.write(w("\n── Subject enrollments ────────────────────────────────────────────"))
        for uname, first, last, roll, enrolled in STUDENT_DEFS:
            self.stdout.write(f"  {first} {last:<12} → {', '.join(enrolled)}")

        self.stdout.write(w("\n── Mathematics content ────────────────────────────────────────────"))
        for title, data in math_content.items():
            ch = data["chapter"]
            due = ch.due_date.strftime("%Y-%m-%d") if ch.due_date else "NO DUE DATE"
            self.stdout.write(f"  {title:<28} due_date={due}  Q={len(data['questions'])}")

        self.stdout.write(w("\n── Tests created ──────────────────────────────────────────────────"))
        self.stdout.write(f"  Math Test  : id={math_test.pk}  2025-11-20 10:00 IST  7 questions")
        self.stdout.write(f"  Sci  Test  : id={sci_test.pk}   2025-11-27 10:00 IST  7 questions")
        self.stdout.write(f"  Eng  Test  : id={eng_test.pk}   2025-12-04 10:00 IST  7 questions")

        self.stdout.write(w("\n── Competitions created ───────────────────────────────────────────"))
        self.stdout.write("  Math Championship  (code=MATHCHMP) — Triangles chapter — 3 participants")
        self.stdout.write("  Science Bowl       (code=SCIBOWL1) — Motion chapter    — 3 participants")

        self.stdout.write(w("\n── Missions created ───────────────────────────────────────────────"))
        self.stdout.write("  alice  → Math mission + Science mission")
        self.stdout.write("  bob    → Math mission")
        self.stdout.write("  charlie→ Science mission + English mission")
        self.stdout.write("  diana  → Math mission + Science mission + English mission")
        self.stdout.write("  eve    → English mission")

        self.stdout.write(w("\n── Expected Teacher Dashboard (Ramesh, subject=Mathematics) ────────"))
        self.stdout.write("  ┌─────────────────────────────────┬────────────┬───────────────────────┐")
        self.stdout.write("  │ Metric                          │ Expected   │ How                   │")
        self.stdout.write("  ├─────────────────────────────────┼────────────┼───────────────────────┤")
        self.stdout.write("  │ Total Students                  │ 3          │ Alice+Bob+Diana        │")
        self.stdout.write("  │ Chapters Covered                │ 3/4        │ Ch1,Ch2,Ch3 have due   │")
        self.stdout.write("  │ Last Assignment Attempt Rate    │ 67%        │ Ch3: Alice+Diana / 3   │")
        self.stdout.write("  │ Attempt Rate                    │ 89%        │ (100+67+100)/3         │")
        self.stdout.write("  │ Overall Student Percentage      │ 35%        │ see answer dist below  │")
        self.stdout.write("  │ Weak Topics                     │ 2          │ QuadEq 37.5%, Tri 30%  │")
        self.stdout.write("  └─────────────────────────────────┴────────────┴───────────────────────┘")

        self.stdout.write(w("\n── Answer distribution (Math, practice) ───────────────────────────"))
        self.stdout.write("  Chapter 1 — Linear Equations (4Q, due 2025-11-01)")
        self.stdout.write("    Alice : Q1✓ Q2✓ Q3✓ Q4✗  → 3/4  │  Bob: Q1✓ Q2✗ Q3✗ Q4✗ → 1/4  │  Diana: 4/4")
        self.stdout.write("    Total : 8/12 = 66.7% → NOT WEAK")
        self.stdout.write("  Chapter 2 — Quadratic Equations (3Q, due 2025-11-15)")
        self.stdout.write("    Alice : Q5✗ Q6✗ Q7✓ → 1/3  │  Bob: Q5✗ Q6✗ → 0/2  │  Diana: Q5✓ Q6✓ Q7✗ → 2/3")
        self.stdout.write("    Total : 3/8 = 37.5% → WEAK ⚠")
        self.stdout.write("  Chapter 3 — Triangles (5Q, due 2025-12-01)")
        self.stdout.write("    Alice : Q8✓ Q9-Q12✗ → 1/5  │  Bob: not attempted  │  Diana: Q8✓ Q9✓ Q10-Q12✗ → 2/5")
        self.stdout.write("    Total : 3/10 = 30.0% → WEAK ⚠")
        self.stdout.write("  Chapter 4 — Circles (3Q, NO DUE DATE — excluded from metrics)")
        self.stdout.write("    Alice: Q13✓ Q14✓  │  Diana: Q13✓")

        self.stdout.write(w("\n── Test answer results (Math test) ────────────────────────────────"))
        self.stdout.write("  Alice:  5/7 correct  (71%)  score=50")
        self.stdout.write("  Bob:    2/7 correct  (29%)  score=20")
        self.stdout.write("  Diana:  6/7 correct  (86%)  score=60")

        self.stdout.write(w("\n── API verification call ──────────────────────────────────────────"))
        self.stdout.write("  GET /api/dashboard/metrics/?role=teacher&subject=<MATH_SUBJECT_ID>")
        self.stdout.write("  Authorization: Bearer <token for ramesh.kumar>")
        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS("\n✔  Seeding complete.\n"))
