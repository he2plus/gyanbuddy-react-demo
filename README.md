# Gyaan Buddy — React Migration (`gyanbuddy-react`)

The React port of the Gyaan Buddy student app, replacing the slow Flutter web build with a real responsive DOM app.

> **Local development only.** No deploy, no CI, no preview URLs. The user will explicitly approve deployment after they've tested on their machine. See `context.txt` §8.E.

---

## Status: Phase 0 (Foundation)

This commit delivers the foundation called for in `context.txt` §14:

- Vite + React + TypeScript scaffold (in place from prior session)
- Tailwind CSS v4 with `@theme` design tokens mirroring `lib/theme/app_theme.dart` (§6)
- React Router v6 with the 7 routes from §7
- Responsive `AppShell` with the three breakpoints from §8.A
- Empty placeholder pages for every route
- Stubs for the axios client (`src/api/client.ts`), token storage (`src/lib/storage.ts`), and zustand stores (`src/state/auth.ts`, `src/state/ui.ts`)
- `.env.example` mirroring §12

**Not in Phase 0:** authentication, real API calls, real screens. Those start in Tier 1 step 5 (login → /home).

---

## Run locally

Requires Node 20+.

```bash
cd gyanbuddy-react
npm install
npm run dev          # http://localhost:5173
```

To switch backend mode, copy `.env.example` to `.env` and set `VITE_BUILD_MODE` to `dev`, `stage`, or `prod`.

> **CORS note (context.txt §16):** the Django dev backend may need to add `http://localhost:5173` to its allowed origins. If you see CORS errors on the first real API call, surface to the backend team — do not work around it from the frontend.

---

## Folder structure (per §10)

```
gyanbuddy-react/
├── index.html
├── vite.config.ts
├── package.json
├── tsconfig.json
├── .env.example
└── src/
    ├── main.tsx                   # Entry — mounts AppProviders + RouterProvider
    ├── styles/
    │   ├── tokens.css             # CSS variables from §6 (single source of truth)
    │   └── globals.css            # Tailwind v4 + @theme bridge + base resets
    ├── app/
    │   ├── routes.tsx             # Route table mirroring lib/main.dart:538
    │   └── providers.tsx          # QueryClient, Toaster (Phase 0)
    ├── shell/
    │   ├── AppShell.tsx           # Responsive chrome (3 breakpoints)
    │   ├── AppBar.tsx
    │   ├── BottomTabs.tsx         # Mobile (<lg)
    │   └── SideNav.tsx            # Desktop (≥lg)
    ├── features/                  # One folder per Flutter screen-group
    │   ├── _placeholder.tsx       # Shared "coming soon" component
    │   ├── auth/LoginPage.tsx
    │   ├── onboarding/OnboardingPage.tsx
    │   ├── home/
    │   │   ├── HomePage.tsx
    │   │   └── _demo/             # Salvaged proof-of-work — head-start for Tier 3
    │   ├── confirmation/ConfirmationPage.tsx
    │   ├── leaderboard/LeaderboardPage.tsx
    │   ├── notifications/NotificationsPage.tsx
    │   └── credits/CreditsPage.tsx
    ├── api/
    │   └── client.ts              # axios stub — interceptors land Tier 1.5
    ├── state/
    │   ├── auth.ts                # zustand store
    │   └── ui.ts                  # zustand store
    └── lib/
        ├── cn.ts                  # className merge helper
        └── storage.ts             # localStorage tokens (mirrors token_storage_service.dart)
```

### Note on `src/features/home/_demo/`

The previous session built a faithful React replica of the GyanBuddy home screen as a proof-of-work. Those components (`Header`, `HeroGreeting`, `LeaderboardCard`, `SubjectCard`, `SubjectRail`, `Avatar`, `AnimatedCounter`) are stashed under `_demo/` to serve as a head-start for **Tier 3** when we migrate `lib/screens/home/new_home_content_screen.dart`. They are NOT imported by the Phase 0 app. Their relative imports (`../lib/cn` → `../../../lib/cn`) will need to be repointed when we revive them.

---

## Stack (matches context.txt §11 with one deviation)

