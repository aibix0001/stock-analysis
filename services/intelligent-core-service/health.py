#!/usr/bin/env python3
"""Health check endpoint for Intelligent Core Service"""

from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from datetime import datetime
import psutil
import asyncio
import os

app = FastAPI(title="Intelligent Core Service Health")

# Service information
SERVICE_NAME = "intelligent-core-service"
SERVICE_VERSION = "1.0.0"
SERVICE_PORT = int(os.getenv("SERVICE_PORT", 8001))

# Health check state
startup_time = datetime.utcnow()
is_ready = False

async def check_database_connection():
    """Check if database is accessible"""
    # TODO: Implement actual database check
    return True

async def check_redis_connection():
    """Check if Redis is accessible"""
    # TODO: Implement actual Redis check
    return True

async def check_rabbitmq_connection():
    """Check if RabbitMQ is accessible"""
    # TODO: Implement actual RabbitMQ check
    return True

@app.on_event("startup")
async def startup_event():
    """Initialize service on startup"""
    global is_ready
    # Perform startup checks
    await asyncio.sleep(2)  # Simulate initialization
    is_ready = True

@app.get("/health", response_model=dict)
async def health_check():
    """Basic health check endpoint"""
    uptime = (datetime.utcnow() - startup_time).total_seconds()
    
    health_status = {
        "status": "healthy" if is_ready else "starting",
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "timestamp": datetime.utcnow().isoformat(),
        "uptime_seconds": uptime,
        "details": {
            "ready": is_ready,
            "cpu_percent": psutil.cpu_percent(interval=0.1),
            "memory_percent": psutil.virtual_memory().percent,
            "pid": os.getpid()
        }
    }
    
    status_code = status.HTTP_200_OK if is_ready else status.HTTP_503_SERVICE_UNAVAILABLE
    return JSONResponse(content=health_status, status_code=status_code)

@app.get("/health/live", response_model=dict)
async def liveness_check():
    """Kubernetes-style liveness probe"""
    return {
        "status": "alive",
        "service": SERVICE_NAME,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/health/ready", response_model=dict)
async def readiness_check():
    """Kubernetes-style readiness probe"""
    checks = {
        "database": await check_database_connection(),
        "redis": await check_redis_connection(),
        "rabbitmq": await check_rabbitmq_connection()
    }
    
    all_ready = all(checks.values()) and is_ready
    
    return JSONResponse(
        content={
            "ready": all_ready,
            "service": SERVICE_NAME,
            "checks": checks,
            "timestamp": datetime.utcnow().isoformat()
        },
        status_code=status.HTTP_200_OK if all_ready else status.HTTP_503_SERVICE_UNAVAILABLE
    )

@app.get("/", response_model=dict)
async def root():
    """Service information endpoint"""
    return {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "description": "Intelligent Core Service - Analysis and Intelligence Engine",
        "health_endpoint": "/health",
        "api_docs": "/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=SERVICE_PORT)