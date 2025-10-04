from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from uuid import UUID

from core.database import get_db
from models.schemas import ModelConfig
from models.pydantic_models import ModelConfigCreate, ModelConfigResponse

router = APIRouter()


@router.post("/", response_model=ModelConfigResponse)
async def create_model_config(
    model_config: ModelConfigCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new model configuration"""
    db_model = ModelConfig(**model_config.model_dump())
    db.add(db_model)
    await db.flush()
    await db.refresh(db_model)
    return db_model


@router.get("/", response_model=List[ModelConfigResponse])
async def list_model_configs(
    project_id: UUID = None,
    db: AsyncSession = Depends(get_db)
):
    """List all model configurations"""
    query = select(ModelConfig)
    if project_id:
        query = query.where(ModelConfig.project_id == project_id)
    
    result = await db.execute(query)
    models = result.scalars().all()
    return models


@router.get("/{model_id}", response_model=ModelConfigResponse)
async def get_model_config(
    model_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get model configuration by ID"""
    result = await db.execute(
        select(ModelConfig).where(ModelConfig.id == model_id)
    )
    model = result.scalar_one_or_none()
    
    if not model:
        raise HTTPException(status_code=404, detail="Model config not found")
    
    return model


@router.delete("/{model_id}")
async def delete_model_config(
    model_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Delete model configuration"""
    result = await db.execute(
        select(ModelConfig).where(ModelConfig.id == model_id)
    )
    model = result.scalar_one_or_none()
    
    if not model:
        raise HTTPException(status_code=404, detail="Model config not found")
    
    await db.delete(model)
    return {"status": "deleted", "model_id": model_id}


