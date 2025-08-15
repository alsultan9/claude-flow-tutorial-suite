"""
Query Model - RAG System
"""
from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime

@dataclass
class Query:
    id: Optional[int] = None
    user_query: str = ""
    query_embedding: Optional[List[float]] = None
    relevant_chunks: Optional[List[int]] = None
    response: str = ""
    confidence_score: float = 0.0
    processing_time: float = 0.0
    created_at: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'user_query': self.user_query,
            'query_embedding': self.query_embedding,
            'relevant_chunks': self.relevant_chunks,
            'response': self.response,
            'confidence_score': self.confidence_score,
            'processing_time': self.processing_time,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
