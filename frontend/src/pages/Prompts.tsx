import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Plus } from 'lucide-react'
import { promptsApi } from '@/services/api'

export default function Prompts() {
  const queryClient = useQueryClient()
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [newPrompt, setNewPrompt] = useState({
    name: '',
    template: '',
    project_id: '00000000-0000-0000-0000-000000000000',
  })

  const { data: prompts, isLoading } = useQuery({
    queryKey: ['prompts'],
    queryFn: () => promptsApi.list().then(res => res.data),
  })

  const createMutation = useMutation({
    mutationFn: (data: any) => promptsApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['prompts'] })
      setShowCreateForm(false)
      setNewPrompt({ name: '', template: '', project_id: '00000000-0000-0000-0000-000000000000' })
    },
  })

  if (isLoading) return <div>Loading...</div>

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Prompt Templates</h1>
          <p className="text-muted-foreground mt-2">Manage your prompt templates and versions</p>
        </div>
        <Button onClick={() => setShowCreateForm(!showCreateForm)}>
          <Plus className="mr-2 h-4 w-4" />
          New Prompt
        </Button>
      </div>

      {showCreateForm && (
        <Card>
          <CardHeader>
            <CardTitle>Create Prompt Template</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-2">Name</label>
                <input
                  type="text"
                  value={newPrompt.name}
                  onChange={(e) => setNewPrompt({ ...newPrompt, name: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  placeholder="customer-support-prompt"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Template</label>
                <textarea
                  value={newPrompt.template}
                  onChange={(e) => setNewPrompt({ ...newPrompt, template: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md font-mono text-sm"
                  rows={6}
                  placeholder="You are a helpful assistant. User question: {question}"
                />
              </div>
              <div className="flex space-x-2">
                <Button onClick={() => createMutation.mutate(newPrompt)}>Create</Button>
                <Button variant="outline" onClick={() => setShowCreateForm(false)}>Cancel</Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      <div className="grid gap-6">
        {prompts && prompts.length > 0 ? (
          prompts.map((prompt: any) => (
            <Card key={prompt.id}>
              <CardHeader>
                <div className="flex justify-between items-start">
                  <div>
                    <CardTitle>{prompt.name}</CardTitle>
                    <CardDescription>Version {prompt.version}</CardDescription>
                  </div>
                  <span className="text-sm text-muted-foreground">
                    {new Date(prompt.created_at).toLocaleDateString()}
                  </span>
                </div>
              </CardHeader>
              <CardContent>
                <pre className="bg-gray-50 p-4 rounded-md text-sm overflow-x-auto">
                  {prompt.template}
                </pre>
              </CardContent>
            </Card>
          ))
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground">No prompts created yet.</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}


