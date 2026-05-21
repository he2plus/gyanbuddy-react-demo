/**
 * SubjectDetailPage — superseded by the new accordion view on /subjects.
 *
 * Any deep link or navigation to /subjects/{subjectId} now immediately
 * redirects to /subjects?expand={subjectId}, which lands on the new list
 * with that subject expanded.
 */
import { Navigate, useParams } from 'react-router-dom'

export function SubjectDetailPage() {
  const { subjectId } = useParams<{ subjectId: string }>()
  const target = subjectId ? `/subjects?expand=${subjectId}` : '/subjects'
  return <Navigate to={target} replace />
}
