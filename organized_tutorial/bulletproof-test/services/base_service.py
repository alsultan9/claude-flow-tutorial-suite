"""
Base Service - BBPF Step 3
Foundation for all services
"""
import logging
from abc import ABC, abstractmethod
from typing import Optional, List, TypeVar, Generic
from ..models.base import BaseModel

T = TypeVar('T', bound=BaseModel)

class BaseService(ABC, Generic[T]):
    def __init__(self):
        self.logger = logging.getLogger(self.__class__.__name__)
    
    @abstractmethod
    async def create(self, model: T) -> Optional[T]:
        """Create new model"""
        pass
    
    @abstractmethod
    async def get_by_id(self, id: str) -> Optional[T]:
        """Get model by ID"""
        pass
    
    @abstractmethod
    async def update(self, model: T) -> bool:
        """Update model"""
        pass
    
    @abstractmethod
    async def delete(self, id: str) -> bool:
        """Delete model"""
        pass
    
    @abstractmethod
    async def list_all(self) -> List[T]:
        """List all models"""
        pass
    
    def validate_model(self, model: T) -> bool:
        """BBMC: Model validation"""
        try:
            return model.validate()
        except Exception as e:
            self.logger.error(f"Model validation failed: {e}")
            return False
    
    def log_operation(self, operation: str, model_id: str):
        """BBMC: Operation logging"""
        self.logger.info(f"{operation} operation for model {model_id}")
