"""
Order Repository - BBCR Advanced Fix
Data access for orders
"""
import logging
from typing import Optional, List
import sqlite3
from ..models.order import Order
from ..config import config

logger = logging.getLogger(__name__)

class OrderRepository:
    def __init__(self):
        self.db_path = config.database.url.replace("sqlite:///", "")
    
    def get_connection(self):
        """BBCR: Proper connection management"""
        try:
            return sqlite3.connect(self.db_path)
        except sqlite3.Error as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    async def get_user_orders(self, user_id: int) -> List[Order]:
        """BBCR: Data access concern only"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "SELECT id, user_id, amount, status FROM orders WHERE user_id = ?",
                    (user_id,)
                )
                rows = cursor.fetchall()
                return [Order(id=row[0], user_id=row[1], amount=row[2], status=row[3]) for row in rows]
        except Exception as e:
            logger.error(f"Failed to get orders for user {user_id}: {e}")
            return []
    
    async def save_order(self, order: Order) -> bool:
        """BBCR: Data access concern only"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT OR REPLACE INTO orders (id, user_id, amount, status) VALUES (?, ?, ?, ?)",
                    (order.id, order.user_id, order.amount, order.status)
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error(f"Failed to save order {order.id}: {e}")
            return False
