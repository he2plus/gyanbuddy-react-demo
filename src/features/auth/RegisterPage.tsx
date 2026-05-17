/**
 * RegisterPage — mirrors the `/auth/register` flow.
 *
 * Faithful to the Flutter API shape (admission #, first/last name, email,
 * password, school). On success: writes session via auth store, then routes
 * to /confirmation (Flutter does the same for new accounts).
 */
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Lock, Mail, User as UserIcon, School, Hash } from 'lucide-react'
import { useNavigate, Link } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import toast from 'react-hot-toast'

import { Button } from '../../components/Button'
import { TextField } from '../../components/TextField'
import { register as apiRegister, type RegisterInput } from '../../api/auth'
import { useAuthStore } from '../../state/auth'

const schema = z.object({
  first_name: z.string().trim().min(1, 'First name is required'),
  last_name: z.string().trim().min(1, 'Last name is required'),
  email: z.string().trim().email('Enter a valid email'),
  username: z.string().trim().min(1, 'Admission number is required'),
  admission_number: z.number({ message: 'Enter a valid admission number' }).int().positive('Enter a valid admission number'),
  school: z.string().trim().min(1, 'School is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
})
type FormValues = z.infer<typeof schema>

const PRIMARY = '#00167A'

export function RegisterPage() {
  const navigate = useNavigate()
  const setSession = useAuthStore((s) => s.setSession)

  const mutation = useMutation({
    mutationFn: (input: RegisterInput) => apiRegister(input),
    onSuccess: ({ user, tokens }) => {
      setSession(user, tokens)
      toast.success('Welcome to Gyaan Buddy!')
      navigate('/confirmation', { replace: true })
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : 'Registration failed')
    },
  })

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      first_name: '',
      last_name: '',
      email: '',
      username: '',
      admission_number: 0,
      school: '',
      password: '',
    },
  })

  const onSubmit = handleSubmit((values) => {
    mutation.mutate({
      username: values.username.trim(),
      password: values.password,
      first_name: values.first_name.trim(),
      last_name: values.last_name.trim(),
      email: values.email.trim(),
      admission_number: values.admission_number,
      school: values.school.trim(),
    })
  })

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <main className="mx-auto flex w-full max-w-[600px] flex-1 flex-col px-9 pt-12 pb-12">
        <div className="mb-6 flex justify-center">
          <img
            src="/images/login_logo.png"
            alt="Gyaan Buddy"
            width={180}
            className="h-auto w-[180px] object-contain"
          />
        </div>

        <h1 className="text-base font-bold text-[#1A1A2E]">Create your account</h1>
        <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
          Already have an account?{' '}
          <Link
            to="/login"
            className="font-semibold underline-offset-4 hover:underline"
            style={{ color: PRIMARY }}
          >
            Log in
          </Link>
        </p>

        <form className="mt-5 space-y-3" onSubmit={onSubmit} noValidate>
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <TextField
              placeholder="First name"
              autoComplete="given-name"
              leftIcon={<UserIcon className="h-5 w-5" />}
              error={errors.first_name?.message}
              {...register('first_name')}
            />
            <TextField
              placeholder="Last name"
              autoComplete="family-name"
              leftIcon={<UserIcon className="h-5 w-5" />}
              error={errors.last_name?.message}
              {...register('last_name')}
            />
          </div>
          <TextField
            type="email"
            placeholder="Email"
            autoComplete="email"
            leftIcon={<Mail className="h-5 w-5" />}
            error={errors.email?.message}
            {...register('email')}
          />
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <TextField
              placeholder="Admission username"
              autoComplete="username"
              leftIcon={<UserIcon className="h-5 w-5" />}
              error={errors.username?.message}
              {...register('username')}
            />
            <TextField
              placeholder="Admission #"
              inputMode="numeric"
              type="number"
              leftIcon={<Hash className="h-5 w-5" />}
              error={errors.admission_number?.message}
              {...register('admission_number', { valueAsNumber: true })}
            />
          </div>
          <TextField
            placeholder="School"
            leftIcon={<School className="h-5 w-5" />}
            error={errors.school?.message}
            {...register('school')}
          />
          <TextField
            type="password"
            placeholder="Password"
            autoComplete="new-password"
            leftIcon={<Lock className="h-5 w-5" />}
            error={errors.password?.message}
            {...register('password')}
          />

          <Button
            type="submit"
            fullWidth
            loading={mutation.isPending}
            className="mt-2 h-12 rounded-[10px]"
            style={{ background: PRIMARY }}
          >
            Create account
          </Button>
        </form>
      </main>
    </div>
  )
}
