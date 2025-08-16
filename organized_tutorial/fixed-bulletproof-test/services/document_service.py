"""
Document Service - BBAM Priority 1
Business logic for document operations
"""
import logging
from typing import Optional, List
from ..models.document import Document
from ..repositories.document_repository import DocumentRepository

logger = logging.getLogger(__name__)

class DocumentService:
    def __init__(self):
        self.repository = DocumentRepository()
        self.logger = logging.getLogger(__name__)
    
    async def create_document(self, document: Document) -> Optional[Document]:
        """Create new document with validation"""
        try:
            if not document.validate():
                self.logger.error("Document validation failed")
                return None
            
            document.update_timestamps()
            created_document = await self.repository.create(document)
            self.logger.info(f"Created document: {created_document.filename}")
            return created_document
        except Exception as e:
            self.logger.error(f"Failed to create document: {e}")
            return None
    
    async def get_document_by_id(self, document_id: str) -> Optional[Document]:
        """Get document by ID"""
        try:
            return await self.repository.get_by_id(document_id)
        except Exception as e:
            self.logger.error(f"Failed to get document: {e}")
            return None
    
    async def update_document(self, document: Document) -> bool:
        """Update document"""
        try:
            if not document.validate():
                return False
            
            document.update_timestamps()
            return await self.repository.update(document)
        except Exception as e:
            self.logger.error(f"Failed to update document: {e}")
            return False
    
    async def delete_document(self, document_id: str) -> bool:
        """Delete document"""
        try:
            return await self.repository.delete(document_id)
        except Exception as e:
            self.logger.error(f"Failed to delete document: {e}")
            return False
    
    async def list_all_documents(self) -> List[Document]:
        """List all documents"""
        try:
            return await self.repository.list_all()
        except Exception as e:
            self.logger.error(f"Failed to list documents: {e}")
            return []
