"""
Ultimate Configuration Management - BBPF Step 1
Environment-based configuration with validation
"""
import os
from typing import Optional, Dict, Any
from dataclasses import dataclass, field
from pathlib import Path

@dataclass
class DatabaseConfig:
    url: str
    pool_size: int = 10
    max_overflow: int = 20
    echo: bool = False

@dataclass
class APIConfig:
    base_url: str
    timeout: int = 30
    retries: int = 3
    api_key: Optional[str] = None

@dataclass
class AppConfig:
    debug: bool = False
    log_level: str = "INFO"
    environment: str = "development"
    storage_path: str = "./storage"

@dataclass
class SecurityConfig:
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

class Config:
    def __init__(self):
        self.database = DatabaseConfig(
            url=os.getenv("DATABASE_URL", "sqlite:///app.db"),
            pool_size=int(os.getenv("DB_POOL_SIZE", "10")),
            max_overflow=int(os.getenv("DB_MAX_OVERFLOW", "20")),
            echo=os.getenv("DB_ECHO", "false").lower() == "true"
        )
        
        self.api = APIConfig(
            base_url=os.getenv("API_BASE_URL", "https://api.example.com"),
            timeout=int(os.getenv("API_TIMEOUT", "30")),
            retries=int(os.getenv("API_RETRIES", "3")),
            api_key=os.getenv("API_KEY")
        )
        
        self.app = AppConfig(
            debug=os.getenv("DEBUG", "false").lower() == "true",
            log_level=os.getenv("LOG_LEVEL", "INFO"),
            environment=os.getenv("ENVIRONMENT", "development"),
            storage_path=os.getenv("STORAGE_PATH", "./storage")
        )
        
        self.security = SecurityConfig(
            secret_key=os.getenv("SECRET_KEY", "your-secret-key-here"),
            algorithm=os.getenv("JWT_ALGORITHM", "HS256"),
            access_token_expire_minutes=int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
        )
    
    def validate(self) -> bool:
        """BBMC: Configuration validation"""
        required_vars = [
            self.database.url,
            self.api.base_url,
            self.security.secret_key
        ]
        return all(var for var in required_vars)

config = Config()
