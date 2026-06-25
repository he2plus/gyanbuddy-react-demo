# GyanBuddy Backend

Django backend for GyanBuddy (users, classes, subjects, analytics, tests).

## Prerequisites

- Python `3.11+`
- PostgreSQL running locally

## Environment

Create `.env` in `gyaan_buddy_backend/` and configure DB + app settings.

Typical local values:

```env
DEBUG=True
ALLOWED_HOSTS=127.0.0.1,localhost
DB_NAME=gyanbuddy
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=127.0.0.1
DB_PORT=5432
```

## Setup

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
```

Optional:

```bash
python manage.py createsuperuser
```

## Run

```bash
source venv/bin/activate
python manage.py runserver 127.0.0.1:8000
```

Backend runs at:
- `http://127.0.0.1:8000`

## Key API Endpoints Used by Parent Frontend

- `POST /api/auth/login/`
- `GET /api/analytics/student/my-progress/`
- `GET /api/analytics/student/weak-areas/`
- `GET /api/analytics/student/leaderboard/`
- `GET /api/analytics/answer-trends/?days=...`
- `GET /api/tests/my-tests/`
- `GET /api/tests/{id}/my-report/`

## Test / Seed Notes

For local QA, you can seed users/tests/progress using Django shell scripts.
Existing seeded login examples in this workspace include:
- `student1 / student123`
- `student2 / student123`
- `student3 / student123`
- `student4 / student123`

### One-command Parent Demo Seed

Use this command to seed parent-dashboard ready data locally (idempotent):

```bash
source venv/bin/activate
python manage.py seed_parent_demo_data
```

Useful options:

```bash
# Preview only (no writes)
python manage.py seed_parent_demo_data --dry-run

# Custom user / generation volume
python manage.py seed_parent_demo_data --username student1 --password student123 --tests 10 --days 30
```
