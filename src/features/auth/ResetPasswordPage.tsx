/**
 * ResetPasswordPage — POST /auth/reset-password.
 * Token comes from the reset email's deep link, captured as ?token=.
 */
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Lock } from 'lucide-react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import toast from 'react-hot-toast'

import { Button } from '../../components/Button'
import { TextField } from '../../components/TextField'
import { resetPassword } from '../../api/auth'

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

const PRIMARY = '#00167A'

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

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { password: '', password_confirmation: '' },
  })

  const onSubmit = handleSubmit((values) => mutation.mutate(values))

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <main className="mx-auto flex w-full max-w-[480px] flex-1 flex-col px-9 pt-20 pb-12">
        <h1 className="text-2xl font-bold text-[#1A1A2E]">Reset password</h1>
        <p className="mt-2 text-sm text-[var(--color-text-secondary)]">
          Choose a new password.
        </p>

        {!token && (
          <div className="mt-6 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
            This link is missing a reset token. Request a new reset email from{' '}
            <Link to="/forgot-password" className="font-semibold underline">
              Forgot password
            </Link>
            .
          </div>
        )}

        {done ? (
          <div className="mt-6 rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-900">
            Password reset. Redirecting to login…
          </div>
        ) : (
          <form className="mt-6 space-y-3" onSubmit={onSubmit} noValidate>
            <TextField
              type="password"
              placeholder="New password"
              autoComplete="new-password"
              leftIcon={<Lock className="h-5 w-5" />}
              error={errors.password?.message}
              {...register('password')}
            />
            <TextField
              type="password"
              placeholder="Confirm new password"
              autoComplete="new-password"
              leftIcon={<Lock className="h-5 w-5" />}
              error={errors.password_confirmation?.message}
              {...register('password_confirmation')}
            />
            <Button
              type="submit"
              fullWidth
              disabled={!token}
              loading={mutation.isPending}
              className="h-12 rounded-[10px]"
              style={{ background: PRIMARY }}
            >
              Reset password
            </Button>
          </form>
        )}
      </main>
    </div>
  )
}
