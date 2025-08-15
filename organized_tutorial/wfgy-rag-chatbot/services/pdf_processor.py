"""
PDF Processing Service - BBAM Priority 1
Handles PDF text extraction and OCR
"""
import logging
import fitz  # PyMuPDF
import pytesseract
from PIL import Image
import numpy as np
from typing import Optional, Tuple, List
from ..models.document import Document, ProcessingStatus
from ..config import config

logger = logging.getLogger(__name__)

class PDFProcessor:
    def __init__(self):
        self.ocr_config = config.ocr
        self.processing_config = config.processing
        
    async def extract_text_from_pdf(self, pdf_path: str) -> Optional[str]:
        """BBAM Priority 1: Critical PDF text extraction"""
        try:
            doc = fitz.open(pdf_path)
            text = ""
            
            for page_num, page in enumerate(doc):
                # Try direct text extraction first
                page_text = page.get_text()
                
                if not page_text.strip():
                    # Fallback to OCR if no text found
                    logger.info(f"Page {page_num + 1} has no text, using OCR")
                    page_text = await self._extract_text_with_ocr(page)
                
                text += f"Page {page_num + 1}: {page_text}\n"
            
            doc.close()
            return text
            
        except Exception as e:
            logger.error(f"Failed to extract text from PDF {pdf_path}: {e}")
            return None
    
    async def _extract_text_with_ocr(self, page) -> str:
        """BBAM Priority 1: Critical OCR processing"""
        try:
            # Convert page to image
            pix = page.get_pixmap()
            img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
            
            # Apply OCR
            ocr_text = pytesseract.image_to_string(
                img, 
                config=self.ocr_config.tesseract_config
            )
            
            return ocr_text
            
        except Exception as e:
            logger.error(f"OCR processing failed: {e}")
            return ""
    
    async def should_use_ocr(self, image: Image.Image) -> bool:
        """BBAM Priority 2: Image analysis for OCR decision"""
        try:
            # Convert to grayscale
            gray = image.convert('L')
            arr = np.array(gray)
            
            # Calculate image statistics
            mean_brightness = np.mean(arr)
            std_brightness = np.std(arr)
            
            # BBMC: Configurable thresholds
            return (mean_brightness < self.ocr_config.brightness_threshold or 
                   std_brightness < self.ocr_config.contrast_threshold)
                   
        except Exception as e:
            logger.error(f"Image analysis failed: {e}")
            return False
    
    async def process_document(self, document: Document) -> bool:
        """BBPF: Progressive document processing pipeline"""
        try:
            # Step 1: Update status to processing
            document.processing_status = ProcessingStatus.PROCESSING
            
            # Step 2: Extract text
            content = await self.extract_text_from_pdf(document.file_path)
            if not content:
                document.processing_status = ProcessingStatus.FAILED
                return False
            
            # Step 3: Update document
            document.content = content
            document.processing_status = ProcessingStatus.COMPLETED
            
            logger.info(f"Successfully processed document: {document.filename}")
            return True
            
        except Exception as e:
            logger.error(f"Document processing failed: {e}")
            document.processing_status = ProcessingStatus.FAILED
            return False
