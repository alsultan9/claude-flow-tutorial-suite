#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Legacy RAG System - Complex Refactoring Test Case
RAG chatbot with PDF processing and OCR capabilities
"""

import os
import sys
import json
import sqlite3
import requests
from datetime import datetime
import logging
import fitz  # PyMuPDF
import pytesseract
from PIL import Image
import numpy as np

# Global variables everywhere - BBMC Issue
PDF_STORAGE_PATH = "/tmp/pdfs"
OCR_ENGINE = "tesseract"
API_KEY = "hardcoded_openai_key_12345"
MODEL_NAME = "gpt-3.5-turbo"
EMBEDDING_MODEL = "text-embedding-ada-002"
CHUNK_SIZE = 1000
OVERLAP = 200

# Monolithic RAG class - BBCR Issue
class LegacyRAGSystem:
    def __init__(self):
        self.db = None
        self.session = requests.Session()
        self.embeddings = {}
        self.documents = {}
        self.chunks = []
        
    def connect_database(self):
        """BBMC: No error handling, hardcoded paths"""
        self.db = sqlite3.connect("rag_data.db")
        self.db.execute("""
            CREATE TABLE IF NOT EXISTS documents (
                id INTEGER PRIMARY KEY,
                filename TEXT,
                content TEXT,
                embeddings TEXT,
                created_at TIMESTAMP
            )
        """)
        self.db.execute("""
            CREATE TABLE IF NOT EXISTS chunks (
                id INTEGER PRIMARY KEY,
                doc_id INTEGER,
                chunk_text TEXT,
                chunk_embedding TEXT,
                page_number INTEGER
            )
        """)
        
    def extract_text_from_pdf(self, pdf_path):
        """BBAM Priority 1: Critical PDF text extraction with poor error handling"""
        try:
            doc = fitz.open(pdf_path)
            text = ""
            for page in doc:
                # BBMC: No OCR fallback for images
                text += page.get_text()
            doc.close()
            return text
        except Exception as e:
            print(f"Error extracting text: {e}")
            return None
            
    def extract_text_with_ocr(self, pdf_path):
        """BBAM Priority 1: Critical OCR processing with mixed concerns"""
        try:
            doc = fitz.open(pdf_path)
            text = ""
            for page_num, page in enumerate(doc):
                # BBMC: Hardcoded image processing
                pix = page.get_pixmap()
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                
                # BBCR: Business logic mixed with image processing
                if self.should_use_ocr(img):
                    ocr_text = pytesseract.image_to_string(img)
                    text += f"Page {page_num + 1}: {ocr_text}\n"
                else:
                    text += page.get_text()
                    
            doc.close()
            return text
        except Exception as e:
            print(f"OCR error: {e}")
            return None
            
    def should_use_ocr(self, image):
        """BBCR: Business logic mixed with image analysis"""
        # Simple heuristic - if image has text-like features
        gray = image.convert('L')
        arr = np.array(gray)
        # BBMC: Hardcoded threshold
        return np.mean(arr) < 200
        
    def chunk_text(self, text):
        """BBAM Priority 2: Text chunking with poor implementation"""
        chunks = []
        words = text.split()
        current_chunk = ""
        
        for word in words:
            if len(current_chunk) + len(word) < CHUNK_SIZE:
                current_chunk += word + " "
            else:
                chunks.append(current_chunk.strip())
                current_chunk = word + " "
                
        if current_chunk:
            chunks.append(current_chunk.strip())
            
        return chunks
        
    def get_embeddings(self, text):
        """BBAM Priority 1: Critical embedding generation with poor error handling"""
        try:
            response = self.session.post(
                "https://api.openai.com/v1/embeddings",
                headers={
                    "Authorization": f"Bearer {API_KEY}",
                    "Content-Type": "application/json"
                },
                json={
                    "input": text,
                    "model": EMBEDDING_MODEL
                }
            )
            if response.status_code == 200:
                return response.json()["data"][0]["embedding"]
            else:
                print(f"Embedding error: {response.status_code}")
                return None
        except Exception as e:
            print(f"Embedding exception: {e}")
            return None
            
    def store_document(self, filename, content):
        """BBMC: No validation, direct database writes"""
        cursor = self.db.cursor()
        embeddings = self.get_embeddings(content)
        if embeddings:
            cursor.execute(
                "INSERT INTO documents (filename, content, embeddings, created_at) VALUES (?, ?, ?, ?)",
                (filename, content, json.dumps(embeddings), datetime.now())
            )
            self.db.commit()
            
    def search_similar_chunks(self, query, top_k=5):
        """BBAM Priority 1: Critical search with poor implementation"""
        try:
            query_embedding = self.get_embeddings(query)
            if not query_embedding:
                return []
                
            cursor = self.db.cursor()
            cursor.execute("SELECT chunk_text, chunk_embedding FROM chunks")
            results = cursor.fetchall()
            
            similarities = []
            for chunk_text, chunk_embedding in results:
                chunk_emb = json.loads(chunk_embedding)
                # BBCR: Simple cosine similarity - could be optimized
                similarity = np.dot(query_embedding, chunk_emb) / (
                    np.linalg.norm(query_embedding) * np.linalg.norm(chunk_emb)
                )
                similarities.append((similarity, chunk_text))
                
            similarities.sort(reverse=True)
            return [text for _, text in similarities[:top_k]]
        except Exception as e:
            print(f"Search error: {e}")
            return []
            
    def generate_response(self, query, context_chunks):
        """BBAM Priority 1: Critical response generation"""
        try:
            context = "\n".join(context_chunks)
            prompt = f"""
            Context: {context}
            
            Question: {query}
            
            Answer based on the context above:
            """
            
            response = self.session.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {API_KEY}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": MODEL_NAME,
                    "messages": [
                        {"role": "system", "content": "You are a helpful assistant that answers questions based on the provided context."},
                        {"role": "user", "content": prompt}
                    ],
                    "max_tokens": 500
                }
            )
            
            if response.status_code == 200:
                return response.json()["choices"][0]["message"]["content"]
            else:
                print(f"Generation error: {response.status_code}")
                return "Sorry, I couldn't generate a response."
        except Exception as e:
            print(f"Generation exception: {e}")
            return "Sorry, an error occurred."
            
    def process_pdf_document(self, pdf_path):
        """BBAM Priority 3: Complex document processing with mixed concerns"""
        filename = os.path.basename(pdf_path)
        
        # Step 1: Extract text with OCR
        text = self.extract_text_with_ocr(pdf_path)
        if not text:
            return False
            
        # Step 2: Store document
        self.store_document(filename, text)
        
        # Step 3: Create chunks and embeddings
        chunks = self.chunk_text(text)
        cursor = self.db.cursor()
        
        for i, chunk in enumerate(chunks):
            embedding = self.get_embeddings(chunk)
            if embedding:
                cursor.execute(
                    "INSERT INTO chunks (doc_id, chunk_text, chunk_embedding, page_number) VALUES (?, ?, ?, ?)",
                    (i, chunk, json.dumps(embedding), i // 10)  # BBMC: Hardcoded page calculation
                )
                
        self.db.commit()
        return True
        
    def chat(self, user_query):
        """BBPF: Main chat pipeline with poor error handling"""
        try:
            # Step 1: Search for relevant chunks
            relevant_chunks = self.search_similar_chunks(user_query)
            
            # Step 2: Generate response
            if relevant_chunks:
                response = self.generate_response(user_query, relevant_chunks)
            else:
                response = "I couldn't find relevant information to answer your question."
                
            return response
        except Exception as e:
            print(f"Chat error: {e}")
            return "Sorry, an error occurred during processing."
            
    def cleanup(self):
        """BBMC: Incomplete cleanup"""
        if self.db:
            self.db.close()

# Global functions - BBMC Issue
def main():
    rag = LegacyRAGSystem()
    rag.connect_database()
    
    # Example usage
    pdf_path = "sample_document.pdf"
    if os.path.exists(pdf_path):
        rag.process_pdf_document(pdf_path)
        
    # Chat example
    response = rag.chat("What is the main topic of the document?")
    print(f"Response: {response}")
    
    rag.cleanup()

if __name__ == "__main__":
    main()
