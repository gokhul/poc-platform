import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Plus, Trash2 } from 'lucide-react'
import { modelsApi } from '@/services/api'

export default function Models() {
  const queryClient = useQueryClient()
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [newModel, setNewModel] = useState({
    provider: 'openai',
    model_name: 'gpt-4',
    project_id: '00000000-0000-0000-0000-000000000000',
    config: { temperature: 0.7, max_tokens: 2000 },
  })

  const { data: models, isLoading } = useQuery({
    queryKey: ['models'],
    queryFn: () => modelsApi.list().then(res => res.data),
  })

  const createMutation = useMutation({
    mutationFn: (data: any) => modelsApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['models'] })
      setShowCreateForm(false)
    },
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => modelsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['models'] })
    },
  })

  if (isLoading) return <div>Loading...</div>

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Model Configurations</h1>
          <p className="text-muted-foreground mt-2">Manage your LLM model configurations</p>
        </div>
        <Button onClick={() => setShowCreateForm(!showCreateForm)}>
          <Plus className="mr-2 h-4 w-4" />
          New Model
        </Button>
      </div>

      {showCreateForm && (
        <Card>
          <CardHeader>
            <CardTitle>Create Model Configuration</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2">Provider</label>
                  <select
                    value={newModel.provider}
                    onChange={(e) => setNewModel({ ...newModel, provider: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  >
                    <option value="openai">OpenAI</option>
                    <option value="anthropic">Anthropic</option>
                    <option value="google">Google</option>
                    <option value="mistral">Mistral</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium mb-2">Model Name</label>
                  <input
                    type="text"
                    value={newModel.model_name}
                    onChange={(e) => setNewModel({ ...newModel, model_name: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  />
                </div>
              </div>
              <div className="flex space-x-2">
                <Button onClick={() => createMutation.mutate(newModel)}>Create</Button>
                <Button variant="outline" onClick={() => setShowCreateForm(false)}>Cancel</Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {models && models.length > 0 ? (
          models.map((model: any) => (
            <Card key={model.id}>
              <CardHeader>
                <CardTitle>{model.model_name}</CardTitle>
                <CardDescription>Provider: {model.provider}</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <p className="text-sm"><strong>Status:</strong> {model.is_active ? 'Active' : 'Inactive'}</p>
                  <div className="flex justify-end">
                    <Button
                      variant="destructive"
                      size="sm"
                      onClick={() => deleteMutation.mutate(model.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        ) : (
          <Card className="col-span-full">
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground">No models configured yet.</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}


