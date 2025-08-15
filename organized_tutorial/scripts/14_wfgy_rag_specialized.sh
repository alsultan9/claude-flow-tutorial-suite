#!/bin/bash

# 14_wfgy_rag_specialized.sh - WFGY RAG Specialized Refactoring
# Specialized refactoring for RAG chatbot systems with PDF/OCR

set -euo pipefail

PROJECT_DIR=""
RAG_TYPE="pdf_ocr"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# WFGY Functions
bbmc() { echo -e "${CYAN}[BBMC]${NC} $*"; }
bbpf() { echo -e "${PURPLE}[BBPF]${NC} $*"; }
bbcr() { echo -e "${RED}[BBCR]${NC} $*"; }
bbam() { echo -e "${YELLOW}[BBAM]${NC} $*"; }
success() { echo -e "${GREEN}[success]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }

# RAG-Specific Components
create_rag_models() {
  local project_dir="$1"
  
  bbam "Creating RAG-specific data models..."
  
  mkdir -p "$project_dir/models"
  
  # Document Model
  cat > "$project_dir/models/document.py" << 'EOF'
"""
Document Model - RAG System
"""
from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime
from enum import Enum

class DocumentType(Enum):
    PDF = "pdf"
    IMAGE = "image"
    TEXT = "text"

class ProcessingStatus(Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

@dataclass
class Document:
    id: Optional[int] = None
    filename: str = ""
    file_path: str = ""
    content: str = ""
    document_type: DocumentType = DocumentType.PDF
    processing_status: ProcessingStatus = ProcessingStatus.PENDING
    page_count: int = 0
    file_size: int = 0
    created_at: Optional[datetime] = None
    processed_at: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'filename': self.filename,
            'file_path': self.file_path,
            'content': self.content,
            'document_type': self.document_type.value,
            'processing_status': self.processing_status.value,
            'page_count': self.page_count,
            'file_size': self.file_size,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'processed_at': self.processed_at.isoformat() if self.processed_at else None
        }
EOF

  # Chunk Model
  cat > "$project_dir/models/chunk.py" << 'EOF'
"""
Chunk Model - RAG System
"""
from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime

@dataclass
class Chunk:
    id: Optional[int] = None
    document_id: int = 0
    chunk_text: str = ""
    chunk_embedding: Optional[List[float]] = None
    page_number: int = 0
    chunk_index: int = 0
    metadata: Optional[dict] = None
    created_at: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'document_id': self.document_id,
            'chunk_text': self.chunk_text,
            'chunk_embedding': self.chunk_embedding,
            'page_number': self.page_number,
            'chunk_index': self.chunk_index,
            'metadata': self.metadata,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
EOF

  # Query Model
  cat > "$project_dir/models/query.py" << 'EOF'
"""
Query Model - RAG System
"""
from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime

@dataclass
class Query:
    id: Optional[int] = None
    user_query: str = ""
    query_embedding: Optional[List[float]] = None
    relevant_chunks: Optional[List[int]] = None
    response: str = ""
    confidence_score: float = 0.0
    processing_time: float = 0.0
    created_at: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'user_query': self.user_query,
            'query_embedding': self.query_embedding,
            'relevant_chunks': self.relevant_chunks,
            'response': self.response,
            'confidence_score': self.confidence_score,
            'processing_time': self.processing_time,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
EOF

  success "RAG models created"
}

create_rag_services() {
  local project_dir="$1"
  
  bbam "Creating RAG-specific services..."
  
  mkdir -p "$project_dir/services"
  
  # PDF Processing Service
  cat > "$project_dir/services/pdf_processor.py" << 'EOF'
"""
PDF Processing Service - BBAM Priority 1
Handles PDF text extraction and OCR
"""
import logging
import fitz  # PyMuPDF
import pytesseract
from PIL import Image
import numpy as np
from typing import Optional, Tuple, List
from ..models.document import Document, ProcessingStatus
from ..config import config

logger = logging.getLogger(__name__)

class PDFProcessor:
    def __init__(self):
        self.ocr_config = config.ocr
        self.processing_config = config.processing
        
    async def extract_text_from_pdf(self, pdf_path: str) -> Optional[str]:
        """BBAM Priority 1: Critical PDF text extraction"""
        try:
            doc = fitz.open(pdf_path)
            text = ""
            
            for page_num, page in enumerate(doc):
                # Try direct text extraction first
                page_text = page.get_text()
                
                if not page_text.strip():
                    # Fallback to OCR if no text found
                    logger.info(f"Page {page_num + 1} has no text, using OCR")
                    page_text = await self._extract_text_with_ocr(page)
                
                text += f"Page {page_num + 1}: {page_text}\n"
            
            doc.close()
            return text
            
        except Exception as e:
            logger.error(f"Failed to extract text from PDF {pdf_path}: {e}")
            return None
    
    async def _extract_text_with_ocr(self, page) -> str:
        """BBAM Priority 1: Critical OCR processing"""
        try:
            # Convert page to image
            pix = page.get_pixmap()
            img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
            
            # Apply OCR
            ocr_text = pytesseract.image_to_string(
                img, 
                config=self.ocr_config.tesseract_config
            )
            
            return ocr_text
            
        except Exception as e:
            logger.error(f"OCR processing failed: {e}")
            return ""
    
    async def should_use_ocr(self, image: Image.Image) -> bool:
        """BBAM Priority 2: Image analysis for OCR decision"""
        try:
            # Convert to grayscale
            gray = image.convert('L')
            arr = np.array(gray)
            
            # Calculate image statistics
            mean_brightness = np.mean(arr)
            std_brightness = np.std(arr)
            
            # BBMC: Configurable thresholds
            return (mean_brightness < self.ocr_config.brightness_threshold or 
                   std_brightness < self.ocr_config.contrast_threshold)
                   
        except Exception as e:
            logger.error(f"Image analysis failed: {e}")
            return False
    
    async def process_document(self, document: Document) -> bool:
        """BBPF: Progressive document processing pipeline"""
        try:
            # Step 1: Update status to processing
            document.processing_status = ProcessingStatus.PROCESSING
            
            # Step 2: Extract text
            content = await self.extract_text_from_pdf(document.file_path)
            if not content:
                document.processing_status = ProcessingStatus.FAILED
                return False
            
            # Step 3: Update document
            document.content = content
            document.processing_status = ProcessingStatus.COMPLETED
            
            logger.info(f"Successfully processed document: {document.filename}")
            return True
            
        except Exception as e:
            logger.error(f"Document processing failed: {e}")
            document.processing_status = ProcessingStatus.FAILED
            return False
EOF

  # Embedding Service
  cat > "$project_dir/services/embedding_service.py" << 'EOF'
"""
Embedding Service - BBAM Priority 1
Handles text embeddings and vector operations
"""
import logging
import numpy as np
from typing import Optional, List
import openai
from sentence_transformers import SentenceTransformer
from ..config import config

logger = logging.getLogger(__name__)

class EmbeddingService:
    def __init__(self):
        self.embedding_config = config.embedding
        
        # Initialize embedding model
        if self.embedding_config.use_local_model:
            self.model = SentenceTransformer(self.embedding_config.local_model_name)
        else:
            openai.api_key = self.embedding_config.openai_api_key
    
    async def get_embedding(self, text: str) -> Optional[List[float]]:
        """BBAM Priority 1: Critical embedding generation"""
        try:
            if self.embedding_config.use_local_model:
                return await self._get_local_embedding(text)
            else:
                return await self._get_openai_embedding(text)
                
        except Exception as e:
            logger.error(f"Embedding generation failed: {e}")
            return None
    
    async def _get_local_embedding(self, text: str) -> List[float]:
        """BBAM Priority 2: Local embedding generation"""
        try:
            embedding = self.model.encode(text)
            return embedding.tolist()
        except Exception as e:
            logger.error(f"Local embedding failed: {e}")
            return []
    
    async def _get_openai_embedding(self, text: str) -> Optional[List[float]]:
        """BBAM Priority 2: OpenAI embedding generation"""
        try:
            response = openai.Embedding.create(
                input=text,
                model=self.embedding_config.openai_model
            )
            return response['data'][0]['embedding']
        except Exception as e:
            logger.error(f"OpenAI embedding failed: {e}")
            return None
    
    async def calculate_similarity(self, embedding1: List[float], embedding2: List[float]) -> float:
        """BBAM Priority 2: Vector similarity calculation"""
        try:
            vec1 = np.array(embedding1)
            vec2 = np.array(embedding2)
            
            # Cosine similarity
            similarity = np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2))
            return float(similarity)
            
        except Exception as e:
            logger.error(f"Similarity calculation failed: {e}")
            return 0.0
    
    async def batch_get_embeddings(self, texts: List[str]) -> List[Optional[List[float]]]:
        """BBAM Priority 3: Batch embedding generation"""
        embeddings = []
        for text in texts:
            embedding = await self.get_embedding(text)
            embeddings.append(embedding)
        return embeddings
