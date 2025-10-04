from pydantic import BaseModel, EmailStr, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from uuid import UUID


# Organization Models
class OrganizationBase(BaseModel):
    name: str


class OrganizationCreate(OrganizationBase):
    pass


class OrganizationResponse(OrganizationBase):
    id: UUID
    created_at: datetime
    
    class Config:
        from_attributes = True


# User Models
class UserBase(BaseModel):
    email: EmailStr
    role: str


class UserCreate(UserBase):
    password: str
    organization_id: UUID


class UserResponse(UserBase):
    id: UUID
    organization_id: UUID
    created_at: datetime
    
    class Config:
        from_attributes = True


# Project Models
class ProjectBase(BaseModel):
    name: str
    description: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None


class ProjectCreate(ProjectBase):
    organization_id: UUID


class ProjectUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None


class ProjectResponse(ProjectBase):
    id: UUID
    organization_id: UUID
    created_at: datetime
    
    class Config:
        from_attributes = True


# Model Config Models
class ModelConfigBase(BaseModel):
    provider: str
    model_name: str
    config: Dict[str, Any]


class ModelConfigCreate(ModelConfigBase):
    project_id: UUID


class ModelConfigResponse(ModelConfigBase):
    id: UUID
    project_id: UUID
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


# Prompt Template Models
class PromptTemplateBase(BaseModel):
    name: str
    template: str
    variables: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = None


class PromptTemplateCreate(PromptTemplateBase):
    project_id: UUID


class PromptTemplateResponse(PromptTemplateBase):
    id: UUID
    project_id: UUID
    version: int
    created_at: datetime
    
    class Config:
        from_attributes = True


# LLM Request Models
class LLMRequestCreate(BaseModel):
    project_id: UUID
    model: str
    messages: List[Dict[str, str]]
    prompt_template_id: Optional[UUID] = None
    metadata: Optional[Dict[str, Any]] = None


class LLMRequestResponse(BaseModel):
    id: UUID
    project_id: UUID
    langfuse_trace_id: Optional[str]
    input_tokens: Optional[int]
    output_tokens: Optional[int]
    latency_ms: Optional[int]
    cost_usd: Optional[float]
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# Evaluation Models
class EvaluationCreate(BaseModel):
    project_id: UUID
    eval_type: str
    config: Dict[str, Any]


class EvaluationResponse(BaseModel):
    id: UUID
    project_id: UUID
    eval_type: str
    config: Dict[str, Any]
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# Dataset Models
class DatasetBase(BaseModel):
    name: str
    description: Optional[str] = None
    type: str


class DatasetCreate(DatasetBase):
    project_id: UUID


class DatasetResponse(DatasetBase):
    id: UUID
    project_id: UUID
    created_at: datetime
    
    class Config:
        from_attributes = True


class DatasetItemCreate(BaseModel):
    dataset_id: UUID
    input: Dict[str, Any]
    expected_output: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = None


class DatasetItemResponse(BaseModel):
    id: UUID
    dataset_id: UUID
    input: Dict[str, Any]
    expected_output: Optional[Dict[str, Any]]
    metadata: Optional[Dict[str, Any]]
    created_at: datetime
    
    class Config:
        from_attributes = True


# Workflow Models
class WorkflowCreate(BaseModel):
    project_id: UUID
    name: str
    graph_definition: Dict[str, Any]


class WorkflowResponse(BaseModel):
    id: UUID
    project_id: UUID
    name: str
    version: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class WorkflowExecutionCreate(BaseModel):
    workflow_id: UUID
    input: Dict[str, Any]


class WorkflowExecutionResponse(BaseModel):
    id: UUID
    workflow_id: UUID
    status: str
    output: Optional[Dict[str, Any]]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    
    class Config:
        from_attributes = True


