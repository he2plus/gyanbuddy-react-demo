# Backend extras

Files in this folder live in the **gyaan_buddy_backend** repo, not this one.
They're checked in here for traceability — anyone reproducing the local demo
needs to know they exist and where they go.

## `management-commands/seed_student_demo.py`

Layers a student-facing demo dataset on top of the backend's
`seed_test_data` command. It cross-enrolls every seeded student in every
subject, backfills hints & explanations on every quiz question, gives
each student a deterministic mix of Done / In Progress / Not Started
chapters, creates a 3-day mission window (yesterday completed / today
fresh / tomorrow upcoming), bumps each student's XP so the leaderboard
ranks them distinctly, and writes 5 demo notifications per student.

### Install + run

```bash
# 1. Drop the file into the backend repo
cp backend-extras/management-commands/seed_student_demo.py \
   /path/to/gyaan_buddy_backend/gyaan_buddy/users/management/commands/

# 2. From the running web container (or wherever you exec manage.py):
docker exec gyan-buddy-web-1 python manage.py seed_test_data --flush
docker exec gyan-buddy-web-1 python manage.py seed_test_data
docker exec gyan-buddy-web-1 python manage.py seed_student_demo
```

### After running, every student in class 9-A sees:

| Endpoint                  | What you get per student |
|---------------------------|--------------------------|
| `/api/subjects/`          | 3 subjects (Math / Science / English) |
| `/api/missions/`          | 10–12 missions (Nov '25 from base seed + yesterday/today/tomorrow from this script) |
| `/api/tests/my-tests/`    | 3 scheduled tests (English / Science / Math) |
| `/api/notifications/`     | 8 notifications (3 from base seed + 5 demo) |
| `/api/users/leaderboard/` | 5 students, distinct XP, sorted descending |

### Demo logins (all share password `Test@1234`)

| Username        | Rank | XP    | Pattern |
|-----------------|------|-------|---------|
| `alice.sharma`  | #1   | 2180  | Most chapters Done |
| `diana.patel`   | #2   | 1890  | Strong but not complete |
| `bob.verma`     | #3   | 1544  | Mid-progress |
| `charlie.nair`  | #4   | 1276  | A few completed |
| `eve.gupta`     | #5   |  980  | Just getting started |

### Idempotence

Safe to re-run. To wipe the extras (missions in the today±1 window,
demo notifications) and re-apply, pass `--reset`:

```bash
docker exec gyan-buddy-web-1 python manage.py seed_student_demo --reset
```
