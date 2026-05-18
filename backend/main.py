"""
GyanBuddy stub backend.

Implements the envelope + endpoint contract documented in context.txt section 5
so the React app can be wired against a real HTTP server instead of relying on
its in-process mock layer. Data is in-memory only; nothing is persisted.

Run:
    pip install -r requirements.txt
    uvicorn main:app --reload --port 8000
"""
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
import secrets

from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from data import (
    DEMO_USER,
    LEADERBOARD_USERS,
    SUBJECTS,
    chapters_for,
    modules_for,
)


app = FastAPI(title="GyanBuddy Stub Backend", version="0.1.0")

# CORS: Vite dev server typically on 5173, falls back to 5174 when occupied.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://localhost:5174",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:5174",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- response envelope -------------------------------------------------------

def envelope(data: Any = None, message: str = "OK", success: bool = True) -> dict:
    return {"success": success, "message": message, "data": data}


@app.exception_handler(HTTPException)
async def http_exc_handler(_: Request, exc: HTTPException):
    """Wrap every error in the same envelope the frontend expects."""
    detail = exc.detail
    if isinstance(detail, dict) and "success" in detail:
        return JSONResponse(status_code=exc.status_code, content=detail)
    return JSONResponse(
        status_code=exc.status_code,
        content={"success": False, "message": str(detail), "data": None},
    )


# --- auth --------------------------------------------------------------------

def _now() -> datetime:
    return datetime.now(timezone.utc)


def _iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def _make_tokens() -> dict:
    n = _now()
    return {
        "access": f"stub_access_{secrets.token_hex(16)}",
        "refresh": f"stub_refresh_{secrets.token_hex(16)}",
        "access_token_expires": _iso(n + timedelta(hours=8)),
        "refresh_token_expires": _iso(n + timedelta(days=30)),
    }


def require_bearer(authorization: Optional[str] = Header(None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Authentication required.", "data": None},
        )
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Empty bearer token.", "data": None},
        )
    return token


# --- request models ---------------------------------------------------------

class LoginIn(BaseModel):
    username: str
    password: str
    fcm_token: Optional[str] = None


class RegisterIn(BaseModel):
    username: str
    password: str
    first_name: str
    last_name: str
    email: str
    user_type: Optional[str] = "student"
    admission_number: int
    roll_number: Optional[int] = None
    school: str
    phone_number: Optional[str] = None
    date_of_birth: Optional[str] = None


class EmailIn(BaseModel):
    email: str


class ResetIn(BaseModel):
    token: str
    password: str
    password_confirmation: str


# --- public auth routes ------------------------------------------------------

@app.post("/api/auth/login/")
def login(payload: LoginIn):
    if not payload.username.strip() or not payload.password:
        raise HTTPException(
            status_code=400,
            detail={
                "success": False,
                "message": "Username and password are required.",
                "errors": {"username": ["Required."]},
                "data": None,
            },
        )
    return envelope(
        {"user": DEMO_USER, "tokens": _make_tokens()},
        message="Logged in.",
    )


@app.post("/api/auth/register")
def register(payload: RegisterIn):
    if not payload.username.strip() or not payload.password:
        raise HTTPException(
            status_code=400,
            detail={
                "success": False,
                "message": "Username and password are required.",
                "data": None,
            },
        )
    user = {**DEMO_USER, "username": payload.username, "first_name": payload.first_name,
            "last_name": payload.last_name, "email": payload.email,
            "admission_number": payload.admission_number,
            "logged_in_once": False}
    return envelope({"user": user, "tokens": _make_tokens()}, "Registered.")


@app.post("/api/auth/forgot-password")
def forgot_password(payload: EmailIn):
    return envelope(
        None,
        f"If an account exists for {payload.email}, a reset link has been sent.",
    )


@app.post("/api/auth/reset-password")
def reset_password(payload: ResetIn):
    if payload.password != payload.password_confirmation:
        raise HTTPException(
            status_code=400,
            detail={"success": False, "message": "Passwords do not match.", "data": None},
        )
    return envelope(None, "Password reset successfully. You can now log in.")


# --- users -------------------------------------------------------------------

@app.get("/api/users/me")
def get_me(_: str = Depends(require_bearer)):
    return envelope(DEMO_USER)


@app.put("/api/users/me")
async def update_me(request: Request, _: str = Depends(require_bearer)):
    body = await request.json()
    updated = {**DEMO_USER, **{k: v for k, v in body.items() if k in DEMO_USER}}
    return envelope(updated, "Profile updated.")


@app.delete("/api/users/me")
def delete_me(_: str = Depends(require_bearer)):
    return envelope(None, "Account deleted.")


@app.get("/api/users/{user_id}")
def get_user(user_id: str, _: str = Depends(require_bearer)):
    if user_id == DEMO_USER["id"]:
        return envelope(DEMO_USER)
    found = next((u for u in LEADERBOARD_USERS if u["id"] == user_id), None)
    if not found:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "User not found.", "data": None},
        )
    return envelope(found)


@app.post("/api/users/logout")
def logout(_: str = Depends(require_bearer)):
    return envelope(None, "Logged out.")


# --- subjects / modules / chapters ------------------------------------------

@app.get("/api/subjects/")
def list_subjects(_: str = Depends(require_bearer)):
    return envelope(SUBJECTS)


