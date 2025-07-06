from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import os
from typing import List, Optional
import logging

from app.core.config import settings
from app.core.database import init_db, close_db
from app.api.v1 import match, recommendations
from app.core.logging import setup_logging

# Setup logging
setup_logging()
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Match Service...")
    await init_db()
    yield
    # Shutdown
    logger.info("Shutting down Match Service...")
    await close_db()

app = FastAPI(
    title="Proxima Match Service",
    description="AI-powered matching and recommendation service for freelancers and jobs",
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
        "service": "match-service",
        "version": "1.0.0"
    }

# Include routers
app.include_router(match.router, prefix="/api/v1/match", tags=["matching"])
app.include_router(recommendations.router, prefix="/api/v1/recommendations", tags=["recommendations"])

@app.get("/")
async def root():
    return {
        "message": "Proxima Match Service",
        "status": "running",
        "endpoints": [
            "/health",
            "/api/v1/match",
            "/api/v1/recommendations"
        ]
    }

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8003))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=settings.DEBUG,
        log_level="info"
    )
