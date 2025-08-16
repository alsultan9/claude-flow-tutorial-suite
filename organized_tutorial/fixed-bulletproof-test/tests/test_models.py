"""
Model Tests - BBAM Priority 3
"""
import pytest
from ..models.user import User
from ..models.document import Document

def test_user_validation():
    """Test user validation"""
    user = User(
        username="testuser",
        email="test@example.com",
        full_name="Test User"
    )
    assert user.validate() == True

def test_user_invalid_email():
    """Test invalid email validation"""
    user = User(
        username="testuser",
        email="invalid-email",
        full_name="Test User"
    )
    assert user.validate() == False

def test_document_validation():
    """Test document validation"""
    document = Document(
        filename="test.pdf",
        file_path="/tmp/test.pdf",
        content="Test content"
    )
    assert document.validate() == True

def test_document_invalid_filename():
    """Test invalid filename validation"""
    document = Document(
        filename="test<>.pdf",
        file_path="/tmp/test.pdf",
        content="Test content"
    )
    assert document.validate() == False
