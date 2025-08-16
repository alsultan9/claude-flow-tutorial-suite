"""
Intelligent Document Model - BBAM Priority 2
Learned from autonomous assessment
"""
from dataclasses import dataclass
from typing import Optional, Dict, Any
from datetime import datetime
import re
from .base import BaseModel

@dataclass
class Document(BaseModel):
    filename: str = ""
    file_path: str = ""
    content: str = ""
    file_size: int = 0
    mime_type: str = ""
    
    def __post_init__(self):
        super().__init__()
        if not self.id:
            self.id = self.generate_id()
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': self.id,
            'filename': self.filename,
            'file_path': self.file_path,
            'content': self.content,
            'file_size': self.file_size,
            'mime_type': self.mime_type,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
    
    def validate(self) -> bool:
        """BBMC: Document validation with learned patterns"""
        if not self.filename or len(self.filename) < 1:
            return False
        
        if not self.file_path or len(self.file_path) < 1:
            return False
        
        if self.file_size < 0:
            return False
        
        # Learned filename validation pattern
        if not re.match(r'^[a-zA-Z0-9._-]+$', self.filename):
            return False
        
        return True
