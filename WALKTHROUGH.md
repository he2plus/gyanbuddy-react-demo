# Pre-Production Walkthrough Plan

For your screen-recorded demo before client/prod deployment. Designed to fit in
**~10–15 minutes** of recording.

---

## Recording setup

| Tool | When | Why |
|---|---|---|
| **Loom** (free tier) | Default — share with client via link | Auto-captions, instant share URL, viewers can comment timestamps |
| **OBS Studio** | If you want a polished video file (.mp4) | More control, bigger learning curve |
| **Windows Game Bar** (Win+G) | Quick local recording, no install | Already installed, decent quality |
| **ScreenToGif** | If client wants short loops, not full video | Lightweight, exports GIF/MP4/APNG |

**Resolution:** record at 1920×1080. The desktop layout shows best at this size.

**Browser:** Chrome with **DevTools** docked to the right at ~360px wide. This lets you flip between desktop and mobile layouts mid-recording without resizing the window.

**Pre-record checklist:**
1. Run `npm run dev` — wait for "ready in XXXms"
2. Open `http://localhost:5173` in a fresh incognito window (no stale localStorage)
3. Open DevTools → Network tab visible (so the client sees real API calls firing)
4. Confirm `.env.local` has `VITE_DEV_MOCK_AUTH=false` and `VITE_USE_PROXY=true` for the recording (you want to show real backend calls)
5. Have valid test admission # + password ready in clipboard

---

## Recording script (in order)

### 1. Performance opener (~30s)

> **Talk track:** "First, the speed difference. Here's the current Flutter web build, here's the React port. Watch the time-to-first-paint."

- Open the live Flutter site (gyanbuddy.ai/student/) in tab 1 — show the white screen + "Loading GyanBuddy" + the ~2-second Flutter bootstrap
- Switch to tab 2 with the React app — first paint is essentially instant
- Open DevTools → Network → reload both with cache disabled, point to the bundle sizes

### 2. Login + auth flow (~90s)

> "All token storage uses the SAME localStorage keys as the Flutter app. Users mid-cutover keep their session."

- Land on `/login` — show the login form (real `login_logo.png` matches Flutter)
- Open DevTools → Application → Local Storage → show it's empty
- Submit valid credentials
- Watch the Network tab fire `POST /api/auth/login/`
- Show Local Storage now has `access_token`, `refresh_token`, `access_token_expires`, `refresh_token_expires` — same keys as Flutter
- Land on `/home` (returning user) or `/confirmation` (new user)
- Refresh the page → bootstrap call to `/api/users/me` → re-renders authenticated

### 3. Responsive design demo (~2 min)

> "This is the headline reason for the migration. The Flutter build was hard-locked to a 430-pixel column. The React build uses every pixel intelligently."

- On `/home`, full desktop view
- DevTools device toolbar (Ctrl+Shift+M) → toggle between:
  - Desktop 1920px → sidebar nav + wide content
  - iPad 1024px → sidebar still visible, content fills nicely
  - iPad portrait 768px → sidebar collapses, bottom tabs appear
  - iPhone 14 Pro Max 430px → mobile column, single-column layouts
  - iPhone SE 375px → still works, no horizontal scroll
- Visit `/credits` → team list grid (1 col mobile, 2 col tablet+)
- Visit `/notifications` → notification grid
- Visit `/leaderboard` → real API call, responsive table
- Visit `/subjects` → subject grid (1 col / 2 col / 3 col)

### 4. Real-data screens (~3 min)

> "Every screen that talks to the backend hits the same Django endpoints with the same payload shapes."

- `/leaderboard` — show period filter (daily/weekly/monthly/all-time), gold/silver/bronze ranks, "You" highlight, pagination
- `/subjects` — list all subjects with logos, "Due" pill on subjects with due modules
- `/profile` — XP, rewards, level (force-refreshes /users/me on mount)
- `/notifications` — empty state → click DevTools console → run `notificationStore.add({title:'Demo', body:'Test', type:'achievement'})` → notification appears with mark-read/delete

### 5. Static / animated screens (~1 min)

- `/onboarding` — swipe through 4 pages with gradient backgrounds
- `/confirmation` — auto-navigate after success animation
- `/credits` — team list, real `final_logo.png`

### 6. Architecture talking points (~2 min)

> Stay on `/home` for this section. Open DevTools → Network and Sources panels.

- **Bundle size comparison**: show compact main JS bundle vs Flutter's ~2 MB main.dart.js
- **Caching strategy**: re-navigate between routes, point out 0 redundant API calls (TanStack Query stale time)
- **Lighthouse**: run a Lighthouse audit, expect Performance ≥ 90, Accessibility ≥ 90
- **Code splitting potential**: mention quiz/test screens (Tier 4) will be lazy-loaded

### 7. Roadmap closer (~30s)

> "Here's what's still pending before prod cutover."

- Open `PROGRESS.md` in the repo, screen-share the screen tracker
- Highlight Tier 3/4 remaining work and the conservative timeline

---

## Pre-recording dry run

Before the actual record, run through the script ONCE silently to:
- Confirm every URL responds
- Confirm the test creds work
- Time yourself — adjust if any section is dragging
- Spot any console errors and fix before recording

---

## Things NOT to demo

- Mock-auth mode (it'll confuse the client)
- The `_demo/` folder (it's salvaged proof-of-work, not part of the live app)
- Any half-built Tier 3+ screen (only show what's done)
- DevTools React DevTools panel (too technical for stakeholder demo)

---

## After recording

1. Write a 2–3 sentence summary in the Loom (or video description)
2. Drop the link into the project's slack/email thread
3. Tag specifically: client, backend lead (for CORS/Firebase asks), QA
4. Wait for explicit approval before any deployment moves
