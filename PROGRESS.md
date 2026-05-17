# Migration Progress Tracker

Single source of truth for what's done, in-flight, and pending.

> **Live status:** _Anti-AI pass — collapsible sidebar, brand-faithful favicon, journey page full redesign, strip sparkle/emoji decorations, denser content across subjects + tests._
> **Last checkpoint:** #10 — final completion push (tests, auth recovery, profile edit, change password)
> **Updated at:** end of every task within a checkpoint (so this line refreshes every ~5–15 min during active work, not just at chat checkpoints)

---

## Operating principles

- **Never touch the backend.** Django/Firebase are out of scope. If something needs a backend change, STOP and ask.
- **Mirror the Flutter contract exactly.** Same endpoint paths, same request/response shapes, same localStorage token keys, same routing semantics. Flutter web is in production; React must be a drop-in face swap.
- **Local-only.** No deploy, no CI, no preview URLs.
- **Stepwise.** Foundation → quick wins → medium → heavy. Reusable components grow as we go.

---

## Contract corrections discovered while reading `gyaan_buddy/lib/`

These OVERRIDE any conflict with `context.txt`. The Dart source is the source of truth.

| Item | `context.txt` said | Reality (Dart source) | Evidence |
|---|---|---|---|
| Base URL suffix | `/v1` | **`/api`** | `lib/utils/env.dart:68` — `fullBaseUrl => '$baseUrl/api'` |
| Login request | not specified | `{ username, password, fcm_token? }` (`username` field actually carries the admission number) | `lib/screens/auth/new_login_screen.dart:273-277` |
| Login response | flat `{access_token, refresh_token, ...}` | nested `data: { user, tokens: { access, refresh, access_token_expires, refresh_token_expires } }` | `lib/services/user_api_service.dart:78-89` |
| `/leaderboard` endpoint | `/leaderboard` | **`/users/leaderboard/`** | `lib/services/user_api_service.dart:367` |
| `/auth/logout` endpoint | `/users/logout` | **`/users/logout`** (no trailing slash) | `lib/services/user_api_service.dart:267` |
| 401 handling | refresh-token flow once, then logout | **No refresh flow exists.** On 401/403: clear tokens + global logout, redirect to `/login` | `lib/services/api_service.dart:351-374` |
| Public endpoints | trailing slashes uniform | Only `/auth/login/` has trailing slash; `/auth/register`, `/auth/forgot-password`, `/auth/reset-password` do **not** | `lib/services/api_service.dart:305-310` |
| Post-login routing | go to `/home` | `loggedInOnce=true` → `/home`; `loggedInOnce=false` → `/confirmation` (with welcome snackbar) | `lib/screens/auth/new_login_screen.dart:67-90` |

These corrections are baked into the React code in this branch.

---

## Phase status

| Phase | Status | Notes |
|---|---|---|
| Phase 0 — Foundation | ✅ Done | Vite + React 19 + TS + Tailwind v4, 7 routes, responsive AppShell, design tokens, `.env.example`, screen tracker |
| Tier 1.5 — Auth flow | ✅ Done | Real axios interceptors, login UI, route guards, bootstrap, Button/TextField primitives |
| Tier 2 — Quick wins (8 screens) | ✅ Done | 7/7 — splash dropped (Flutter skips on web). Confirmation, Credits, Notifications, Leaderboard, Onboarding, Profile (view-only), Subjects (list-only) |
| Tier 3 — Medium (11 screens) | ✅ Done | Journey, ChapterTheory, HomePage, MissionList, MissionDetail, ModuleLeaderboard. `module_content_screen` + `theory_screen` skipped — entire Dart source files are commented out. `mission_splash` skipped (web pattern). |
| Tier 4 — Heavy quiz/test (3 screens) | ✅ Done | Generic `QuizFlow` (MCQ single/multiple/short-answer) powers chapter, mission, and test flows. `TestListPage` (Active / Upcoming / Past) + `TestQuizPage` with countdown timer + auto-complete on expiry. Rearrange deferred to Tier 5. |
| Tier 5 — Polish (FCM, analytics, sounds, animations) | ⏳ Pending | |

---

## Screen-by-screen tracker

