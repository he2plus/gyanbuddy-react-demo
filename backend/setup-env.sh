#!/bin/bash

# Gyaan Buddy Backend - Environment Setup Script
# This script helps you set up your .env file from the template

echo "🐳 Setting up environment variables for Gyaan Buddy Backend..."
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled. Your existing .env file is preserved."
        exit 1
    fi
fi

# Copy template to .env
if [ -f "env-template.txt" ]; then
    cp env-template.txt .env
    echo "✅ .env file created successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Edit .env file with your specific values:"
    echo "   nano .env"
    echo "   # or"
    echo "   code .env"
    echo ""
    echo "2. Update the following important variables:"
    echo "   - SECRET_KEY (generate a new one for production)"
    echo "   - Database credentials (if using PostgreSQL)"
    echo "   - Email settings"
    echo "   - API keys for external services"
    echo ""
    echo "3. Start your Docker environment:"
    echo "   make up"
    echo ""
    echo "🔐 Security Note: Never commit .env files to version control!"
    echo "   The .env file is already in .gitignore"
else
    echo "❌ Error: env-template.txt not found!"
    echo "Please make sure the template file exists."
    exit 1
fi

echo ""
echo "🎉 Environment setup complete!"
