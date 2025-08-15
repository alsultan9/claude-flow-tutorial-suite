"""
User Service Tests - BBAM Priority 2
"""
import pytest
from unittest.mock import Mock, AsyncMock
from ..services.user_service import UserService
from ..models.user import User

@pytest.mark.asyncio
async def test_fetch_user_success():
    """Test successful user fetch"""
    service = UserService()
    service.session = Mock()
    service.session.get = AsyncMock()
    service.session.get.return_value.json.return_value = {
        'id': 1, 'name': 'Test User', 'email': 'test@example.com'
    }
    service.session.get.return_value.raise_for_status = Mock()
    
    user = await service.fetch_user(1)
    assert user is not None
    assert user.name == 'Test User'

@pytest.mark.asyncio
async def test_fetch_user_failure():
    """Test failed user fetch"""
    service = UserService()
    service.session = Mock()
    service.session.get = AsyncMock(side_effect=Exception("API Error"))
    
    user = await service.fetch_user(1)
    assert user is None
