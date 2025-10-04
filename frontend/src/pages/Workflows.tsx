import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Plus, Workflow } from 'lucide-react'
import { workflowsApi } from '@/services/api'
import WorkflowBuilder from '@/components/WorkflowBuilder'

export default function Workflows() {
  const [activeTab, setActiveTab] = useState('list')
  
  const { data: workflows, isLoading } = useQuery({
    queryKey: ['workflows'],
    queryFn: () => workflowsApi.list().then(res => res.data),
  })

  if (isLoading) return <div>Loading...</div>

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Workflows</h1>
          <p className="text-muted-foreground mt-2">Create and manage LangGraph workflows</p>
        </div>
        <Button onClick={() => setActiveTab('builder')}>
          <Plus className="mr-2 h-4 w-4" />
          New Workflow
        </Button>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList>
          <TabsTrigger value="list">All Workflows</TabsTrigger>
          <TabsTrigger value="builder">Workflow Builder</TabsTrigger>
        </TabsList>
        
        <TabsContent value="list" className="space-y-4">
          <div className="grid gap-6">
            {workflows && workflows.length > 0 ? (
              workflows.map((workflow: any) => (
                <Card key={workflow.id}>
                  <CardHeader>
                    <div className="flex justify-between items-start">
                      <div>
                        <CardTitle>{workflow.name}</CardTitle>
                        <CardDescription>Version {workflow.version}</CardDescription>
                      </div>
                      <div className="flex space-x-2">
                        <Button 
                          size="sm" 
                          onClick={() => setActiveTab('builder')}
                        >
                          <Workflow className="mr-2 h-4 w-4" />
                          Edit
                        </Button>
                        <Button size="sm">Execute</Button>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-muted-foreground">
                      Created: {new Date(workflow.created_at).toLocaleString()}
                    </p>
                  </CardContent>
                </Card>
              ))
            ) : (
              <Card>
                <CardContent className="py-12 text-center">
                  <Workflow className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
                  <p className="text-muted-foreground mb-4">No workflows yet.</p>
                  <Button onClick={() => setActiveTab('builder')}>
                    <Plus className="mr-2 h-4 w-4" />
                    Create Your First Workflow
                  </Button>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>
        
        <TabsContent value="builder" className="space-y-4">
          <WorkflowBuilder />
        </TabsContent>
      </Tabs>
    </div>
  )
}


