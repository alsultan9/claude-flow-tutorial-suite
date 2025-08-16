"""
Main Application - BBPF Priority 1
Clean application entry point
"""
import asyncio
import logging
from .config import config

logging.basicConfig(level=getattr(logging, config.app.log_level))
logger = logging.getLogger(__name__)

class Application:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    async def run(self):
        """Main application loop"""
        self.logger.info("Starting application")
        try:
            # Application logic here
            self.logger.info("Application running successfully")
        except Exception as e:
            self.logger.error(f"Application error: {e}")

async def main():
    app = Application()
    await app.run()

if __name__ == "__main__":
    asyncio.run(main())
