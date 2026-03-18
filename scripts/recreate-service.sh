#!/bin/bash
# Recreate Docker service (stop, remove, create new with updated env vars)
# Usage: ./scripts/recreate-service.sh <service_name>
# Example: ./scripts/recreate-service.sh n8n

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_DIR/docker"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVICE=$1

if [ -z "$SERVICE" ]; then
    echo -e "${RED}ERROR: Service name required${NC}"
    echo ""
    echo "Usage: $0 <service_name>"
    echo "Example: $0 n8n"
    echo ""
    echo "Available services: n8n, postgres, ollama, redis"
    exit 1
fi

cd "$DOCKER_DIR"

echo "========================================"
echo "  Recreating $SERVICE"
echo "========================================"
echo ""
echo -e "${YELLOW}This will stop, remove, and recreate the container${NC}"
echo -e "${YELLOW}with updated environment variables and configuration.${NC}"
echo ""

# Stop and remove container
echo "Stopping $SERVICE..."
docker-compose stop "$SERVICE"

echo "Removing $SERVICE container..."
docker-compose rm -f "$SERVICE"

# Recreate with up (doesn't recreate if not needed, but we removed it)
echo "Creating and starting $SERVICE..."
docker-compose up -d "$SERVICE"

echo ""
echo -e "${GREEN}✓ Recreate complete${NC}"
echo ""
echo "The container has been recreated with updated configuration."
echo ""
echo "Check status:"
echo "  bash scripts/healthcheck.sh"
echo ""
echo "View logs:"
echo "  cd docker && docker-compose logs -f $SERVICE"
