# Gyaan Buddy - Database Schema & Analytics Documentation

> **Version:** 1.0  
> **Last Updated:** December 6, 2024  
> **Author:** Development Team

---

## Table of Contents

1. [Overview](#overview)
2. [Database Schema](#database-schema)
   - [Entity Relationship Diagram](#entity-relationship-diagram)
   - [Core Models](#core-models)
   - [Relationships](#relationships)
3. [Data Flow Diagrams](#data-flow-diagrams)
   - [Student Learning Journey](#student-learning-journey)
   - [Teacher Analytics Flow](#teacher-analytics-flow)
4. [Analytics Capabilities](#analytics-capabilities)
   - [Teacher Analytics](#teacher-analytics)
   - [Student Analytics](#student-analytics)
   - [Admin Analytics](#admin-analytics)
5. [Detailed Analytics Specifications](#detailed-analytics-specifications)
   - [Answer Analysis](#answer-analysis)
   - [Mission Analysis](#mission-analysis)
   - [Competition Analysis](#competition-analysis)
   - [Progress Tracking](#progress-tracking)
6. [API Endpoints](#api-endpoints)
7. [Implementation Examples](#implementation-examples)

---

## Overview

Gyaan Buddy is an educational platform designed to facilitate learning through gamification. The system supports:

- **Schools** with multiple classes and grades
- **Classes** that can have multiple subjects (Many-to-Many relationship)
- **Teachers** who manage classes and subjects
- **Students** who learn through modules, chapters, and questions
- **Missions & Competitions** for engaging learning experiences
- **Progress Tracking** with experience points and levels

---

## Database Schema

### Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                         GYAAN BUDDY DATABASE SCHEMA                                              │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

                                    ┌──────────────────┐
                                    │      SCHOOL      │
                                    ├──────────────────┤
                                    │ id (UUID)        │
                                    │ name             │
                                    │ address          │
                                    │ phone            │
                                    │ email            │
                                    │ website          │
                                    │ is_active        │
                                    └────────┬─────────┘
                                             │
          ┌──────────────────────────────────┼──────────────────────────────────┐
          │                                  │                                  │
          ▼                                  ▼                                  ▼
┌─────────────────┐                ┌─────────────────┐                ┌─────────────────┐
│     GRADE       │                │  USER_PROFILE   │                │      CLASS      │
├─────────────────┤                ├─────────────────┤                ├─────────────────┤
│ id (UUID)       │                │ id (UUID)       │                │ id (UUID)       │
│ name            │◄──────────────►│ school_id (FK)  │◄──────────────►│ school_id (FK)  │
│ school_id (FK)  │                │ account_id (FK) │                │ grade_id (FK)   │
│ description     │                │ user_type       │                │ class_teacher   │
│ is_active       │                │ phone_number    │                │ name            │
└─────────────────┘                │ date_of_birth   │                │ description     │
        │                          │ gender          │                │ is_active       │
        │                          │ profile_picture │                │ subjects (M2M)  │
        │                          │ bio             │                └────────┬────────┘
        │                          └────────┬────────┘                         │
        │                                   │                                  │
        │                    ┌──────────────┴──────────────┐                   │
        │                    │                             │                   │
        │                    ▼                             ▼                   │
        │          ┌─────────────────┐           ┌─────────────────┐           │
        │          │    STUDENT      │           │ TEACHER_PROFILE │           │
        │          ├─────────────────┤           ├─────────────────┤           │
        │          │ user_profile_id │           │ user_profile_id │           │
        │          │ admission_number│           │ employee_id     │           │
        │          │ roll_number     │           │ is_class_teacher│           │
        │          │ class_instance  │───────────│                 │           │
        │          │ parent_name     │           └────────┬────────┘           │
        │          │ total_exp       │                    │                    │
        │          │ rewards         │                    │                    │
        │          │ level_id (FK)   │                    ▼                    │
        │          └────────┬────────┘           ┌─────────────────┐           │
        │                   │                    │    TEACHER      │◄──────────┘
        │                   │                    │  (Assignment)   │
        │                   │                    ├─────────────────┤
        │                   │                    │ teacher_id (FK) │
        │                   │                    │ class_id (FK)   │
        │                   │                    │ subject_id (FK) │
        │                   │                    └─────────────────┘
        │                   │                             │
        │                   │                             ▼
        │                   │                    ┌─────────────────┐
        │                   │                    │    SUBJECT      │
        │                   │                    ├─────────────────┤
        │                   │                    │ id (UUID)       │
        │                   │                    │ name            │
        │                   │                    │ code            │
        │                   │                    │ description     │
        │                   │                    │ logo            │
        │                   │                    │ color           │
        │                   │                    │ order           │
        │                   │                    └────────┬────────┘
        │                   │                             │
        │                   │                             ▼
        │                   │                    ┌─────────────────┐
        │                   │                    │     MODULE      │
        │                   │                    ├─────────────────┤
        │                   │                    │ id (UUID)       │
        │                   │                    │ name            │
        │                   │                    │ subject_id (FK) │
        │                   │                    │ description     │
        │                   │                    │ order           │
        │                   │                    │ is_enabled      │
        │                   │                    └────────┬────────┘
        │                   │                             │
        │                   ▼                             ▼
        │          ┌─────────────────┐           ┌─────────────────┐
        │          │     LEVEL       │           │ MODULE_CHAPTER  │
        │          ├─────────────────┤           ├─────────────────┤
        │          │ id              │           │ id (UUID)       │
        │          │ name (int)      │           │ module_id (FK)  │
        │          │ min_exp         │           │ title           │
        │          │ max_exp         │           │ description     │
        │          └─────────────────┘           │ order           │
        │                                        │ is_enabled      │
        │                                        │ is_important    │
        │                                        │ has_hots        │
        │                                        └────────┬────────┘
        │                                                 │
        │                             ┌───────────────────┼───────────────────┐
        │                             │                   │                   │
        │                             ▼                   ▼                   ▼
        │                    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
        │                    │ MODULE_CONTENT  │ │  CHAPTER_HOTS   │ │    THEORY       │
        │                    ├─────────────────┤ ├─────────────────┤ ├─────────────────┤
        │                    │ chapter_id (FK) │ │ chapter_id (FK) │ │ id (UUID)       │
        │                    │ content_type    │ │ question_id (FK)│ │ title           │
        │                    │ order           │ │ order           │ │ description     │
        │                    │ question_id     │ └─────────────────┘ └─────────────────┘
        │                    │ theory_id       │
        │                    └────────┬────────┘
        │                             │
        │                             ▼
        │                    ┌─────────────────┐
        │                    │    QUESTION     │
        │                    ├─────────────────┤
        │                    │ id (UUID)       │
        │                    │ question_text   │
        │                    │ image           │
        │                    │ question_type   │
        │                    │ exp_points      │
        │                    │ difficulty_level│
        │                    │ explanation     │
        │                    │ is_hots         │
        │                    └────────┬────────┘
        │                             │
        │                             ▼
        │                    ┌─────────────────┐
        │                    │     OPTION      │
        │                    ├─────────────────┤
        │                    │ id (UUID)       │
        │                    │ question_id (FK)│
        │                    │ option_text     │
        │                    │ is_correct      │
        │                    │ order           │
        │                    └─────────────────┘
```

### Core Models

#### 1. User Management Models

| Model | Table Name | Description | Key Fields |
|-------|------------|-------------|------------|
| **School** | `schools` | Educational institution | `name`, `address`, `phone`, `email`, `is_active` |
| **Account** | `accounts` | Base user authentication (extends AbstractUser) | `first_name`, `fcm_token`, `logged_in_once` |
| **UserProfile** | `user_profiles` | Extended user information | `user_type`, `school_id`, `phone_number`, `gender`, `bio` |
| **Student** | `students` | Student-specific data | `admission_number`, `roll_number`, `class_instance`, `total_exp`, `level` |
| **TeacherProfile** | `teacher_profiles` | Teacher-specific data | `employee_id`, `is_class_teacher` |
| **Level** | `levels` | Gamification levels | `name`, `min_exp`, `max_exp` |

#### 2. Academic Structure Models

| Model | Table Name | Description | Key Fields |
|-------|------------|-------------|------------|
| **Grade** | `grades` | Academic grades | `name`, `school_id`, `is_active` |
| **Class** | `classes` | Class sections | `name`, `school_id`, `grade_id`, `class_teacher`, `subjects` (M2M) |
| **Teacher** | `teachers` | Teacher assignments (junction table) | `teacher_id`, `class_instance_id`, `subject_id` |

#### 3. Subject & Content Models

| Model | Table Name | Description | Key Fields |
|-------|------------|-------------|------------|
| **Subject** | `subjects` | Academic subjects | `name`, `code`, `color`, `order` |
| **Module** | `modules` | Subject modules | `name`, `subject_id`, `order`, `is_enabled` |
| **ModuleChapter** | `module_chapters` | Chapters within modules | `module_id`, `title`, `order`, `has_hots` |
| **ModuleContent** | `module_contents` | Content items (questions/theories) | `chapter_id`, `content_type`, `question_id`, `theory_id` |
| **Theory** | `theories` | Theoretical content | `title`, `description` |
| **Question** | `questions` | Quiz questions | `question_text`, `question_type`, `difficulty_level`, `exp_points`, `is_hots` |
| **Option** | `options` | Question options | `question_id`, `option_text`, `is_correct` |
| **ChapterHOTS** | `chapter_hots` | HOTS questions for chapters | `chapter_id`, `question_id`, `order` |

#### 4. Answer & Progress Models

| Model | Table Name | Description | Key Fields |
|-------|------------|-------------|------------|
| **Answer** | `answers` | User answers to questions | `user_id`, `question_id`, `is_correct`, `tries`, `prev_exp`, `current_exp` |
| **ManualVerificationAnswer** | `manual_verification_answers` | Answers needing manual review | `user_id`, `question_id`, `answer` |
| **UserModuleProgress** | `user_module_progress` | Module progress tracking | `account_id`, `module_id`, `status`, `percentage`, `started_at`, `completed_at` |
| **UserChapterProgress** | `user_chapter_progress` | Chapter progress tracking | `account_id`, `chapter_id`, `status`, `percentage` |

#### 5. Mission & Competition Models

| Model | Table Name | Description | Key Fields |
|-------|------------|-------------|------------|
| **Mission** | `missions` | Assigned learning missions | `title`, `mission_date`, `class_group`, `subject_id`, `exp_multiplier` |
| **MissionQuestion** | `mission_questions` | Questions in missions | `mission_id`, `question_id`, `order` |
| **UserMissionProgress** | `user_mission_progress` | Mission progress tracking | `account_id`, `mission_id`, `status`, `exp_earned` |
| **Competition** | `competitions` | Competitive quizzes | `title`, `code`, `subject_id`, `total_time`, `status` |
| **CompetitionQuestion** | `competition_questions` | Questions in competitions | `competition_id`, `question_id`, `points` |
| **UserCompetitionProgress** | `user_competition_progress` | Competition progress | `account_id`, `competition_id`, `score`, `time_taken`, `exp_earned` |

#### 6. Notification Model

| Model | Table Name | Description | Key Fields |
|-------|------------|-------------|------------|
| **Notification** | `notifications` | User notifications | `user_id`, `type`, `data` (JSON), `is_read` |

### Relationships

#### One-to-One Relationships
```
Account ←→ UserProfile
UserProfile ←→ Student
UserProfile ←→ TeacherProfile
```

#### One-to-Many Relationships
```
School → UserProfile (one school has many profiles)
School → Class (one school has many classes)
School → Grade (one school has many grades)
Grade → Class (one grade has many classes)
Class → Student (one class has many students)
Subject → Module (one subject has many modules)
Module → ModuleChapter (one module has many chapters)
ModuleChapter → ModuleContent (one chapter has many content items)
Question → Option (one question has many options)
Question → Answer (one question has many answers)
Mission → MissionQuestion (one mission has many questions)
Competition → CompetitionQuestion (one competition has many questions)
```

#### Many-to-Many Relationships
```
Class ↔ Subject (through classes_subjects)
  → One Class can have multiple Subjects
  → One Subject can be taught in multiple Classes
Teacher ↔ (Class, Subject) (Teacher assignment junction table)
Mission ↔ Question (through MissionQuestion)
Competition ↔ Question (through CompetitionQuestion)
Competition ↔ Account (through UserCompetitionProgress)
```

**Class-Subject Relationship Details:**
- A single class can be associated with multiple subjects (e.g., Class 5A studies Math, Science, English)
- A single subject can be associated with multiple classes (e.g., Mathematics is taught in Class 5A, 5B, 6A)
- The relationship is defined on the `Class` model with `subjects = ManyToManyField('subjects.Subject')`
- This is managed through the `classes_subjects` junction table
- Access patterns:
  - Get all subjects for a class: `class_instance.subjects.all()`
  - Get all classes for a subject: `subject.classes.all()`

---

## Data Flow Diagrams

### Student Learning Journey

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                STUDENT LEARNING JOURNEY FLOW                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

                                    ┌─────────────┐
                                    │   STUDENT   │
                                    │   LOGIN     │
                                    └──────┬──────┘
                                           │
                                           ▼
                              ┌────────────────────────┐
                              │ Get Enrolled Class     │
                              │ (Student.class_instance)│
                              └────────────┬───────────┘
                                           │
                                           ▼
                              ┌────────────────────────┐
                              │ Get Available Subjects │
                              │ (Class.subjects M2M)   │
                              └────────────┬───────────┘
                                           │
            ┌──────────────────────────────┼──────────────────────────────┐
            │                              │                              │
            ▼                              ▼                              ▼
   ┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
   │ Subject A       │          │ Subject B       │          │ Subject C       │
   │ (e.g., Math)    │          │ (e.g., Science) │          │ (e.g., English) │
   └────────┬────────┘          └────────┬────────┘          └────────┬────────┘
            │                            │                            │
            ▼                            ▼                            ▼
   ┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
   │ Get Modules     │          │ Get Modules     │          │ Get Modules     │
   │ (Subject.modules)│          │ (Subject.modules)│          │ (Subject.modules)│
   └────────┬────────┘          └─────────────────┘          └─────────────────┘
            │
            ▼
   ┌─────────────────┐
   │ Get Chapters    │
   │(Module.chapters)│
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐      Track: UserChapterProgress
   │ Get Content     │◄──────────────────────────────┐
   │(Chapter.contents)                               │
   └────────┬────────┘                               │
            │                                        │
     ┌──────┴──────┐                                 │
     │             │                                 │
     ▼             ▼                                 │
┌─────────┐  ┌─────────┐                             │
│ Theory  │  │Question │                             │
└─────────┘  └────┬────┘                             │
                  │                                  │
                  ▼                                  │
         ┌─────────────────┐                         │
         │ Submit Answer   │                         │
         └────────┬────────┘                         │
                  │                                  │
                  ▼                                  │
         ┌─────────────────┐                         │
         │ Create Answer   │                         │
         │ Record          │                         │
         └────────┬────────┘                         │
                  │                                  │
       ┌──────────┴──────────┐                       │
       │                     │                       │
       ▼                     ▼                       │
┌─────────────┐      ┌─────────────┐                 │
│  CORRECT    │      │  INCORRECT  │                 │
└──────┬──────┘      └──────┬──────┘                 │
       │                    │                        │
       ▼                    ▼                        │
┌─────────────┐      ┌─────────────┐                 │
│ Add EXP     │      │ Track tries │                 │
│ Update Level│      └─────────────┘                 │
└──────┬──────┘                                      │
       │                                             │
       └─────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Update Progress │
                    │ (Percentage,    │
                    │  Status, etc.)  │
                    └─────────────────┘
```

### Teacher Analytics Flow

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              TEACHER ANALYTICS DATA FLOW                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

                                    ┌─────────────┐
                                    │   TEACHER   │
                                    │   LOGIN     │
                                    └──────┬──────┘
                                           │
                                           ▼
                              ┌────────────────────────┐
                              │ Get Teacher Assignments│
                              │ (Teacher model)        │
                              └────────────┬───────────┘
                                           │
                                           ▼
                      ┌────────────────────────────────────────┐
                      │     FOR EACH (Class + Subject)         │
                      └────────────────────┬───────────────────┘
                                           │
        ┌──────────────────────────────────┼──────────────────────────────────┐
        │                                  │                                  │
        ▼                                  ▼                                  ▼
┌─────────────────┐              ┌─────────────────┐              ┌─────────────────┐
│ Get Students    │              │ Get Subject     │              │ Get Missions    │
│ in Class        │              │ Modules         │              │ for Class       │
│ (enrolled_      │              │ & Chapters      │              │ & Subject       │
│  students)      │              │                 │              │                 │
└────────┬────────┘              └────────┬────────┘              └────────┬────────┘
         │                                │                                │
         ▼                                ▼                                ▼
┌─────────────────┐              ┌─────────────────┐              ┌─────────────────┐
│ For Each Student│              │ Get Questions   │              │ Get Mission     │
│                 │              │ in Subject      │              │ Progress        │
└────────┬────────┘              └─────────────────┘              └─────────────────┘
         │
         │
    ┌────┴────────────────────────────────────────────────────┐
    │                                                          │
    ▼                                                          ▼
┌─────────────────┐                                  ┌─────────────────┐
│ Get Student's   │                                  │ Get Student's   │
│ Answers         │                                  │ Progress        │
│ (Answer model)  │                                  │ (UserModule/    │
│                 │                                  │  ChapterProgress)│
└────────┬────────┘                                  └────────┬────────┘
         │                                                    │
         │                                                    │
    ┌────┴────────────────────────────────────────────────────┴────┐
    │                              │                               │
    ▼                              ▼                               ▼
┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────────────┐
│ ACCURACY        │    │ COMPLETION          │    │ TIME/ENGAGEMENT         │
│ ANALYTICS       │    │ ANALYTICS           │    │ ANALYTICS               │
├─────────────────┤    ├─────────────────────┤    ├─────────────────────────┤
│ • Correct/Wrong │    │ • Module %          │    │ • started_at            │
│ • tries count   │    │ • Chapter %         │    │ • completed_at          │
│ • difficulty    │    │ • Status            │    │ • last_accessed         │
│   performance   │    │   (not_started,     │    │ • Time per question     │
│ • HOTS score    │    │    in_progress,     │    │ • Session duration      │
│                 │    │    completed)       │    │                         │
└─────────────────┘    └─────────────────────┘    └─────────────────────────┘
```

---

## Analytics Capabilities

### Teacher Analytics

#### 1. Subject-wise Student Performance

**Data Sources:**
- `Teacher` (assignments)
- `Student` (enrolled students)
- `Answer` (student responses)
- `UserModuleProgress` / `UserChapterProgress` (progress tracking)

**Available Metrics:**

| Metric | Source | Formula |
|--------|--------|---------|
| Accuracy Rate | `Answer.is_correct` | `SUM(is_correct) / COUNT(*)` |
| Average Attempts | `Answer.tries` | `AVG(tries)` |
| Questions Completed | `Answer` | `COUNT(DISTINCT question_id)` |
| Module Completion % | `UserModuleProgress.percentage` | Direct field |
| Chapter Completion % | `UserChapterProgress.percentage` | Direct field |
| Total EXP | `Student.total_exp` | Direct field |
| Current Level | `Student.level` | FK to Level |
| Difficulty Performance | `Answer + Question.difficulty_level` | Group by difficulty |
| HOTS Performance | `Answer + Question.is_hots` | Filter `is_hots=True` |

**Sample Query:**
```sql
SELECT 
    st.id as student_id,
    up.account_id,
    acc.username as student_name,
    subj.name as subject_name,
    c.name as class_name,
    
    -- Answer Analytics
    COUNT(a.id) as total_questions_attempted,
    SUM(CASE WHEN a.is_correct THEN 1 ELSE 0 END) as correct_answers,
    ROUND(AVG(CASE WHEN a.is_correct THEN 100 ELSE 0 END), 2) as accuracy_percentage,
    ROUND(AVG(a.tries), 2) as avg_attempts_per_question,
    
    -- EXP Analytics
    st.total_exp as total_experience,
    l.name as current_level

FROM students st
JOIN user_profiles up ON st.user_profile_id = up.id
JOIN accounts acc ON up.account_id = acc.id
JOIN classes c ON st.class_instance_id = c.id
JOIN teachers ta ON ta.class_instance_id = c.id
JOIN subjects subj ON ta.subject_id = subj.id
LEFT JOIN answers a ON a.user_id = up.account_id
LEFT JOIN questions q ON a.question_id = q.id
LEFT JOIN module_contents mc ON q.id = mc.question_id
LEFT JOIN module_chapters ch ON mc.chapter_id = ch.id
LEFT JOIN modules m ON ch.module_id = m.id AND m.subject_id = subj.id
LEFT JOIN levels l ON st.level_id = l.id
WHERE ta.teacher_id = :teacher_profile_id
  AND st.is_deleted = FALSE
GROUP BY st.id, up.account_id, acc.username, subj.name, c.name, st.total_exp, l.name
ORDER BY accuracy_percentage DESC;
```

#### 2. Class Performance Overview

```sql
SELECT 
    c.id as class_id,
    c.name as class_name,
    COUNT(DISTINCT st.id) as total_students,
    ROUND(AVG(st.total_exp), 2) as avg_exp,
    ROUND(AVG(CASE WHEN a.is_correct THEN 100 ELSE 0 END), 2) as avg_accuracy,
    COUNT(DISTINCT CASE WHEN ump.status = 'completed' THEN ump.module_id END) as modules_completed,
    COUNT(DISTINCT CASE WHEN ump.status = 'in_progress' THEN ump.module_id END) as modules_in_progress

FROM classes c
JOIN students st ON st.class_instance_id = c.id
JOIN user_profiles up ON st.user_profile_id = up.id
LEFT JOIN answers a ON a.user_id = up.account_id
LEFT JOIN user_module_progress ump ON ump.account_id = up.account_id
WHERE c.id IN (SELECT class_instance_id FROM teachers WHERE teacher_id = :teacher_profile_id)
  AND st.is_deleted = FALSE
GROUP BY c.id, c.name;
```

### Student Analytics

#### 1. Personal Performance Dashboard

**Available Metrics:**
- Overall accuracy rate
- Subject-wise performance breakdown
- Module/Chapter completion progress
- EXP progression over time
- Level advancement history
- Weak areas identification
- Comparison with class average

#### 2. Subject-wise Performance

```python
# Django ORM Example
from django.db.models import Count, Avg, Sum, Case, When, F, Q

def get_student_subject_performance(student_id):
    return Answer.objects.filter(
        user__profile__student__id=student_id
    ).select_related(
        'question__module_contents__chapter__module__subject'
    ).values(
        subject_name=F('question__module_contents__chapter__module__subject__name')
    ).annotate(
        total_questions=Count('id'),
        correct_answers=Sum(Case(When(is_correct=True, then=1), default=0)),
        accuracy=Avg(Case(When(is_correct=True, then=100), default=0)),
        avg_attempts=Avg('tries'),
        total_exp_earned=Sum(F('current_Exp') - F('prev_exp'))
    ).order_by('-accuracy')
```

### Admin Analytics

#### 1. School-wide Overview
- Total active students, teachers, classes
- Subject distribution
- Overall platform engagement
- Top performing classes/students

#### 2. Grade-wise Analytics
```sql
SELECT 
    g.name as grade_name,
    COUNT(DISTINCT c.id) as total_classes,
    COUNT(DISTINCT st.id) as total_students,
    ROUND(AVG(st.total_exp), 2) as avg_exp,
    ROUND(AVG(l.name), 1) as avg_level

FROM grades g
JOIN classes c ON c.grade_id = g.id
JOIN students st ON st.class_instance_id = c.id
JOIN levels l ON st.level_id = l.id
WHERE g.school_id = :school_id
  AND g.is_active = TRUE
  AND st.is_deleted = FALSE
GROUP BY g.id, g.name
ORDER BY g.name;
```

---

## Detailed Analytics Specifications

### Answer Analysis

#### Data Model: `Answer`

| Field | Type | Analytics Use |
|-------|------|---------------|
| `user_id` | FK | Student identification |
| `question_id` | FK | Question tracking |
| `is_correct` | Boolean | Accuracy calculation |
| `answer` | Text | Response content |
| `tries` | Integer | Attempt tracking |
| `prev_exp` | Integer | EXP before answer |
| `current_Exp` | Integer | EXP after answer |
| `created_at` | DateTime | Timeline analysis |

#### Derived Analytics

1. **Question Difficulty Analysis**
   ```
   ┌────────────────┬───────────────┬───────────────┬───────────────┐
   │ Difficulty     │ Attempted     │ Correct %     │ Avg Tries     │
   ├────────────────┼───────────────┼───────────────┼───────────────┤
   │ Easy           │     150       │     92%       │     1.1       │
   │ Medium         │     120       │     75%       │     1.8       │
   │ Hard           │      80       │     58%       │     2.5       │
   └────────────────┴───────────────┴───────────────┴───────────────┘
   ```

2. **Question Type Performance**
   ```
   ┌─────────────────┬───────────────┬───────────────┐
   │ Type            │ Correct %     │ Avg Attempts  │
   ├─────────────────┼───────────────┼───────────────┤
   │ MCQ Single      │     85%       │     1.2       │
   │ MCQ Multiple    │     68%       │     1.9       │
   │ Short Answer    │     72%       │     1.5       │
   └─────────────────┴───────────────┴───────────────┘
   ```

3. **HOTS Analysis**
   - Total HOTS questions attempted
   - HOTS accuracy vs regular questions
   - HOTS improvement over time

### Mission Analysis

#### Data Model: `Mission` + `UserMissionProgress`

**Key Metrics:**

| Metric | Calculation |
|--------|-------------|
| Participation Rate | `COUNT(started) / Total Students * 100` |
| Completion Rate | `COUNT(completed) / COUNT(started) * 100` |
| Average Time | `AVG(completed_at - started_at)` |
| Average EXP | `AVG(exp_earned)` |
| Question Success Rate | Per-question accuracy within mission |

**Sample Dashboard:**
```
┌─────────────────┬───────────┬───────────────┬───────────────┬───────────────┬─────────────┐
│ Mission Title   │ Class     │ Subject       │ Completion %  │ Avg Score     │ Status      │
├─────────────────┼───────────┼───────────────┼───────────────┼───────────────┼─────────────┤
│ Math Quiz 1     │ Class 5A  │ Mathematics   │     85%       │     78%       │ Completed   │
│ Science Test    │ Class 5A  │ Science       │     72%       │     65%       │ In Progress │
│ Weekly Review   │ Class 5B  │ Mathematics   │     45%       │     70%       │ In Progress │
└─────────────────┴───────────┴───────────────┴───────────────┴───────────────┴─────────────┘
```

### Competition Analysis

#### Data Model: `Competition` + `UserCompetitionProgress`

**Leaderboard Data:**
```
┌──────┬──────────────────┬───────────────┬───────────────┬─────────────┬───────────────────┐
│ Rank │ Student          │ Score         │ Time Taken    │ Accuracy    │ EXP Earned        │
├──────┼──────────────────┼───────────────┼───────────────┼─────────────┼───────────────────┤
│  1   │ Emma Johnson     │     95        │    12:45      │    95%      │      150          │
│  2   │ John Smith       │     88        │    14:30      │    88%      │      140          │
│  3   │ Sarah Williams   │     85        │    13:15      │    85%      │      130          │
└──────┴──────────────────┴───────────────┴───────────────┴─────────────┴───────────────────┘
```

**Analytics Available:**
- Participation rate
- Score distribution (histogram)
- Time vs score correlation
- Subject/chapter difficulty identification
- Top performers
- Students needing support (bottom 25%)

### Progress Tracking

#### Module Progress (`UserModuleProgress`)

| Field | Description |
|-------|-------------|
| `status` | `not_started`, `in_progress`, `due`, `completed` |
| `percentage` | 0-100% completion |
| `started_at` | When learning began |
| `completed_at` | When module was finished |
| `last_accessed` | Engagement tracking |
| `current_question` | Identify stopping point |

#### Chapter Progress (`UserChapterProgress`)

Same structure as module progress, but at chapter level for granular tracking.

**Key Metrics:**
```
Overall Completion % = AVG(percentage) across all modules
Active Learning = COUNT(status='in_progress')
Engagement Score = Frequency of last_accessed updates
Time to Complete = completed_at - started_at
Dropout Points = Chapters where status != 'completed' but started
```

---

## API Endpoints

### Recommended Analytics API Structure

#### Admin Endpoints
```
GET /api/analytics/admin/school-overview/
    Response: { total_students, total_teachers, total_classes, avg_accuracy, avg_exp }

GET /api/analytics/admin/grades/{grade_id}/performance/
    Response: { grade_name, classes[], avg_metrics, top_students[], struggling_students[] }

GET /api/analytics/admin/classes/{class_id}/performance/
    Response: { class_name, students[], subject_performance[], missions[], competitions[] }

GET /api/analytics/admin/teachers/{teacher_id}/performance/
    Response: { teacher_name, classes_assigned[], student_performance_summary }
```

#### Teacher Endpoints
```
GET /api/analytics/teacher/my-classes/
    Response: { classes: [{ id, name, student_count, avg_performance }] }

GET /api/analytics/teacher/class/{class_id}/subject/{subject_id}/
    Response: { class_name, subject_name, module_progress[], chapter_stats[], question_analysis }

GET /api/analytics/teacher/class/{class_id}/students/
    Response: { students: [{ id, name, accuracy, exp, level, weak_areas }] }

GET /api/analytics/teacher/class/{class_id}/students/{student_id}/
    Response: { student_details, subject_performance[], progress_history, answer_analysis }

GET /api/analytics/teacher/missions/{mission_id}/analytics/
    Response: { mission_details, participation_rate, completion_rate, question_wise_stats }

GET /api/analytics/teacher/competitions/{competition_id}/analytics/
    Response: { competition_details, leaderboard[], score_distribution, time_analysis }

GET /api/analytics/teacher/subject/{subject_id}/question-analysis/
    Response: { difficulty_breakdown, question_type_stats, most_missed_questions[] }
```

#### Student Endpoints
```
GET /api/analytics/student/my-progress/
    Response: { overall_progress, subject_breakdown[], level_info, exp_history }

GET /api/analytics/student/subject/{subject_id}/performance/
    Response: { accuracy, modules_completed, chapters_progress[], weak_areas[] }

GET /api/analytics/student/missions/history/
    Response: { missions: [{ id, title, status, score, exp_earned }] }

GET /api/analytics/student/competitions/history/
    Response: { competitions: [{ id, title, rank, score, time_taken }] }

GET /api/analytics/student/improvement-areas/
    Response: { weak_subjects[], difficult_questions[], recommended_practice[] }

GET /api/analytics/student/leaderboard/class/{class_id}/
    Response: { my_rank, total_students, top_10[], my_stats }
```

---

## Implementation Examples

### Django ORM Queries

#### 1. Get Teacher's Class Performance Summary

```python
from django.db.models import Count, Avg, Sum, Case, When, F, Q
from gyaan_buddy.users.models import Teacher, Student, Class
from gyaan_buddy.subjects.models import Answer, Question

def get_teacher_class_summary(teacher_profile_id):
    """Get performance summary for all classes assigned to a teacher."""
    
    # Get teacher's assignments
    assignments = Teacher.objects.filter(
        teacher_id=teacher_profile_id
    ).select_related('class_instance', 'subject')
    
    results = []
    for assignment in assignments:
        class_instance = assignment.class_instance
        subject = assignment.subject
        
        # Get students in this class
        students = Student.objects.filter(
            class_instance=class_instance,
            is_deleted=False
        )
        
        # Calculate metrics
        student_ids = students.values_list('user_profile__account_id', flat=True)
        
        # Get answers for this subject's questions
        answer_stats = Answer.objects.filter(
            user_id__in=student_ids,
            question__module_contents__chapter__module__subject=subject
        ).aggregate(
            total_answers=Count('id'),
            correct_answers=Count('id', filter=Q(is_correct=True)),
            avg_tries=Avg('tries')
        )
        
        accuracy = 0
        if answer_stats['total_answers'] > 0:
            accuracy = (answer_stats['correct_answers'] / answer_stats['total_answers']) * 100
        
        results.append({
            'class_id': str(class_instance.id),
            'class_name': class_instance.name,
            'subject_id': str(subject.id),
            'subject_name': subject.name,
            'student_count': students.count(),
            'total_questions_attempted': answer_stats['total_answers'] or 0,
            'accuracy_percentage': round(accuracy, 2),
            'avg_attempts': round(answer_stats['avg_tries'] or 0, 2)
        })
    
    return results
```

#### 2. Get Student Subject-wise Performance

```python
def get_student_subject_performance(student_id):
    """Get detailed subject-wise performance for a student."""
    
    student = Student.objects.get(id=student_id)
    account_id = student.user_profile.account_id
    
    # Get all subjects available to the student
    subjects = student.class_instance.subjects.filter(is_active=True)
    
    results = []
    for subject in subjects:
        # Get answers for this subject
        answers = Answer.objects.filter(
            user_id=account_id,
            question__module_contents__chapter__module__subject=subject
        )
        
        total = answers.count()
        correct = answers.filter(is_correct=True).count()
        accuracy = (correct / total * 100) if total > 0 else 0
        
        # Get module progress
        from gyaan_buddy.users.models import UserModuleProgress
        module_progress = UserModuleProgress.objects.filter(
            account_id=account_id,
            module__subject=subject
        ).aggregate(
            avg_completion=Avg('percentage'),
            completed_modules=Count('id', filter=Q(status='completed')),
            total_modules=Count('id')
        )
        
        results.append({
            'subject_id': str(subject.id),
            'subject_name': subject.name,
            'questions_attempted': total,
            'correct_answers': correct,
            'accuracy_percentage': round(accuracy, 2),
            'avg_module_completion': round(module_progress['avg_completion'] or 0, 2),
            'modules_completed': module_progress['completed_modules'],
            'total_modules': module_progress['total_modules']
        })
    
    return results
```

#### 3. Get Mission Analytics

```python
def get_mission_analytics(mission_id):
    """Get detailed analytics for a mission."""
    
    from gyaan_buddy.users.models import Mission, UserMissionProgress, Student
    
    mission = Mission.objects.get(id=mission_id)
    
    # Total students in the class
    total_students = Student.objects.filter(
        class_instance=mission.class_group,
        is_deleted=False
    ).count()
    
    # Progress statistics
    progress = UserMissionProgress.objects.filter(mission=mission)
    
    started_count = progress.exclude(status='not_started').count()
    completed_count = progress.filter(status='completed').count()
    
    # Average time calculation
    completed_progress = progress.filter(
        status='completed',
        started_at__isnull=False,
        completed_at__isnull=False
    )
    
    avg_time_seconds = None
    if completed_progress.exists():
        from django.db.models import F, ExpressionWrapper, DurationField
        time_data = completed_progress.annotate(
            duration=ExpressionWrapper(
                F('completed_at') - F('started_at'),
                output_field=DurationField()
            )
        ).aggregate(avg_duration=Avg('duration'))
        
        if time_data['avg_duration']:
            avg_time_seconds = time_data['avg_duration'].total_seconds()
    
    # Question-wise performance
    question_stats = []
    for mq in mission.mission_questions.all().order_by('order'):
        answers = Answer.objects.filter(
            question=mq.question,
            user__profile__student__class_instance=mission.class_group
        )
        total = answers.count()
        correct = answers.filter(is_correct=True).count()
        
        question_stats.append({
            'order': mq.order,
            'question_id': str(mq.question.id),
            'question_text': mq.question.question_text[:100],
            'difficulty': mq.question.difficulty_level,
            'attempts': total,
            'correct': correct,
            'accuracy': round((correct / total * 100) if total > 0 else 0, 2)
        })
    
    return {
        'mission_id': str(mission.id),
        'mission_title': mission.title,
        'class_name': mission.class_group.name,
        'subject_name': mission.subject.name if mission.subject else None,
        'total_students': total_students,
        'started_count': started_count,
        'completed_count': completed_count,
        'participation_rate': round((started_count / total_students * 100) if total_students > 0 else 0, 2),
        'completion_rate': round((completed_count / started_count * 100) if started_count > 0 else 0, 2),
        'avg_time_seconds': avg_time_seconds,
        'question_performance': question_stats
    }
```

---

## Dashboard UI Recommendations

### Teacher Dashboard Structure

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              TEACHER ANALYTICS DASHBOARD                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

1. OVERVIEW TAB
   ├── My Classes Summary Cards
   │   ├── Class Name | Student Count | Avg Accuracy | Active Missions
   │   └── [Click to drill down]
   │
   ├── Quick Stats
   │   ├── Total Students
   │   ├── Average Class Performance
   │   ├── Active Missions
   │   └── Upcoming Competitions
   │
   └── Alerts
       ├── Students needing attention (low accuracy/progress)
       └── Overdue missions

2. CLASS ANALYTICS TAB
   ├── Class Selector Dropdown
   ├── Subject Filter
   │
   ├── Performance Overview
   │   ├── Accuracy Trend Chart (line)
   │   ├── Progress Distribution (pie)
   │   └── EXP Leaderboard
   │
   ├── Module/Chapter Progress
   │   ├── Progress bars per module
   │   └── Completion rates
   │
   └── Student List
       ├── Name | Accuracy | Progress | EXP | Level | Status
       └── [Click for individual analysis]

3. STUDENT DETAIL VIEW
   ├── Student Profile Card
   ├── Subject Performance Breakdown
   ├── Answer History
   ├── Weak Areas
   └── Recommendations

4. MISSION ANALYTICS TAB
   ├── Active Missions List
   ├── Mission Detail View
   │   ├── Participation/Completion rates
   │   ├── Question-wise analysis
   │   └── Time analysis
   └── Historical comparison

5. COMPETITION TAB
   ├── Competition Leaderboards
   ├── Score Distributions
   └── Historical Results
```

### Student Dashboard Structure

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                               STUDENT ANALYTICS DASHBOARD                                    │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

1. MY PROGRESS
   ├── Overall Progress Ring
   ├── EXP & Level Display
   ├── Subject Progress Bars
   └── Recent Activity Timeline

2. SUBJECT PERFORMANCE
   ├── Subject Cards with Accuracy
   ├── Module Completion Status
   └── Weak Areas Highlight

3. MISSIONS & COMPETITIONS
   ├── Active Missions
   ├── Completed Missions with Scores
   ├── Competition History
   └── Achievements

4. LEADERBOARD
   ├── Class Ranking
   ├── Subject Rankings
   └── Competition Rankings

5. IMPROVEMENT SUGGESTIONS
   ├── Recommended Practice Questions
   ├── Focus Areas
   └── Study Tips
```

---

## Appendix

### Status Values Reference

**Module/Chapter Progress Status:**
- `not_started` - User hasn't begun
- `in_progress` - Currently working on
- `due` - Past expected completion
- `completed` - Finished

**Mission/Competition Progress Status:**
- `not_started` - Not participated
- `in_progress` - Currently active
- `completed` - Finished

**Competition Status:**
- `not_started` - Scheduled but not begun
- `in_progress` - Currently running
- `completed` - Ended

### Question Types

- `mcq_single` - Single correct answer MCQ
- `mcq_multiple` - Multiple correct answers MCQ
- `short_answer` - Text-based answer

### Difficulty Levels

- `easy` - Basic questions
- `medium` - Intermediate questions
- `hard` - Advanced questions

### Notification Types

- `module` - Module-related notifications
- `subject` - Subject updates
- `user` - Personal notifications (level up, etc.)
- `mission` - Mission assignments/reminders
- `competition` - Competition invites/results

---

*Document generated for Gyaan Buddy Backend - Educational Platform Analytics System*

