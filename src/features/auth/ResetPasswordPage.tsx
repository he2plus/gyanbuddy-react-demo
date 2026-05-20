/**
 * ResetPasswordPage — restyled. POST /auth/reset-password. Token comes
 * from the deep-link in the password-reset email as ?token=.
 */
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import { Check } from 'lucide-react'

import { resetPassword } from '../../api/auth'
import { AuthShell, AuthTextField, AuthSubmitButton } from './AuthShell'

const schema = z
  .object({
    password: z.string().min(6, 'Password must be at least 6 characters'),
    password_confirmation: z.string(),
  })
  .refine((v) => v.password === v.password_confirmation, {
    message: 'Passwords do not match',
    path: ['password_confirmation'],
  })
type FormValues = z.infer<typeof schema>

export function ResetPasswordPage() {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const token = params.get('token') ?? ''
  const [done, setDone] = useState(false)

  const mutation = useMutation({
    mutationFn: (input: { password: string; password_confirmation: string }) =>
      resetPassword({ token, ...input }),
    onSuccess: () => {
      setDone(true)
      toast.success('Password reset. You can log in now.')
      window.setTimeout(() => navigate('/login', { replace: true }), 1500)
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : 'Could not reset password')
    },
  })

  const { register, handleSubmit, formState: { errors } } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { password: '', password_confirmation: '' },
  })

  const onSubmit = handleSubmit((values) => mutation.mutate(values))

  return (
    <AuthShell
      title="Reset password"
      subtitle="Choose a new password for your account."
      footer={
        <div className="text-center">
          <Link
            to="/login"
            style={{ color: '#00167A', fontWeight: 700, textDecoration: 'none' }}
          >
            Back to sign in
          </Link>
        </div>
      }
    >
      {done ? (
        <div
          className="flex items-start"
          style={{
            gap: 12, padding: 16, borderRadius: 16,
            background: '#DCFCE7', border: '1px solid #86EFAC',
          }}
        >
          <span
            className="grid place-items-center shrink-0"
            style={{
              width: 32, height: 32, borderRadius: 999,
              background: '#22C55E', color: '#fff',
            }}
          >
            <Check className="w-5 h-5" strokeWidth={3} />
          </span>
          <div className="font-body" style={{ fontSize: 15, color: '#166534', lineHeight: '22px' }}>
            Password reset successfully. Redirecting to sign in…
          </div>
        </div>
      ) : !token ? (
        <div
          className="flex items-start"
          style={{
            gap: 12, padding: 16, borderRadius: 16,
            background: '#FFE2E2', border: '1px solid #FCA5A5',
          }}
        >
          <div className="font-body" style={{ fontSize: 15, color: '#B91C1C', lineHeight: '22px' }}>
            Missing reset token. Use the link in your email or{' '}
            <Link to="/forgot-password" style={{ textDecoration: 'underline', fontWeight: 700 }}>
              request a new one
            </Link>.
          </div>
        </div>
      ) : (
        <form onSubmit={onSubmit} noValidate className="flex flex-col" style={{ gap: 16 }}>
          <AuthTextField
            label="New password"
            type="password"
            placeholder="At least 6 characters"
            error={errors.password?.message}
            {...register('password')}
          />
          <AuthTextField
            label="Confirm password"
            type="password"
            placeholder="Re-enter your password"
            error={errors.password_confirmation?.message}
            {...register('password_confirmation')}
          />
          <AuthSubmitButton type="submit" loading={mutation.isPending}>
            Reset password
          </AuthSubmitButton>
        </form>
      )}
    </AuthShell>
  )
}
