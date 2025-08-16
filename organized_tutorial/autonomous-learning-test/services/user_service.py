"""
Intelligent User Service - BBAM Priority 1
Learned from autonomous assessment
"""
import logging
from typing import Optional, List
from ..models.user import User
from ..repositories.user_repository import UserRepository

logger = logging.getLogger(__name__)

class UserService:
    def __init__(self):
        self.repository = UserRepository()
        self.logger = logging.getLogger(__name__)
    
    async def create_user(self, user: User) -> Optional[User]:
        """Create user with learned validation patterns"""
        try:
            if not user.validate():
                self.logger.error("User validation failed")
                return None
            
            user.update_timestamps()
            created_user = await self.repository.create(user)
            self.logger.info(f"Created user: {created_user.username}")
            return created_user
        except Exception as e:
            self.logger.error(f"Failed to create user: {e}")
            return None
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID with learned error handling"""
        try:
            return await self.repository.get_by_id(user_id)
        except Exception as e:
            self.logger.error(f"Failed to get user: {e}")
            return None
    
    async def update_user(self, user: User) -> bool:
        """Update user with learned patterns"""
        try:
            if not user.validate():
                return False
            
            user.update_timestamps()
            return await self.repository.update(user)
        except Exception as e:
            self.logger.error(f"Failed to update user: {e}")
            return False
    
    async def delete_user(self, user_id: str) -> bool:
        """Delete user with learned safety patterns"""
        try:
            return await self.repository.delete(user_id)
        except Exception as e:
            self.logger.error(f"Failed to delete user: {e}")
            return False
    
    async def list_all_users(self) -> List[User]:
        """List all users with learned pagination"""
        try:
            return await self.repository.list_all()
        except Exception as e:
            self.logger.error(f"Failed to list users: {e}")
            return []
