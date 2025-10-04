from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Dict, Any
from uuid import UUID
import json

from core.database import get_db
from models.schemas import Workflow, WorkflowExecution
from models.pydantic_models import (
    WorkflowCreate, WorkflowResponse,
    WorkflowExecutionCreate, WorkflowExecutionResponse
)
from services.langgraph_service import langgraph_service

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


# LangGraph specific endpoints
@router.post("/langgraph/create")
async def create_langgraph_workflow(
    name: str,
    description: str,
    nodes: List[Dict[str, Any]],
    edges: List[Dict[str, str]],
    config: Dict[str, Any] = None
):
    """Create a new LangGraph workflow"""
    try:
        workflow_id = f"workflow_{name.lower().replace(' ', '_')}"
        
        workflow_data = await langgraph_service.create_workflow(
            workflow_id=workflow_id,
            name=name,
            description=description,
            nodes=nodes,
            edges=edges,
            config=config
        )
        
        return {
            "success": True,
            "workflow": workflow_data
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/langgraph/{workflow_id}/execute")
async def execute_langgraph_workflow(
    workflow_id: str,
    input_data: Dict[str, Any]
):
    """Execute a LangGraph workflow"""
    try:
        result = await langgraph_service.execute_workflow(
            workflow_id=workflow_id,
            input_data=input_data
        )
        
        return {
            "success": True,
            "execution": result
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/langgraph/{workflow_id}")
async def get_langgraph_workflow(workflow_id: str):
    """Get LangGraph workflow information"""
    workflow = langgraph_service.get_workflow(workflow_id)
    
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found")
    
    return {
        "success": True,
        "workflow": workflow
    }


@router.get("/langgraph/{workflow_id}/execution/{execution_id}")
async def get_langgraph_execution(workflow_id: str, execution_id: str):
    """Get LangGraph execution information"""
    execution = langgraph_service.get_execution(execution_id)
    
    if not execution:
        raise HTTPException(status_code=404, detail="Execution not found")
    
    return {
        "success": True,
        "execution": execution
    }


@router.get("/langgraph/")
async def list_langgraph_workflows():
    """List all LangGraph workflows"""
    workflows = langgraph_service.list_workflows()
    
    return {
        "success": True,
        "workflows": workflows
    }


@router.delete("/langgraph/{workflow_id}")
async def delete_langgraph_workflow(workflow_id: str):
    """Delete a LangGraph workflow"""
    success = langgraph_service.delete_workflow(workflow_id)
    
    if not success:
        raise HTTPException(status_code=404, detail="Workflow not found")
    
    return {
        "success": True,
        "message": f"Workflow {workflow_id} deleted successfully"
    }