| Concern | Locked spec | Installed | Reason for delta |
|---|---|---|---|
| React | 18.3 | **19.x** | Repo started on React 19 in the prior session; user approved keeping it. No code in §11 depends on a v18-only API. |
| Vite | 5.4 | **8.x** | Same as above. |
| Tailwind | 3.4 | **v4** | Uses `@theme` block + `@tailwindcss/vite` instead of `tailwind.config.ts` + PostCSS. Tokens still come from §6, just declared inline. |
| Router | react-router-dom v6 | ✓ | Match. |
| Server state | @tanstack/react-query v5 | ✓ | Match. |
| Client state | zustand v4 | ✓ | Match. |
| HTTP | axios | ✓ | Match. |
| Forms | react-hook-form + zod | ✓ | Match. |
| Animations | framer-motion | ✓ | Match. |
| Firebase | firebase v10 JS SDK | ✓ | Match. |
| Analytics | posthog-js + firebase analytics | ✓ | Match. |
| Dates | date-fns | ✓ | Match. |
| Toasts | react-hot-toast | ✓ | Match. |
| Testing | vitest + playwright | NOT INSTALLED | Skipped Phase 0 — install when first test lands. |

---

## Web limitations (call out per §8.D)

- **Screenshot blocking is dropped on web.** Browsers cannot block screenshots — there is no DOM API for it. The mobile apps still have it. Any "no_screenshot" requirement does not apply here.
- **Vibration**: polyfilled with `navigator.vibrate?.()` (no-op on desktop).
- **Local notifications** → Firebase Messaging Web Push (`firebase-messaging-sw.js` from the existing repo, reused).
- **Audio** → native `HTMLAudioElement`.
- **bytebrew, gameanalytics**: dropped on web (no clean equivalents).

---

## Screen tracker (24 screens from §4)

| Tier | Source path | LoC | Status |
|---|---|---|---|
| 1 | lib/screens/auth/login_screen.dart | 843 | Pending |
| 1 | lib/screens/auth/new_login_screen.dart | ~ | Pending |
| 2 | lib/screens/splash/image_splash_screen.dart | ~ | Pending |
| 2 | lib/screens/confirmation/confirmation_screen.dart | ~ | Pending |
| 2 | lib/screens/profile/credits_screen.dart | ~ | Pending |
| 2 | lib/screens/notifications/notification_screen.dart | ~ | Pending |
| 2 | lib/screens/profile/profile_screen.dart | 1,109 | Pending |
| 2 | lib/screens/onboarding/onboarding_screen.dart | ~ | Pending |
| 2 | lib/screens/subject/subject_screen.dart | 723 | Pending |
| 2 | lib/screens/leaderboard/leaderboard_screen.dart | 727 | Pending |
| 3 | lib/screens/leaderboard/module_leaderboard_screen.dart | ~ | Pending |
| 3 | lib/screens/module/module_chapter_screen.dart | 1,468 | Pending |
| 3 | lib/screens/module/module_content_screen.dart | 757 | Pending |
| 3 | lib/screens/module/chapter_theory_screen.dart | 1,059 | Pending |
| 3 | lib/screens/module/theory_screen.dart | 1,008 | Pending |
| 3 | lib/screens/mission/mission_screen.dart | 952 | Pending |
| 3 | lib/screens/mission/mission_subject_screen.dart | 1,194 | Pending |
| 3 | lib/screens/mission/mission_detail_screen.dart | 2,292 | Pending |
| 3 | lib/screens/mission/mission_splash_screen.dart | ~ | Pending |
| 3 | lib/screens/home/home_screen.dart | ~ | Pending |
| 3 | lib/screens/home/new_home_content_screen.dart | ~ | Pending (proof-of-work demo available in `_demo/`) |
| 4 | lib/screens/quiz/quiz_screen.dart | 2,707 | Pending |
| 4 | lib/screens/test/test_quiz_screen.dart | 1,502 | Pending |
| 4 | lib/screens/test/test_subject_screen.dart | 1,488 | Pending |

---

## Next step

Phase 0 is foundation only. When this builds and runs cleanly on `localhost:5173` and you've eyeballed the three breakpoints, the next milestone is **Tier 1 step 5**:

1. Implement axios interceptors (auth header + envelope unwrap + 401 refresh)
2. Build the real `LoginPage` against `POST /auth/login/`
3. Bootstrap auth state on app load (`/` → `/home` if token valid, else `/login`)

Ask explicitly to begin Tier 1.5.
