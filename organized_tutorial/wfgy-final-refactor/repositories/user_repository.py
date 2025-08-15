"""
User Repository - BBPF Step 4
Data access for users
"""
import logging
from typing import Optional, List
import sqlite3
from ..models.user import User
from ..config import config

logger = logging.getLogger(__name__)

class UserRepository:
    def __init__(self):
        self.db_path = config.database.url.replace("sqlite:///", "")
    
    def get_connection(self):
        """BBMC: Proper connection management"""
        try:
            return sqlite3.connect(self.db_path)
        except sqlite3.Error as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    async def get_user(self, user_id: int) -> Optional[User]:
        """BBAM Priority 1: Critical data access"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "SELECT id, name, email FROM users WHERE id = ?",
                    (user_id,)
                )
                row = cursor.fetchone()
                if row:
                    return User(id=row[0], name=row[1], email=row[2])
                return None
        except Exception as e:
            logger.error(f"Failed to get user {user_id}: {e}")
            return None
    
    async def save_user(self, user: User) -> bool:
        """BBMC: Validate data before database operations"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT OR REPLACE INTO users (id, name, email) VALUES (?, ?, ?)",
                    (user.id, user.name, user.email)
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error(f"Failed to save user {user.id}: {e}")
            return False
