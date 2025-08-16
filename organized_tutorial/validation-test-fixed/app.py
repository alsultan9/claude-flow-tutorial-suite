"""
Ultimate Main Application - BBPF Step 5
Clean application entry point with proper orchestration
"""
import asyncio
import logging
from typing import Optional
from .config import config
from .services.user_service import UserService
from .services.document_service import DocumentService

# BBMC: Proper logging setup
logging.basicConfig(
    level=getattr(logging, config.app.log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class UltimateApplication:
    def __init__(self):
        self.user_service = UserService()
        self.document_service = DocumentService()
        self.logger = logging.getLogger(__name__)
    
    async def initialize(self):
        """BBPF: Application initialization"""
        try:
            # Validate configuration
            if not config.validate():
                raise ValueError("Invalid configuration")
            
            self.logger.info("Application initialized successfully")
            return True
        except Exception as e:
            self.logger.error(f"Application initialization failed: {e}")
            return False
    
    async def run(self):
        """BBPF: Main application loop"""
        self.logger.info("Starting Ultimate Application")
        
        try:
            # Initialize application
            if not await self.initialize():
                self.logger.error("Failed to initialize application")
                return
            
            # Example usage
            await self.example_workflow()
            
        except Exception as e:
            self.logger.error(f"Application error: {e}")
        finally:
            self.logger.info("Application stopped")
    
    async def example_workflow(self):
        """BBPF: Example workflow"""
        try:
            # Create user
            from .models.user import User
            user = User(
                username="testuser",
                email="test@example.com",
                full_name="Test User"
            )
            
            if user.validate():
                created_user = await self.user_service.create(user)
                if created_user:
                    self.logger.info(f"Created user: {created_user.username}")
            
        except Exception as e:
            self.logger.error(f"Workflow error: {e}")

async def main():
    """BBPF: Clean entry point"""
    app = UltimateApplication()
    await app.run()

if __name__ == "__main__":
    asyncio.run(main())
