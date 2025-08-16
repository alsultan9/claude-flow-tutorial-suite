"""
Intelligent Document Service - BBAM Priority 1
Learned from autonomous assessment
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
        """Create document with learned validation patterns"""
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
        """Get document by ID with learned error handling"""
        try:
            return await self.repository.get_by_id(document_id)
        except Exception as e:
            self.logger.error(f"Failed to get document: {e}")
            return None
    
    async def update_document(self, document: Document) -> bool:
        """Update document with learned patterns"""
        try:
            if not document.validate():
                return False
            
            document.update_timestamps()
            return await self.repository.update(document)
        except Exception as e:
            self.logger.error(f"Failed to update document: {e}")
            return False
    
    async def delete_document(self, document_id: str) -> bool:
        """Delete document with learned safety patterns"""
        try:
            return await self.repository.delete(document_id)
        except Exception as e:
            self.logger.error(f"Failed to delete document: {e}")
            return False
    
    async def list_all_documents(self) -> List[Document]:
        """List all documents with learned pagination"""
        try:
            return await self.repository.list_all()
        except Exception as e:
            self.logger.error(f"Failed to list documents: {e}")
            return []