EOF

  # Vector Database Service
  cat > "$project_dir/services/vector_store.py" << 'EOF'
"""
Vector Store Service - BBAM Priority 1
Handles vector database operations
"""
import logging
import chromadb
from typing import List, Optional, Dict, Any
from ..models.chunk import Chunk
from ..models.document import Document
from ..config import config

logger = logging.getLogger(__name__)

class VectorStore:
    def __init__(self):
        self.vector_config = config.vector_store
        self.client = chromadb.PersistentClient(path=self.vector_config.chroma_path)
        self.collection = self.client.get_or_create_collection(
            name=self.vector_config.collection_name,
            metadata={"hnsw:space": "cosine"}
        )
    
    async def add_chunks(self, chunks: List[Chunk]) -> bool:
        """BBAM Priority 1: Critical chunk storage"""
        try:
            if not chunks:
                return True
            
            # Prepare data for ChromaDB
            ids = [str(chunk.id) for chunk in chunks]
            texts = [chunk.chunk_text for chunk in chunks]
            embeddings = [chunk.chunk_embedding for chunk in chunks]
            metadatas = [chunk.metadata or {} for chunk in chunks]
            
            # Add to collection
            self.collection.add(
                ids=ids,
                documents=texts,
                embeddings=embeddings,
                metadatas=metadatas
            )
            
            logger.info(f"Successfully added {len(chunks)} chunks to vector store")
            return True
            
        except Exception as e:
            logger.error(f"Failed to add chunks to vector store: {e}")
            return False
    
    async def search_similar(self, query_embedding: List[float], top_k: int = 5) -> List[Dict[str, Any]]:
        """BBAM Priority 1: Critical similarity search"""
        try:
            results = self.collection.query(
                query_embeddings=[query_embedding],
                n_results=top_k
            )
            
            # Format results
            formatted_results = []
            for i in range(len(results['ids'][0])):
                formatted_results.append({
                    'id': results['ids'][0][i],
                    'text': results['documents'][0][i],
                    'distance': results['distances'][0][i],
                    'metadata': results['metadatas'][0][i]
                })
            
            return formatted_results
            
        except Exception as e:
            logger.error(f"Vector search failed: {e}")
            return []
    
    async def delete_document_chunks(self, document_id: int) -> bool:
        """BBAM Priority 2: Document chunk deletion"""
        try:
            # Get chunks for document
            results = self.collection.get(
                where={"document_id": document_id}
            )
            
            if results['ids']:
                self.collection.delete(ids=results['ids'])
                logger.info(f"Deleted {len(results['ids'])} chunks for document {document_id}")
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete document chunks: {e}")
            return False
