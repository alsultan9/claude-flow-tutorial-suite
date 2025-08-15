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
