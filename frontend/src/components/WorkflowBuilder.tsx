import React, { useState, useCallback, useRef, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Badge } from '@/components/ui/badge'
import { 
  Plus, 
  Play, 
  Save, 
  Trash2, 
  Settings, 
  Code, 
  Brain, 
  GitBranch,
  Eye,
  Download,
  Upload
} from 'lucide-react'

interface Node {
  id: string
  type: 'llm' | 'function' | 'condition'
  label: string
  x: number
  y: number
  config: any
}

interface Edge {
  id: string
  from: string
  to: string
  condition?: string
}

interface WorkflowData {
  name: string
  description: string
  nodes: Node[]
  edges: Edge[]
}

const WorkflowBuilder: React.FC = () => {
  const [workflowData, setWorkflowData] = useState<WorkflowData>({
    name: '',
    description: '',
    nodes: [],
    edges: []
  })
  
  const [selectedNode, setSelectedNode] = useState<Node | null>(null)
  const [isExecuting, setIsExecuting] = useState(false)
  const [executionResult, setExecutionResult] = useState<any>(null)
  const canvasRef = useRef<HTMLDivElement>(null)
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 })

  // Node types configuration
  const nodeTypes = [
    { type: 'llm', label: 'LLM', icon: Brain, color: 'bg-blue-500' },
    { type: 'function', label: 'Function', icon: Code, color: 'bg-green-500' },
    { type: 'condition', label: 'Condition', icon: GitBranch, color: 'bg-yellow-500' }
  ]

  const addNode = (type: 'llm' | 'function' | 'condition') => {
    const newNode: Node = {
      id: `node_${Date.now()}`,
      type,
      label: `New ${type}`,
      x: 100 + Math.random() * 200,
      y: 100 + Math.random() * 200,
      config: getDefaultConfig(type)
    }
    
    setWorkflowData(prev => ({
      ...prev,
      nodes: [...prev.nodes, newNode]
    }))
  }

  const getDefaultConfig = (type: string) => {
    switch (type) {
      case 'llm':
        return {
          model: 'gpt-3.5-turbo',
          temperature: 0.7,
          prompt: 'You are a helpful assistant.'
        }
      case 'function':
        return {
          code: '# Custom function code\nresult = {"output": "Hello from function!"}'
        }
      case 'condition':
        return {
          condition: '# Condition logic\nresult = "yes" if state.get("value") > 0 else "no"'
        }
      default:
        return {}
    }
  }

  const updateNode = (nodeId: string, updates: Partial<Node>) => {
    setWorkflowData(prev => ({
      ...prev,
      nodes: prev.nodes.map(node => 
        node.id === nodeId ? { ...node, ...updates } : node
      )
    }))
  }

  const deleteNode = (nodeId: string) => {
    setWorkflowData(prev => ({
      ...prev,
      nodes: prev.nodes.filter(node => node.id !== nodeId),
      edges: prev.edges.filter(edge => edge.from !== nodeId && edge.to !== nodeId)
    }))
    setSelectedNode(null)
  }

  const addEdge = (fromNodeId: string, toNodeId: string) => {
    const newEdge: Edge = {
      id: `edge_${Date.now()}`,
      from: fromNodeId,
      to: toNodeId
    }
    
    setWorkflowData(prev => ({
      ...prev,
      edges: [...prev.edges, newEdge]
    }))
  }

  const handleMouseDown = (e: React.MouseEvent, node: Node) => {
    e.preventDefault()
    const rect = canvasRef.current?.getBoundingClientRect()
    if (rect) {
      setDragOffset({
        x: e.clientX - rect.left - node.x,
        y: e.clientY - rect.top - node.y
      })
    }
  }

  const handleMouseMove = useCallback((e: MouseEvent) => {
    if (selectedNode && dragOffset) {
      const rect = canvasRef.current?.getBoundingClientRect()
      if (rect) {
        const newX = e.clientX - rect.left - dragOffset.x
        const newY = e.clientY - rect.top - dragOffset.y
        
        updateNode(selectedNode.id, { x: newX, y: newY })
      }
    }
  }, [selectedNode, dragOffset])

  useEffect(() => {
    document.addEventListener('mousemove', handleMouseMove)
    return () => document.removeEventListener('mousemove', handleMouseMove)
  }, [handleMouseMove])

  const saveWorkflow = async () => {
    try {
      const response = await fetch('/api/workflows/langgraph/create', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: workflowData.name,
          description: workflowData.description,
          nodes: workflowData.nodes.map(node => ({
            id: node.id,
            type: node.type,
            label: node.label,
            config: node.config
          })),
          edges: workflowData.edges
        })
      })

      if (response.ok) {
        alert('Workflow saved successfully!')
      } else {
        throw new Error('Failed to save workflow')
      }
    } catch (error) {
      console.error('Error saving workflow:', error)
      alert('Failed to save workflow')
    }
  }

  const executeWorkflow = async () => {
    if (!workflowData.name) {
      alert('Please provide a workflow name')
      return
    }

    setIsExecuting(true)
    try {
      const response = await fetch(`/api/workflows/langgraph/${workflowData.name}/execute`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          input: { message: "Hello, workflow!" }
        })
      })

      const result = await response.json()
      setExecutionResult(result)
    } catch (error) {
      console.error('Error executing workflow:', error)
      alert('Failed to execute workflow')
    } finally {
      setIsExecuting(false)
    }
  }

  const exportWorkflow = () => {
    const dataStr = JSON.stringify(workflowData, null, 2)
    const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr)
    
    const exportFileDefaultName = `${workflowData.name || 'workflow'}.json`
    
    const linkElement = document.createElement('a')
    linkElement.setAttribute('href', dataUri)
    linkElement.setAttribute('download', exportFileDefaultName)
    linkElement.click()
  }

  const importWorkflow = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        try {
          const importedData = JSON.parse(e.target?.result as string)
          setWorkflowData(importedData)
        } catch (error) {
          alert('Invalid workflow file')
        }
      }
      reader.readAsText(file)
    }
  }

  return (
    <div className="h-screen flex flex-col">
      {/* Header */}
      <div className="border-b p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <h1 className="text-2xl font-bold">Workflow Builder</h1>
            <div className="flex items-center space-x-2">
              <Input
                placeholder="Workflow name"
                value={workflowData.name}
                onChange={(e) => setWorkflowData(prev => ({ ...prev, name: e.target.value }))}
                className="w-64"
              />
            </div>
          </div>
          
          <div className="flex items-center space-x-2">
            <Button onClick={exportWorkflow} variant="outline" size="sm">
              <Download className="h-4 w-4 mr-2" />
              Export
            </Button>
            
            <label>
              <Button variant="outline" size="sm" asChild>
                <span>
                  <Upload className="h-4 w-4 mr-2" />
                  Import
                </span>
              </Button>
              <input
                type="file"
                accept=".json"
                onChange={importWorkflow}
                className="hidden"
              />
            </label>
            
            <Button onClick={saveWorkflow} variant="outline" size="sm">
              <Save className="h-4 w-4 mr-2" />
              Save
            </Button>
            
            <Button 
              onClick={executeWorkflow} 
              disabled={isExecuting || !workflowData.name}
              size="sm"
            >
              <Play className="h-4 w-4 mr-2" />
              {isExecuting ? 'Executing...' : 'Execute'}
            </Button>
          </div>
        </div>
      </div>

      <div className="flex flex-1">
        {/* Sidebar */}
        <div className="w-80 border-r p-4 space-y-4">
          <div>
            <Label>Description</Label>
            <Textarea
              placeholder="Describe your workflow..."
              value={workflowData.description}
              onChange={(e) => setWorkflowData(prev => ({ ...prev, description: e.target.value }))}
              rows={3}
            />
          </div>

          {/* Node Types */}
          <div>
            <Label>Add Nodes</Label>
            <div className="space-y-2 mt-2">
              {nodeTypes.map(({ type, label, icon: Icon, color }) => (
                <Button
                  key={type}
                  variant="outline"
                  size="sm"
                  className="w-full justify-start"
                  onClick={() => addNode(type as any)}
                >
                  <div className={`w-3 h-3 rounded-full ${color} mr-2`} />
                  <Icon className="h-4 w-4 mr-2" />
                  {label}
                </Button>
              ))}
            </div>
          </div>

          {/* Node Properties */}
          {selectedNode && (
            <div className="border-t pt-4">
              <div className="flex items-center justify-between mb-2">
                <Label>Node Properties</Label>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => deleteNode(selectedNode.id)}
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
              
              <div className="space-y-2">
                <Input
                  placeholder="Node label"
                  value={selectedNode.label}
                  onChange={(e) => updateNode(selectedNode.id, { label: e.target.value })}
                />
                
                {selectedNode.type === 'llm' && (
                  <div className="space-y-2">
                    <Select
                      value={selectedNode.config.model}
                      onValueChange={(value) => updateNode(selectedNode.id, {
                        config: { ...selectedNode.config, model: value }
                      })}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Select model" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="gpt-3.5-turbo">GPT-3.5 Turbo</SelectItem>
                        <SelectItem value="gpt-4">GPT-4</SelectItem>
                        <SelectItem value="gpt-4-turbo">GPT-4 Turbo</SelectItem>
                      </SelectContent>
                    </Select>
                    
                    <div>
                      <Label>Temperature</Label>
                      <Input
                        type="number"
                        min="0"
                        max="2"
                        step="0.1"
                        value={selectedNode.config.temperature}
                        onChange={(e) => updateNode(selectedNode.id, {
                          config: { ...selectedNode.config, temperature: parseFloat(e.target.value) }
                        })}
                      />
                    </div>
                    
                    <div>
                      <Label>Prompt</Label>
                      <Textarea
                        value={selectedNode.config.prompt}
                        onChange={(e) => updateNode(selectedNode.id, {
                          config: { ...selectedNode.config, prompt: e.target.value }
                        })}
                        rows={3}
                      />
                    </div>
                  </div>
                )}
                
                {(selectedNode.type === 'function' || selectedNode.type === 'condition') && (
                  <div>
                    <Label>{selectedNode.type === 'function' ? 'Code' : 'Condition'}</Label>
                    <Textarea
                      value={selectedNode.config.code || selectedNode.config.condition}
                      onChange={(e) => updateNode(selectedNode.id, {
                        config: { ...selectedNode.config, [selectedNode.type === 'function' ? 'code' : 'condition']: e.target.value }
                      })}
                      rows={6}
                      className="font-mono text-sm"
                    />
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        {/* Canvas */}
        <div className="flex-1 flex flex-col">
          <div
            ref={canvasRef}
            className="flex-1 relative bg-gray-50 overflow-hidden"
            style={{ minHeight: '500px' }}
          >
            {/* SVG for edges */}
            <svg className="absolute inset-0 w-full h-full pointer-events-none">
              {workflowData.edges.map(edge => {
                const fromNode = workflowData.nodes.find(n => n.id === edge.from)
                const toNode = workflowData.nodes.find(n => n.id === edge.to)
                
                if (!fromNode || !toNode) return null
                
                return (
                  <line
                    key={edge.id}
                    x1={fromNode.x + 60}
                    y1={fromNode.y + 30}
                    x2={toNode.x + 60}
                    y2={toNode.y + 30}
                    stroke="#6b7280"
                    strokeWidth="2"
                    markerEnd="url(#arrowhead)"
                  />
                )
              })}
              <defs>
                <marker
                  id="arrowhead"
                  markerWidth="10"
                  markerHeight="7"
                  refX="9"
                  refY="3.5"
                  orient="auto"
                >
                  <polygon points="0 0, 10 3.5, 0 7" fill="#6b7280" />
                </marker>
              </defs>
            </svg>

            {/* Nodes */}
            {workflowData.nodes.map(node => {
              const nodeType = nodeTypes.find(nt => nt.type === node.type)
              const Icon = nodeType?.icon || Code
              const color = nodeType?.color || 'bg-gray-500'
              
              return (
                <div
                  key={node.id}
                  className={`absolute w-32 h-16 rounded-lg border-2 cursor-move ${
                    selectedNode?.id === node.id ? 'border-blue-500 shadow-lg' : 'border-gray-300'
                  } ${color} text-white flex items-center justify-center space-x-2`}
                  style={{ left: node.x, top: node.y }}
                  onMouseDown={(e) => handleMouseDown(e, node)}
                  onClick={() => setSelectedNode(node)}
                >
                  <Icon className="h-4 w-4" />
                  <span className="text-xs font-medium truncate">{node.label}</span>
                </div>
              )
            })}
          </div>

          {/* Execution Results */}
          {executionResult && (
            <div className="border-t p-4">
              <h3 className="font-semibold mb-2">Execution Result</h3>
              <pre className="bg-gray-100 p-3 rounded text-sm overflow-auto max-h-32">
                {JSON.stringify(executionResult, null, 2)}
              </pre>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default WorkflowBuilder
