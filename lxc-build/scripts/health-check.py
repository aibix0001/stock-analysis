#!/usr/bin/env python3
"""
Health check script for Stock Analysis services
"""
import sys
import json
import subprocess
from typing import Dict, Tuple, Any

def check_service_status(service_name: str) -> Tuple[bool, str]:
    """Check if a systemd service is running"""
    try:
        result = subprocess.run(
            ["systemctl", "is-active", service_name],
            capture_output=True,
            text=True
        )
        is_active = result.returncode == 0
        status = "active" if is_active else "inactive"
        return is_active, f"Service {service_name} is {status}"
    except Exception as e:
        return False, f"Failed to check {service_name}: {str(e)}"

def check_postgresql() -> Tuple[bool, str]:
    """Check PostgreSQL connectivity"""
    try:
        result = subprocess.run(
            ["pg_isready", "-h", "localhost", "-p", "5432"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            return True, "PostgreSQL is accepting connections"
        return False, "PostgreSQL is not accepting connections"
    except Exception as e:
        return False, f"PostgreSQL check failed: {str(e)}"

def check_redis() -> Tuple[bool, str]:
    """Check Redis connectivity"""
    try:
        result = subprocess.run(
            ["redis-cli", "-a", "changeme", "ping"],
            capture_output=True,
            text=True
        )
        if result.stdout.strip() == "PONG":
            return True, "Redis is responding to ping"
        return False, "Redis is not responding"
    except Exception as e:
        return False, f"Redis check failed: {str(e)}"

def check_rabbitmq() -> Tuple[bool, str]:
    """Check RabbitMQ status"""
    try:
        result = subprocess.run(
            ["rabbitmqctl", "status"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            return True, "RabbitMQ is running"
        return False, "RabbitMQ is not running"
    except Exception as e:
        return False, f"RabbitMQ check failed: {str(e)}"

def main():
    """Run all health checks"""
    checks = {
        "postgresql": check_postgresql(),
        "redis": check_redis(),
        "rabbitmq": check_rabbitmq(),
    }
    
    # Check services if they exist
    services = [
        "stock-analysis-broker-gateway",
        "stock-analysis-intelligent-core",
        "stock-analysis-event-bus",
        "stock-analysis-monitoring",
        "stock-analysis-frontend"
    ]
    
    for service in services:
        checks[service] = check_service_status(service)
    
    # Calculate overall health
    all_healthy = all(status for status, _ in checks.values())
    
    # Output results
    output = {
        "healthy": all_healthy,
        "timestamp": subprocess.run(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], 
                                  capture_output=True, text=True).stdout.strip(),
        "checks": {
            name: {"healthy": status, "message": msg}
            for name, (status, msg) in checks.items()
        }
    }
    
    print(json.dumps(output, indent=2))
    sys.exit(0 if all_healthy else 1)

if __name__ == "__main__":
    main()
