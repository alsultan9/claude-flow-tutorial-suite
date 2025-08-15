"""
Document Model - RAG System
"""
from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime
from enum import Enum

class DocumentType(Enum):
    PDF = "pdf"
    IMAGE = "image"
    TEXT = "text"

class ProcessingStatus(Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

@dataclass
class Document:
    id: Optional[int] = None
    filename: str = ""
    file_path: str = ""
    content: str = ""
    document_type: DocumentType = DocumentType.PDF
    processing_status: ProcessingStatus = ProcessingStatus.PENDING
    page_count: int = 0
    file_size: int = 0
    created_at: Optional[datetime] = None
    processed_at: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'filename': self.filename,
            'file_path': self.file_path,
            'content': self.content,
            'document_type': self.document_type.value,
            'processing_status': self.processing_status.value,
            'page_count': self.page_count,
            'file_size': self.file_size,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'processed_at': self.processed_at.isoformat() if self.processed_at else None
        }