EOF

  # RAG Chat Service
  cat > "$project_dir/services/rag_chat_service.py" << 'EOF'
"""
RAG Chat Service - BBAM Priority 1
Main RAG orchestration service
"""
import logging
import time
from typing import Optional, List, Dict, Any
import openai
from ..models.query import Query
from ..models.chunk import Chunk
from ..services.embedding_service import EmbeddingService
from ..services.vector_store import VectorStore
from ..config import config

logger = logging.getLogger(__name__)

class RAGChatService:
    def __init__(self):
        self.chat_config = config.chat
        self.embedding_service = EmbeddingService()
        self.vector_store = VectorStore()
        
        if not self.chat_config.use_local_model:
            openai.api_key = self.chat_config.openai_api_key
    
    async def process_query(self, user_query: str) -> Query:
        """BBPF: Progressive RAG pipeline"""
        start_time = time.time()
        
        query = Query(user_query=user_query)
        
        try:
            # Step 1: Generate query embedding
            query_embedding = await self.embedding_service.get_embedding(user_query)
            if not query_embedding:
                query.response = "Sorry, I couldn't process your query."
                return query
            
            query.query_embedding = query_embedding
            
            # Step 2: Search for relevant chunks
            relevant_results = await self.vector_store.search_similar(
                query_embedding, 
                top_k=self.chat_config.top_k_chunks
            )
            
            if not relevant_results:
                query.response = "I couldn't find relevant information to answer your question."
                return query
            
            query.relevant_chunks = [int(r['id']) for r in relevant_results]
            
            # Step 3: Generate response
            context_chunks = [r['text'] for r in relevant_results]
            response = await self._generate_response(user_query, context_chunks)
            
            query.response = response
            query.confidence_score = self._calculate_confidence(relevant_results)
            
        except Exception as e:
            logger.error(f"Query processing failed: {e}")
            query.response = "Sorry, an error occurred while processing your query."
        
        finally:
            query.processing_time = time.time() - start_time
            query.created_at = time.time()
        
        return query
    
    async def _generate_response(self, query: str, context_chunks: List[str]) -> str:
        """BBAM Priority 1: Critical response generation"""
        try:
            context = "\n\n".join(context_chunks)
            
            if self.chat_config.use_local_model:
                return await self._generate_local_response(query, context)
            else:
                return await self._generate_openai_response(query, context)
                
        except Exception as e:
            logger.error(f"Response generation failed: {e}")
            return "Sorry, I couldn't generate a response."
    
    async def _generate_openai_response(self, query: str, context: str) -> str:
        """BBAM Priority 2: OpenAI response generation"""
        try:
            prompt = f"""
            Context: {context}
            
            Question: {query}
            
            Answer based on the context above. If the context doesn't contain relevant information, say so.
            """
            
            response = openai.ChatCompletion.create(
                model=self.chat_config.openai_model,
                messages=[
                    {"role": "system", "content": self.chat_config.system_prompt},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=self.chat_config.max_tokens,
                temperature=self.chat_config.temperature
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            logger.error(f"OpenAI response generation failed: {e}")
            return "Sorry, I couldn't generate a response."
    
    async def _generate_local_response(self, query: str, context: str) -> str:
        """BBAM Priority 2: Local model response generation"""
        # Placeholder for local model implementation
        return f"Based on the context: {context[:200]}... (Local model response)"
    
    def _calculate_confidence(self, results: List[Dict[str, Any]]) -> float:
        """BBAM Priority 3: Confidence score calculation"""
        if not results:
            return 0.0
        
        # Calculate average similarity score
        distances = [r['distance'] for r in results]
        avg_distance = sum(distances) / len(distances)
        
        # Convert distance to confidence (lower distance = higher confidence)
        confidence = max(0.0, 1.0 - avg_distance)
        return confidence
EOF

  success "RAG services created"
}

create_rag_config() {
  local project_dir="$1"
  
  bbam "Creating RAG-specific configuration..."
  
  cat > "$project_dir/config.py" << 'EOF'
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
EOF

  success "RAG configuration created"
}

main() {
  echo -e "\n${CYAN}🏥 WFGY RAG Specialized Refactoring${NC}"
  echo -e "${PURPLE}====================================${NC}\n"
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -p|--project)
        PROJECT_DIR="$2"
        shift 2
        ;;
      -t|--type)
        RAG_TYPE="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: $0 -p PROJECT_DIR [-t RAG_TYPE]"
        echo "RAG types: pdf_ocr, text_only, multimodal"
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
  done
  
  [[ -n "$PROJECT_DIR" ]] || { echo "Project directory required (-p)"; exit 1; }
  [[ -d "$PROJECT_DIR" ]] || { echo "Project directory does not exist: $PROJECT_DIR"; exit 1; }
  
  echo -e "${WHITE}Project:${NC} $PROJECT_DIR"
  echo -e "${WHITE}RAG Type:${NC} $RAG_TYPE"
  echo ""
  
  # Apply RAG-specific refactoring
  create_rag_models "$PROJECT_DIR"
  create_rag_services "$PROJECT_DIR"
  create_rag_config "$PROJECT_DIR"
  
  success "WFGY RAG specialized refactoring completed!"
  
  echo ""
  echo -e "${CYAN}🏥 WFGY RAG Refactoring Complete${NC}"
  echo -e "${PURPLE}================================${NC}"
}

main "$@"
