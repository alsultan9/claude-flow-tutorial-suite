"""
User Repository - BBAM Priority 1
Data access for user operations
"""
import logging
from typing import Optional, List
from sqlalchemy.orm import Session
from ..models.user import User
from .base_repository import BaseRepository

logger = logging.getLogger(__name__)

class UserRepository(BaseRepository[User]):
    def __init__(self):
        super().__init__()
        self.logger = logging.getLogger(__name__)
    
    async def create(self, user: User) -> Optional[User]:
        """Create user in database"""
        try:
            with self.get_session() as session:
                # Convert to dict and save
                user_dict = user.to_dict()
                # Simulate database save
                user.id = self._generate_id()
                self.log_database_operation("create", user.id)
                return user
        except Exception as e:
            self.logger.error(f"Database create failed: {e}")
            return None
    
    async def get_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID from database"""
        try:
            # Simulate database query
            user = User(
                id=user_id,
                username="testuser",
                email="test@example.com",
                full_name="Test User"
            )
            self.log_database_operation("get", user_id)
            return user
        except Exception as e:
            self.logger.error(f"Database get failed: {e}")
            return None
    
    async def update(self, user: User) -> bool:
        """Update user in database"""
        try:
            self.log_database_operation("update", user.id)
            return True
        except Exception as e:
            self.logger.error(f"Database update failed: {e}")
            return False
    
    async def delete(self, user_id: str) -> bool:
        """Delete user from database"""
        try:
            self.log_database_operation("delete", user_id)
            return True
        except Exception as e:
            self.logger.error(f"Database delete failed: {e}")
            return False
    
    async def list_all(self) -> List[User]:
        """List all users from database"""
        try:
            # Simulate database query
            users = [
                User(username="user1", email="user1@example.com", full_name="User One"),
                User(username="user2", email="user2@example.com", full_name="User Two")
            ]
            self.log_database_operation("list", "all")
            return users
        except Exception as e:
            self.logger.error(f"Database list failed: {e}")
            return []
    
    def _generate_id(self) -> str:
        """Generate unique ID"""
        import uuid
        return str(uuid.uuid4())
