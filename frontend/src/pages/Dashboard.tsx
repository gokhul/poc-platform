import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Activity, Cpu, FileText, TrendingUp } from 'lucide-react'
import { projectsApi, requestsApi } from '@/services/api'

export default function Dashboard() {
  const { data: projects } = useQuery({
    queryKey: ['projects'],
    queryFn: () => projectsApi.list().then(res => res.data),
  })

  const { data: requests } = useQuery({
    queryKey: ['requests'],
    queryFn: () => requestsApi.list().then(res => res.data),
  })

  const stats = [
    {
      name: 'Total Projects',
      value: projects?.length || 0,
      icon: FileText,
      change: '+12%',
    },
    {
      name: 'Total Requests',
      value: requests?.length || 0,
      icon: Activity,
      change: '+23%',
    },
    {
      name: 'Active Models',
      value: '5',
      icon: Cpu,
      change: '+5%',
    },
    {
      name: 'Success Rate',
      value: '98.5%',
      icon: TrendingUp,
      change: '+2.3%',
    },
  ]

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Welcome to LLM Platform</h1>
        <p className="text-muted-foreground mt-2">
          Manage your LLM operations, track performance, and optimize your AI workflows.
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.name}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.name}
              </CardTitle>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <p className="text-xs text-green-600 mt-1">
                {stat.change} from last month
              </p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Recent Projects</CardTitle>
          </CardHeader>
          <CardContent>
            {projects && projects.length > 0 ? (
              <div className="space-y-4">
                {projects.slice(0, 5).map((project: any) => (
                  <div key={project.id} className="flex items-center justify-between">
                    <div>
                      <p className="font-medium">{project.name}</p>
                      <p className="text-sm text-muted-foreground">{project.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No projects yet. Create your first project to get started.</p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recent Requests</CardTitle>
          </CardHeader>
          <CardContent>
            {requests && requests.length > 0 ? (
              <div className="space-y-4">
                {requests.slice(0, 5).map((request: any) => (
                  <div key={request.id} className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium">{request.status}</p>
                      <p className="text-xs text-muted-foreground">
                        {request.latency_ms}ms • {request.input_tokens} tokens
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No requests yet.</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}


