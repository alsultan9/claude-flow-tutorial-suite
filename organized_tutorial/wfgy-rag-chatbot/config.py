"""
RAG System Configuration - BBMC Advanced Fix
Environment-based configuration for RAG system
"""
import os
from dataclasses import dataclass
from typing import Optional

@dataclass
class OCRConfig:
    tesseract_config: str = "--psm 6"
    brightness_threshold: int = 200
    contrast_threshold: int = 50
    enable_ocr: bool = True

@dataclass
class ProcessingConfig:
    chunk_size: int = 1000
    chunk_overlap: int = 200
    max_file_size: int = 50 * 1024 * 1024  # 50MB
    supported_formats: list = None
    
    def __post_init__(self):
        if self.supported_formats is None:
            self.supported_formats = ['.pdf', '.txt', '.docx']

@dataclass
class EmbeddingConfig:
    use_local_model: bool = True
    local_model_name: str = "all-MiniLM-L6-v2"
    openai_model: str = "text-embedding-ada-002"
    openai_api_key: Optional[str] = None
    embedding_dimension: int = 384

@dataclass
class VectorStoreConfig:
    chroma_path: str = "./chroma_db"
    collection_name: str = "rag_documents"
    similarity_metric: str = "cosine"

@dataclass
class ChatConfig:
    use_local_model: bool = False
    openai_model: str = "gpt-3.5-turbo"
    openai_api_key: Optional[str] = None
    system_prompt: str = "You are a helpful assistant that answers questions based on the provided context."
    max_tokens: int = 500
    temperature: float = 0.7
    top_k_chunks: int = 5

@dataclass
class DatabaseConfig:
    url: str = "sqlite:///rag_system.db"
    pool_size: int = 10
    max_overflow: int = 20

@dataclass
class AppConfig:
    debug: bool = False
    log_level: str = "INFO"
    environment: str = "development"
    storage_path: str = "./uploads"

class Config:
    def __init__(self):
        self.ocr = OCRConfig(
            tesseract_config=os.getenv("TESSERACT_CONFIG", "--psm 6"),
            brightness_threshold=int(os.getenv("BRIGHTNESS_THRESHOLD", "200")),
            contrast_threshold=int(os.getenv("CONTRAST_THRESHOLD", "50")),
            enable_ocr=os.getenv("ENABLE_OCR", "true").lower() == "true"
        )
        
        self.processing = ProcessingConfig(
            chunk_size=int(os.getenv("CHUNK_SIZE", "1000")),
            chunk_overlap=int(os.getenv("CHUNK_OVERLAP", "200")),
            max_file_size=int(os.getenv("MAX_FILE_SIZE", str(50 * 1024 * 1024)))
        )
        
        self.embedding = EmbeddingConfig(
            use_local_model=os.getenv("USE_LOCAL_MODEL", "true").lower() == "true",
            local_model_name=os.getenv("LOCAL_MODEL_NAME", "all-MiniLM-L6-v2"),
            openai_model=os.getenv("OPENAI_EMBEDDING_MODEL", "text-embedding-ada-002"),
            openai_api_key=os.getenv("OPENAI_API_KEY")
        )
        
        self.vector_store = VectorStoreConfig(
            chroma_path=os.getenv("CHROMA_PATH", "./chroma_db"),
            collection_name=os.getenv("COLLECTION_NAME", "rag_documents")
        )
        
        self.chat = ChatConfig(
            use_local_model=os.getenv("USE_LOCAL_CHAT_MODEL", "false").lower() == "true",
            openai_model=os.getenv("OPENAI_CHAT_MODEL", "gpt-3.5-turbo"),
            openai_api_key=os.getenv("OPENAI_API_KEY"),
            system_prompt=os.getenv("SYSTEM_PROMPT", "You are a helpful assistant that answers questions based on the provided context."),
            max_tokens=int(os.getenv("MAX_TOKENS", "500")),
            temperature=float(os.getenv("TEMPERATURE", "0.7")),
            top_k_chunks=int(os.getenv("TOP_K_CHUNKS", "5"))
        )
        
        self.database = DatabaseConfig(
            url=os.getenv("DATABASE_URL", "sqlite:///rag_system.db")
        )
        
        self.app = AppConfig(
            debug=os.getenv("DEBUG", "false").lower() == "true",
            log_level=os.getenv("LOG_LEVEL", "INFO"),
            environment=os.getenv("ENVIRONMENT", "development"),
            storage_path=os.getenv("STORAGE_PATH", "./uploads")
        )

config = Config()
