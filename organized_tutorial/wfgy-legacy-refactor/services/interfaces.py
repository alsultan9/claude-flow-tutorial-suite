"""
Service Interfaces - BBCR Advanced Fix
Clear separation of concerns
"""
from abc import ABC, abstractmethod
from typing import Optional, List
from ..models.user import User
from ..models.order import Order

class IUserService(ABC):
    """BBCR: Clear interface for user operations"""
    @abstractmethod
    async def fetch_user(self, user_id: int) -> Optional[User]:
        """Fetch user data - data access concern"""
        pass
    
    @abstractmethod
    async def save_user(self, user: User) -> bool:
        """Save user data - persistence concern"""
        pass
    
    @abstractmethod
    async def validate_user(self, user: User) -> bool:
        """Validate user data - business logic concern"""
        pass

class IOrderService(ABC):
    """BBCR: Clear interface for order operations"""
    @abstractmethod
    async def get_user_orders_total(self, user_id: int) -> float:
        """Get user orders total - business logic concern"""
        pass
    
    @abstractmethod
    async def process_order(self, order: Order) -> bool:
        """Process order - business logic concern"""
        pass

class IReportService(ABC):
    """BBCR: Clear interface for report operations"""
    @abstractmethod
    async def create_report(self, user: User, orders_total: float) -> Optional[dict]:
        """Create report - business logic concern"""
        pass
