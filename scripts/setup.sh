#!/bin/bash
# AI Agent Social Automation - Setup Script
# Usage: ./scripts/setup.sh
# This script sets up the complete Docker environment

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_DIR/docker"

echo "========================================"
echo "  AI Agent Social Automation Setup"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step counter
STEP=1
TOTAL_STEPS=7

print_step() {
    echo -e "\n${BLUE}[$STEP/$TOTAL_STEPS]${NC} $1"
    ((STEP++))
}

# Check Docker
print_step "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker not found!${NC}"
    echo "Please install Docker first:"
    echo "  sudo apt update && sudo apt install docker.io docker-compose"
    exit 1
fi
echo -e "${GREEN}✓ Docker: $(docker --version)${NC}"

# Check Docker Compose
print_step "Checking Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}ERROR: Docker Compose not found!${NC}"
    echo "Please install Docker Compose first"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose: $(docker-compose --version)${NC}"

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${RED}ERROR: Docker daemon is not running!${NC}"
    echo "Please start Docker service"
    exit 1
fi
echo -e "${GREEN}✓ Docker daemon is running${NC}"

# Setup environment file
print_step "Setting up environment file..."
cd "$DOCKER_DIR"

if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${YELLOW}Created .env file from .env.example${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANT: Please edit docker/.env with your passwords!${NC}"
        echo ""
        echo "Required changes:"
        echo "  - POSTGRES_PASSWORD"
        echo "  - N8N_BASIC_AUTH_PASSWORD"
        echo "  - N8N_ENCRYPTION_KEY (32+ random characters)"
        echo ""
        read -p "Press Enter after editing .env file, or Ctrl+C to exit..."
    else
        echo -e "${RED}ERROR: .env.example not found!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ .env file exists${NC}"
fi

# Validate .env has been configured
if grep -q "your_secure_password_here" .env 2>/dev/null; then
    echo -e "${RED}ERROR: Please edit .env file with your actual passwords!${NC}"
    exit 1
fi

# Start Docker services
print_step "Starting Docker services..."
docker-compose up -d

# Wait for services to be healthy
print_step "Waiting for services to be healthy..."
echo "This may take 30-60 seconds..."

MAX_WAIT=120
WAIT_INTERVAL=5
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    HEALTHY=$(docker-compose ps | grep -c "(healthy)" || true)
    if [ "$HEALTHY" -ge 3 ]; then
        echo -e "${GREEN}✓ Services are healthy${NC}"
        break
    fi
    echo "  Waiting... ($WAITED seconds)"
    sleep $WAIT_INTERVAL
    WAITED=$((WAITED + WAIT_INTERVAL))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "${YELLOW}⚠️  Some services may still be starting${NC}"
fi

# Show service status
docker-compose ps

# Pull Ollama model
print_step "Pulling Llama 3.1 8B model..."
echo -e "${YELLOW}This downloads ~4.7GB and may take several minutes...${NC}"
echo ""

if docker exec ollama ollama list 2>/dev/null | grep -q "llama3.1:8b"; then
    echo -e "${GREEN}✓ Model already downloaded${NC}"
else
    docker exec -it ollama ollama pull llama3.1:8b
    echo -e "${GREEN}✓ Model downloaded successfully${NC}"
fi

# Verify setup
print_step "Verifying setup..."
echo ""

# Test PostgreSQL
echo -n "PostgreSQL: "
if docker exec postgres pg_isready -U postgres -d social_automation &>/dev/null; then
    TABLES=$(docker exec postgres psql -U postgres -d social_automation -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | tr -d ' ')
    echo -e "${GREEN}✓ Running ($TABLES tables)${NC}"
else
    echo -e "${RED}✗ Not ready${NC}"
fi

# Test Ollama
echo -n "Ollama:     "
if curl -sf http://localhost:11434/api/tags &>/dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not ready${NC}"
fi

# Test Redis
echo -n "Redis:      "
if docker exec redis redis-cli ping &>/dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not ready${NC}"
fi

# Test n8n
echo -n "n8n:        "
if curl -sf http://localhost:5678/healthz &>/dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${YELLOW}○ Starting (may take a moment)${NC}"
fi

# Success message
echo ""
echo -e "${GREEN}========================================"
echo "  Setup Complete!"
echo "========================================${NC}"
echo ""
echo "Access points:"
echo -e "  ${BLUE}n8n UI:${NC}      http://localhost:5678"
echo -e "  ${BLUE}PostgreSQL:${NC}  localhost:5432"
echo -e "  ${BLUE}Ollama API:${NC}  http://localhost:11434"
echo -e "  ${BLUE}Redis:${NC}       localhost:6379"
echo ""
echo "Next steps:"
echo "  1. Open http://localhost:5678"
echo "  2. Login with credentials from .env"
echo "  3. Add PostgreSQL credentials in n8n"
echo "  4. Import workflows from workflows/n8n/"
echo ""
echo "Useful commands:"
echo "  ./scripts/healthcheck.sh  - Check service health"
echo "  ./scripts/backup.sh       - Backup databases"
echo "  docker-compose logs -f    - View logs"
echo ""
