import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Plus } from 'lucide-react'
import { evaluationsApi } from '@/services/api'

export default function Evaluations() {
  const { data: evaluations, isLoading } = useQuery({
    queryKey: ['evaluations'],
    queryFn: () => evaluationsApi.list().then(res => res.data),
  })

  if (isLoading) return <div>Loading...</div>

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Evaluations</h1>
          <p className="text-muted-foreground mt-2">Run and view LLM evaluations</p>
        </div>
        <Button>
          <Plus className="mr-2 h-4 w-4" />
          New Evaluation
        </Button>
      </div>

      <div className="grid gap-6">
        {evaluations && evaluations.length > 0 ? (
          evaluations.map((evaluation: any) => (
            <Card key={evaluation.id}>
              <CardHeader>
                <div className="flex justify-between items-start">
                  <div>
                    <CardTitle>Evaluation {evaluation.id.slice(0, 8)}</CardTitle>
                    <CardDescription>Type: {evaluation.eval_type}</CardDescription>
                  </div>
                  <span className={`px-3 py-1 rounded-full text-sm ${
                    evaluation.status === 'completed' ? 'bg-green-100 text-green-800' :
                    evaluation.status === 'running' ? 'bg-blue-100 text-blue-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {evaluation.status}
                  </span>
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground">
                  Created: {new Date(evaluation.created_at).toLocaleString()}
                </p>
              </CardContent>
            </Card>
          ))
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground">No evaluations yet.</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}


