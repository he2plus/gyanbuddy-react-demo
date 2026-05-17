# archive/source branch

This branch is a side-channel for source material that does **not** ship with
the deployed app. It is not built or deployed by Vercel — Vercel only watches
`main` for production. At most a preview URL may be generated for this branch;
the production URL is untouched.

## Contents

| Path | What it is |
|------|------------|
| `gyaan_buddy/` | The original Flutter source the React app was migrated from. Kept for reference. Build artifacts (`build/`, `.dart_tool/`) and the nested `.git/` are intentionally stripped. |
| `context.txt`  | Full handoff brief written before the React migration started. Architecture decisions, route table, design tokens, screen inventory. |
| `prompt.txt`   | The original prompt that kicked off the migration work. |
| Everything else | Mirrors `main` (the React app), so cloning this branch gives you a working dev environment too. |

## What is NOT here

- **Backend (Django + DRF + Firebase)** — context.txt notes this lives elsewhere
  at `theshushant/gyaan_buddy.git` and was explicitly out of scope. If you need
  it on this repo, fetch it from there and add it under `backend/`.
- **Flutter build artifacts** — re-generate with `flutter pub get` then
  `flutter build web` inside `gyaan_buddy/`.

## Usage

```bash
# Local
git fetch origin archive/source
git checkout archive/source

# Claude Code web session (or any fresh clone)
git clone https://github.com/he2plus/gyanbuddy-react-demo.git
cd gyanbuddy-react-demo
git checkout archive/source
```

`main` continues to be the deploying branch. Push to `main` ⇒ Vercel
redeploys. Push to `archive/source` ⇒ nothing goes live.
