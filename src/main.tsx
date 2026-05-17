import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { RouterProvider } from 'react-router-dom'

import './styles/globals.css'

import { AppProviders } from './app/providers'
import { router } from './app/routes'
import { useAuthStore } from './state/auth'
import { registerUnauthorizedHandler } from './api/client'

// Wire the axios 401 interceptor to the auth store BEFORE the first request fires.
registerUnauthorizedHandler(() => {
  useAuthStore.getState().forceLogout()
})

// Kick off the auth bootstrap once. The store guards against re-entry.
useAuthStore.getState().bootstrap()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AppProviders>
      <RouterProvider router={router} />
    </AppProviders>
  </StrictMode>,
)
