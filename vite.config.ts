import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

/**
 * Vite config — when VITE_USE_PROXY=true, requests to /api/* are proxied to the
 * backend so the browser never makes a cross-origin call (CORS becomes the
 * server's problem, not the user's). Set VITE_BUILD_MODE to pick which backend.
 */
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const buildMode = (env.VITE_BUILD_MODE ?? 'dev') as 'dev' | 'stage' | 'prod'
  const baseUrl =
    buildMode === 'prod'
      ? env.VITE_BASE_URL_PROD
      : buildMode === 'stage'
        ? env.VITE_BASE_URL_STAGE
        : env.VITE_BASE_URL_DEV

  const useProxy = env.VITE_USE_PROXY === 'true'

  return {
    plugins: [react(), tailwindcss()],
    server: {
      host: true,
      port: 5173,
      proxy: useProxy && baseUrl
        ? {
            '/api': {
              target: baseUrl,
              changeOrigin: true,
              secure: true,
            },
          }
        : undefined,
    },
  }
})
