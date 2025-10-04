from sqlalchemy import Column, String, Integer, Boolean, TIMESTAMP, ForeignKey, JSON, DECIMAL, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from core.database import Base


class Organization(Base):
    __tablename__ = "organizations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    users = relationship("User", back_populates="organization")
    projects = relationship("Project", back_populates="organization")


class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"))
    email = Column(String(255), unique=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    organization = relationship("Organization", back_populates="users")


class Project(Base):
    __tablename__ = "projects"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"))
    name = Column(String(255), nullable=False)
    description = Column(Text)
    settings = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    organization = relationship("Organization", back_populates="projects")
    model_configs = relationship("ModelConfig", back_populates="project")
    prompt_templates = relationship("PromptTemplate", back_populates="project")


class ModelConfig(Base):
    __tablename__ = "model_configs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"))
    provider = Column(String(50), nullable=False)
    model_name = Column(String(255), nullable=False)
    config = Column(JSON, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    project = relationship("Project", back_populates="model_configs")


class PromptTemplate(Base):
    __tablename__ = "prompt_templates"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"))
    name = Column(String(255), nullable=False)
    version = Column(Integer, nullable=False)
    template = Column(Text, nullable=False)
    variables = Column(JSON)
    prompt_metadata = Column("metadata", JSON)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    project = relationship("Project", back_populates="prompt_templates")


class PromptDeployment(Base):
    __tablename__ = "prompt_deployments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    prompt_template_id = Column(UUID(as_uuid=True), ForeignKey("prompt_templates.id"))
    environment = Column(String(50), nullable=False)
    deployed_at = Column(TIMESTAMP, server_default=func.now())
    deployed_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))


class LLMRequest(Base):
    __tablename__ = "llm_requests"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"))
    prompt_template_id = Column(UUID(as_uuid=True), ForeignKey("prompt_templates.id"), nullable=True)
    model_config_id = Column(UUID(as_uuid=True), ForeignKey("model_configs.id"), nullable=True)
    langfuse_trace_id = Column(String(255))
    input_tokens = Column(Integer)
    output_tokens = Column(Integer)
    latency_ms = Column(Integer)
    cost_usd = Column(DECIMAL(10, 6))
    status = Column(String(50))
    created_at = Column(TIMESTAMP, server_default=func.now())


class Evaluation(Base):
    __tablename__ = "evaluations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"))
    eval_type = Column(String(50), nullable=False)
    config = Column(JSON, nullable=False)
    status = Column(String(50), nullable=False)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    created_at = Column(TIMESTAMP, server_default=func.now())


class EvaluationResult(Base):
    __tablename__ = "evaluation_results"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    evaluation_id = Column(UUID(as_uuid=True), ForeignKey("evaluations.id"))
    llm_request_id = Column(UUID(as_uuid=True), ForeignKey("llm_requests.id"), nullable=True)
    metrics = Column(JSON, nullable=False)
    passed = Column(Boolean)
    created_at = Column(TIMESTAMP, server_default=func.now())


class Dataset(Base):
    __tablename__ = "datasets"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"))
    name = Column(String(255), nullable=False)
    description = Column(Text)
    type = Column(String(50), nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())


class DatasetItem(Base):
    __tablename__ = "dataset_items"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dataset_id = Column(UUID(as_uuid=True), ForeignKey("datasets.id"))
    input = Column(JSON, nullable=False)
    expected_output = Column(JSON)
    item_metadata = Column("metadata", JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())


class Workflow(Base):
    __tablename__ = "workflows"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"))
    name = Column(String(255), nullable=False)
    graph_definition = Column(JSON, nullable=False)
    version = Column(Integer, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())


class WorkflowExecution(Base):
    __tablename__ = "workflow_executions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    workflow_id = Column(UUID(as_uuid=True), ForeignKey("workflows.id"))
    status = Column(String(50), nullable=False)
    input = Column(JSON)
    output = Column(JSON)
    trace_data = Column(JSON)
    started_at = Column(TIMESTAMP)
    completed_at = Column(TIMESTAMP)


class CostBudget(Base):
    __tablename__ = "cost_budgets"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"))
    period = Column(String(50), nullable=False)
    limit_usd = Column(DECIMAL(10, 2))
    alert_threshold = Column(DECIMAL(5, 2))
    created_at = Column(TIMESTAMP, server_default=func.now())

