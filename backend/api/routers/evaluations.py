from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from uuid import UUID

from core.database import get_db
from models.schemas import Evaluation, EvaluationResult
from models.pydantic_models import EvaluationCreate, EvaluationResponse

router = APIRouter()


@router.post("/", response_model=EvaluationResponse)
async def create_evaluation(
    evaluation: EvaluationCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new evaluation"""
    db_evaluation = Evaluation(
        **evaluation.model_dump(),
        status="pending"
    )
    db.add(db_evaluation)
    await db.flush()
    await db.refresh(db_evaluation)
    
    # TODO: Trigger evaluation job based on eval_type (ragas, deepeval, etc.)
    
    return db_evaluation


@router.get("/", response_model=List[EvaluationResponse])
async def list_evaluations(
    project_id: UUID = None,
    db: AsyncSession = Depends(get_db)
):
    """List all evaluations"""
    query = select(Evaluation)
    if project_id:
        query = query.where(Evaluation.project_id == project_id)
    
    result = await db.execute(query.order_by(Evaluation.created_at.desc()))
    evaluations = result.scalars().all()
    return evaluations


@router.get("/{evaluation_id}", response_model=EvaluationResponse)
async def get_evaluation(
    evaluation_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get evaluation by ID"""
    result = await db.execute(
        select(Evaluation).where(Evaluation.id == evaluation_id)
    )
    evaluation = result.scalar_one_or_none()
    
    if not evaluation:
        raise HTTPException(status_code=404, detail="Evaluation not found")
    
    return evaluation


@router.get("/{evaluation_id}/results")
async def get_evaluation_results(
    evaluation_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get evaluation results"""
    result = await db.execute(
        select(EvaluationResult).where(EvaluationResult.evaluation_id == evaluation_id)
    )
    results = result.scalars().all()
    
    return {
        "evaluation_id": evaluation_id,
        "results": [
            {
                "id": str(r.id),
                "metrics": r.metrics,
                "passed": r.passed,
                "created_at": r.created_at
            }
            for r in results
        ]
    }


