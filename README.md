# LLM Platform - Comprehensive LLM Operations Platform

A unified platform for managing all aspects of LLM operations, including model management, prompt engineering, observability, evaluations, and deployments.

## Features

- **Project Management**: Organize your LLM work into projects
- **Model Configuration**: Configure and manage multiple LLM providers (OpenAI, Anthropic, Google, etc.)
- **Prompt Management**: Version control for prompts with template support
- **Request Tracking**: Monitor all LLM requests with detailed metrics
- **Evaluations**: Run Ragas and DeepEval evaluations on your models
- **Datasets**: Manage training and evaluation datasets
- **Workflows**: Create and execute LangGraph workflows
- **Observability**: Integrated with Langfuse for complete tracing
- **Vector Storage**: Qdrant integration for embeddings and RAG

## Tech Stack

### Backend
- **FastAPI**: Python web framework
- **PostgreSQL**: Primary database with pgvector extension
- **SQLAlchemy**: ORM with async support
- **LiteLLM**: Unified LLM gateway
- **Langfuse**: Observability and tracing
- **Qdrant**: Vector database
- **Redis**: Caching layer

### Frontend
- **React 18**: UI framework
- **TypeScript**: Type safety
- **Vite**: Build tool
- **TailwindCSS**: Styling
- **shadcn/ui**: Component library
- **React Query**: Data fetching
- **Zustand**: State management

### Infrastructure
- **Docker Compose**: Local development
- **Prometheus**: Metrics
- **Grafana**: Dashboards
- **MinIO**: Object storage

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 20+ (for local frontend development)
- Python 3.11+ (for local backend development)

### Launch the Platform

1. Start all services:
```bash
docker-compose up -d
```

2. Wait for services to initialize (about 30 seconds)

3. Access the platform:
   - **Frontend**: http://localhost:5173
   - **API Docs**: http://localhost:8000/api/docs
   - **Langfuse**: http://localhost:3000
   - **Grafana**: http://localhost:3001 (admin/admin)
   - **Prometheus**: http://localhost:9090
   - **MinIO**: http://localhost:9001 (minioadmin/minioadmin)

### First Steps

1. **Create a Project**:
   - Navigate to the Projects page
   - Click "New Project"
   - Fill in project details

2. **Configure a Model**:
   - Go to Models page
   - Add a model configuration (e.g., OpenAI GPT-4)

3. **Create a Prompt**:
   - Visit Prompts page
   - Create a versioned prompt template

4. **Test a Request**:
   - Go to Requests page
   - Click "Test Request"
   - Send your first LLM request

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   React     │─────▶│   FastAPI    │─────▶│  PostgreSQL │
│  Frontend   │      │   Backend    │      │  + pgvector │
└─────────────┘      └──────────────┘      └─────────────┘
                            │
                            ├─────▶ LiteLLM (Model Gateway)
                            ├─────▶ Langfuse (Observability)
                            ├─────▶ Qdrant (Vector DB)
                            ├─────▶ Redis (Cache)
                            └─────▶ MinIO (Storage)
```

## Development

### Backend Development

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn api.main:app --reload
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev
```

## API Endpoints

### Projects
- `GET /api/projects` - List projects
- `POST /api/projects` - Create project
- `GET /api/projects/{id}` - Get project
- `PATCH /api/projects/{id}` - Update project
- `DELETE /api/projects/{id}` - Delete project

### Models
- `GET /api/models` - List model configs
- `POST /api/models` - Create model config
- `GET /api/models/{id}` - Get model config
- `DELETE /api/models/{id}` - Delete model config

### Prompts
- `GET /api/prompts` - List prompts
- `POST /api/prompts` - Create prompt
- `GET /api/prompts/{id}` - Get prompt
- `GET /api/prompts/by-name/{project_id}/{name}` - Get prompt versions

### Requests
- `GET /api/requests` - List requests
- `POST /api/requests/complete` - Create completion
- `GET /api/requests/{id}` - Get request

### Evaluations
- `GET /api/evaluations` - List evaluations
- `POST /api/evaluations` - Create evaluation
- `GET /api/evaluations/{id}` - Get evaluation
- `GET /api/evaluations/{id}/results` - Get results

### Datasets
- `GET /api/datasets` - List datasets
- `POST /api/datasets` - Create dataset
- `POST /api/datasets/{id}/items` - Add item
- `GET /api/datasets/{id}/items` - List items

### Workflows
- `GET /api/workflows` - List workflows
- `POST /api/workflows` - Create workflow
- `POST /api/workflows/{id}/execute` - Execute workflow
- `GET /api/workflows/{id}/executions` - List executions

## Configuration

### Environment Variables

Key environment variables (see `.env` file):

- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `LANGFUSE_PUBLIC_KEY`: Langfuse public key
- `LANGFUSE_SECRET_KEY`: Langfuse secret key
- `QDRANT_HOST`: Qdrant host
- `SECRET_KEY`: JWT secret key

### LLM Provider Configuration

To use LiteLLM with actual LLM providers, set environment variables:

```bash
# OpenAI
OPENAI_API_KEY=your-key

# Anthropic
ANTHROPIC_API_KEY=your-key

# Google
GOOGLE_API_KEY=your-key
```

## Monitoring

- **Prometheus metrics**: Available at `/metrics` endpoint
- **Grafana dashboards**: Pre-configured at http://localhost:3001
- **Langfuse traces**: View all LLM calls at http://localhost:3000

## Troubleshooting

### Services not starting

```bash
docker-compose down -v
docker-compose up -d
```

### Database issues

```bash
docker-compose exec postgres psql -U llmuser -d llmplatform
```

### Check logs

```bash
docker-compose logs -f api
docker-compose logs -f frontend
```

## Future Enhancements

- [ ] Authentication and authorization
- [ ] Multi-tenant support
- [ ] Advanced workflow builder UI
- [ ] Real-time evaluation dashboard
- [ ] Cost tracking and budgets
- [ ] A/B testing for prompts
- [ ] Fine-tuning integration
- [ ] LLM Guard safety layer
- [ ] Kubernetes deployment manifests

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.


