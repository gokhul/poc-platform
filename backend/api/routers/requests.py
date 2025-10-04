from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from uuid import UUID
from datetime import datetime

from core.database import get_db
from models.schemas import LLMRequest
from models.pydantic_models import LLMRequestCreate, LLMRequestResponse
from integrations.litellm_service import LiteLLMService

router = APIRouter()
litellm_service = LiteLLMService()


@router.post("/complete")
async def create_completion(
    request: LLMRequestCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create an LLM completion request"""
    start_time = datetime.now()
    
    # Make LLM request through LiteLLM
    result = await litellm_service.complete(
        model=request.model,
        messages=request.messages,
        project_id=str(request.project_id),
        prompt_template_id=str(request.prompt_template_id) if request.prompt_template_id else None,
        metadata=request.metadata
    )
    
    end_time = datetime.now()
    latency_ms = int((end_time - start_time).total_seconds() * 1000)
    
    # Store request in database
    db_request = LLMRequest(
        project_id=request.project_id,
        prompt_template_id=request.prompt_template_id,
        langfuse_trace_id=result.get("trace_id"),
        input_tokens=result["usage"]["prompt_tokens"],
        output_tokens=result["usage"]["completion_tokens"],
        latency_ms=latency_ms,
        status="success" if not result.get("error") else "error"
    )
    db.add(db_request)
    await db.flush()
    await db.refresh(db_request)
    
    return {
        "request_id": db_request.id,
        "content": result.get("content"),
        "usage": result["usage"],
        "latency_ms": latency_ms,
        "trace_id": result.get("trace_id"),
        "error": result.get("error")
    }


@router.get("/", response_model=List[LLMRequestResponse])
async def list_requests(
    project_id: UUID = None,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
):
    """List LLM requests"""
    query = select(LLMRequest)
    if project_id:
        query = query.where(LLMRequest.project_id == project_id)
    
    query = query.order_by(LLMRequest.created_at.desc()).limit(limit)
    
    result = await db.execute(query)
    requests = result.scalars().all()
    return requests


@router.get("/{request_id}", response_model=LLMRequestResponse)
async def get_request(
    request_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get request by ID"""
    result = await db.execute(
        select(LLMRequest).where(LLMRequest.id == request_id)
    )
    request = result.scalar_one_or_none()
    
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")
    
    return request


