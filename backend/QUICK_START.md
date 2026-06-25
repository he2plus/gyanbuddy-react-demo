
# 🚀 Quick Start Guide

## Super Simple Development Setup

Now you can start your Django development server with just **one command**!

### 🎯 **Option 1: One Command Start (Recommended)**

```bash
./start_dev.sh
```

This will:
- ✅ Start PostgreSQL and Redis in Docker
- ✅ Set up all environment variables
- ✅ Start Django development server
- ✅ Show you the URLs to access

### 🎯 **Option 2: Manual Activation**

```bash
# 1. Activate virtual environment (auto-starts PostgreSQL & Redis)
source venv/bin/activate

# 2. Run Django server
python manage.py runserver
```

### 🎯 **Option 3: Just Run Server (if already activated)**

```bash
python manage.py runserver
```

---

## 📱 **Access Your Application**

Once running, access your app at:
- **Main App**: http://localhost:8000
- **API**: http://localhost:8000/api/
- **Admin**: http://localhost:8000/admin/

---

## 🔧 **What Happens Automatically**

When you activate the virtual environment:
- 🐳 **PostgreSQL** starts on localhost:5432
- 🔴 **Redis** starts on localhost:6379
- 🔧 **Environment variables** are set for PostgreSQL
- ✅ **Database connection** is verified

When you deactivate:
- 🛑 **Docker services** are stopped automatically

---

## 🛠️ **Useful Commands**

```bash
# Database operations
python manage.py migrate
python manage.py makemigrations
python manage.py createsuperuser

# Development
python manage.py shell
python manage.py check

# Stop everything
deactivate
```

---

## 🔑 **Get a Bearer Token (Teacher Login)**

```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "teacher1", "password": "teacher123", "type": "dashboard"}'
```

> **Note:** Teachers must pass `"type": "dashboard"`. The default type is `"mobile"` which blocks teacher/admin accounts.

The `access` token from the response is your Bearer token for API requests.

---

## 🐛 **Troubleshooting**

**If PostgreSQL fails to start:**
1. Make sure Docker Desktop is running
2. Run `docker ps` to check container status
3. Try `docker-compose -f docker-compose.dev.yml up db redis -d`

**If Django can't connect:**
1. Check if PostgreSQL is running: `docker ps | grep postgres`
2. Verify environment variables: `echo $DB_ENGINE`
3. Test connection: `python manage.py check`

---

## 🎉 **That's It!**

No more complex setup - just activate your environment and run Django! 🚀
