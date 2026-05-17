/**
 * useLogin — TanStack mutation wrapper around the auth API.
 *
 * On success: writes session into auth store + tokenStorage and returns the
 * authenticated User so the caller can route based on `loggedInOnce`.
 */
import { useMutation } from '@tanstack/react-query'
import { login, type LoginInput, LoginFailedError } from '../../api/auth'
import { useAuthStore } from '../../state/auth'

export function useLogin() {
  const setSession = useAuthStore((s) => s.setSession)

  return useMutation({
    mutationFn: (input: LoginInput) => login(input),
    onSuccess: ({ user, tokens }) => {
      setSession(user, tokens)
    },
  })
}

export { LoginFailedError }