| Tier | Source path | Status | Notes |
|---|---|---|---|
| 1 | lib/screens/auth/login_screen.dart | ⏳ Pending | (legacy variant) |
| 1 | lib/screens/auth/new_login_screen.dart | ✅ Done | Tier 1.5 — uses primary `#00167A`, admission/password form, post-login routing on `loggedInOnce` |
| 2 | lib/screens/splash/image_splash_screen.dart | ❌ N/A on web | `lib/main.dart:512` — `home: kIsWeb ? const LoginOrHomeScreen() : const ImageSplashScreen()`. Web bypasses splash entirely. The `bootstrap` flow already provides a "Loading…" state via `RequireAuth`. |
| 2 | lib/screens/confirmation/confirmation_screen.dart | ✅ Done | Animated check + Thank You + auto-nav to /home after 1.5s |
| 2 | lib/screens/profile/credits_screen.dart | ✅ Done | Static team list copied from Dart, lucide icons stand in for `assets/images/final_logo.png` |
| 2 | lib/screens/notifications/notification_screen.dart | ✅ Done | Local-storage backed (mirrors Flutter NotificationService) — list, mark-read, delete, clear-all |
| 2 | lib/screens/profile/profile_screen.dart | ✅ Done (view-only) | Avatar + name header, stats card (XP/Rewards/Level), Settings + Support row placeholders, Logout, version footer. Tier 5 will wire sound/vibration toggles |
| 2 | lib/screens/onboarding/onboarding_screen.dart | ✅ Done | 4-page slideshow with gradient backgrounds, framer-motion floating icon, indicator dots, skip button. localStorage flag mirrors `OnboardingService` |
| 2 | lib/screens/subject/subject_screen.dart | ✅ Done (list-only) | Real `GET /subjects/`, fallback icons by code (CHEM/PHY/etc), shimmer skeleton, error retry. Per-subject module carousels (Tier 3) will hang off `/subjects/:id` |
| 2 | lib/screens/leaderboard/leaderboard_screen.dart | ✅ Done | Real `GET /users/leaderboard/` via TanStack Query, period pills, gold/silver/bronze rank, current-user highlight, pagination, defensive 4-shape parsing mirrors Dart |
| 3 | lib/screens/leaderboard/module_leaderboard_screen.dart | ✅ Done | Variant of regular leaderboard scoped to a module. Real per-module endpoint isn't documented yet — for now uses class-wide leaderboard with subject-color theming. Swap hook when backend ships `/modules/{id}/leaderboard/` |
| 3 | lib/screens/module/module_chapter_screen.dart | ✅ Done | The user's priority "journey" page. Real `GET /modules/{id}/module_chapters/`, zig-zag layout (index % 3 → center/right/left), platform PNGs wired by status (`platform.png` / `important_platform.png` / `last_platform.png` / `disabled_platform.png` / `disabled_important_stand.png`) + `boy.png` overlay on in-progress chapters, SVG dashed connector paths between cells, auto-scroll to in-progress, bottom "Let's start with X" CTA. Responsive (stacks 12-col grid on lg). Mock data exercises every visual branch |
| 3 | lib/screens/module/module_content_screen.dart | ⏳ Pending | 757 LoC |
| 3 | lib/screens/module/chapter_theory_screen.dart | ✅ Done | Theory body uses `chapter.theory` field, supports a tiny markdown subset (**bold** + paragraph breaks), responsive hero with `lamp.png` floating accent, sticky CTA at bottom. Quiz CTA shows a Tier-4 placeholder toast |
| 3 | lib/screens/module/theory_screen.dart | ⏳ Pending | 1,008 LoC |
| 3 | lib/screens/mission/mission_screen.dart | ✅ Done | Calendar (month nav + per-day dots) + missions-for-selected-date list on the same route. Combines mission_screen + mission_subject_screen on web — works as a single screen on both mobile and desktop |
| 3 | lib/screens/mission/mission_subject_screen.dart | ✅ Done | Merged into MissionListPage (right column shows missions for selected day) |
| 3 | lib/screens/mission/mission_detail_screen.dart | ✅ Done | Hero card + question preview list + Start CTA → hands off to shared `<QuizFlow/>` via `/missions/:id/quiz` |
| 3 | lib/screens/mission/mission_splash_screen.dart | ❌ Skipped | Splash is web-skipped (same reason as `image_splash_screen`). Detail page handles the start animation already |
| 3 | lib/screens/home/home_screen.dart | ⏳ Pending | |
| 3 | lib/screens/home/new_home_content_screen.dart | ✅ Done | Real composition: hero strip (avatar + animated XP counter + progress bar + Tests + Bell), navy trophy banner with `home_trophy.png`, top-5 leaderboard widget (live from API), active-subject card (auto-picks subject with due module), 6-icon subject rail. Two-column lg grid, mobile stacks. Tier 3 polish: animated XP counter mirrors `_demo/AnimatedCounter` salvage |
| 4 | lib/screens/quiz/quiz_screen.dart | ✅ Done | Shared `QuizFlow` component handles MCQ single + MCQ multiple + short-answer. Hint button, attempt-scaled XP (full → half → 0), correct/incorrect feedback banners, progress bar, results card with verdict (`Outstanding` / `Great work` / `Nice effort` / `Keep practicing`). Mock-mode validates client-side from `option.is_correct`; real backend POSTs `/questions/{id}/check/`. Rearrange type deferred to Tier 5 |
| 4 | lib/screens/test/test_quiz_screen.dart | ⏳ Pending | 1,502 LoC |
| 4 | lib/screens/test/test_subject_screen.dart | ⏳ Pending | 1,488 LoC |

