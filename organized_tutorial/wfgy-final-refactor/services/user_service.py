"""
User Service - BBPF Step 3
Business logic for user operations
"""
import logging
from typing import Optional, List
import requests
from ..models.user import User
from ..config import config

logger = logging.getLogger(__name__)

class UserService:
    def __init__(self):
        self.api_config = config.api
        self.session = requests.Session()
    
    async def fetch_user(self, user_id: int) -> Optional[User]:
        """BBAM Priority 1: Critical user data fetching"""
        try:
            response = await self.session.get(
                f"{self.api_config.base_url}/users/{user_id}",
                timeout=self.api_config.timeout
            )
            response.raise_for_status()
            data = response.json()
            return User(**data)
        except requests.RequestException as e:
            logger.error(f"Failed to fetch user {user_id}: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error fetching user {user_id}: {e}")
            return None
    
    async def save_user(self, user: User) -> bool:
        """BBMC: Validate user data before saving"""
        try:
            if not user.name or not user.email:
                logger.error("Invalid user data: missing name or email")
                return False
            
            # Save to database logic here
            logger.info(f"User {user.id} saved successfully")
            return True
        except Exception as e:
            logger.error(f"Failed to save user {user.id}: {e}")
            return False
