/**
 * ProfileEditPage — PUT /users/me.
 * Edits first/last name, email, phone, date of birth, bio.
 */
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { User as UserIcon, Mail, Phone, FileText, Calendar } from 'lucide-react'
import toast from 'react-hot-toast'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import { Card } from '../../components/Card'
import { Button } from '../../components/Button'
import { TextField } from '../../components/TextField'
import { useAuthStore } from '../../state/auth'
import { updateProfile, type UpdateProfileInput } from '../../api/users'

const schema = z.object({
  first_name: z.string().trim().min(1, 'First name is required'),
  last_name: z.string().trim().min(1, 'Last name is required'),
  email: z.string().trim().email('Enter a valid email'),
  phone_number: z.string().trim().optional().or(z.literal('')),
  date_of_birth: z.string().trim().optional().or(z.literal('')),
  bio: z.string().trim().max(280, 'Bio must be 280 characters or fewer').optional().or(z.literal('')),
})
type FormValues = z.infer<typeof schema>

export function ProfileEditPage() {
  const navigate = useNavigate()
  const me = useAuthStore((s) => s.user)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isDirty },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      first_name: me?.firstName ?? '',
      last_name: me?.lastName ?? '',
      email: me?.email ?? '',
      phone_number: me?.phoneNumber ?? '',
      date_of_birth: me?.dateOfBirth ?? '',
      bio: me?.bio ?? '',
    },
  })

  useEffect(() => {
    if (me) {
      reset({
        first_name: me.firstName,
        last_name: me.lastName,
        email: me.email,
        phone_number: me.phoneNumber ?? '',
        date_of_birth: me.dateOfBirth ?? '',
        bio: me.bio ?? '',
      })
    }
  }, [me, reset])

  const mutation = useMutation({
    mutationFn: (input: UpdateProfileInput) => updateProfile(input),
    onSuccess: (updated) => {
      useAuthStore.setState({ user: updated })
      toast.success('Profile updated')
      navigate('/profile')
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : 'Failed to update profile')
    },
  })

  const onSubmit = handleSubmit((values) => {
    const input: UpdateProfileInput = {
      first_name: values.first_name.trim(),
      last_name: values.last_name.trim(),
      email: values.email.trim(),
    }
    if (values.phone_number?.trim()) input.phone_number = values.phone_number.trim()
    if (values.date_of_birth?.trim()) input.date_of_birth = values.date_of_birth.trim()
    if (values.bio?.trim()) input.bio = values.bio.trim()
    mutation.mutate(input)
  })

  if (!me) return null

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader title="Edit profile" />
      <PageContainer variant="narrow" className="mx-auto pb-12 pt-6">
        <Card>
          <form className="space-y-3 p-5 sm:p-6" onSubmit={onSubmit} noValidate>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <TextField
                label="First name"
                leftIcon={<UserIcon className="h-5 w-5" />}
                error={errors.first_name?.message}
                {...register('first_name')}
              />
              <TextField
                label="Last name"
                leftIcon={<UserIcon className="h-5 w-5" />}
                error={errors.last_name?.message}
                {...register('last_name')}
              />
            </div>
            <TextField
              label="Email"
              type="email"
              leftIcon={<Mail className="h-5 w-5" />}
              error={errors.email?.message}
              {...register('email')}
            />
            <TextField
              label="Phone number"
              leftIcon={<Phone className="h-5 w-5" />}
              error={errors.phone_number?.message}
              {...register('phone_number')}
            />
            <TextField
              label="Date of birth"
              type="date"
              leftIcon={<Calendar className="h-5 w-5" />}
              error={errors.date_of_birth?.message}
              {...register('date_of_birth')}
            />

            <div>
              <label
                htmlFor="bio"
                className="mb-1.5 block text-sm font-medium text-[var(--color-text-primary)]"
              >
                Bio
              </label>
              <div className="relative">
                <FileText className="pointer-events-none absolute left-3 top-3 h-5 w-5 text-[var(--color-text-light)]" />
                <textarea
                  id="bio"
                  rows={3}
                  className="w-full rounded-[10px] border border-[var(--color-input-border)] bg-[var(--color-input-fill)] py-3 pl-10 pr-3 text-sm text-[var(--color-text-primary)] outline-none focus:border-[var(--color-input-focus)] focus:bg-white"
                  {...register('bio')}
                />
              </div>
              {errors.bio?.message && (
                <p className="mt-1.5 text-xs text-[var(--color-error)]">
                  {errors.bio.message}
                </p>
              )}
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <Button variant="ghost" onClick={() => navigate('/profile')}>
                Cancel
              </Button>
              <Button
                type="submit"
                disabled={!isDirty || mutation.isPending}
                loading={mutation.isPending}
                className="px-6"
              >
                Save changes
              </Button>
            </div>
          </form>
        </Card>
      </PageContainer>
    </div>
  )
}
