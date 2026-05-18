"""
Seed data for the stub backend. Shapes mirror the DTOs in
gyanbuddy-react/src/api/*.ts and the contract in context.txt section 5.

Snake-case (Django/DRF convention) so parseUser / parseSubject / parseModule /
parseChapter on the React side don't need any changes.
"""
from datetime import datetime, timedelta, timezone


def _iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


NOW = datetime.now(timezone.utc)
NOW_ISO = _iso(NOW)
WEEK_LATER = _iso(NOW + timedelta(days=7))


DEMO_USER = {
    "id": "stub-user-1",
    "username": "demo_student",
    "first_name": "Demo",
    "last_name": "Student",
    "email": "demo@gyanbuddy.local",
    "user_type": "student",
    "admission_number": 1234,
    "roll_number": 7,
    "total_exp": 1544,
    "rewards": 320,
    "level": {"id": "3", "name": 3, "min_exp": 200, "max_exp": 1999},
    "phone_number": None,
    "date_of_birth": None,
    "profile_picture": None,
    "bio": None,
    "is_active": True,
    "logged_in_once": True,
    "school": "stub-school",
    "school_name": "GyanBuddy Demo School",
    "created_at": NOW_ISO,
    "updated_at": NOW_ISO,
}


SUBJECTS = [
    {"id": "chem", "name": "Chemistry", "code": "CHEM", "color": "#3B82F6",
     "logo": "", "is_active": True, "module_count": 4, "has_due_module": True,
     "created_at": NOW_ISO, "updated_at": NOW_ISO},
    {"id": "phys", "name": "Physics", "code": "PHY", "color": "#8B5CF6",
     "logo": "", "is_active": True, "module_count": 5, "has_due_module": False,
     "created_at": NOW_ISO, "updated_at": NOW_ISO},
    {"id": "bio", "name": "Biology", "code": "BIO", "color": "#10B981",
     "logo": "", "is_active": True, "module_count": 6, "has_due_module": False,
     "created_at": NOW_ISO, "updated_at": NOW_ISO},
    {"id": "math", "name": "Mathematics", "code": "MATH", "color": "#F59E0B",
     "logo": "", "is_active": True, "module_count": 7, "has_due_module": True,
     "created_at": NOW_ISO, "updated_at": NOW_ISO},
    {"id": "geo", "name": "Geography", "code": "GEO", "color": "#06B6D4",
     "logo": "", "is_active": True, "module_count": 3, "has_due_module": False,
     "created_at": NOW_ISO, "updated_at": NOW_ISO},
    {"id": "hist", "name": "History", "code": "HIS", "color": "#A855F7",
     "logo": "", "is_active": True, "module_count": 4, "has_due_module": False,
     "created_at": NOW_ISO, "updated_at": NOW_ISO},
]


def modules_for(subject_id: str):
    """Mirror mockModulesFor() in gyanbuddy-react/src/api/modules.ts."""
    def base(overrides):
        return {
            "subject": subject_id,
            "is_enabled": True,
            "chapter_count": 6,
            "question_count": 24,
            "status": "in_progress",
            "user_status": "in_progress",
            "user_percentage": 40,
            "created_at": NOW_ISO,
            "updated_at": NOW_ISO,
            **overrides,
        }
    return [
        base({"id": f"{subject_id}-m1", "name": "Foundations",   "order": 1,
              "status": "completed",  "user_status": "completed",  "user_percentage": 100}),
        base({"id": f"{subject_id}-m2", "name": "Core Concepts", "order": 2,
              "status": "in_progress", "user_status": "in_progress", "user_percentage": 45}),
        base({"id": f"{subject_id}-m3", "name": "Applications",  "order": 3,
              "status": "not_started", "user_status": "not_started", "user_percentage": 0,
              "due_date": WEEK_LATER}),
        base({"id": f"{subject_id}-m4", "name": "Advanced Topics", "order": 4,
              "status": "not_started", "user_status": "not_started", "user_percentage": 0}),
    ]


def chapters_for(module_id: str):
    """Mirror mockChaptersFor() in gyanbuddy-react/src/api/modules.ts."""
    def theory(name: str) -> str:
        return (
            f"Welcome to **{name}**. In this chapter you'll learn the core ideas, "
            "work through guided examples, and try a short quiz at the end. "
            "Take your time on the key principles below - they show up again in "
            "later chapters and on the assessment. If anything is unclear, you "
            "can revisit the previous chapters using the path on the left."
        )

    def c(overrides):
        return {
            "is_enabled": True,
            "is_important": False,
            "has_hots": False,
            "content_count": 5,
            "status": "not_started",
            "created_at": NOW_ISO,
            "updated_at": NOW_ISO,
            **overrides,
        }
    return [
        c({"id": f"{module_id}-c1", "title": "Introduction",            "order": 1, "status": "completed",   "theory": theory("Introduction")}),
        c({"id": f"{module_id}-c2", "title": "Building Blocks",         "order": 2, "status": "completed",   "theory": theory("Building Blocks")}),
        c({"id": f"{module_id}-c3", "title": "Key Principles",          "order": 3, "status": "completed",   "is_important": True, "theory": theory("Key Principles")}),
        c({"id": f"{module_id}-c4", "title": "Hands-on Practice",       "order": 4, "status": "in_progress", "is_important": True, "theory": theory("Hands-on Practice")}),
        c({"id": f"{module_id}-c5", "title": "Deeper Dive",             "order": 5, "status": "not_started", "theory": theory("Deeper Dive")}),
        c({"id": f"{module_id}-c6", "title": "Real-world Applications", "order": 6, "status": "not_started", "is_important": True, "theory": theory("Real-world Applications")}),
        c({"id": f"{module_id}-c7", "title": "Final Project",           "order": 7, "status": "not_started", "theory": theory("Final Project")}),
    ]


LEADERBOARD_USERS = [
    {"id": "u1", "username": "tanishq", "first_name": "Tanishq", "last_name": "Chhabra",
     "full_name": "Tanishq Chhabra", "total_exp": 1322,
     "level": {"id": "5", "name": 5, "min_exp": 1000, "max_exp": 1999},
     "profile_picture": None},
    {"id": "u2", "username": "naman", "first_name": "Naman", "last_name": "Mehta",
     "full_name": "Naman Mehta", "total_exp": 750,
     "level": {"id": "3", "name": 3, "min_exp": 500, "max_exp": 999},
     "profile_picture": None},
    {"id": "u3", "username": "girish", "first_name": "Girish", "last_name": "Vyas",
     "full_name": "Girish Vyas", "total_exp": 621,
     "level": {"id": "3", "name": 3, "min_exp": 500, "max_exp": 999},
     "profile_picture": None},
    {"id": "u4", "username": "priya", "first_name": "Priya", "last_name": "Sharma",
     "full_name": "Priya Sharma", "total_exp": 410,
     "level": {"id": "2", "name": 2, "min_exp": 200, "max_exp": 499},
     "profile_picture": None},
    {"id": "u5", "username": "rohan", "first_name": "Rohan", "last_name": "Verma",
     "full_name": "Rohan Verma", "total_exp": 287,
     "level": {"id": "2", "name": 2, "min_exp": 200, "max_exp": 499},
     "profile_picture": None},
    {"id": DEMO_USER["id"], "username": DEMO_USER["username"],
     "first_name": DEMO_USER["first_name"], "last_name": DEMO_USER["last_name"],
     "full_name": "Demo Student", "total_exp": DEMO_USER["total_exp"],
     "level": DEMO_USER["level"], "profile_picture": None},
]
