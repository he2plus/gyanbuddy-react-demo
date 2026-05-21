# Gyaan Buddy — React Student Dashboard

Pixel-faithful React rebuild of the Gyanbuddy student app, matching the
designer's Figma file [_Gyanbuddy student dashboard_](https://www.figma.com/design/M3Gc9gO1maTgx50pTPNxax/Gyanbuddy-student-dashboard).

Replaces the original Flutter-Web build, which locked the layout to a 430×932
phone viewport on desktop.

---

## Try the live demo

The Vercel deployment runs in **mock-auth mode** — any non-empty username +
password works; the app then serves rich fixture data so every screen is
populated.

**Recommended test credentials**

| Username | Password |
|----------|----------|
| `1234`   | `demo1234` |
| `demo`   | `demo1234` |

Anything else with both fields non-empty also logs you straight in. No
account is created on the backend; it's all client-side mock.

### Walkthrough (in order)

| Screen | Route | What to look for |
|--------|-------|------------------|
| **Onboarding** | `/onboarding` | 4-page intro carousel for first-time visitors. |
| **Login** | `/login` | Mock-auth — type anything, hit Sign In. |
| **Home** | `/home` | Animated metric counters (Day Streak / Today's Goal / Test Score), CSS molecule in the Chemistry illustration zone, trophy banner with King of Leaderboard, real-data podium + ranked class list, subject rail on the right. |
| **Subjects** | `/subjects` | Filter chips (All Chapters / Overdue / In Progress / Locked), accordion-expandable subject rows, chapter chips with DONE / OVERDUE / DUE / LOCKED status. |
| **Learning Journey** | `/subjects/{id}/modules/{id}/chapters` | Two-column layout. Left = topic preview with Start. Right = snake-curve path of platforms using the design assets in `/public/images/podium/*` (blue = due, green = completed, grey-lock = locked, finish-flag on the last). |
| **Missions** | `/missions` | Calendar view. Days that have missions get a cyan dot. Today's mission is launchable; past = read-only, future = locked. "Explore Topics" CTA when no mission. |
| **Leaderboard** | `/leaderboard` | Big "Me" card on the left (rank / XP / streak + "X XP to go" progress), top-3 podium + full ranked list on the right. Period tabs This Week / This Month / All Time. |
| **My Tests** | `/tests` | Header counters (Skipped / Upcoming / Completed), filter tabs (All / Upcoming / Skipped / Completed), test rows with status-coloured stroke and Start buttons. |

---

## Local development (real Django backend)

To run against the real Django backend instead of the mock layer:

```bash
# 1. Clone the backend
git clone https://github.com/theshushant/gyaan_buddy_backend.git ../gyaan_buddy_backend
cd ../gyaan_buddy_backend

# 2. Create logs/ (the LOGGING config writes here)
mkdir -p logs

# 3. Create a local .env (use .env.backup as a template)
# Minimum required:
#   DEBUG=True
#   DJANGO_ENV=development
#   DJANGO_SETTINGS_MODULE=gyaan_buddy.settings
#   SECRET_KEY=django-insecure-anything
#   POSTGRES_DB=gyaan_buddy
#   POSTGRES_USER=gyaan_buddy_user
#   POSTGRES_PASSWORD=gyaan_buddy_password
#   POSTGRES_HOST=db
#   POSTGRES_PORT=5432
#   REDIS_URL=redis://redis:6379/0

# 4. Bring up Postgres + Redis + Django (skip ai-service / qdrant)
docker compose -f docker-compose.dev.yml up db redis web -d

# 5. Drop the demo seed file into the backend (see backend-extras/ in THIS repo)
cp ../gyanbuddy-react/backend-extras/management-commands/seed_student_demo.py \
   gyaan_buddy/users/management/commands/

# 6. Migrate + seed rich demo data
docker exec gyan-buddy-web-1 python manage.py migrate
docker exec gyan-buddy-web-1 python manage.py seed_test_data --flush
docker exec gyan-buddy-web-1 python manage.py seed_test_data
docker exec gyan-buddy-web-1 python manage.py seed_student_demo
```

Then back in this repo, create `.env.local` (gitignored) with:

```env
VITE_BUILD_MODE=dev
VITE_DEV_MOCK_AUTH=false
VITE_USE_PROXY=true
VITE_BASE_URL_DEV=http://localhost:8000
VITE_API_PREFIX=/api
```

```bash
npm install
npm run dev
```

### Demo logins (all share password `Test@1234`)

After the seeds run, every account below has rich data on every screen —
3 subjects, mix of completed / in-progress / not-started chapters, today's
mission ready, 3 tests scheduled, 8 notifications, distinct leaderboard XP.

| Username        | Class | Rank | XP    | Pattern |
|-----------------|-------|------|-------|---------|
| `alice.sharma`  | 9-A   | #1   | 2180  | Most chapters Done |
| `diana.patel`   | 9-A   | #2   | 1890  | Strong but not complete |
| `bob.verma`     | 9-A   | #3   | 1544  | Mid-progress |
| `charlie.nair`  | 9-A   | #4   | 1276  | A few completed |
| `eve.gupta`     | 9-A   | #5   |  980  | Just getting started |

Any of the above logs into the same class so the leaderboard shows the
same 5 names regardless of who you sign in as — you can A/B test the
view between a top student and a struggling one without changing data.

See [`backend-extras/README.md`](backend-extras/README.md) for the full
seed-data contract.

---

## Architecture summary

- **Vite + React 19 + TypeScript** — strict mode, Tailwind v4 via `@tailwindcss/vite`.
- **`@tanstack/react-query`** — every API call goes through a typed hook (`useSubjects`, `useLeaderboard`, `useMissions`, etc.); request-de-dupe + caching for free.
- **`framer-motion`** — entrance animations, hover lifts, count-up counters, calendar selection.
- **`react-router-dom` v7** — see [`src/app/routes.tsx`](src/app/routes.tsx) for the full route table.
- **`zustand`** — single `useAuthStore` holds the session.
- **Design tokens** — verified against the actual Figma file via REST API; see [`src/styles/tokens.css`](src/styles/tokens.css).
- **Mock layer** — every `src/api/*` module has a mock branch that activates when `VITE_DEV_MOCK_AUTH=true` AND a `mock_access_token` is in storage. That's how the Vercel demo works without a backend.

### Folder map

```
src/
  api/                Axios client + per-resource modules (auth, users, subjects,
                      modules, leaderboard, missions, tests, quiz, ...) with
                      mock branches.
  features/           Screen-level components grouped by domain.
    home/             Home dashboard (pixel-faithful to Figma frame 6:2)
    subject/          Subject list with accordion + filter chips (10:1259)
    module/           Learning Journey with podium path (10:4377)
    mission/          Calendar-style Missions (10:5406)
    leaderboard/      Leaderboard page + Podium component (49:2)
    test/             My Tests with status tabs (83:2)
    auth/             Login, register, forgot/reset password
    onboarding/       4-page intro carousel
  shell/              TopBar, AppShell, SideNav (used by non-redesigned routes)
  state/              Zustand stores (auth, ui)
  styles/             tokens.css + globals.css (Tailwind v4 @theme)
  types/              DTO ↔ domain models for every backend resource
```

---

## What's faked vs. real

| Data | Real backend | Mock branch |
|------|--------------|-------------|
| Login / user / tokens | ✅ | ✅ |
| Subjects, modules, chapters | ✅ | ✅ |
| Leaderboard (rank, XP) | ✅ | ✅ |
| Missions | ✅ | ✅ (6 across past/today/future) |
| Tests | ✅ | ✅ (one of each status) |
| Quiz questions / answer-check | ✅ — backend already implements 2/1/0 XP scoring based on `tries` | ✅ |
| Day Streak | ❌ — backend has no streak field | ⚠️ placeholder `1` |
| Today's Goal | ❌ — no daily-goal API | ⚠️ placeholder `35%` |
| Test Score | ❌ — no aggregate field | ⚠️ placeholder `78%` |
| Rearrange-question scoring | ⚠️ backend stores the answer but `is_correct` falls through to `false`; UI is shipped, scoring needs backend follow-up | — |

---

## Backend repo

The Django backend is in a separate repository:
[`theshushant/gyaan_buddy_backend`](https://github.com/theshushant/gyaan_buddy_backend).
Don't push to that repo from this one — it's third-party.

---

## Credits

UI design: see Figma file linked at the top.
Engineering & integration: Prakhar Tripathi.
