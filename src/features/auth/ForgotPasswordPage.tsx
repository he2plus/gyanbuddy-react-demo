/**
 * ForgotPasswordPage — POST /auth/forgot-password.
 * Always shows a generic "if an account exists" message regardless of result
 * (don't leak account existence — same convention as the Dart contract).
 */
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Mail } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'

import { Button } from '../../components/Button'
import { TextField } from '../../components/TextField'
import { forgotPassword } from '../../api/auth'

const schema = z.object({ email: z.string().trim().email('Enter a valid email') })
type FormValues = z.infer<typeof schema>

const PRIMARY = '#00167A'

export function ForgotPasswordPage() {
  const [sent, setSent] = useState(false)
  const mutation = useMutation({
    mutationFn: (email: string) => forgotPassword(email),
    onSuccess: () => setSent(true),
    onError: () => setSent(true), // Don't leak account existence
  })
  const {
    register,
    handleSubmit,
    formState: { errors },
    getValues,
  } = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: { email: '' } })

  const onSubmit = handleSubmit((values) => mutation.mutate(values.email))

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <main className="mx-auto flex w-full max-w-[480px] flex-1 flex-col px-9 pt-20 pb-12">
        <h1 className="text-2xl font-bold text-[#1A1A2E]">Forgot password</h1>
        <p className="mt-2 text-sm text-[var(--color-text-secondary)]">
          Enter the email on your account. We'll send a link to reset your password.
        </p>

        {sent ? (
          <div className="mt-6 rounded-xl border border-emerald-200 bg-emerald-50 p-4">
            <p className="text-sm text-emerald-900">
              If an account exists for <span className="font-semibold">{getValues('email')}</span>, a
              reset link has been sent. Check your inbox.
            </p>
            <Link
              to="/login"
              className="mt-3 inline-block text-sm font-semibold underline-offset-4 hover:underline"
              style={{ color: PRIMARY }}
            >
              Back to login →
            </Link>
          </div>
        ) : (
          <form className="mt-6 space-y-3" onSubmit={onSubmit} noValidate>
            <TextField
              type="email"
              placeholder="Email"
              autoComplete="email"
              leftIcon={<Mail className="h-5 w-5" />}
              error={errors.email?.message}
              {...register('email')}
            />
            <Button
              type="submit"
              fullWidth
              loading={mutation.isPending}
              className="h-12 rounded-[10px]"
              style={{ background: PRIMARY }}
            >
              Send reset link
            </Button>
            <p className="text-center text-sm text-[var(--color-text-secondary)]">
              <Link
                to="/login"
                className="font-semibold underline-offset-4 hover:underline"
                style={{ color: PRIMARY }}
              >
                Back to login
              </Link>
            </p>
          </form>
        )}
      </main>
    </div>
  )
}
