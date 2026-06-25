#!/bin/bash

# Gyaan Buddy Development Server Startup Script

echo "🚀 Starting Gyaan Buddy Development Server..."

# Activate virtual environment
source venv/bin/activate

# Start PostgreSQL and Redis (if using Docker)
echo "🐳 Starting PostgreSQL and Redis..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

# Start Django server with development settings
echo "📡 Starting Django server with development settings..."
DJANGO_SETTINGS_MODULE=gyaan_buddy.settings.development python manage.py runserver

echo "✅ Server started successfully!"
echo "🌐 API available at: http://localhost:8000"
echo "📚 API documentation: http://localhost:8000/api/"
echo "🔑 Test credentials: student1 / student123"
