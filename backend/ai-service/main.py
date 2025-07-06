from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import os
from typing import List, Optional
import logging

from app.core.config import settings
from app.core.database import init_db, close_db
from app.api.v1 import skillsheet, portfolio, analysis
from app.core.logging import setup_logging
from app.services.nlp_service import NLPService

# Setup logging
setup_logging()
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting AI Service...")
    await init_db()
    
    # Initialize NLP models
    logger.info("Loading NLP models...")
    nlp_service = NLPService()
    await nlp_service.initialize()
    app.state.nlp_service = nlp_service
    
    yield
    
    # Shutdown
    logger.info("Shutting down AI Service...")
    await close_db()

app = FastAPI(
    title="Proxima AI Service",
    description="AI-powered skill sheet analysis, text enhancement, and NLP services",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "ai-service",
        "version": "1.0.0",
        "models_loaded": hasattr(app.state, 'nlp_service')
    }

# Include routers
app.include_router(skillsheet.router, prefix="/api/v1/ai/skillsheet", tags=["skillsheet"])
app.include_router(portfolio.router, prefix="/api/v1/ai/portfolio", tags=["portfolio"])
app.include_router(analysis.router, prefix="/api/v1/ai/analysis", tags=["analysis"])

@app.get("/")
async def root():
    return {
        "message": "Proxima AI Service",
        "status": "running",
        "endpoints": [
            "/health",
            "/api/v1/ai/skillsheet",
            "/api/v1/ai/portfolio",
            "/api/v1/ai/analysis"
        ]
    }

# File upload endpoint
@app.post("/api/v1/files/upload")
async def upload_file(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...)
):
    """
    Upload and process skill sheet files (PDF, DOCX, TXT)
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    
    # Validate file type
    allowed_types = ['.pdf', '.docx', '.txt']
    file_ext = os.path.splitext(file.filename)[1].lower()
    
    if file_ext not in allowed_types:
        raise HTTPException(
            status_code=400, 
            detail=f"File type {file_ext} not supported. Allowed types: {allowed_types}"
        )
    
    # Save file temporarily
    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True)
    file_path = os.path.join(upload_dir, file.filename)
    
    try:
        with open(file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        # Process file in background
        background_tasks.add_task(process_uploaded_file, file_path, file.filename)
        
        return {
            "message": "File uploaded successfully",
            "filename": file.filename,
            "size": len(content),
            "status": "processing"
        }
    
    except Exception as e:
        logger.error(f"Error uploading file: {str(e)}")
        raise HTTPException(status_code=500, detail="Error uploading file")

async def process_uploaded_file(file_path: str, filename: str):
    """
    Background task to process uploaded files
    """
    try:
        logger.info(f"Processing file: {filename}")
        
        # Extract text from file
        nlp_service = app.state.nlp_service
        extracted_text = await nlp_service.extract_text_from_file(file_path)
        
        # Analyze skill sheet
        analysis_result = await nlp_service.analyze_skillsheet(extracted_text)
        
        # Save results to database
        # TODO: Implement database save logic
        
        logger.info(f"File processing completed: {filename}")
        
        # Clean up temporary file
        os.remove(file_path)
        
    except Exception as e:
        logger.error(f"Error processing file {filename}: {str(e)}")

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8004))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=settings.DEBUG,
        log_level="info"
    )
