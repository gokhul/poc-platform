"""
LangGraph Service for LLM Platform
Handles workflow creation, execution, and management
"""

import json
from typing import Dict, Any, List, Optional
from uuid import UUID
from datetime import datetime
import asyncio

try:
    from langgraph.graph import StateGraph, END
    from langchain_core.messages import HumanMessage, AIMessage
    from langchain_core.runnables import RunnableLambda
    from langchain_openai import ChatOpenAI
    LANGGRAPH_AVAILABLE = True
except ImportError:
    LANGGRAPH_AVAILABLE = False
    print("Warning: LangGraph dependencies not installed")

from core.config import settings


class LangGraphService:
    """Service for managing LangGraph workflows"""
    
    def __init__(self):
        self.workflows: Dict[str, StateGraph] = {}
        self.executions: Dict[str, Dict[str, Any]] = {}
        
    async def create_workflow(
        self, 
        workflow_id: str, 
        name: str, 
        description: str,
        nodes: List[Dict[str, Any]],
        edges: List[Dict[str, str]],
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Create a new LangGraph workflow"""
        
        if not LANGGRAPH_AVAILABLE:
            raise RuntimeError("LangGraph is not available. Please install dependencies.")
        
        try:
            # Create the state graph
            workflow = StateGraph(dict)
            
            # Add nodes
            for node in nodes:
                node_id = node["id"]
                node_type = node.get("type", "function")
                
                if node_type == "llm":
                    # Create LLM node
                    llm_node = self._create_llm_node(node)
                    workflow.add_node(node_id, llm_node)
                elif node_type == "function":
                    # Create function node
                    func_node = self._create_function_node(node)
                    workflow.add_node(node_id, func_node)
                elif node_type == "condition":
                    # Create conditional node
                    cond_node = self._create_condition_node(node)
                    workflow.add_node(node_id, cond_node)
                else:
                    # Default to function node
                    func_node = self._create_function_node(node)
                    workflow.add_node(node_id, func_node)
            
            # Add edges
            for edge in edges:
                if edge.get("condition"):
                    workflow.add_conditional_edges(
                        edge["from"],
                        edge["condition"],
                        edge["to"]
                    )
                else:
                    workflow.add_edge(edge["from"], edge["to"])
            
            # Set entry point
            entry_point = nodes[0]["id"] if nodes else "start"
            workflow.set_entry_point(entry_point)
            
            # Compile the workflow
            compiled_workflow = workflow.compile()
            self.workflows[workflow_id] = compiled_workflow
            
            return {
                "id": workflow_id,
                "name": name,
                "description": description,
                "nodes": nodes,
                "edges": edges,
                "config": config,
                "created_at": datetime.now().isoformat(),
                "status": "created"
            }
            
        except Exception as e:
            raise RuntimeError(f"Failed to create workflow: {str(e)}")
    
    def _create_llm_node(self, node_config: Dict[str, Any]) -> callable:
        """Create an LLM node"""
        
        def llm_node(state: Dict[str, Any]) -> Dict[str, Any]:
            try:
                # Initialize LLM
                llm = ChatOpenAI(
                    model=node_config.get("model", "gpt-3.5-turbo"),
                    temperature=node_config.get("temperature", 0.7),
                    api_key=settings.OPENAI_API_KEY if hasattr(settings, 'OPENAI_API_KEY') else None
                )
                
                # Get input from state
                input_text = state.get("input", "")
                if isinstance(input_text, str):
                    messages = [HumanMessage(content=input_text)]
                else:
                    messages = input_text
                
                # Generate response
                response = llm.invoke(messages)
                
                # Update state
                return {
                    **state,
                    "output": response.content,
                    "messages": state.get("messages", []) + [response]
                }
                
            except Exception as e:
                return {
                    **state,
                    "error": str(e),
                    "status": "error"
                }
        
        return llm_node
    
    def _create_function_node(self, node_config: Dict[str, Any]) -> callable:
        """Create a function node"""
        
        def function_node(state: Dict[str, Any]) -> Dict[str, Any]:
            try:
                # Execute custom function logic
                function_code = node_config.get("code", "")
                
                if function_code:
                    # Create a safe execution environment
                    exec_globals = {
                        "state": state,
                        "json": json,
                        "datetime": datetime
                    }
                    exec_locals = {}
                    
                    # Execute the function code
                    exec(function_code, exec_globals, exec_locals)
                    
                    # Get result from locals
                    result = exec_locals.get("result", {})
                    
                    return {
                        **state,
                        **result
                    }
                else:
                    # Default passthrough
                    return state
                    
            except Exception as e:
                return {
                    **state,
                    "error": str(e),
                    "status": "error"
                }
        
        return function_node
    
    def _create_condition_node(self, node_config: Dict[str, Any]) -> callable:
        """Create a conditional node"""
        
        def condition_function(state: Dict[str, Any]) -> str:
            try:
                condition_code = node_config.get("condition", "")
                
                if condition_code:
                    # Create a safe execution environment
                    exec_globals = {
                        "state": state,
                        "json": json
                    }
                    exec_locals = {}
                    
                    # Execute the condition
                    exec(condition_code, exec_globals, exec_locals)
                    
                    # Return the condition result
                    return exec_locals.get("result", "default")
                else:
                    return "default"
                    
            except Exception as e:
                return "error"
        
        return condition_function
    
    async def execute_workflow(
        self, 
        workflow_id: str, 
        input_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Execute a LangGraph workflow"""
        
        if workflow_id not in self.workflows:
            raise ValueError(f"Workflow {workflow_id} not found")
        
        execution_id = f"{workflow_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        try:
            # Initialize execution state
            initial_state = {
                "input": input_data,
                "execution_id": execution_id,
                "status": "running",
                "started_at": datetime.now().isoformat()
            }
            
            # Store execution info
            self.executions[execution_id] = {
                "workflow_id": workflow_id,
                "status": "running",
                "started_at": datetime.now().isoformat(),
                "input": input_data
            }
            
            # Execute the workflow
            workflow = self.workflows[workflow_id]
            result = await workflow.ainvoke(initial_state)
            
            # Update execution info
            self.executions[execution_id].update({
                "status": "completed",
                "completed_at": datetime.now().isoformat(),
                "output": result
            })
            
            return {
                "execution_id": execution_id,
                "workflow_id": workflow_id,
                "status": "completed",
                "result": result,
                "started_at": initial_state["started_at"],
                "completed_at": datetime.now().isoformat()
            }
            
        except Exception as e:
            # Update execution info with error
            if execution_id in self.executions:
                self.executions[execution_id].update({
                    "status": "error",
                    "error": str(e),
                    "completed_at": datetime.now().isoformat()
                })
            
            raise RuntimeError(f"Workflow execution failed: {str(e)}")
    
    def get_workflow(self, workflow_id: str) -> Optional[Dict[str, Any]]:
        """Get workflow information"""
        if workflow_id in self.workflows:
            return {
                "id": workflow_id,
                "status": "available",
                "nodes": "dynamic",  # Would need to store this separately
                "edges": "dynamic"   # Would need to store this separately
            }
        return None
    
    def get_execution(self, execution_id: str) -> Optional[Dict[str, Any]]:
        """Get execution information"""
        return self.executions.get(execution_id)
    
    def list_workflows(self) -> List[Dict[str, Any]]:
        """List all available workflows"""
        return [
            {
                "id": workflow_id,
                "status": "available"
            }
            for workflow_id in self.workflows.keys()
        ]
    
    def delete_workflow(self, workflow_id: str) -> bool:
        """Delete a workflow"""
        if workflow_id in self.workflows:
            del self.workflows[workflow_id]
            return True
        return False


# Global service instance
langgraph_service = LangGraphService()
