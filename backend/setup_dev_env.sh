
#!/bin/bash

# Gyaan Buddy Development Environment Setup Script
# This script sets up the development environment

echo "🔧 Setting up Gyaan Buddy Development Environment..."

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "📦 Installing PostgreSQL..."
    brew install postgresql@14
fi

# Start PostgreSQL service
echo "🚀 Starting PostgreSQL service..."
brew services start postgresql@14

# Wait for PostgreSQL to start
sleep 3

# Check if database user exists, create if not
echo "👤 Setting up database user..."
psql -U sushantmalik -h localhost -d postgres -c "SELECT 1 FROM pg_user WHERE usename='gyaan_buddy_user';" | grep -q "1 row" || {
    echo "Creating database user..."
    psql -U sushantmalik -h localhost -d postgres -c "CREATE USER gyaan_buddy_user WITH PASSWORD 'gyaan_buddy_password';"
}

# Check if database exists, create if not
echo "🗄️  Setting up database..."
psql -U sushantmalik -h localhost -d postgres -c "SELECT 1 FROM pg_database WHERE datname='gyaan_buddy';" | grep -q "1 row" || {
    echo "Creating database..."
    psql -U sushantmalik -h localhost -d postgres -c "CREATE DATABASE gyaan_buddy OWNER gyaan_buddy_user;"
}

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "📦 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing Python dependencies..."
pip install -r requirements.txt

# Run migrations
echo "🗃️  Running database migrations..."
python manage.py migrate

echo "✅ Development environment setup complete!"
echo ""
echo "🚀 To start the development server, run:"
echo "   ./start_dev.sh"
echo ""
echo "Or manually:"
echo "   source venv/bin/activate"
echo "   python manage.py runserver"
