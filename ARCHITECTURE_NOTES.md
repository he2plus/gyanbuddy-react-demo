# Architecture & Infra Notes

What we kept faithful, what we improved silently, and what's worth doing later.
None of these change the backend contract or alter screen behavior — they're
React-side improvements made possible by leaving Flutter behind.

---

## Already in place (kept faithful, executed better)

| Area | Faithful to Flutter | Improvement |
|---|---|---|
| API contract | Same endpoints, same payloads, same trailing-slash habits | TanStack Query gives free request deduplication, caching, retry-on-mount |
| Token storage | Same `localStorage` keys (`access_token`, `refresh_token`, `*_expires`) | Mid-cutover users keep their session if you ever serve both apps simultaneously |
| Auth interceptor | Same logic: skip Authorization on public endpoints, 401 → clear + logout | No speculative refresh-token retry (Dart doesn't have one — we don't pretend) |
| Routing | Same 7 route names from `lib/main.dart:538` | Real history API, deep-linkable, browser back button works |
| Notification storage | Same local-only model as `NotificationService` | localStorage with the same shape so a future native ↔ web sync is trivial |
| Onboarding flag | Same local flag as `OnboardingService` | localStorage, gitignored `.env.local` for dev override |

---

## Performance improvements (already shipped)

1. **First paint < 200 ms** vs Flutter's ~2 s engine bootstrap (CanvasKit + skwasm download)
2. **Real DOM** = browser can paint progressively, no blocking canvas init
3. **Tree-shaken bundles** — `lucide-react`, `framer-motion`, `react-router` all import-on-use, not whole-package
4. **TanStack Query stale-time** = repeat navigations skip the network when data is fresh
5. **Vite HMR** = changes show up in the dev server in <100 ms vs Flutter's full hot-reload

---

## Worth doing before prod cutover (small, high ROI)

1. **Lazy-load heavy routes**
   `quiz_screen.dart` (2,707 LoC), `test_quiz_screen.dart` (1,502), `mission_detail_screen.dart` (2,292) → wrap their React equivalents in `React.lazy()` so they don't ship in the initial bundle. Saves ~30–40% off main bundle for users who never open them in a session.

2. **Asset compression**
   Some Flutter PNGs we copied are oversized for the web:
   - `mission.png` 585 KB
   - `you.png` 370 KB
   - `home.png` 261 KB
   - `dashboard.png` 365 KB
   - `avatar.jpeg` 374 KB

   Run them through `squoosh-cli` or convert to WebP. Each can drop to <100 KB with no visible quality loss. Zero code change required — just replace files in `public/images/`.

3. **Image preloading for the journey page**
   When `ModuleChapterPage` lands, preload `platform.png` / `thread.png` / `stand_boy.png` so the first chapter scroll doesn't pop-in.

4. **HTTP cache headers in production**
   When deployed, the static `/images/*` and hashed JS/CSS bundles should have `Cache-Control: max-age=31536000, immutable`. Vite generates content-hashed filenames so this is safe. Tell whoever deploys.

5. **Service worker for offline shell** *(optional)*
   PWA-lite — cache the JS/CSS bundle and the static assets so the app loads instantly even on flaky networks. ~40 lines of code. Don't do this until backend signs off because it can mask deploy issues.

---

## Worth doing after prod (can wait, not blocking)

1. **Sentry-style error reporting** — currently if a component throws, the user sees a blank page. An error boundary + Sentry would surface this. Backend doesn't change.

2. **Code-quality scaffolding** — Prettier + ESLint Husky pre-commit, Vitest setup. Helpful when more devs join.

3. **Migrate the `home_trophy.png` to an SVG** — the Flutter banner uses a raster trophy. SVG would be sharper and smaller.

4. **Replace dev-mock with MSW** — Mock Service Worker would intercept ALL endpoints (not just auth) so QA can test screens that need fake data without backend access.

---

## What we deliberately did NOT change (and why)

- **Backend** — explicitly out of scope. Same Django + DRF + Firebase.
- **Brand colors / typography** — kept exact (`#365DEA`, system sans). Tier 3 home screen will keep the same hero color identity.
- **Endpoint shapes** — every payload mirrors the Flutter code's expectations.
- **Token model** — same access/refresh/expires keys in localStorage.
- **No state library beyond zustand + TanStack Query** — Redux would be overkill for this app's scale.

---

## Database / what to ask the client for (real-data testing)

You don't need direct DB access. Everything goes through the Django API.
What you need:

| Item | Who | Why |
|---|---|---|
| Test admission # + password (one student account) | Backend / client | Login + every authenticated screen |
| (Optional) A second test account in the same class | Backend / client | Verify "You" pill on leaderboard, friend visibility |
| (Optional) A teacher/admin account | Backend / client | Only if Tier 5 includes teacher views (currently no) |
| CORS allowance for `http://localhost:5173` on dev API | Backend | Skip if you use the Vite proxy (already set up) |
| Firebase web config from `lib/firebase_options.dart` | Backend / client | Required only for Tier 5 (FCM push notifications) |
| PostHog project key | Client / marketing | Required only for Tier 5 (analytics) |

That's it. No SQL access, no Django admin login, no AWS/GCP creds needed for what we're building.

---

## When NOT to deploy

Hold off on production cutover until ALL of these are true:

- [ ] Tier 3 + 4 screens shipped
- [ ] Walkthrough recorded and approved by client
- [ ] At least one full user journey tested end-to-end against real backend
- [ ] Backend team has confirmed CORS settings include the prod React domain
- [ ] Firebase web push tested (Tier 5)
- [ ] Lighthouse Performance ≥ 90 on Home and a representative content screen

If any of these are false on demo day, push back on the timeline rather than ship.
