"""
Base Model - BBPF Step 2
Foundation for all data models
"""
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from datetime import datetime
import uuid

class BaseModel(ABC):
    def __init__(self):
        self.id: Optional[str] = None
        self.created_at: Optional[datetime] = None
        self.updated_at: Optional[datetime] = None
    
    @abstractmethod
    def to_dict(self) -> Dict[str, Any]:
        """Convert model to dictionary"""
        pass
    
    @abstractmethod
    def validate(self) -> bool:
        """Validate model data"""
        pass
    
    def generate_id(self) -> str:
        """Generate unique ID"""
        return str(uuid.uuid4())
    
    def update_timestamps(self):
        """Update timestamps"""
        now = datetime.now()
        if not self.created_at:
            self.created_at = now
        self.updated_at = now
