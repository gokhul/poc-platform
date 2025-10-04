from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from uuid import UUID

from core.database import get_db
from models.schemas import Dataset, DatasetItem
from models.pydantic_models import (
    DatasetCreate, DatasetResponse,
    DatasetItemCreate, DatasetItemResponse
)

router = APIRouter()


@router.post("/", response_model=DatasetResponse)
async def create_dataset(
    dataset: DatasetCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new dataset"""
    db_dataset = Dataset(**dataset.model_dump())
    db.add(db_dataset)
    await db.flush()
    await db.refresh(db_dataset)
    return db_dataset


@router.get("/", response_model=List[DatasetResponse])
async def list_datasets(
    project_id: UUID = None,
    db: AsyncSession = Depends(get_db)
):
    """List all datasets"""
    query = select(Dataset)
    if project_id:
        query = query.where(Dataset.project_id == project_id)
    
    result = await db.execute(query)
    datasets = result.scalars().all()
    return datasets


@router.post("/{dataset_id}/items", response_model=DatasetItemResponse)
async def add_dataset_item(
    dataset_id: UUID,
    item: DatasetItemCreate,
    db: AsyncSession = Depends(get_db)
):
    """Add item to dataset"""
    # Verify dataset exists
    result = await db.execute(
        select(Dataset).where(Dataset.id == dataset_id)
    )
    dataset = result.scalar_one_or_none()
    
    if not dataset:
        raise HTTPException(status_code=404, detail="Dataset not found")
    
    db_item = DatasetItem(**item.model_dump())
    db.add(db_item)
    await db.flush()
    await db.refresh(db_item)
    return db_item


@router.get("/{dataset_id}/items", response_model=List[DatasetItemResponse])
async def list_dataset_items(
    dataset_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """List dataset items"""
    result = await db.execute(
        select(DatasetItem).where(DatasetItem.dataset_id == dataset_id)
    )
    items = result.scalars().all()
    return items


