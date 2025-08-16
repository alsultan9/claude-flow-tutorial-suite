"""
Service Tests - BBAM Priority 3
"""
import pytest
from unittest.mock import Mock, AsyncMock
from ..services.user_service import UserService
from ..services.document_service import DocumentService
from ..models.user import User
from ..models.document import Document

@pytest.mark.asyncio
async def test_user_service_create():
    """Test user service create"""
    service = UserService()
    service.repository = Mock()
    service.repository.create = AsyncMock()
    
    user = User(
        username="testuser",
        email="test@example.com",
        full_name="Test User"
    )
    
    result = await service.create_user(user)
    assert result is not None

@pytest.mark.asyncio
async def test_document_service_create():
    """Test document service create"""
    service = DocumentService()
    service.repository = Mock()
    service.repository.create = AsyncMock()
    
    document = Document(
        filename="test.pdf",
        file_path="/tmp/test.pdf",
        content="Test content"
    )
    
    result = await service.create_document(document)
    assert result is not None
