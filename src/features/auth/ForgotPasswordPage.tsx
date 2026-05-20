/**
 * ForgotPasswordPage — restyled. Backend behavior unchanged: POST
 * /auth/forgot-password, always show a generic "if an account exists"
 * confirmation regardless of whether the email was registered.
 */
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Link } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { Mail } from 'lucide-react'

import { forgotPassword } from '../../api/auth'
import { AuthShell, AuthTextField, AuthSubmitButton } from './AuthShell'

const schema = z.object({ email: z.string().trim().email('Enter a valid email') })
type FormValues = z.infer<typeof schema>

export function ForgotPasswordPage() {
  const [sent, setSent] = useState(false)
  const mutation = useMutation({
    mutationFn: (email: string) => forgotPassword(email),
    onSuccess: () => setSent(true),
    onError: () => setSent(true),
  })
  const { register, handleSubmit, formState: { errors }, getValues } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { email: '' },
  })

  const onSubmit = handleSubmit((values) => mutation.mutate(values.email))

  return (
    <AuthShell
      title="Forgot password"
      subtitle="Enter the email on your account. We'll send a reset link."
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
      {sent ? (
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
            <Mail className="w-5 h-5" strokeWidth={2.5} />
          </span>
          <div className="font-body" style={{ fontSize: 15, color: '#166534', lineHeight: '22px' }}>
            If an account exists for{' '}
            <strong style={{ fontWeight: 700 }}>{getValues('email')}</strong>, a
            password-reset link will arrive in your inbox within a few minutes.
          </div>
        </div>
      ) : (
        <form onSubmit={onSubmit} noValidate className="flex flex-col" style={{ gap: 16 }}>
          <AuthTextField
            label="Email"
            type="email"
            placeholder="you@school.edu"
            error={errors.email?.message}
            {...register('email')}
          />
          <AuthSubmitButton type="submit" loading={mutation.isPending}>
            Send reset link
          </AuthSubmitButton>
        </form>
      )}
    </AuthShell>
  )
}
