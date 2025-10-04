from typing import Dict, Any, List
from datetime import datetime
import httpx
from core.config import settings


class LangfuseService:
    def __init__(self):
        self.host = settings.LANGFUSE_HOST
        self.public_key = settings.LANGFUSE_PUBLIC_KEY
        self.secret_key = settings.LANGFUSE_SECRET_KEY
        self.client = httpx.AsyncClient(timeout=30.0)
    
    async def get_traces(
        self,
        project_id: str,
        start_date: datetime = None,
        end_date: datetime = None,
        filters: Dict[str, Any] = None
    ) -> List[Dict]:
        """Fetch traces with project filtering"""
        try:
            params = {
                "userId": project_id,
            }
            if start_date:
                params["fromTimestamp"] = start_date.isoformat()
            if end_date:
                params["toTimestamp"] = end_date.isoformat()
            
            response = await self.client.get(
                f"{self.host}/api/public/traces",
                params=params,
                auth=(self.public_key, self.secret_key)
            )
            
            if response.status_code == 200:
                return response.json().get("data", [])
            return []
        except Exception as e:
            print(f"Error fetching traces: {e}")
            return []
    
    async def get_trace_details(self, trace_id: str) -> Dict:
        """Get detailed trace information"""
        try:
            response = await self.client.get(
                f"{self.host}/api/public/traces/{trace_id}",
                auth=(self.public_key, self.secret_key)
            )
            
            if response.status_code == 200:
                trace = response.json()
                return {
                    "id": trace.get("id"),
                    "name": trace.get("name"),
                    "metadata": trace.get("metadata"),
                    "latency": trace.get("latency"),
                    "cost": trace.get("calculatedTotalCost")
                }
            return {}
        except Exception as e:
            print(f"Error fetching trace details: {e}")
            return {}
    
    async def add_score(
        self,
        trace_id: str,
        name: str,
        value: float,
        comment: str = None
    ):
        """Add evaluation score to trace"""
        try:
            payload = {
                "traceId": trace_id,
                "name": name,
                "value": value,
            }
            if comment:
                payload["comment"] = comment
            
            await self.client.post(
                f"{self.host}/api/public/scores",
                json=payload,
                auth=(self.public_key, self.secret_key)
            )
        except Exception as e:
            print(f"Error adding score: {e}")
    
    async def close(self):
        await self.client.aclose()


