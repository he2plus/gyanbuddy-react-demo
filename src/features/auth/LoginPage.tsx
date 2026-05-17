/**
 * LoginPage — mirror of lib/screens/auth/new_login_screen.dart.
 *
 * Form fields:
 *   - "Admission Number" → submitted as `username`
 *   - Password           → submitted as `password`
 *
 * Routing after success (matches Dart logic at new_login_screen.dart:67-90):
 *   - user.loggedInOnce === true  → /home
 *   - user.loggedInOnce === false → /confirmation
 */
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Lock, User as UserIcon } from 'lucide-react'
import { useNavigate, Navigate, Link } from 'react-router-dom'
import toast from 'react-hot-toast'

import { Button } from '../../components/Button'
import { TextField } from '../../components/TextField'
import { useLogin, LoginFailedError } from './useLogin'
import { useAuthStore } from '../../state/auth'

const schema = z.object({
  username: z
    .string()
    .trim()
    .min(1, 'Admission number is required'),
  password: z.string().min(1, 'Password is required'),
})

type FormValues = z.infer<typeof schema>

// Login screen primary button color from the Flutter source.
const LOGIN_PRIMARY = '#00167A'
const LOGIN_PRIMARY_DARK = '#000F5C'

export function LoginPage() {
  const navigate = useNavigate()
  const status = useAuthStore((s) => s.status)
  const message = useAuthStore((s) => s.message)
  const login = useLogin()

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { username: '', password: '' },
  })

  // If session expired in another tab and dropped us here, surface it once.
  useEffect(() => {
    if (status === 'unauthenticated' && message) {
      toast(message, { icon: '⚠️' })
    }
  }, [status, message])

  if (status === 'authenticated') {
    return <Navigate to="/home" replace />
  }

  const onSubmit = handleSubmit(async (values) => {
    try {
      const data = await login.mutateAsync({
        username: values.username.trim(),
        password: values.password,
      })
      const next = data.user.loggedInOnce ? '/home' : '/confirmation'
      if (!data.user.loggedInOnce) {
        toast.success('Welcome! Please complete your profile setup.')
      } else {
        toast.success('Login successful!')
      }
      navigate(next, { replace: true })
    } catch (err) {
      const msg =
        err instanceof LoginFailedError
          ? err.message
          : err instanceof Error
            ? err.message
            : 'Login failed. Please try again.'
      toast.error(msg)
    }
  })

  const mockOn = import.meta.env.VITE_DEV_MOCK_AUTH === 'true'

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <main className="mx-auto flex w-full max-w-[600px] flex-1 flex-col px-9 pt-[110px]">
        {mockOn && (
          <div className="mb-4 rounded-lg border border-amber-300 bg-amber-50 px-3 py-2 text-xs text-amber-900">
            <span className="font-semibold">Dev mock mode:</span> any non-empty
            admission # / password will sign you in. Disable in <code>.env.local</code>.
          </div>
        )}
        {/* Real Flutter asset: gyaan_buddy/assets/images/login_logo.png */}
        <div className="mb-8 flex justify-center">
          <img
            src="/images/login_logo.png"
            alt="Gyaan Buddy"
            width={230}
            className="h-auto w-[230px] object-contain"
          />
        </div>

        <h1 className="text-sm font-bold text-[#1A1A2E]">
          Log In to your account
        </h1>

        <form className="mt-2 space-y-3" onSubmit={onSubmit} noValidate>
          <TextField
            placeholder="Admission Number"
            autoComplete="username"
            inputMode="text"
            leftIcon={<UserIcon className="h-5 w-5" />}
            error={errors.username?.message}
            {...register('username')}
          />
          <TextField
            type="password"
            placeholder="Password"
            autoComplete="current-password"
            leftIcon={<Lock className="h-5 w-5" />}
            error={errors.password?.message}
            {...register('password')}
          />

          <Button
            type="submit"
            fullWidth
            loading={login.isPending}
            className="mt-3 h-12 rounded-[10px]"
            style={{
              background: login.isPending ? `${LOGIN_PRIMARY}99` : LOGIN_PRIMARY,
            }}
            onMouseEnter={(e) => {
              if (!login.isPending) {
                e.currentTarget.style.background = LOGIN_PRIMARY_DARK
              }
            }}
            onMouseLeave={(e) => {
              if (!login.isPending) {
                e.currentTarget.style.background = LOGIN_PRIMARY
              }
            }}
          >
            Log In
          </Button>

          <div className="mt-4 flex items-center justify-between text-sm">
            <Link
              to="/forgot-password"
              className="font-medium text-[var(--color-text-secondary)] underline-offset-4 hover:text-[var(--color-text-primary)] hover:underline"
            >
              Forgot password?
            </Link>
            <Link
              to="/register"
              className="font-semibold underline-offset-4 hover:underline"
              style={{ color: LOGIN_PRIMARY }}
            >
              Create account
            </Link>
          </div>
        </form>
      </main>
    </div>
  )
}
