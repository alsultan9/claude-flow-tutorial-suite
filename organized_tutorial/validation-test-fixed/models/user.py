"""
User Model - BBPF Step 2
User data structure with validation
"""
from dataclasses import dataclass
from typing import Optional, Dict, Any
from datetime import datetime
import re
from .base import BaseModel

@dataclass
class User(BaseModel):
    username: str = ""
    email: str = ""
    full_name: str = ""
    is_active: bool = True
    role: str = "user"
    
    def __post_init__(self):
        super().__init__()
        if not self.id:
            self.id = self.generate_id()
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'full_name': self.full_name,
            'is_active': self.is_active,
            'role': self.role,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
    
    def validate(self) -> bool:
        """BBMC: User data validation"""
        if not self.username or len(self.username) < 3:
            return False
        
        if not self.email or not re.match(r"[^@]+@[^@]+\.[^@]+", self.email):
            return False
        
        if not self.full_name or len(self.full_name) < 2:
            return False
        
        return True
