"""
Chunk Model - RAG System
"""
from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime

@dataclass
class Chunk:
    id: Optional[int] = None
    document_id: int = 0
    chunk_text: str = ""
    chunk_embedding: Optional[List[float]] = None
    page_number: int = 0
    chunk_index: int = 0
    metadata: Optional[dict] = None
    created_at: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'document_id': self.document_id,
            'chunk_text': self.chunk_text,
            'chunk_embedding': self.chunk_embedding,
            'page_number': self.page_number,
            'chunk_index': self.chunk_index,
            'metadata': self.metadata,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
