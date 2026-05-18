# GyanBuddy stub backend

A small FastAPI app that implements the response envelope and endpoint contract
documented in `context.txt` section 5 so the React app can be wired against a
real HTTP server during local development. **Not the real production backend.**
Data is in-memory and resets on restart.

## Why this exists

The Django backend that the React app was originally built against
(`api-dev.gyaanbuddy.com`) is no longer reachable. This stub is enough to:

- Exercise the login → token-storage → bearer-auth flow end to end.
- Render every screen the React app has (home, subjects, modules, chapters,
  leaderboard, missions, tests, notifications, profile) against a real network
  call instead of the in-process mock layer.
- Test CORS, error envelopes, and 401 → logout behaviour with real responses.

## Run locally

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate          # PowerShell:  .venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Health check:

```bash
curl http://localhost:8000/health
```

## Run with Docker

```bash
docker build -t gyanbuddy-stub .
docker run --rm -p 8000:8000 gyanbuddy-stub
```

## Point the React app at this backend

In `gyanbuddy-react/.env.local`:

```
VITE_BUILD_MODE=dev
VITE_DEV_MOCK_AUTH=false
VITE_USE_PROXY=true
VITE_BASE_URL_DEV=http://localhost:8000
VITE_API_PREFIX=/api
```

Then `npm run dev` in the React folder. The Vite dev server will proxy
`/api/*` to `http://localhost:8000`, sidestepping CORS in the browser. (CORS
is also enabled server-side for `localhost:5173` and `localhost:5174` if you
prefer to talk to the backend directly.)

Any non-empty username/password works on `POST /api/auth/login/`; you'll get
the demo user and a fresh pair of stub access/refresh tokens.

## Endpoints

All routes are under `/api`. Response shape is uniformly:

```json
{ "success": true|false, "message": "...", "data": <T or null> }
```

Public (no Authorization header):

- `POST /api/auth/login/`
- `POST /api/auth/register`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`

Authenticated (require `Authorization: Bearer <token>`):

- `GET /api/users/me`, `PUT /api/users/me`, `DELETE /api/users/me`
- `GET /api/users/{userId}`, `POST /api/users/logout`
- `GET /api/subjects/`, `GET /api/subjects/{id}`,
  `GET /api/subjects/{id}/modules`
- `GET /api/modules/{moduleId}/module_chapters/`
- `GET /api/module_chapters/{chapterId}/module_content`
- `GET /api/module_chapters/{chapterId}/module_questions/`
- `GET /api/module_chapters/{chapterId}/hots_questions/`
- `GET /api/module_chapters/{chapterId}/get_next_content/{queryParam}`
- `POST /api/questions/{questionId}/check/`
- `GET /api/missions/`, `GET /api/tests/`, `GET /api/leaderboard`
- `GET /api/notifications`, `GET /api/home`, `GET /api/profile`
- `POST /api/fcm/token`, `DELETE /api/fcm/token/{userId}`
- `POST /api/fcm/topics/subscribe`, `POST /api/fcm/topics/unsubscribe`

## What this is NOT

- A real authentication system. Tokens are random strings, never validated
  against a user, never expire on the server side. Any non-empty bearer string
  is accepted.
- A real database. All data is hardcoded in `data.py`.
- A drop-in replacement for production. Use it only for local development
  and reviewer demos.
