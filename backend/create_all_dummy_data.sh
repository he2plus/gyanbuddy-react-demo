#!/bin/bash

# Script to create all dummy data in the correct order
# Usage: ./create_all_dummy_data.sh

echo "=========================================="
echo "Creating All Dummy Data"
echo "=========================================="
echo ""

# Install Faker if not already installed
echo "Checking for Faker..."
pip show Faker > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Installing Faker..."
    pip install Faker==24.0.0
fi

echo ""
echo "Starting dummy data creation..."
echo ""

# Run scripts in dependency order
echo "1. Creating Schools..."
python manage.py create_dummy_schools
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create schools"
    exit 1
fi

echo ""
echo "2. Creating Grades..."
python manage.py create_dummy_grades
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create grades"
    exit 1
fi

echo ""
echo "3. Creating Subjects..."
python manage.py create_dummy_subjects
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create subjects"
    exit 1
fi

echo ""
echo "4. Creating Users..."
python manage.py create_dummy_users
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create users"
    exit 1
fi

echo ""
echo "5. Creating Classes..."
python manage.py create_dummy_classes
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create classes"
    exit 1
fi

echo ""
echo "6. Creating Teachers..."
python manage.py create_dummy_teachers
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create teachers"
    exit 1
fi

echo ""
echo "7. Creating Students..."
python manage.py create_dummy_students
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create students"
    exit 1
fi

echo ""
echo "8. Creating Modules..."
python manage.py create_dummy_modules
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create modules"
    exit 1
fi

echo ""
echo "9. Creating Chapters..."
python manage.py create_dummy_chapters
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create chapters"
    exit 1
fi

echo ""
echo "10. Creating Questions..."
python manage.py create_dummy_questions
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create questions"
    exit 1
fi

echo ""
echo "11. Creating Module Content..."
python manage.py create_dummy_module_content
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create module content"
    exit 1
fi

echo ""
echo "12. Creating Missions..."
python manage.py create_dummy_missions
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create missions"
    exit 1
fi

echo ""
echo "13. Creating Competitions (Quizzes)..."
python manage.py create_dummy_competitions
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create competitions"
    exit 1
fi

echo ""
echo "=========================================="
echo "All dummy data created successfully!"
echo "=========================================="

