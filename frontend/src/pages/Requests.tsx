import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Send } from 'lucide-react'
import { requestsApi } from '@/services/api'

export default function Requests() {
  const queryClient = useQueryClient()
  const [showTestForm, setShowTestForm] = useState(false)
  const [testRequest, setTestRequest] = useState({
    project_id: '00000000-0000-0000-0000-000000000000',
    model: 'gpt-4',
    messages: [{ role: 'user', content: 'Hello, how are you?' }],
  })
  const [response, setResponse] = useState<any>(null)

  const { data: requests, isLoading } = useQuery({
    queryKey: ['requests'],
    queryFn: () => requestsApi.list().then(res => res.data),
  })

  const completeMutation = useMutation({
    mutationFn: (data: any) => requestsApi.complete(data),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['requests'] })
      setResponse(data.data)
    },
  })

  if (isLoading) return <div>Loading...</div>

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">LLM Requests</h1>
          <p className="text-muted-foreground mt-2">View and test LLM requests</p>
        </div>
        <Button onClick={() => setShowTestForm(!showTestForm)}>
          <Send className="mr-2 h-4 w-4" />
          Test Request
        </Button>
      </div>

      {showTestForm && (
        <Card>
          <CardHeader>
            <CardTitle>Test LLM Request</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-2">Model</label>
                <input
                  type="text"
                  value={testRequest.model}
                  onChange={(e) => setTestRequest({ ...testRequest, model: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Message</label>
                <textarea
                  value={testRequest.messages[0].content}
                  onChange={(e) => setTestRequest({
                    ...testRequest,
                    messages: [{ role: 'user', content: e.target.value }]
                  })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  rows={4}
                />
              </div>
              <div className="flex space-x-2">
                <Button 
                  onClick={() => completeMutation.mutate(testRequest)}
                  disabled={completeMutation.isPending}
                >
                  {completeMutation.isPending ? 'Sending...' : 'Send Request'}
                </Button>
                <Button variant="outline" onClick={() => setShowTestForm(false)}>Cancel</Button>
              </div>
              
              {response && (
                <div className="mt-4 p-4 bg-gray-50 rounded-md">
                  <h3 className="font-semibold mb-2">Response:</h3>
                  <p className="text-sm whitespace-pre-wrap">{response.content}</p>
                  <div className="mt-3 pt-3 border-t text-xs text-muted-foreground">
                    Latency: {response.latency_ms}ms | Tokens: {response.usage?.total_tokens}
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      <div className="space-y-4">
        {requests && requests.length > 0 ? (
          requests.map((request: any) => (
            <Card key={request.id}>
              <CardContent className="py-4">
                <div className="flex justify-between items-center">
                  <div className="space-y-1">
                    <p className="text-sm font-medium">Request ID: {request.id}</p>
                    <p className="text-sm text-muted-foreground">
                      Status: {request.status} | Latency: {request.latency_ms}ms | 
                      Tokens: {request.input_tokens + request.output_tokens}
                    </p>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    {new Date(request.created_at).toLocaleString()}
                  </p>
                </div>
              </CardContent>
            </Card>
          ))
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground">No requests yet. Test your first request above.</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}


