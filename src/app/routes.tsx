/**
 * Route table — full Flutter feature surface (auth + recovery, profile edit,
 * subjects, modules, journey, theory, quiz, missions, tests, leaderboard).
 *
 * Public auth routes: /login /register /forgot-password /reset-password /onboarding.
 * Everything else is wrapped in <RequireAuth/>.
 */
import { type ReactElement } from 'react'
import { createBrowserRouter, Navigate } from 'react-router-dom'

import { AppShell } from '../shell/AppShell'
import { RequireAuth } from '../features/auth/RequireAuth'

// Auth
import { LoginPage } from '../features/auth/LoginPage'
import { RegisterPage } from '../features/auth/RegisterPage'
import { ForgotPasswordPage } from '../features/auth/ForgotPasswordPage'
import { ResetPasswordPage } from '../features/auth/ResetPasswordPage'
import { OnboardingPage } from '../features/onboarding/OnboardingPage'

// Top-level screens
import { HomePage } from '../features/home/HomePage'
import { ConfirmationPage } from '../features/confirmation/ConfirmationPage'
import { LeaderboardPage } from '../features/leaderboard/LeaderboardPage'
import { PodiumPage } from '../features/leaderboard/PodiumPage'
import { ModuleLeaderboardPage } from '../features/leaderboard/ModuleLeaderboardPage'
import { NotificationsPage } from '../features/notifications/NotificationsPage'
import { CreditsPage } from '../features/credits/CreditsPage'

// Profile
import { ProfilePage } from '../features/profile/ProfilePage'
import { ProfileEditPage } from '../features/profile/ProfileEditPage'
import { ChangePasswordPage } from '../features/profile/ChangePasswordPage'

// Subjects → modules → chapters → theory → quiz
import { SubjectListPage } from '../features/subject/SubjectListPage'
import { SubjectDetailPage } from '../features/subject/SubjectDetailPage'
import { ModuleChapterPage } from '../features/module/ModuleChapterPage'
import { ChapterTheoryPage } from '../features/module/ChapterTheoryPage'
import { ChapterQuizPage } from '../features/quiz/ChapterQuizPage'

// Missions
import { MissionListPage } from '../features/mission/MissionListPage'
import { MissionDetailPage } from '../features/mission/MissionDetailPage'
import { MissionQuizPage } from '../features/quiz/MissionQuizPage'

// Tests
import { TestListPage } from '../features/test/TestListPage'
import { TestQuizPage } from '../features/test/TestQuizPage'

const guarded = (el: ReactElement) => <RequireAuth>{el}</RequireAuth>

export const router = createBrowserRouter([
  {
    path: '/',
    element: <AppShell />,
    children: [
      { index: true, element: guarded(<Navigate to="/home" replace />) },

      // Public auth flow
      { path: 'login', element: <LoginPage /> },
      { path: 'register', element: <RegisterPage /> },
      { path: 'forgot-password', element: <ForgotPasswordPage /> },
      { path: 'reset-password', element: <ResetPasswordPage /> },
      { path: 'onboarding', element: <OnboardingPage /> },

      // Top-level
      { path: 'home', element: guarded(<HomePage />) },
      { path: 'confirmation', element: guarded(<ConfirmationPage />) },
      { path: 'leaderboard', element: guarded(<LeaderboardPage />) },
      { path: 'podium', element: guarded(<PodiumPage />) },
      { path: 'notifications', element: guarded(<NotificationsPage />) },
      { path: 'credits', element: guarded(<CreditsPage />) },

      // Profile
      { path: 'profile', element: guarded(<ProfilePage />) },
      { path: 'profile/edit', element: guarded(<ProfileEditPage />) },
      { path: 'profile/change-password', element: guarded(<ChangePasswordPage />) },

      // Subjects → modules → chapters → theory → quiz
      { path: 'subjects', element: guarded(<SubjectListPage />) },
      { path: 'subjects/:subjectId', element: guarded(<SubjectDetailPage />) },
      {
        path: 'subjects/:subjectId/modules/:moduleId/chapters',
        element: guarded(<ModuleChapterPage />),
      },
      {
        path: 'subjects/:subjectId/modules/:moduleId/chapters/:chapterId',
        element: guarded(<ChapterTheoryPage />),
      },
      {
        path: 'subjects/:subjectId/modules/:moduleId/chapters/:chapterId/quiz',
        element: guarded(<ChapterQuizPage />),
      },
      {
        path: 'subjects/:subjectId/modules/:moduleId/leaderboard',
        element: guarded(<ModuleLeaderboardPage />),
      },

      // Missions
      { path: 'missions', element: guarded(<MissionListPage />) },
      { path: 'missions/:missionId', element: guarded(<MissionDetailPage />) },
      { path: 'missions/:missionId/quiz', element: guarded(<MissionQuizPage />) },

      // Tests
      { path: 'tests', element: guarded(<TestListPage />) },
      { path: 'tests/:testId', element: guarded(<TestQuizPage />) },

      { path: '*', element: <Navigate to="/" replace /> },
    ],
  },
])
