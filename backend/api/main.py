from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from contextlib import asynccontextmanager

from api.routers import (
    projects, models, prompts,
    requests, evaluations, datasets, workflows
)
from core.config import settings
from core.database import init_db, close_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("🚀 Starting LLM Platform...")
    await init_db()
    print("✅ Database initialized")
    
    yield
    
    # Shutdown
    print("👋 Shutting down LLM Platform...")
    await close_db()


app = FastAPI(
    title="LLM Platform API",
    version="1.0.0",
    description="Comprehensive LLM Operations Platform",
    docs_url="/api/docs",
    openapi_url="/api/openapi.json",
    lifespan=lifespan
)

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_allowed_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Routers
app.include_router(projects.router, prefix="/api/projects", tags=["projects"])
app.include_router(models.router, prefix="/api/models", tags=["models"])
app.include_router(prompts.router, prefix="/api/prompts", tags=["prompts"])
app.include_router(requests.router, prefix="/api/requests", tags=["requests"])
app.include_router(evaluations.router, prefix="/api/evaluations", tags=["evaluations"])
app.include_router(datasets.router, prefix="/api/datasets", tags=["datasets"])
app.include_router(workflows.router, prefix="/api/workflows", tags=["workflows"])


@app.get("/")
async def root():
    return {
        "message": "LLM Platform API",
        "version": "1.0.0",
        "docs": "/api/docs"
    }


@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "environment": settings.ENVIRONMENT
    }

