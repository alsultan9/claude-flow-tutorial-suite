"""
Main Application - BBPF Step 5
Clean application entry point
"""
import asyncio
import logging
from typing import Optional
from .config import config
from .services.user_service import UserService
from .services.order_service import OrderService
from .services.report_service import ReportService

# BBMC: Proper logging setup
logging.basicConfig(
    level=getattr(logging, config.app.log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class Application:
    def __init__(self):
        self.user_service = UserService()
        self.order_service = OrderService()
        self.report_service = ReportService()
    
    async def generate_report(self, user_id: int) -> Optional[dict]:
        """BBPF: Progressive pipeline for report generation"""
        try:
            # Step 1: Fetch user data
            user = await self.user_service.fetch_user(user_id)
            if not user:
                logger.error(f"User {user_id} not found")
                return None
            
            # Step 2: Process orders
            orders_total = await self.order_service.get_user_orders_total(user_id)
            
            # Step 3: Generate report
            report = await self.report_service.create_report(user, orders_total)
            
            logger.info(f"Report generated successfully for user {user_id}")
            return report
            
        except Exception as e:
            logger.error(f"Failed to generate report for user {user_id}: {e}")
            return None
    
    async def run(self):
        """BBPF: Main application loop"""
        logger.info("Application started")
        try:
            # Example usage
            user_id = 123
            report = await self.generate_report(user_id)
            if report:
                logger.info(f"Report: {report}")
            else:
                logger.error("Failed to generate report")
        except Exception as e:
            logger.error(f"Application error: {e}")
        finally:
            logger.info("Application stopped")

async def main():
    """BBPF: Clean entry point"""
    app = Application()
    await app.run()

if __name__ == "__main__":
    asyncio.run(main())
