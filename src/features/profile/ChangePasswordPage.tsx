/**
 * ChangePasswordPage — PUT /users/change-password.
 */
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { Lock } from 'lucide-react'
import toast from 'react-hot-toast'

import { ScreenHeader } from '../../components/ScreenHeader'
import { PageContainer } from '../../components/PageContainer'
import { Card } from '../../components/Card'
import { Button } from '../../components/Button'
import { TextField } from '../../components/TextField'
import { changePassword } from '../../api/users'

const schema = z
  .object({
    current_password: z.string().min(1, 'Current password is required'),
    new_password: z.string().min(6, 'New password must be at least 6 characters'),
    new_password_confirmation: z.string(),
  })
  .refine((v) => v.new_password === v.new_password_confirmation, {
    message: 'New passwords do not match',
    path: ['new_password_confirmation'],
  })
type FormValues = z.infer<typeof schema>

export function ChangePasswordPage() {
  const navigate = useNavigate()
  const mutation = useMutation({
    mutationFn: (input: FormValues) => changePassword(input),
    onSuccess: () => {
      toast.success('Password changed')
      navigate('/profile')
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : 'Failed to change password')
    },
  })
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { current_password: '', new_password: '', new_password_confirmation: '' },
  })
  const onSubmit = handleSubmit((values) => mutation.mutate(values))

  return (
    <div className="min-h-screen bg-white">
      <ScreenHeader title="Change password" />
      <PageContainer variant="narrow" className="mx-auto pb-12 pt-6">
        <Card>
          <form className="space-y-3 p-5 sm:p-6" onSubmit={onSubmit} noValidate>
            <TextField
              label="Current password"
              type="password"
              autoComplete="current-password"
              leftIcon={<Lock className="h-5 w-5" />}
              error={errors.current_password?.message}
              {...register('current_password')}
            />
            <TextField
              label="New password"
              type="password"
              autoComplete="new-password"
              leftIcon={<Lock className="h-5 w-5" />}
              error={errors.new_password?.message}
              {...register('new_password')}
            />
            <TextField
              label="Confirm new password"
              type="password"
              autoComplete="new-password"
              leftIcon={<Lock className="h-5 w-5" />}
              error={errors.new_password_confirmation?.message}
              {...register('new_password_confirmation')}
            />
            <div className="flex items-center justify-end gap-3 pt-2">
              <Button variant="ghost" onClick={() => navigate('/profile')}>
                Cancel
              </Button>
              <Button
                type="submit"
                loading={mutation.isPending}
                className="px-6"
              >
                Change password
              </Button>
            </div>
          </form>
        </Card>
      </PageContainer>
    </div>
  )
}
