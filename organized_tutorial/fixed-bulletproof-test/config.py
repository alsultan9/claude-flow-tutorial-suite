"""
Configuration Management - BBMC Priority 1
Environment-based configuration with validation
"""
import os
from typing import Optional
from dataclasses import dataclass

@dataclass
class DatabaseConfig:
    url: str
    pool_size: int = 10
    max_overflow: int = 20
    echo: bool = False

@dataclass
class AppConfig:
    debug: bool = False
    log_level: str = "INFO"
    environment: str = "development"

class Config:
    def __init__(self):
        self.database = DatabaseConfig(
            url=os.getenv("DATABASE_URL", "sqlite:///app.db")
        )
        self.app = AppConfig(
            debug=os.getenv("DEBUG", "false").lower() == "true",
            log_level=os.getenv("LOG_LEVEL", "INFO")
        )
    
    def validate(self) -> bool:
        return bool(self.database.url)

config = Config()
