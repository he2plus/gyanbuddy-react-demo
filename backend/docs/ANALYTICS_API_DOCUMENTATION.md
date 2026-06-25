# Gyaan Buddy - Analytics API Documentation

> **Version:** 1.0  
> **Last Updated:** December 6, 2024  
> **Base URL:** `/api/users/analytics/`  
> **Authentication:** Required (JWT Token)

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Response Format](#response-format)
4. [Teacher Analytics APIs](#teacher-analytics-apis)
   - [Teacher Overview](#1-teacher-overview)
   - [Class-Subject Analytics](#2-class-subject-analytics)
   - [Student Detail Analytics](#3-student-detail-analytics)
5. [Student Analytics APIs](#student-analytics-apis)
   - [My Progress](#4-my-progress)
   - [Subject Performance](#5-subject-performance)
   - [Weak Areas](#6-weak-areas)
   - [Leaderboard](#7-leaderboard)
6. [Mission Analytics APIs](#mission-analytics-apis)
   - [Mission Analytics](#8-mission-analytics)
7. [Competition Analytics APIs](#competition-analytics-apis)
   - [Competition Analytics](#9-competition-analytics)
8. [Admin Analytics APIs](#admin-analytics-apis)
   - [School Overview](#10-school-overview)
   - [Grade Analytics](#11-grade-analytics)
   - [Class Analytics](#12-class-analytics)
9. [General Analytics APIs](#general-analytics-apis)
   - [Answer Trends](#13-answer-trends)
10. [Error Handling](#error-handling)

---

## Overview

The Analytics API provides comprehensive data analysis capabilities for the Gyaan Buddy educational platform. It enables teachers to track student performance, students to monitor their progress, and administrators to get school-wide insights.

### Key Features
- **Real-time Analytics**: All data is calculated in real-time from the database
- **Role-based Access**: Different endpoints for teachers, students, and admins
- **Comprehensive Metrics**: Accuracy, progress, EXP, difficulty breakdown, and more
- **Trend Analysis**: Historical data for tracking improvement over time

---

## Authentication

All Analytics API endpoints require authentication using JWT (JSON Web Token).

### Headers Required
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

### Example
```bash
curl -X GET "https://api.example.com/api/users/analytics/student/my-progress/" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json"
```

---

## Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Description of the action",
  "data": {
    // Response data here
  }
}
```

### Error Response
```json
{
  "status": "error",
  "status_code": 400,
  "message": "Error description",
  "data": {
    "error": "Detailed error message"
  }
}
```

---

## Teacher Analytics APIs

### 1. Teacher Overview

Get an overview of all classes and subjects assigned to the logged-in teacher.

**Endpoint:** `GET /api/users/analytics/teacher/overview/`

**Permissions:** Teacher, Admin

**Request:**
```bash
GET /api/users/analytics/teacher/overview/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Teacher overview analytics retrieved successfully",
  "data": {
    "teacher_id": "550e8400-e29b-41d4-a716-446655440000",
    "teacher_name": "Mr. John Smith",
    "total_classes": 3,
    "total_students": 85,
    "total_questions_attempted": 2450,
    "overall_accuracy": 72.5,
    "classes": [
      {
        "class_id": "550e8400-e29b-41d4-a716-446655440001",
        "class_name": "Class 5A",
        "grade_name": "Grade 5",
        "subject_id": "550e8400-e29b-41d4-a716-446655440002",
        "subject_name": "Mathematics",
        "student_count": 30,
        "questions_attempted": 850,
        "correct_answers": 620,
        "accuracy_percentage": 72.94,
        "modules_completed": 45
      },
      {
        "class_id": "550e8400-e29b-41d4-a716-446655440003",
        "class_name": "Class 5B",
        "grade_name": "Grade 5",
        "subject_id": "550e8400-e29b-41d4-a716-446655440002",
        "subject_name": "Mathematics",
        "student_count": 28,
        "questions_attempted": 780,
        "correct_answers": 550,
        "accuracy_percentage": 70.51,
        "modules_completed": 38
      },
      {
        "class_id": "550e8400-e29b-41d4-a716-446655440004",
        "class_name": "Class 6A",
        "grade_name": "Grade 6",
        "subject_id": "550e8400-e29b-41d4-a716-446655440005",
        "subject_name": "Science",
        "student_count": 27,
        "questions_attempted": 820,
        "correct_answers": 610,
        "accuracy_percentage": 74.39,
        "modules_completed": 52
      }
    ]
  }
}
```

---

### 2. Class-Subject Analytics

Get detailed analytics for a specific class and subject combination.

**Endpoint:** `GET /api/users/analytics/teacher/class/{class_id}/subject/{subject_id}/`

**Permissions:** Teacher, Admin

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `class_id` | UUID | The class ID |
| `subject_id` | UUID | The subject ID |

**Request:**
```bash
GET /api/users/analytics/teacher/class/550e8400-e29b-41d4-a716-446655440001/subject/550e8400-e29b-41d4-a716-446655440002/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Class-subject analytics retrieved successfully",
  "data": {
    "class_id": "550e8400-e29b-41d4-a716-446655440001",
    "class_name": "Class 5A",
    "subject_id": "550e8400-e29b-41d4-a716-446655440002",
    "subject_name": "Mathematics",
    "total_students": 30,
    "overall_stats": {
      "total_questions_attempted": 850,
      "correct_answers": 620,
      "accuracy": 72.94
    },
    "difficulty_breakdown": {
      "easy": {
        "total": 300,
        "correct": 270,
        "accuracy": 90.0
      },
      "medium": {
        "total": 350,
        "correct": 245,
        "accuracy": 70.0
      },
      "hard": {
        "total": 200,
        "correct": 105,
        "accuracy": 52.5
      }
    },
    "module_progress": [
      {
        "module_id": "550e8400-e29b-41d4-a716-446655440010",
        "module_name": "Algebra Basics",
        "questions_attempted": 280,
        "correct_answers": 210,
        "accuracy": 75.0,
        "avg_completion": 85.5,
        "students_completed": 25
      },
      {
        "module_id": "550e8400-e29b-41d4-a716-446655440011",
        "module_name": "Geometry",
        "questions_attempted": 220,
        "correct_answers": 165,
        "accuracy": 75.0,
        "avg_completion": 62.3,
        "students_completed": 18
      },
      {
        "module_id": "550e8400-e29b-41d4-a716-446655440012",
        "module_name": "Fractions",
        "questions_attempted": 350,
        "correct_answers": 245,
        "accuracy": 70.0,
        "avg_completion": 78.2,
        "students_completed": 22
      }
    ],
    "student_performance": [
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440020",
        "student_name": "Emma Johnson",
        "username": "emma_j",
        "roll_number": 1,
        "questions_attempted": 45,
        "correct_answers": 42,
        "accuracy": 93.33,
        "avg_progress": 95.0,
        "total_exp": 1500,
        "level": 8
      },
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440021",
        "student_name": "Michael Chen",
        "username": "michael_c",
        "roll_number": 2,
        "questions_attempted": 42,
        "correct_answers": 38,
        "accuracy": 90.48,
        "avg_progress": 88.5,
        "total_exp": 1350,
        "level": 7
      }
      // ... more students
    ],
    "struggling_students": [
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440030",
        "student_name": "Tom Wilson",
        "username": "tom_w",
        "roll_number": 15,
        "questions_attempted": 25,
        "correct_answers": 10,
        "accuracy": 40.0,
        "avg_progress": 35.0,
        "total_exp": 450,
        "level": 3
      }
    ]
  }
}
```

---

### 3. Student Detail Analytics

Get detailed analytics for a specific student.

**Endpoint:** `GET /api/users/analytics/teacher/student/{student_id}/`

**Permissions:** Teacher, Admin

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `student_id` | UUID | The student ID |

**Request:**
```bash
GET /api/users/analytics/teacher/student/550e8400-e29b-41d4-a716-446655440020/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Student detail analytics retrieved successfully",
  "data": {
    "student_id": "550e8400-e29b-41d4-a716-446655440020",
    "student_name": "Emma Johnson",
    "username": "emma_j",
    "roll_number": 1,
    "admission_number": 2024001,
    "class_name": "Class 5A",
    "grade_name": "Grade 5",
    "overall_stats": {
      "total_questions_attempted": 250,
      "correct_answers": 210,
      "accuracy": 84.0,
      "first_attempt_success_rate": 72.0,
      "avg_attempts": 1.35
    },
    "exp_and_level": {
      "total_exp": 1500,
      "current_level": 8,
      "rewards": 75,
      "exp_to_next_level": 200
    },
    "difficulty_breakdown": {
      "easy": {
        "total": 100,
        "correct": 95,
        "accuracy": 95.0
      },
      "medium": {
        "total": 100,
        "correct": 80,
        "accuracy": 80.0
      },
      "hard": {
        "total": 50,
        "correct": 35,
        "accuracy": 70.0
      }
    },
    "hots_performance": {
      "total": 30,
      "correct": 22,
      "accuracy": 73.33
    },
    "subject_performance": [
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440002",
        "subject_name": "Mathematics",
        "questions_attempted": 120,
        "correct_answers": 102,
        "accuracy": 85.0,
        "avg_module_progress": 88.5,
        "modules_completed": 3,
        "total_modules": 4,
        "chapters_completed": 12
      },
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440005",
        "subject_name": "Science",
        "questions_attempted": 80,
        "correct_answers": 68,
        "accuracy": 85.0,
        "avg_module_progress": 75.0,
        "modules_completed": 2,
        "total_modules": 3,
        "chapters_completed": 8
      },
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440006",
        "subject_name": "English",
        "questions_attempted": 50,
        "correct_answers": 40,
        "accuracy": 80.0,
        "avg_module_progress": 60.0,
        "modules_completed": 1,
        "total_modules": 3,
        "chapters_completed": 5
      }
    ],
    "mission_stats": {
      "total_missions": 8,
      "completed": 6,
      "avg_exp_earned": 45.5
    },
    "competition_stats": {
      "participated": 5,
      "completed": 5,
      "avg_score": 82.4
    },
    "weak_areas": [
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440006",
        "subject_name": "English",
        "accuracy": 55.0,
        "recommendation": "Focus on English - practice more questions"
      }
    ]
  }
}
```

---

## Student Analytics APIs

### 4. My Progress

Get personal progress analytics for the logged-in student.

**Endpoint:** `GET /api/users/analytics/student/my-progress/`

**Permissions:** Student (any authenticated user with student profile)

**Request:**
```bash
GET /api/users/analytics/student/my-progress/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Student progress analytics retrieved successfully",
  "data": {
    "student_id": "550e8400-e29b-41d4-a716-446655440020",
    "student_name": "Emma Johnson",
    "class_name": "Class 5A",
    "overall_stats": {
      "total_questions_attempted": 250,
      "correct_answers": 210,
      "wrong_answers": 40,
      "accuracy": 84.0
    },
    "exp_and_level": {
      "total_exp": 1500,
      "current_level": 8,
      "rewards": 75,
      "exp_to_next_level": 200
    },
    "module_progress": {
      "completed": 6,
      "in_progress": 3,
      "total": 12,
      "avg_completion": 72.5
    },
    "chapter_progress": {
      "completed": 25,
      "in_progress": 5
    },
    "subject_progress": [
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440002",
        "subject_name": "Mathematics",
        "subject_code": "MATH",
        "color": "0DA6F2",
        "questions_attempted": 120,
        "correct_answers": 102,
        "accuracy": 85.0,
        "avg_completion": 88.5
      },
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440005",
        "subject_name": "Science",
        "subject_code": "SCI",
        "color": "4CAF50",
        "questions_attempted": 80,
        "correct_answers": 68,
        "accuracy": 85.0,
        "avg_completion": 75.0
      },
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440006",
        "subject_name": "English",
        "subject_code": "ENG",
        "color": "FF9800",
        "questions_attempted": 50,
        "correct_answers": 40,
        "accuracy": 80.0,
        "avg_completion": 60.0
      }
    ],
    "mission_stats": {
      "total": 8,
      "completed": 6,
      "total_exp_earned": 364
    },
    "competition_stats": {
      "participated": 5,
      "completed": 5,
      "total_exp_earned": 250
    }
  }
}
```

---

### 5. Subject Performance

Get detailed performance analytics for a specific subject.

**Endpoint:** `GET /api/users/analytics/student/subject/{subject_id}/`

**Permissions:** Student

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `subject_id` | UUID | The subject ID |

**Request:**
```bash
GET /api/users/analytics/student/subject/550e8400-e29b-41d4-a716-446655440002/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Subject performance analytics retrieved successfully",
  "data": {
    "subject_id": "550e8400-e29b-41d4-a716-446655440002",
    "subject_name": "Mathematics",
    "subject_code": "MATH",
    "overall_stats": {
      "total_questions": 120,
      "correct_answers": 102,
      "accuracy": 85.0,
      "avg_attempts": 1.25
    },
    "difficulty_breakdown": {
      "easy": {
        "total": 50,
        "correct": 48,
        "accuracy": 96.0
      },
      "medium": {
        "total": 45,
        "correct": 36,
        "accuracy": 80.0
      },
      "hard": {
        "total": 25,
        "correct": 18,
        "accuracy": 72.0
      }
    },
    "question_type_breakdown": {
      "mcq_single": {
        "total": 80,
        "correct": 70,
        "accuracy": 87.5
      },
      "mcq_multiple": {
        "total": 25,
        "correct": 20,
        "accuracy": 80.0
      },
      "short_answer": {
        "total": 15,
        "correct": 12,
        "accuracy": 80.0
      }
    },
    "hots_performance": {
      "total": 15,
      "correct": 11,
      "accuracy": 73.33
    },
    "modules": [
      {
        "module_id": "550e8400-e29b-41d4-a716-446655440010",
        "module_name": "Algebra Basics",
        "questions_attempted": 45,
        "correct": 40,
        "accuracy": 88.89,
        "progress_percentage": 100,
        "status": "completed",
        "chapters": [
          {
            "chapter_id": "550e8400-e29b-41d4-a716-446655440100",
            "chapter_title": "Introduction to Variables",
            "questions_attempted": 15,
            "correct": 14,
            "accuracy": 93.33,
            "progress_percentage": 100,
            "status": "completed"
          },
          {
            "chapter_id": "550e8400-e29b-41d4-a716-446655440101",
            "chapter_title": "Linear Equations",
            "questions_attempted": 15,
            "correct": 13,
            "accuracy": 86.67,
            "progress_percentage": 100,
            "status": "completed"
          },
          {
            "chapter_id": "550e8400-e29b-41d4-a716-446655440102",
            "chapter_title": "Inequalities",
            "questions_attempted": 15,
            "correct": 13,
            "accuracy": 86.67,
            "progress_percentage": 100,
            "status": "completed"
          }
        ]
      },
      {
        "module_id": "550e8400-e29b-41d4-a716-446655440011",
        "module_name": "Geometry",
        "questions_attempted": 35,
        "correct": 30,
        "accuracy": 85.71,
        "progress_percentage": 75,
        "status": "in_progress",
        "chapters": [
          {
            "chapter_id": "550e8400-e29b-41d4-a716-446655440110",
            "chapter_title": "Points, Lines, and Planes",
            "questions_attempted": 12,
            "correct": 11,
            "accuracy": 91.67,
            "progress_percentage": 100,
            "status": "completed"
          },
          {
            "chapter_id": "550e8400-e29b-41d4-a716-446655440111",
            "chapter_title": "Angles",
            "questions_attempted": 12,
            "correct": 10,
            "accuracy": 83.33,
            "progress_percentage": 100,
            "status": "completed"
          },
          {
            "chapter_id": "550e8400-e29b-41d4-a716-446655440112",
            "chapter_title": "Triangles",
            "questions_attempted": 11,
            "correct": 9,
            "accuracy": 81.82,
            "progress_percentage": 60,
            "status": "in_progress"
          }
        ]
      },
      {
        "module_id": "550e8400-e29b-41d4-a716-446655440012",
        "module_name": "Fractions",
        "questions_attempted": 40,
        "correct": 32,
        "accuracy": 80.0,
        "progress_percentage": 100,
        "status": "completed",
        "chapters": []
      }
    ]
  }
}
```

---

### 6. Weak Areas

Identify weak areas for the logged-in student with recommendations.

**Endpoint:** `GET /api/users/analytics/student/weak-areas/`

**Permissions:** Student

**Request:**
```bash
GET /api/users/analytics/student/weak-areas/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Weak areas identified successfully",
  "data": {
    "student_id": "550e8400-e29b-41d4-a716-446655440020",
    "total_weak_areas": 4,
    "weak_areas": [
      {
        "area_type": "subject",
        "area_id": "550e8400-e29b-41d4-a716-446655440006",
        "area_name": "English",
        "total_questions": 50,
        "correct_answers": 25,
        "accuracy": 50.0,
        "severity": "high",
        "recommendation": "Practice more questions in English. Focus on fundamental concepts."
      },
      {
        "area_type": "difficulty",
        "area_id": null,
        "area_name": "Hard Questions",
        "total_questions": 75,
        "correct_answers": 28,
        "accuracy": 37.33,
        "severity": "medium",
        "recommendation": "Work on hard level questions. Your accuracy is below expected."
      },
      {
        "area_type": "hots",
        "area_id": null,
        "area_name": "Higher Order Thinking Skills (HOTS)",
        "total_questions": 30,
        "correct_answers": 12,
        "accuracy": 40.0,
        "severity": "high",
        "recommendation": "Focus on analytical and application-based questions."
      },
      {
        "area_type": "subject",
        "area_id": "550e8400-e29b-41d4-a716-446655440007",
        "area_name": "Social Studies",
        "total_questions": 40,
        "correct_answers": 22,
        "accuracy": 55.0,
        "severity": "medium",
        "recommendation": "Practice more questions in Social Studies. Focus on fundamental concepts."
      }
    ]
  }
}
```

---

### 7. Leaderboard

Get class leaderboard for the logged-in student.

**Endpoint:** `GET /api/users/analytics/student/leaderboard/`

**Permissions:** Student

**Request:**
```bash
GET /api/users/analytics/student/leaderboard/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Leaderboard retrieved successfully",
  "data": {
    "class_id": "550e8400-e29b-41d4-a716-446655440001",
    "class_name": "Class 5A",
    "total_students": 30,
    "my_rank": 3,
    "leaderboard": [
      {
        "rank": 1,
        "student_id": "550e8400-e29b-41d4-a716-446655440025",
        "student_name": "Sarah Williams",
        "username": "sarah_w",
        "profile_picture": "https://example.com/media/profile_pictures/sarah.jpg",
        "total_exp": 1850,
        "level": 9,
        "questions_attempted": 280,
        "accuracy": 92.5,
        "is_me": false
      },
      {
        "rank": 2,
        "student_id": "550e8400-e29b-41d4-a716-446655440021",
        "student_name": "Michael Chen",
        "username": "michael_c",
        "profile_picture": null,
        "total_exp": 1650,
        "level": 8,
        "questions_attempted": 260,
        "accuracy": 89.23,
        "is_me": false
      },
      {
        "rank": 3,
        "student_id": "550e8400-e29b-41d4-a716-446655440020",
        "student_name": "Emma Johnson",
        "username": "emma_j",
        "profile_picture": "https://example.com/media/profile_pictures/emma.jpg",
        "total_exp": 1500,
        "level": 8,
        "questions_attempted": 250,
        "accuracy": 84.0,
        "is_me": true
      },
      {
        "rank": 4,
        "student_id": "550e8400-e29b-41d4-a716-446655440022",
        "student_name": "David Lee",
        "username": "david_l",
        "profile_picture": null,
        "total_exp": 1400,
        "level": 7,
        "questions_attempted": 240,
        "accuracy": 81.67,
        "is_me": false
      }
      // ... up to 50 students
    ]
  }
}
```

---

## Mission Analytics APIs

### 8. Mission Analytics

Get detailed analytics for a specific mission.

**Endpoint:** `GET /api/users/analytics/mission/{mission_id}/`

**Permissions:** Teacher, Admin (creator or assigned teacher)

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `mission_id` | UUID | The mission ID |

**Request:**
```bash
GET /api/users/analytics/mission/550e8400-e29b-41d4-a716-446655440200/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Mission analytics retrieved successfully",
  "data": {
    "mission_id": "550e8400-e29b-41d4-a716-446655440200",
    "mission_title": "Weekly Math Quiz - Algebra",
    "mission_date": "2024-12-05",
    "class_name": "Class 5A",
    "subject_name": "Mathematics",
    "created_by": "Mr. John Smith",
    "summary": {
      "total_students": 30,
      "started": 28,
      "in_progress": 3,
      "completed": 25,
      "not_started": 2,
      "participation_rate": 93.33,
      "completion_rate": 89.29,
      "avg_exp_earned": 42.5,
      "total_questions": 10
    },
    "question_analytics": [
      {
        "question_id": "550e8400-e29b-41d4-a716-446655440300",
        "question_text": "Solve for x: 2x + 5 = 15",
        "order": 1,
        "difficulty": "easy",
        "question_type": "mcq_single",
        "is_hots": false,
        "total_attempts": 28,
        "correct_attempts": 26,
        "accuracy": 92.86,
        "avg_tries": 1.1
      },
      {
        "question_id": "550e8400-e29b-41d4-a716-446655440301",
        "question_text": "If 3y - 7 = 14, what is the value of y?",
        "order": 2,
        "difficulty": "easy",
        "question_type": "mcq_single",
        "is_hots": false,
        "total_attempts": 28,
        "correct_attempts": 25,
        "accuracy": 89.29,
        "avg_tries": 1.2
      },
      {
        "question_id": "550e8400-e29b-41d4-a716-446655440302",
        "question_text": "A rectangle has a perimeter of 36 cm. If the length is 10 cm...",
        "order": 3,
        "difficulty": "medium",
        "question_type": "mcq_single",
        "is_hots": true,
        "total_attempts": 27,
        "correct_attempts": 18,
        "accuracy": 66.67,
        "avg_tries": 1.8
      }
      // ... more questions
    ],
    "student_performance": [
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440020",
        "student_name": "Emma Johnson",
        "username": "emma_j",
        "status": "completed",
        "questions_attempted": 10,
        "correct_answers": 9,
        "accuracy": 90.0,
        "exp_earned": 50,
        "started_at": "2024-12-05T09:00:00Z",
        "completed_at": "2024-12-05T09:15:30Z"
      },
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440021",
        "student_name": "Michael Chen",
        "username": "michael_c",
        "status": "completed",
        "questions_attempted": 10,
        "correct_answers": 8,
        "accuracy": 80.0,
        "exp_earned": 45,
        "started_at": "2024-12-05T09:05:00Z",
        "completed_at": "2024-12-05T09:22:15Z"
      },
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440030",
        "student_name": "Tom Wilson",
        "username": "tom_w",
        "status": "in_progress",
        "questions_attempted": 5,
        "correct_answers": 3,
        "accuracy": 60.0,
        "exp_earned": 20,
        "started_at": "2024-12-05T09:30:00Z",
        "completed_at": null
      }
      // ... more students
    ]
  }
}
```

---

## Competition Analytics APIs

### 9. Competition Analytics

Get detailed analytics for a specific competition.

**Endpoint:** `GET /api/users/analytics/competition/{competition_id}/`

**Permissions:** Teacher, Admin (creator)

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `competition_id` | UUID | The competition ID |

**Request:**
```bash
GET /api/users/analytics/competition/550e8400-e29b-41d4-a716-446655440400/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Competition analytics retrieved successfully",
  "data": {
    "competition_id": "550e8400-e29b-41d4-a716-446655440400",
    "competition_title": "Math Olympiad - Round 1",
    "competition_code": "MATH2024",
    "subject_name": "Mathematics",
    "chapter_name": "Algebra",
    "status": "completed",
    "total_time_minutes": 30,
    "summary": {
      "total_participants": 45,
      "completed": 42,
      "in_progress": 3,
      "avg_score": 78.5,
      "max_score": 100,
      "min_score": 35,
      "avg_time_seconds": 1245,
      "avg_exp_earned": 85.2,
      "total_questions": 20
    },
    "leaderboard": [
      {
        "rank": 1,
        "user_id": "550e8400-e29b-41d4-a716-446655440025",
        "user_name": "Sarah Williams",
        "username": "sarah_w",
        "profile_picture": "https://example.com/media/profile_pictures/sarah.jpg",
        "score": 100,
        "time_taken_seconds": 980,
        "time_taken_formatted": "16m 20s",
        "accuracy": 100.0,
        "exp_earned": 120,
        "status": "completed"
      },
      {
        "rank": 2,
        "user_id": "550e8400-e29b-41d4-a716-446655440020",
        "user_name": "Emma Johnson",
        "username": "emma_j",
        "profile_picture": "https://example.com/media/profile_pictures/emma.jpg",
        "score": 95,
        "time_taken_seconds": 1100,
        "time_taken_formatted": "18m 20s",
        "accuracy": 95.0,
        "exp_earned": 110,
        "status": "completed"
      },
      {
        "rank": 3,
        "user_id": "550e8400-e29b-41d4-a716-446655440021",
        "user_name": "Michael Chen",
        "username": "michael_c",
        "profile_picture": null,
        "score": 90,
        "time_taken_seconds": 1050,
        "time_taken_formatted": "17m 30s",
        "accuracy": 90.0,
        "exp_earned": 100,
        "status": "completed"
      }
      // ... up to 100 participants
    ],
    "question_analytics": [
      {
        "question_id": "550e8400-e29b-41d4-a716-446655440500",
        "question_text": "Simplify: (x² + 2x + 1) / (x + 1)",
        "order": 1,
        "points": 5,
        "difficulty": "easy",
        "total_attempts": 45,
        "correct_attempts": 42,
        "accuracy": 93.33
      },
      {
        "question_id": "550e8400-e29b-41d4-a716-446655440501",
        "question_text": "Find the roots of: x² - 5x + 6 = 0",
        "order": 2,
        "points": 5,
        "difficulty": "easy",
        "total_attempts": 45,
        "correct_attempts": 40,
        "accuracy": 88.89
      },
      {
        "question_id": "550e8400-e29b-41d4-a716-446655440502",
        "question_text": "Solve the system of equations: 2x + y = 10, x - y = 2",
        "order": 3,
        "points": 5,
        "difficulty": "medium",
        "total_attempts": 44,
        "correct_attempts": 32,
        "accuracy": 72.73
      }
      // ... more questions
    ]
  }
}
```

---

## Admin Analytics APIs

### 10. School Overview

Get school-wide analytics overview.

**Endpoint:** `GET /api/users/analytics/admin/school-overview/`

**Permissions:** Admin, Principal

**Request:**
```bash
GET /api/users/analytics/admin/school-overview/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "School overview retrieved successfully",
  "data": {
    "school_id": "550e8400-e29b-41d4-a716-446655440600",
    "school_name": "ABC International School",
    "counts": {
      "total_students": 500,
      "total_teachers": 35,
      "total_classes": 20,
      "total_grades": 5,
      "total_subjects": 8
    },
    "student_stats": {
      "avg_exp": 850.5,
      "avg_level": 5.2
    },
    "activity_stats": {
      "total_questions_attempted": 45000,
      "correct_answers": 32500,
      "overall_accuracy": 72.22,
      "modules_completed": 1250
    },
    "active_items": {
      "active_missions": 12,
      "active_competitions": 3
    },
    "grade_breakdown": [
      {
        "grade_id": "550e8400-e29b-41d4-a716-446655440700",
        "grade_name": "Grade 5",
        "student_count": 120,
        "class_count": 4,
        "avg_exp": 920.3
      },
      {
        "grade_id": "550e8400-e29b-41d4-a716-446655440701",
        "grade_name": "Grade 6",
        "student_count": 110,
        "class_count": 4,
        "avg_exp": 1050.8
      },
      {
        "grade_id": "550e8400-e29b-41d4-a716-446655440702",
        "grade_name": "Grade 7",
        "student_count": 100,
        "class_count": 4,
        "avg_exp": 1180.2
      },
      {
        "grade_id": "550e8400-e29b-41d4-a716-446655440703",
        "grade_name": "Grade 8",
        "student_count": 90,
        "class_count": 4,
        "avg_exp": 1320.5
      },
      {
        "grade_id": "550e8400-e29b-41d4-a716-446655440704",
        "grade_name": "Grade 9",
        "student_count": 80,
        "class_count": 4,
        "avg_exp": 1450.0
      }
    ]
  }
}
```

---

### 11. Grade Analytics

Get detailed analytics for a specific grade.

**Endpoint:** `GET /api/users/analytics/admin/grade/{grade_id}/`

**Permissions:** Admin, Principal

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `grade_id` | UUID | The grade ID |

**Request:**
```bash
GET /api/users/analytics/admin/grade/550e8400-e29b-41d4-a716-446655440700/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Grade analytics retrieved successfully",
  "data": {
    "grade_id": "550e8400-e29b-41d4-a716-446655440700",
    "grade_name": "Grade 5",
    "overall_stats": {
      "total_classes": 4,
      "total_students": 120,
      "total_questions_attempted": 12000,
      "correct_answers": 8760,
      "overall_accuracy": 73.0
    },
    "class_performance": [
      {
        "class_id": "550e8400-e29b-41d4-a716-446655440001",
        "class_name": "Class 5A",
        "student_count": 30,
        "questions_attempted": 3200,
        "correct_answers": 2500,
        "accuracy": 78.13,
        "avg_exp": 1020.5,
        "avg_level": 5.8,
        "top_performer": {
          "name": "Sarah Williams",
          "exp": 1850
        },
        "class_teacher": "Mr. John Smith"
      },
      {
        "class_id": "550e8400-e29b-41d4-a716-446655440003",
        "class_name": "Class 5B",
        "student_count": 30,
        "questions_attempted": 3000,
        "correct_answers": 2280,
        "accuracy": 76.0,
        "avg_exp": 950.2,
        "avg_level": 5.5,
        "top_performer": {
          "name": "Alex Turner",
          "exp": 1720
        },
        "class_teacher": "Mrs. Jane Doe"
      },
      {
        "class_id": "550e8400-e29b-41d4-a716-446655440004",
        "class_name": "Class 5C",
        "student_count": 30,
        "questions_attempted": 2900,
        "correct_answers": 2030,
        "accuracy": 70.0,
        "avg_exp": 880.0,
        "avg_level": 5.2,
        "top_performer": {
          "name": "Lisa Chen",
          "exp": 1550
        },
        "class_teacher": "Mr. Robert Brown"
      },
      {
        "class_id": "550e8400-e29b-41d4-a716-446655440005",
        "class_name": "Class 5D",
        "student_count": 30,
        "questions_attempted": 2900,
        "correct_answers": 1950,
        "accuracy": 67.24,
        "avg_exp": 820.8,
        "avg_level": 4.9,
        "top_performer": {
          "name": "James Wilson",
          "exp": 1480
        },
        "class_teacher": "Mrs. Emily Davis"
      }
    ]
  }
}
```

---

### 12. Class Analytics

Get detailed analytics for a specific class (admin view).

**Endpoint:** `GET /api/users/analytics/admin/class/{class_id}/`

**Permissions:** Admin, Principal

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `class_id` | UUID | The class ID |

**Request:**
```bash
GET /api/users/analytics/admin/class/550e8400-e29b-41d4-a716-446655440001/
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Class analytics retrieved successfully",
  "data": {
    "class_id": "550e8400-e29b-41d4-a716-446655440001",
    "class_name": "Class 5A",
    "grade_name": "Grade 5",
    "class_teacher": "Mr. John Smith",
    "overall_stats": {
      "total_students": 30,
      "total_questions_attempted": 3200,
      "correct_answers": 2500,
      "accuracy": 78.13,
      "avg_exp": 1020.5
    },
    "subject_performance": [
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440002",
        "subject_name": "Mathematics",
        "questions_attempted": 1000,
        "correct": 820,
        "accuracy": 82.0,
        "teacher": "Mr. John Smith"
      },
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440005",
        "subject_name": "Science",
        "questions_attempted": 800,
        "correct": 640,
        "accuracy": 80.0,
        "teacher": "Mrs. Sarah Green"
      },
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440006",
        "subject_name": "English",
        "questions_attempted": 700,
        "correct": 525,
        "accuracy": 75.0,
        "teacher": "Mr. David White"
      },
      {
        "subject_id": "550e8400-e29b-41d4-a716-446655440007",
        "subject_name": "Social Studies",
        "questions_attempted": 700,
        "correct": 515,
        "accuracy": 73.57,
        "teacher": "Mrs. Jennifer Black"
      }
    ],
    "student_rankings": [
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440025",
        "student_name": "Sarah Williams",
        "roll_number": 25,
        "total_exp": 1850,
        "level": 9,
        "questions_attempted": 280,
        "correct": 259,
        "accuracy": 92.5
      },
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440021",
        "student_name": "Michael Chen",
        "roll_number": 8,
        "total_exp": 1650,
        "level": 8,
        "questions_attempted": 260,
        "correct": 232,
        "accuracy": 89.23
      },
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440020",
        "student_name": "Emma Johnson",
        "roll_number": 1,
        "total_exp": 1500,
        "level": 8,
        "questions_attempted": 250,
        "correct": 210,
        "accuracy": 84.0
      }
      // ... all 30 students
    ]
  }
}
```

---

## General Analytics APIs

### 13. Answer Trends

Get answer trends over time for the current user or a specific student.

**Endpoint:** `GET /api/users/analytics/answer-trends/`

**Permissions:** Authenticated users (teachers can query students)

**Query Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `days` | Integer | No | 30 | Number of days to analyze |
| `student_id` | UUID | No | - | Student ID (for teachers/admins) |

**Request:**
```bash
GET /api/users/analytics/answer-trends/?days=30
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "success",
  "status_code": 200,
  "message": "Answer trends retrieved successfully",
  "data": {
    "start_date": "2024-11-06",
    "end_date": "2024-12-06",
    "total_days": 30,
    "trends": [
      {
        "date": "2024-11-06",
        "total_answers": 15,
        "correct_answers": 12,
        "accuracy": 80.0,
        "exp_earned": 120
      },
      {
        "date": "2024-11-07",
        "total_answers": 20,
        "correct_answers": 18,
        "accuracy": 90.0,
        "exp_earned": 180
      },
      {
        "date": "2024-11-08",
        "total_answers": 12,
        "correct_answers": 9,
        "accuracy": 75.0,
        "exp_earned": 90
      },
      {
        "date": "2024-11-11",
        "total_answers": 25,
        "correct_answers": 22,
        "accuracy": 88.0,
        "exp_earned": 220
      }
      // ... more dates (only dates with activity are included)
    ]
  }
}
```

**Request (Teacher querying student):**
```bash
GET /api/users/analytics/answer-trends/?days=14&student_id=550e8400-e29b-41d4-a716-446655440020
Authorization: Bearer <token>
```

---

## Error Handling

### Common Error Responses

#### 401 Unauthorized
```json
{
  "status": "error",
  "status_code": 401,
  "message": "Authentication credentials were not provided.",
  "data": null
}
```

#### 403 Forbidden
```json
{
  "status": "error",
  "status_code": 403,
  "message": "Only teachers can access this endpoint",
  "data": {
    "error": "Only teachers can access this endpoint"
  }
}
```

#### 404 Not Found
```json
{
  "status": "error",
  "status_code": 404,
  "message": "Not found",
  "data": {
    "error": "Student not found"
  }
}
```

#### 400 Validation Error
```json
{
  "status": "error",
  "status_code": 400,
  "message": "Validation error",
  "data": {
    "error": "Student profile not found"
  }
}
```

#### 500 Internal Server Error
```json
{
  "status": "error",
  "status_code": 500,
  "message": "Internal server error",
  "data": {
    "error": "Failed to retrieve analytics: <error details>"
  }
}
```

---

## Rate Limiting

Analytics endpoints may be subject to rate limiting to prevent abuse:

- **Standard users:** 100 requests per minute
- **Premium users:** 500 requests per minute

If rate limited, you'll receive:
```json
{
  "status": "error",
  "status_code": 429,
  "message": "Too many requests",
  "data": {
    "retry_after": 60
  }
}
```

---

## Best Practices

### 1. Caching
Analytics data can be cached on the client side for better performance:
- **Student progress:** Cache for 5 minutes
- **Leaderboards:** Cache for 1 minute
- **School overview:** Cache for 10 minutes

### 2. Pagination
For endpoints returning large datasets (like leaderboards), results are limited:
- **Leaderboard:** Maximum 50 entries
- **Student performance:** All students in class
- **Competition participants:** Maximum 100 entries

### 3. Efficient Querying
- Use specific endpoints rather than broad ones
- Include `student_id` parameter when available
- Limit `days` parameter for trend analysis

---

## Changelog

### Version 1.0 (December 6, 2024)
- Initial release
- 13 analytics endpoints
- Teacher, Student, and Admin analytics
- Mission and Competition analytics
- Answer trend analysis

---

*Documentation for Gyaan Buddy Analytics API - Educational Platform*