@app.get("/api/subjects/{subject_id}")
def get_subject(subject_id: str, _: str = Depends(require_bearer)):
    found = next((s for s in SUBJECTS if s["id"] == subject_id), None)
    if not found:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Subject not found.", "data": None},
        )
    return envelope(found)


@app.get("/api/subjects/{subject_id}/modules")
def list_modules(subject_id: str, _: str = Depends(require_bearer)):
    if not any(s["id"] == subject_id for s in SUBJECTS):
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Subject not found.", "data": None},
        )
    return envelope(modules_for(subject_id))


@app.get("/api/modules/{module_id}/module_chapters/")
def list_chapters(module_id: str, _: str = Depends(require_bearer)):
    return envelope(chapters_for(module_id))


@app.get("/api/module_chapters/{chapter_id}/module_content")
def chapter_content(chapter_id: str, _: str = Depends(require_bearer)):
    return envelope({
        "id": chapter_id,
        "content": (
            "## Theory\n\n"
            "This is stub content served by the local backend. "
            "In the real product this would be rich learning content for the chapter."
        ),
        "next_content_id": None,
    })


@app.get("/api/module_chapters/{chapter_id}/module_questions/")
def chapter_questions(chapter_id: str, _: str = Depends(require_bearer)):
    return envelope([
        {
            "id": f"{chapter_id}-q1",
            "question_text": "Which of the following best describes the concept?",
            "options": [
                {"id": "o1", "text": "Option A", "is_correct": True},
                {"id": "o2", "text": "Option B", "is_correct": False},
                {"id": "o3", "text": "Option C", "is_correct": False},
                {"id": "o4", "text": "Option D", "is_correct": False},
            ],
            "explanation": "Option A is correct because the stub said so.",
            "exp_reward": 10,
        }
    ])


@app.get("/api/module_chapters/{chapter_id}/hots_questions/")
def chapter_hots(chapter_id: str, _: str = Depends(require_bearer)):
    return envelope([])


@app.get("/api/module_chapters/{chapter_id}/get_next_content/{query_param}")
def next_content(chapter_id: str, query_param: str, _: str = Depends(require_bearer)):
    return envelope({"id": f"{chapter_id}-next", "content": "Next stub content."})


@app.post("/api/questions/{question_id}/check/")
async def check_question(question_id: str, request: Request, _: str = Depends(require_bearer)):
    body = await request.json()
    return envelope({
        "question_id": question_id,
        "is_correct": True,
        "selected_option_id": body.get("option_id"),
        "exp_awarded": 10,
        "explanation": "Stub backend always agrees with you.",
    })


# --- missions / tests / leaderboard / notifications / home / profile --------

@app.get("/api/missions/")
def missions(_: str = Depends(require_bearer)):
    return envelope([
        {"id": "mission-1", "name": "Daily Streak", "description": "Complete one chapter today.",
         "is_completed": False, "exp_reward": 50, "due_date": None},
        {"id": "mission-2", "name": "Quiz Champion", "description": "Score 100% on any quiz.",
         "is_completed": True, "exp_reward": 100, "due_date": None},
    ])


@app.get("/api/tests/")
def tests(_: str = Depends(require_bearer)):
    return envelope([
        {"id": "test-1", "name": "Chemistry Unit Test 1", "subject": "chem",
         "question_count": 10, "duration_minutes": 30, "status": "available"},
    ])


@app.get("/api/leaderboard")
def leaderboard(_: str = Depends(require_bearer)):
    ordered = sorted(LEADERBOARD_USERS, key=lambda u: -u["total_exp"])
    return envelope({
        "users": ordered,
        "className": "Class 10-A",
        "gradeName": "Grade 10",
    })


@app.get("/api/notifications")
def notifications(_: str = Depends(require_bearer)):
    return envelope([
        {"id": "n1", "title": "Welcome to GyanBuddy",
         "body": "You're connected to the stub backend.", "is_read": False,
         "created_at": _iso(_now())},
    ])


@app.get("/api/home")
def home(_: str = Depends(require_bearer)):
    return envelope({
        "user": DEMO_USER,
        "subjects": SUBJECTS,
        "leaderboard": LEADERBOARD_USERS[:5],
        "active_subject": "chem",
    })


@app.get("/api/profile")
def profile(_: str = Depends(require_bearer)):
    return envelope(DEMO_USER)


# --- FCM (mobile push, stubs only) ------------------------------------------

@app.post("/api/fcm/token")
async def fcm_register(request: Request, _: str = Depends(require_bearer)):
    await request.json()
    return envelope(None, "Token registered.")


@app.delete("/api/fcm/token/{user_id}")
def fcm_unregister(user_id: str, _: str = Depends(require_bearer)):
    return envelope(None, f"Token removed for {user_id}.")


@app.post("/api/fcm/topics/subscribe")
async def fcm_subscribe(request: Request, _: str = Depends(require_bearer)):
    await request.json()
    return envelope(None, "Subscribed.")


@app.post("/api/fcm/topics/unsubscribe")
async def fcm_unsubscribe(request: Request, _: str = Depends(require_bearer)):
    await request.json()
    return envelope(None, "Unsubscribed.")


# --- health ------------------------------------------------------------------

@app.get("/")
def root():
    return envelope({"service": "gyanbuddy-stub-backend", "version": "0.1.0"})


@app.get("/health")
def health():
    return envelope({"status": "ok", "now": _iso(_now())})
