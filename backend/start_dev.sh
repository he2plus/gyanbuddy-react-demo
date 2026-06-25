#!/bin/bash

# Gyaan Buddy Development Server Startup Script
# This script starts the Django development server with proper environment setup

echo "🚀 Starting Gyaan Buddy Development Server..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please create it first:"
    echo "   python -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements.txt"
    exit 1
fi

# Activate virtual environment
echo "📦 Activating virtual environment..."
source venv/bin/activate

# Check if PostgreSQL is running
if ! pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo "⚠️  PostgreSQL is not running. Starting PostgreSQL service..."
    brew services start postgresql@14
    sleep 3
fi

# Check database connection
echo "🔍 Checking database connection..."
python manage.py check --database default

if [ $? -eq 0 ]; then
    echo "✅ Database connection successful!"
    echo "🌐 Starting Django development server..."
    echo "📍 Server will be available at: http://localhost:8000"
    echo "🛑 Press Ctrl+C to stop the server"
    echo ""
    python manage.py runserver
else
    echo "❌ Database connection failed. Please check your PostgreSQL setup."
    exit 1
fi