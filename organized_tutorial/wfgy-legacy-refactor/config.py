"""
Configuration Management - BBPF Step 1
Extracted from legacy hardcoded values
"""
import os
from typing import Optional
from dataclasses import dataclass

@dataclass
class DatabaseConfig:
    url: str
    pool_size: int = 10
    max_overflow: int = 20

@dataclass
class APIConfig:
    base_url: str
    timeout: int = 30
    retries: int = 3

@dataclass
class AppConfig:
    debug: bool = False
    log_level: str = "INFO"
    environment: str = "development"

class Config:
    def __init__(self):
        self.database = DatabaseConfig(
            url=os.getenv("DATABASE_URL", "sqlite:///data.db")
        )
        self.api = APIConfig(
            base_url=os.getenv("API_BASE_URL", "https://api.example.com"),
            timeout=int(os.getenv("API_TIMEOUT", "30")),
            retries=int(os.getenv("API_RETRIES", "3"))
        )
        self.app = AppConfig(
            debug=os.getenv("DEBUG", "false").lower() == "true",
            log_level=os.getenv("LOG_LEVEL", "INFO"),
            environment=os.getenv("ENVIRONMENT", "development")
        )

config = Config()
