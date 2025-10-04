from typing import Dict, Any, List
import httpx
import uuid
from datetime import datetime
from core.config import settings


class LiteLLMService:
    def __init__(self):
        self.proxy_url = settings.LITELLM_PROXY_URL
        self.client = httpx.AsyncClient(timeout=120.0)
    
    async def complete(
        self,
        model: str,
        messages: List[Dict[str, str]],
        project_id: str,
        prompt_template_id: str = None,
        metadata: Dict[str, Any] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Unified completion call through LiteLLM proxy
        """
        # Prepare request payload
        payload = {
            "model": model,
            "messages": messages,
            **kwargs
        }
        
        # Add metadata for tracing
        if metadata:
            payload["metadata"] = {
                "project_id": project_id,
                "prompt_template_id": prompt_template_id,
                **metadata
            }
        
        try:
            # Make request to LiteLLM proxy
            response = await self.client.post(
                f"{self.proxy_url}/chat/completions",
                json=payload
            )
            response.raise_for_status()
            result = response.json()
            
            # Extract usage information
            usage = result.get("usage", {})
            
            return {
                "response": result,
                "trace_id": result.get("id"),
                "usage": {
                    "prompt_tokens": usage.get("prompt_tokens", 0),
                    "completion_tokens": usage.get("completion_tokens", 0),
                    "total_tokens": usage.get("total_tokens", 0)
                },
                "model": result.get("model"),
                "content": result["choices"][0]["message"]["content"] if result.get("choices") else None
            }
        except httpx.HTTPError as e:
            # Fallback to mock response for development
            return {
                "response": {"error": str(e)},
                "trace_id": str(uuid.uuid4()),
                "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
                "model": model,
                "content": "LiteLLM proxy not available. Configure LLM providers to get real responses.",
                "error": str(e)
            }
    
    async def close(self):
        await self.client.aclose()


