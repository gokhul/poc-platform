import axios from 'axios'

const API_BASE_URL = '/api'

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Projects
export const projectsApi = {
  list: (organizationId?: string) => 
    api.get('/projects', { params: { organization_id: organizationId } }),
  get: (id: string) => api.get(`/projects/${id}`),
  create: (data: any) => api.post('/projects', data),
  update: (id: string, data: any) => api.patch(`/projects/${id}`, data),
  delete: (id: string) => api.delete(`/projects/${id}`),
}

// Models
export const modelsApi = {
  list: (projectId?: string) => 
    api.get('/models', { params: { project_id: projectId } }),
  get: (id: string) => api.get(`/models/${id}`),
  create: (data: any) => api.post('/models', data),
  delete: (id: string) => api.delete(`/models/${id}`),
}

// Prompts
export const promptsApi = {
  list: (projectId?: string) => 
    api.get('/prompts', { params: { project_id: projectId } }),
  get: (id: string) => api.get(`/prompts/${id}`),
  create: (data: any) => api.post('/prompts', data),
  getVersions: (projectId: string, name: string) => 
    api.get(`/prompts/by-name/${projectId}/${name}`),
}

// Requests
export const requestsApi = {
  list: (projectId?: string, limit = 100) => 
    api.get('/requests', { params: { project_id: projectId, limit } }),
  get: (id: string) => api.get(`/requests/${id}`),
  complete: (data: any) => api.post('/requests/complete', data),
}

// Evaluations
export const evaluationsApi = {
  list: (projectId?: string) => 
    api.get('/evaluations', { params: { project_id: projectId } }),
  get: (id: string) => api.get(`/evaluations/${id}`),
  create: (data: any) => api.post('/evaluations', data),
  getResults: (id: string) => api.get(`/evaluations/${id}/results`),
}

// Datasets
export const datasetsApi = {
  list: (projectId?: string) => 
    api.get('/datasets', { params: { project_id: projectId } }),
  create: (data: any) => api.post('/datasets', data),
  addItem: (datasetId: string, data: any) => 
    api.post(`/datasets/${datasetId}/items`, data),
  getItems: (datasetId: string) => 
    api.get(`/datasets/${datasetId}/items`),
}

// Workflows
export const workflowsApi = {
  list: (projectId?: string) => 
    api.get('/workflows', { params: { project_id: projectId } }),
  create: (data: any) => api.post('/workflows', data),
  execute: (id: string, data: any) => 
    api.post(`/workflows/${id}/execute`, data),
  getExecutions: (id: string) => 
    api.get(`/workflows/${id}/executions`),
}


