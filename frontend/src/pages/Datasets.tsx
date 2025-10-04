import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Plus } from 'lucide-react'
import { datasetsApi } from '@/services/api'

export default function Datasets() {
  const { data: datasets, isLoading } = useQuery({
    queryKey: ['datasets'],
    queryFn: () => datasetsApi.list().then(res => res.data),
  })

  if (isLoading) return <div>Loading...</div>

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Datasets</h1>
          <p className="text-muted-foreground mt-2">Manage training and evaluation datasets</p>
        </div>
        <Button>
          <Plus className="mr-2 h-4 w-4" />
          New Dataset
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {datasets && datasets.length > 0 ? (
          datasets.map((dataset: any) => (
            <Card key={dataset.id}>
              <CardHeader>
                <CardTitle>{dataset.name}</CardTitle>
                <CardDescription>{dataset.type}</CardDescription>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground">{dataset.description}</p>
                <p className="text-xs text-muted-foreground mt-2">
                  Created: {new Date(dataset.created_at).toLocaleDateString()}
                </p>
              </CardContent>
            </Card>
          ))
        ) : (
          <Card className="col-span-full">
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground">No datasets yet.</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}


