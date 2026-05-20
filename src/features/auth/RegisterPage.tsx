/**
 * RegisterPage — restyled in the new design language. Backend contract
 * preserved: posts to /auth/register, stores the returned session, routes
 * to /confirmation for first-time profile setup.
 */
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useNavigate, Link } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import toast from 'react-hot-toast'

import { register as apiRegister, type RegisterInput } from '../../api/auth'
import { useAuthStore } from '../../state/auth'
import { AuthShell, AuthTextField, AuthSubmitButton } from './AuthShell'

const schema = z.object({
  first_name: z.string().trim().min(1, 'First name is required'),
  last_name: z.string().trim().min(1, 'Last name is required'),
  email: z.string().trim().email('Enter a valid email'),
  username: z.string().trim().min(1, 'Admission number is required'),
  admission_number: z.number({ message: 'Enter a valid admission number' }).int().positive(),
  school: z.string().trim().min(1, 'School is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
})
type FormValues = z.infer<typeof schema>

export function RegisterPage() {
  const navigate = useNavigate()
  const setSession = useAuthStore((s) => s.setSession)

  const mutation = useMutation({
    mutationFn: (input: RegisterInput) => apiRegister(input),
    onSuccess: ({ user, tokens }) => {
      setSession(user, tokens)
      toast.success('Welcome to GyanBuddy!')
      navigate('/confirmation', { replace: true })
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : 'Registration failed')
    },
  })

  const { register, handleSubmit, formState: { errors } } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      first_name: '', last_name: '', email: '',
      username: '', admission_number: 0, school: '', password: '',
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
    <AuthShell
      title="Create your account"
      subtitle="Set up your GyanBuddy profile in under a minute."
      footer={
        <div className="text-center">
          Already have an account?{' '}
          <Link
            to="/login"
            style={{ color: '#00167A', fontWeight: 700, textDecoration: 'none' }}
          >
            Sign in
          </Link>
        </div>
      }
    >
      <form onSubmit={onSubmit} noValidate className="flex flex-col" style={{ gap: 14 }}>
        <div className="grid grid-cols-2" style={{ gap: 14 }}>
          <AuthTextField
            label="First name"
            placeholder="Riya"
            error={errors.first_name?.message}
            {...register('first_name')}
          />
          <AuthTextField
            label="Last name"
            placeholder="Sharma"
            error={errors.last_name?.message}
            {...register('last_name')}
          />
        </div>
        <AuthTextField
          label="Email"
          type="email"
          placeholder="you@school.edu"
          error={errors.email?.message}
          {...register('email')}
        />
        <div className="grid grid-cols-2" style={{ gap: 14 }}>
          <AuthTextField
            label="Username"
            placeholder="riyas"
            error={errors.username?.message}
            {...register('username')}
          />
          <AuthTextField
            label="Admission #"
            type="number"
            placeholder="1234"
            error={errors.admission_number?.message}
            {...register('admission_number', { valueAsNumber: true })}
          />
        </div>
        <AuthTextField
          label="School"
          placeholder="GyanBuddy Demo School"
          error={errors.school?.message}
          {...register('school')}
        />
        <AuthTextField
          label="Password"
          type="password"
          placeholder="At least 6 characters"
          error={errors.password?.message}
          {...register('password')}
        />
        <div style={{ marginTop: 4 }}>
          <AuthSubmitButton type="submit" loading={mutation.isPending}>
            Create account
          </AuthSubmitButton>
        </div>
      </form>
    </AuthShell>
  )
}