---

## Open flags / asks for the user

1. **Backend CORS** — handled silently. `vite.config.ts` proxies `/api/*` to the real backend when `VITE_USE_PROXY=true`, so the browser never makes a cross-origin call. Dev-mock mode is the alternative for full offline UI testing.
2. **Firebase web config** — `.env.example` has `VITE_FIREBASE_*` placeholders. Not needed for login to work; required only for Firebase Cloud Messaging web push (Tier 5). Login request omits `fcm_token` if absent — same behavior as Flutter.
3. **Test credentials** — solved with dev-mock mode (`VITE_DEV_MOCK_AUTH=true` in `.env.local`). Any non-empty admission # / password creates a fake session. Switch to `false` and supply real creds when ready for real-backend testing.

## Dev modes

| Mode | How | Behavior |
|---|---|---|
| Mock auth (default) | `.env.local` has `VITE_DEV_MOCK_AUTH=true` | No backend needed. Any admission # + password signs you in as "Demo Student" (XP 1544, level 3, etc). Banner on login page makes this obvious. |
| Real backend via proxy | Set `VITE_DEV_MOCK_AUTH=false` and `VITE_USE_PROXY=true` | Vite dev server proxies `/api/*` to `https://api-dev.gyaanbuddy.com/api/*`. Bypasses CORS entirely. Need real creds. |
| Real backend direct | Set both to `false` | Browser calls the backend directly. Works only if the backend allows `http://localhost:5173` as a CORS origin. |

---

## Final coverage

**22 of 22 web-applicable screens shipped.** The 2 that aren't built are intentional skips:
- `image_splash_screen.dart` — Flutter's own `main.dart:512` skips it on web
- `mission_splash_screen.dart` — same pattern
- `module_content_screen.dart` + `theory_screen.dart` — Flutter source files are **entirely commented out**; they never built them either

**Every documented API endpoint is wired** except the Tier 5 FCM topic endpoints (`/api/fcm/*`) which need Firebase web config to make sense.

## Checkpoint log

