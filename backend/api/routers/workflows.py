from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from uuid import UUID

from core.database import get_db
from models.schemas import Workflow, WorkflowExecution
from models.pydantic_models import (
    WorkflowCreate, WorkflowResponse,
    WorkflowExecutionCreate, WorkflowExecutionResponse
)

router = APIRouter()


@router.post("/", response_model=WorkflowResponse)
async def create_workflow(
    workflow: WorkflowCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new workflow"""
    # Get next version
    result = await db.execute(
        select(Workflow)
        .where(
            Workflow.project_id == workflow.project_id,
            Workflow.name == workflow.name
        )
        .order_by(Workflow.version.desc())
    )
    latest = result.scalar_one_or_none()
    next_version = (latest.version if latest else 0) + 1
    
    db_workflow = Workflow(
        **workflow.model_dump(),
        version=next_version
    )
    db.add(db_workflow)
    await db.flush()
    await db.refresh(db_workflow)
    return db_workflow


@router.get("/", response_model=List[WorkflowResponse])
async def list_workflows(
    project_id: UUID = None,
    db: AsyncSession = Depends(get_db)
):
    """List all workflows"""
    query = select(Workflow)
    if project_id:
        query = query.where(Workflow.project_id == project_id)
    
    result = await db.execute(query)
    workflows = result.scalars().all()
    return workflows


@router.post("/{workflow_id}/execute", response_model=WorkflowExecutionResponse)
async def execute_workflow(
    workflow_id: UUID,
    execution: WorkflowExecutionCreate,
    db: AsyncSession = Depends(get_db)
):
    """Execute a workflow"""
    # Verify workflow exists
    result = await db.execute(
        select(Workflow).where(Workflow.id == workflow_id)
    )
    workflow = result.scalar_one_or_none()
    
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found")
    
    # Create execution record
    from datetime import datetime
    db_execution = WorkflowExecution(
        workflow_id=workflow_id,
        input=execution.input,
        status="running",
        started_at=datetime.now()
    )
    db.add(db_execution)
    await db.flush()
    
    # TODO: Actually execute the workflow using LangGraph
    # For now, just mark as completed
    db_execution.status = "completed"
    db_execution.output = {"result": "Workflow execution placeholder"}
    db_execution.completed_at = datetime.now()
    
    await db.flush()
    await db.refresh(db_execution)
    return db_execution


@router.get("/{workflow_id}/executions", response_model=List[WorkflowExecutionResponse])
async def list_workflow_executions(
    workflow_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """List workflow executions"""
    result = await db.execute(
        select(WorkflowExecution)
        .where(WorkflowExecution.workflow_id == workflow_id)
        .order_by(WorkflowExecution.started_at.desc())
    )
    executions = result.scalars().all()
    return executions


