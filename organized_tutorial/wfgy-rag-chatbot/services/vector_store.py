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
