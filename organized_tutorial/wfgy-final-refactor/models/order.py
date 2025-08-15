"""
Order Model - BBPF Step 2
"""
from dataclasses import dataclass
from typing import Optional
from datetime import datetime

@dataclass
class Order:
    id: int
    user_id: int
    amount: float
    status: str = "pending"
    created_at: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'user_id': self.user_id,
            'amount': self.amount,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
