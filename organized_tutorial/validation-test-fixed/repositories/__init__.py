"""
Ultimate Repository Layer - BBPF Step 4
Data access with proper abstraction
"""
from .base_repository import BaseRepository
from .user_repository import UserRepository
from .document_repository import DocumentRepository

__all__ = ['BaseRepository', 'UserRepository', 'DocumentRepository']
