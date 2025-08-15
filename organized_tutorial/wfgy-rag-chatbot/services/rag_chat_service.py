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