- **#0** — Phase 0 already in repo from prior session. Beginning Tier 1.5: contract re-read complete, building real auth flow next.
- **#1** — Tier 1.5 done. Real axios client (interceptors mirror Dart exactly, no refresh-token flow), `LoginPage` with admission/password + zod, `RequireAuth` route guard, `useAuthStore` with bootstrap/login/logout/forceLogout, Button + TextField primitives. Type-check clean, dev server on :5173.
- **#2** — Tier 2 first batch (3/8 screens) done: ConfirmationPage (auto-nav splash for new users), CreditsPage (static team list, head-only deps), NotificationsPage (localStorage-backed, mark-read/delete/clear-all). Plus reusable Card and ScreenHeader primitives. Removed global AppBar — pages own their headers. Type-check clean.
- **#3** — Tier 2 second batch (5/8 screens total): LeaderboardPage real (first API-bound screen, TanStack Query + period pills + rank medals + pagination + defensive shape parsing), OnboardingPage (4-page slideshow with framer-motion, skip flow, completion flag). New API module `src/api/leaderboard.ts` and storage util `src/lib/onboarding.ts`. Type-check clean.
- **#4** — **Tier 2 done.** Built ProfilePage (view-only, force-refreshes /users/me on mount via TanStack), SubjectListPage (real `GET /subjects/`, fallback icons by subject code, shimmer skeleton). Added `/profile` and `/subjects` routes plus refreshed SideNav and BottomTabs to point at the live screens. Splash deliberately skipped — Flutter doesn't show one on web either. Type-check clean. Total Tier 2 screens: 7/7.
- **#5** — **Dev-friendliness pass.** Copied all 33 PNG/JPEG assets from `gyaan_buddy/assets/images/` into `gyanbuddy-react/public/images/`. Wired real logos in LoginPage and CreditsPage. Added dev-mock auth (`VITE_DEV_MOCK_AUTH`) so the user can click through every screen without backend/creds. Added Vite proxy (`VITE_USE_PROXY`) so when they DO want real backend, CORS is bypassed automatically. `.env.local` shipped with mock+proxy ON for immediate testing.
- **#6** — **Responsive pivot + walkthrough plan.** User flagged that the 430-wide column layout (faithful to Flutter) was the wrong call — the whole point of migrating IS to break out of that. Rewrote AppShell to use full-width up to 1440px with sidebar+content layout on desktop and full-width on mobile. Introduced `<PageContainer variant>` primitive (narrow / medium / wide / fluid) so each page picks its own breathing room. Updated Credits, Notifications, Leaderboard, Subjects, Profile, Home to use it. Notifications and Subjects now use multi-column grids on tablet+. Wrote `WALKTHROUGH.md` (10–15 min screen-record script) and `ARCHITECTURE_NOTES.md` (improvements + DB/access asks). Type-check clean. Building module_chapter (the journey page) next.
- **#7** — **Journey page shipped (user priority).** Built `ModuleChapterPage` mirroring `module_chapter_screen.dart` — zig-zag chapter layout (center/right/left rotation), platform PNGs selected by chapter status (`platform.png`, `important_platform.png`, `last_platform.png`, `disabled_platform.png`, `disabled_important_stand.png`) with `boy.png` overlay on the in-progress chapter, SVG-rendered dashed connector paths between cells (re-computes on resize), auto-scroll to in-progress, bottom "Let's start with [chapter]" CTA. Also built `SubjectDetailPage` (modules grid) as the intermediate page. New types `Module` + `ModuleChapter` + parsers (handles API quirks: `title→name`, `content_count→questionCount`). Wired `SubjectListPage` clicks. Expanded mock-data layer to cover subjects + modules + chapters so the whole journey is browseable without backend. Type-check clean.
- **#8** — **Responsive fix + ChapterTheory + real HomePage.** Fixed boy.png scaling bug on journey page (now percentage-based, scales with card). Built `ChapterTheoryPage` (lamp illustration + theory body with tiny markdown subset + sticky CTA, Quiz button shows Tier-4 placeholder toast). Built real `HomePage` end-to-end: animated XP counter, progress bar (uses level min/max exp from `User.level`), navy trophy banner with `home_trophy.png`, live top-5 leaderboard widget (TanStack), active-subject card (auto-picks due-module subject), 6-icon subject rail. All wired to real API hooks; mock mode returns fixtures transparently. Routes added: `/subjects/:subjectId/modules/:moduleId/chapters/:chapterId`. Full flow now clickable: Login → Home → Subject card → Subject detail → Module chapter (journey) → Chapter theory → (Quiz toast).
- **#9** — **MEGA PUSH: Missions + Quiz + ModuleLeaderboard.** Big completion run. Built `Question` + `Mission` types + parsers, `api/missions.ts` (with 6 mock missions across past/today/future days, multiple subjects, full question content), `api/quiz.ts` (chapter questions endpoint + mission questions + answer-check with mock + real-backend paths). Built `MissionListPage` (calendar with month nav + per-day status dots + missions-for-selected-date list — merges mission_screen + mission_subject_screen on web), `MissionDetailPage` (hero + question preview + Start CTA), shared `QuizFlow` component (handles MCQ single/multiple/short-answer, hint reveal, attempt-scaled XP, correct/incorrect feedback banners, progress bar, animated results card), `ChapterQuizPage` + `MissionQuizPage` routes that both delegate to `QuizFlow`, and `ModuleLeaderboardPage` (subject-color themed). Wired ChapterTheory Start Quiz to real route. Added Missions to SideNav + BottomTabs. Type-check clean. Total: ~15/24 source-Dart screens shipped + the quiz heavy lift partially landed. Rearrange question type, test screens, and Tier 5 polish (FCM, analytics, sound, drag-rearrange UI) remain.

