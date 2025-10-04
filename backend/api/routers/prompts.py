from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List
from uuid import UUID

from core.database import get_db
from models.schemas import PromptTemplate
from models.pydantic_models import PromptTemplateCreate, PromptTemplateResponse

router = APIRouter()


@router.post("/", response_model=PromptTemplateResponse)
async def create_prompt_template(
    prompt: PromptTemplateCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new prompt template"""
    # Get the next version number for this prompt name
    result = await db.execute(
        select(func.max(PromptTemplate.version))
        .where(
            PromptTemplate.project_id == prompt.project_id,
            PromptTemplate.name == prompt.name
        )
    )
    max_version = result.scalar()
    next_version = (max_version or 0) + 1
    
    db_prompt = PromptTemplate(
        **prompt.model_dump(),
        version=next_version
    )
    db.add(db_prompt)
    await db.flush()
    await db.refresh(db_prompt)
    return db_prompt


@router.get("/", response_model=List[PromptTemplateResponse])
async def list_prompt_templates(
    project_id: UUID = None,
    db: AsyncSession = Depends(get_db)
):
    """List all prompt templates"""
    query = select(PromptTemplate)
    if project_id:
        query = query.where(PromptTemplate.project_id == project_id)
    
    result = await db.execute(query.order_by(PromptTemplate.created_at.desc()))
    prompts = result.scalars().all()
    return prompts


@router.get("/{prompt_id}", response_model=PromptTemplateResponse)
async def get_prompt_template(
    prompt_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get prompt template by ID"""
    result = await db.execute(
        select(PromptTemplate).where(PromptTemplate.id == prompt_id)
    )
    prompt = result.scalar_one_or_none()
    
    if not prompt:
        raise HTTPException(status_code=404, detail="Prompt template not found")
    
    return prompt


@router.get("/by-name/{project_id}/{name}", response_model=List[PromptTemplateResponse])
async def get_prompt_versions(
    project_id: UUID,
    name: str,
    db: AsyncSession = Depends(get_db)
):
    """Get all versions of a prompt template"""
    result = await db.execute(
        select(PromptTemplate)
        .where(
            PromptTemplate.project_id == project_id,
            PromptTemplate.name == name
        )
        .order_by(PromptTemplate.version.desc())
    )
    prompts = result.scalars().all()
    return prompts


