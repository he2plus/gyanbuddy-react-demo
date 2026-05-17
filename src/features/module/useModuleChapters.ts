import { useQuery } from '@tanstack/react-query'
import { getModuleChapters, getSubjectModules } from '../../api/modules'

export function useModuleChapters(moduleId: string | undefined) {
  return useQuery({
    queryKey: ['modules', moduleId, 'chapters'],
    queryFn: () => getModuleChapters(moduleId!),
    enabled: !!moduleId,
    staleTime: 60_000,
  })
}

export function useSubjectModules(subjectId: string | undefined) {
  return useQuery({
    queryKey: ['subjects', subjectId, 'modules'],
    queryFn: () => getSubjectModules(subjectId!),
    enabled: !!subjectId,
    staleTime: 60_000,
  })
}
