"""
Order Service - BBCR Advanced Fix
Business logic for order operations
"""
import logging
from typing import Optional, List
from ..models.order import Order
from ..repositories.order_repository import OrderRepository
from .interfaces import IOrderService

logger = logging.getLogger(__name__)

class OrderService(IOrderService):
    def __init__(self, order_repository: OrderRepository):
        self.order_repository = order_repository
    
    async def get_user_orders_total(self, user_id: int) -> float:
        """BBCR: Business logic separated from data access"""
        try:
            orders = await self.order_repository.get_user_orders(user_id)
            total = sum(order.amount for order in orders)
            
            # BBCR: Business logic for discounts
            if total > 1000:
                discount = total * 0.1
                total -= discount
                logger.info(f"Applied 10% discount for user {user_id}")
            
            return total
        except Exception as e:
            logger.error(f"Failed to calculate orders total for user {user_id}: {e}")
            return 0.0
    
    async def process_order(self, order: Order) -> bool:
        """BBCR: Business logic for order processing"""
        try:
            # BBCR: Business validation
            if order.amount <= 0:
                logger.error(f"Invalid order amount: {order.amount}")
                return False
            
            # BBCR: Business rules
            if order.amount > 10000:
                logger.warning(f"Large order detected: {order.amount}")
            
            # BBCR: Save order
            success = await self.order_repository.save_order(order)
            if success:
                logger.info(f"Order {order.id} processed successfully")
            
            return success
        except Exception as e:
            logger.error(f"Failed to process order {order.id}: {e}")
            return False
