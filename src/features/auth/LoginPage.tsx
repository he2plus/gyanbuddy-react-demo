/**
 * LoginPage — restyled in the new design language. Routing semantics are
 * unchanged: on success, loggedInOnce → /home, else → /confirmation.
 */
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Navigate, useNavigate, Link } from 'react-router-dom'
import toast from 'react-hot-toast'

import { useLogin, LoginFailedError } from './useLogin'
import { useAuthStore } from '../../state/auth'
import { AuthShell, AuthTextField, AuthSubmitButton } from './AuthShell'

const schema = z.object({
  username: z.string().trim().min(1, 'Admission number is required'),
  password: z.string().min(1, 'Password is required'),
})
type FormValues = z.infer<typeof schema>

export function LoginPage() {
  const navigate = useNavigate()
  const status = useAuthStore((s) => s.status)
  const message = useAuthStore((s) => s.message)
  const login = useLogin()
  const mockOn = import.meta.env.VITE_DEV_MOCK_AUTH === 'true'

  const { register, handleSubmit, formState: { errors } } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { username: '', password: '' },
  })

  useEffect(() => {
    if (status === 'unauthenticated' && message) toast(message, { icon: '⚠️' })
  }, [status, message])

  if (status === 'authenticated') return <Navigate to="/home" replace />

  const onSubmit = handleSubmit(async (values) => {
    try {
      const data = await login.mutateAsync({
        username: values.username.trim(),
        password: values.password,
      })
      const next = data.user.loggedInOnce ? '/home' : '/confirmation'
      toast.success(
        data.user.loggedInOnce ? 'Welcome back!' : 'Welcome! Complete your profile.',
      )
      navigate(next, { replace: true })
    } catch (err) {
      const msg =
        err instanceof LoginFailedError ? err.message :
        err instanceof Error ? err.message :
        'Login failed. Please try again.'
      toast.error(msg)
    }
  })

  return (
    <AuthShell
      title="Welcome back"
      subtitle="Log in to pick up where you left off."
      footer={
        <div className="flex items-center justify-between">
          <Link
            to="/forgot-password"
            style={{ color: '#545454', fontWeight: 600, textDecoration: 'none' }}
            onMouseEnter={(e) => (e.currentTarget.style.color = '#121212')}
            onMouseLeave={(e) => (e.currentTarget.style.color = '#545454')}
          >
            Forgot password?
          </Link>
          <Link
            to="/register"
            style={{ color: '#00167A', fontWeight: 700, textDecoration: 'none' }}
          >
            Create account
          </Link>
        </div>
      }
    >
      {mockOn && (
        <div
          className="font-body"
          style={{
            marginBottom: 18, padding: '10px 14px', borderRadius: 12,
            background: '#FFF4D6', border: '1px solid #FFE48B',
            fontSize: 13, color: '#92400E', lineHeight: '18px',
          }}
        >
          <strong>Demo mode</strong> — any non-empty username + password signs you in.
          Try <code>1234</code> / <code>demo1234</code>.
        </div>
      )}

      <form
        onSubmit={onSubmit}
        noValidate
        className="flex flex-col"
        style={{ gap: 16 }}
      >
        <AuthTextField
          label="Admission Number"
          placeholder="e.g. 1234"
          autoComplete="username"
          inputMode="text"
          error={errors.username?.message}
          {...register('username')}
        />
        <AuthTextField
          label="Password"
          type="password"
          placeholder="••••••••"
          autoComplete="current-password"
          error={errors.password?.message}
          {...register('password')}
        />
        <AuthSubmitButton type="submit" loading={login.isPending}>
          Sign in
        </AuthSubmitButton>
      </form>
    </AuthShell>
  )
}
