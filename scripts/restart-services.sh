#!/bin/bash
# Restart Docker services
# Usage: ./scripts/restart-services.sh [service_name]
# Example: ./scripts/restart-services.sh n8n
# Or restart all: ./scripts/restart-services.sh

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

cd "$DOCKER_DIR"

SERVICE=$1

if [ -z "$SERVICE" ]; then
    echo "========================================"
    echo "  Restarting All Services"
    echo "========================================"
    echo ""
    docker-compose restart
else
    echo "========================================"
    echo "  Restarting $SERVICE"
    echo "========================================"
    echo ""
    docker-compose restart "$SERVICE"
fi

echo ""
echo -e "${GREEN}✓ Restart complete${NC}"
echo ""
echo "Check status:"
echo "  bash scripts/healthcheck.sh"
