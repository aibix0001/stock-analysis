#!/usr/bin/env python3
"""Generic health check module for all services"""

from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from datetime import datetime
import psutil
import asyncio
import os
import redis
import psycopg2
import pika
from typing import Dict, Any, Optional

class HealthChecker:
    """Generic health check implementation for microservices"""
    
    def __init__(self, service_name: str, service_version: str = "1.0.0"):
        self.service_name = service_name
        self.service_version = service_version
        self.service_port = int(os.getenv("SERVICE_PORT", 8000))
        self.startup_time = datetime.utcnow()
        self.is_ready = False
        
        # Connection parameters from environment
        self.postgres_config = {
            "host": os.getenv("POSTGRES_HOST", "localhost"),
            "port": int(os.getenv("POSTGRES_PORT", 5432)),
            "database": os.getenv("POSTGRES_DB", "aktienanalyse_event_store"),
            "user": os.getenv("POSTGRES_USER", "stock_analysis"),
            "password": os.getenv("POSTGRES_PASSWORD", "secure_password")
        }
        
        self.redis_config = {
            "host": os.getenv("REDIS_HOST", "localhost"),
            "port": int(os.getenv("REDIS_PORT", 6379)),
            "decode_responses": True
        }
        
        self.rabbitmq_config = {
            "host": os.getenv("RABBITMQ_HOST", "localhost"),
            "port": int(os.getenv("RABBITMQ_PORT", 5672)),
            "virtual_host": os.getenv("RABBITMQ_VHOST", "/"),
            "username": os.getenv("RABBITMQ_USER", "stock_analysis"),
            "password": os.getenv("RABBITMQ_PASSWORD", "stock_password")
        }
    
    async def check_database(self) -> bool:
        """Check PostgreSQL connection"""
        try:
            conn = psycopg2.connect(**self.postgres_config)
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.close()
            conn.close()
            return True
        except Exception as e:
            print(f"Database check failed: {e}")
            return False
    
    async def check_redis(self) -> bool:
        """Check Redis connection"""
        try:
            r = redis.Redis(**self.redis_config)
            r.ping()
            return True
        except Exception as e:
            print(f"Redis check failed: {e}")
            return False
    
    async def check_rabbitmq(self) -> bool:
        """Check RabbitMQ connection"""
        try:
            credentials = pika.PlainCredentials(
                self.rabbitmq_config["username"],
                self.rabbitmq_config["password"]
            )
            parameters = pika.ConnectionParameters(
                host=self.rabbitmq_config["host"],
                port=self.rabbitmq_config["port"],
                virtual_host=self.rabbitmq_config["virtual_host"],
                credentials=credentials,
                blocked_connection_timeout=3
            )
            connection = pika.BlockingConnection(parameters)
            connection.close()
            return True
        except Exception as e:
            print(f"RabbitMQ check failed: {e}")
            return False
    
    def get_system_metrics(self) -> Dict[str, Any]:
        """Get system resource metrics"""
        return {
            "cpu_percent": psutil.cpu_percent(interval=0.1),
            "memory_percent": psutil.virtual_memory().percent,
            "memory_mb": psutil.virtual_memory().used / (1024 * 1024),
            "disk_percent": psutil.disk_usage('/').percent,
            "pid": os.getpid(),
            "threads": psutil.Process().num_threads()
        }
    
    async def get_health_status(self) -> Dict[str, Any]:
        """Get comprehensive health status"""
        uptime = (datetime.utcnow() - self.startup_time).total_seconds()
        
        return {
            "status": "healthy" if self.is_ready else "starting",
            "service": self.service_name,
            "version": self.service_version,
            "timestamp": datetime.utcnow().isoformat(),
            "uptime_seconds": uptime,
            "metrics": self.get_system_metrics(),
            "details": {
                "ready": self.is_ready,
                "port": self.service_port,
                "environment": os.getenv("NODE_ENV", "development")
            }
        }
    
    async def get_readiness_status(self) -> Dict[str, Any]:
        """Get readiness status with dependency checks"""
        checks = {
            "service": self.is_ready,
            "database": await self.check_database(),
            "redis": await self.check_redis(),
            "rabbitmq": await self.check_rabbitmq()
        }
        
        all_ready = all(checks.values())
        
        return {
            "ready": all_ready,
            "service": self.service_name,
            "checks": checks,
            "timestamp": datetime.utcnow().isoformat()
        }
    
    def create_health_app(self) -> FastAPI:
        """Create FastAPI app with health endpoints"""
        app = FastAPI(
            title=f"{self.service_name} Health",
            version=self.service_version,
            docs_url="/health/docs"
        )
        
        @app.on_event("startup")
        async def startup_event():
            """Initialize service on startup"""
            # Simulate initialization
            await asyncio.sleep(2)
            self.is_ready = True
        
        @app.get("/health")
        async def health_check():
            """Basic health check endpoint"""
            status_data = await self.get_health_status()
            status_code = status.HTTP_200_OK if self.is_ready else status.HTTP_503_SERVICE_UNAVAILABLE
            return JSONResponse(content=status_data, status_code=status_code)
        
        @app.get("/health/live")
        async def liveness_check():
            """Kubernetes-style liveness probe"""
            return {
                "status": "alive",
                "service": self.service_name,
                "timestamp": datetime.utcnow().isoformat()
            }
        
        @app.get("/health/ready")
        async def readiness_check():
            """Kubernetes-style readiness probe"""
            status_data = await self.get_readiness_status()
            status_code = status.HTTP_200_OK if status_data["ready"] else status.HTTP_503_SERVICE_UNAVAILABLE
            return JSONResponse(content=status_data, status_code=status_code)
        
        @app.get("/")
        async def root():
            """Service information endpoint"""
            return {
                "service": self.service_name,
                "version": self.service_version,
                "health_endpoint": "/health",
                "liveness_endpoint": "/health/live",
                "readiness_endpoint": "/health/ready",
                "api_docs": "/docs"
            }
        
        return app


# Helper function to create health check app for any service
def create_service_health_app(service_name: str, service_version: str = "1.0.0") -> FastAPI:
    """Create a health check FastAPI app for a service"""
    checker = HealthChecker(service_name, service_version)
    return checker.create_health_app()


# Example usage for creating minimal health endpoint
if __name__ == "__main__":
    import uvicorn
    
    # Example service
    service_name = os.getenv("SERVICE_NAME", "example-service")
    port = int(os.getenv("SERVICE_PORT", 8000))
    
    app = create_service_health_app(service_name)
    uvicorn.run(app, host="0.0.0.0", port=port)