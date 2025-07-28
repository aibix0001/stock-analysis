#!/bin/bash
# Python and uv setup script
set -euo pipefail

echo "Setting up Python environment..."

# Install uv
echo "Installing uv package manager..."
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="/root/.cargo/bin:$PATH"

# Create virtual environments for each service
SERVICES=("broker-gateway" "intelligent-core" "event-bus" "monitoring" "frontend")

for service in "${SERVICES[@]}"; do
    echo "Creating virtual environment for $service..."
    cd /opt/stock-analysis
    /root/.cargo/bin/uv venv "venvs/$service"
    
    # Create requirements file for service
    cat > "venvs/$service/requirements.txt" << REQUIREMENTS
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
redis==5.0.1
pika==1.3.2
httpx==0.25.2
python-dotenv==1.0.0
REQUIREMENTS
    
    # Install base requirements
    /root/.cargo/bin/uv pip install -r "venvs/$service/requirements.txt" --python "venvs/$service/bin/python"
done

# Make uv available system-wide
ln -sf /root/.cargo/bin/uv /usr/local/bin/uv

echo "Python environment setup completed!"
