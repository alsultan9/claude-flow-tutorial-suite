"""
Base Repository - BBPF Step 4
Foundation for all repositories
"""
import logging
from abc import ABC, abstractmethod
from typing import Optional, List, TypeVar, Generic
from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from ..models.base import BaseModel
from ..config import config

T = TypeVar('T', bound=BaseModel)

class BaseRepository(ABC, Generic[T]):
    def __init__(self):
        self.logger = logging.getLogger(self.__class__.__name__)
        self.engine = create_engine(config.database.url, echo=config.database.echo)
    
    def get_session(self) -> Session:
        """BBMC: Proper session management"""
        return Session(self.engine)
    
    @abstractmethod
    async def create(self, model: T) -> Optional[T]:
        """Create new model in database"""
        pass
    
    @abstractmethod
    async def get_by_id(self, id: str) -> Optional[T]:
        """Get model by ID from database"""
        pass
    
    @abstractmethod
    async def update(self, model: T) -> bool:
        """Update model in database"""
        pass
    
    @abstractmethod
    async def delete(self, id: str) -> bool:
        """Delete model from database"""
        pass
    
    @abstractmethod
    async def list_all(self) -> List[T]:
        """List all models from database"""
        pass
    
    def log_database_operation(self, operation: str, model_id: str):
        """BBMC: Database operation logging"""
        self.logger.info(f"Database {operation} for model {model_id}")
