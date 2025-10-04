from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from typing import List, Dict, Any
import numpy as np
from core.config import settings


class QdrantService:
    def __init__(self):
        try:
            self.client = QdrantClient(
                host=settings.QDRANT_HOST,
                port=settings.QDRANT_PORT
            )
        except Exception as e:
            print(f"Warning: Could not connect to Qdrant: {e}")
            self.client = None
    
    async def create_collection(
        self,
        project_id: str,
        collection_name: str,
        vector_size: int = 1536,
        distance: Distance = Distance.COSINE
    ):
        """Create a new collection for a project"""
        if not self.client:
            return {"error": "Qdrant not available"}
        
        full_name = f"{project_id}_{collection_name}"
        
        try:
            self.client.create_collection(
                collection_name=full_name,
                vectors_config=VectorParams(
                    size=vector_size,
                    distance=distance
                )
            )
            return {"collection_name": full_name, "status": "created"}
        except Exception as e:
            return {"error": str(e)}
    
    async def upsert_vectors(
        self,
        collection_name: str,
        vectors: List[List[float]],
        payloads: List[Dict],
        ids: List[str] = None
    ):
        """Insert or update vectors"""
        if not self.client:
            return {"error": "Qdrant not available"}
        
        try:
            points = [
                PointStruct(
                    id=ids[i] if ids else str(i),
                    vector=vectors[i],
                    payload=payloads[i]
                )
                for i in range(len(vectors))
            ]
            
            self.client.upsert(
                collection_name=collection_name,
                points=points
            )
            return {"status": "success", "count": len(points)}
        except Exception as e:
            return {"error": str(e)}
    
    async def search(
        self,
        collection_name: str,
        query_vector: List[float],
        limit: int = 10,
        filters: Dict = None
    ):
        """Search for similar vectors"""
        if not self.client:
            return []
        
        try:
            results = self.client.search(
                collection_name=collection_name,
                query_vector=query_vector,
                limit=limit,
                query_filter=filters
            )
            return results
        except Exception as e:
            print(f"Search error: {e}")
            return []


