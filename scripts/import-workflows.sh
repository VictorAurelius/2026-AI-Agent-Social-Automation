#!/bin/bash

# Import all n8n workflows using n8n CLI
# Usage: bash scripts/import-workflows.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKFLOWS_DIR="workflows/n8n"
N8N_CONTAINER="n8n"

echo "========================================"
echo "  n8n Workflow Importer"
echo "========================================"
echo ""

# Check if n8n container is running
echo -e "${BLUE}Checking n8n container...${NC}"
if ! docker ps | grep -q "$N8N_CONTAINER"; then
    echo -e "${RED}❌ n8n container is not running!${NC}"
    echo "Start n8n first: cd docker && docker-compose up -d n8n"
    exit 1
fi
echo -e "${GREEN}✓ n8n container is running${NC}"
echo ""

# Import workflows using n8n CLI
echo -e "${BLUE}Importing workflows from ${WORKFLOWS_DIR}...${NC}"
echo ""

SUCCESS_COUNT=0
ERROR_COUNT=0

# Copy workflows to container
echo -e "${YELLOW}⊳ Copying workflows to container...${NC}"
docker cp "$WORKFLOWS_DIR" "$N8N_CONTAINER:/tmp/workflows"
echo -e "${GREEN}✓ Workflows copied${NC}"
echo ""

# Import all workflows at once using --separate flag
echo -e "${YELLOW}⊳ Importing workflows via n8n CLI...${NC}"
if docker exec "$N8N_CONTAINER" n8n import:workflow --separate --input=/tmp/workflows/ 2>&1; then
    echo -e "${GREEN}✓ Workflows imported successfully!${NC}"
    SUCCESS_COUNT=$(ls -1 "$WORKFLOWS_DIR"/*.json 2>/dev/null | wc -l)
else
    echo -e "${RED}✗ Import failed${NC}"
    ERROR_COUNT=$(ls -1 "$WORKFLOWS_DIR"/*.json 2>/dev/null | wc -l)
fi
echo ""

# Cleanup
echo -e "${YELLOW}⊳ Cleaning up...${NC}"
docker exec "$N8N_CONTAINER" rm -rf /tmp/workflows
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Summary
echo "========================================"
echo -e "${BLUE}Import Summary:${NC}"
echo -e "  ${GREEN}Success: ${SUCCESS_COUNT}${NC}"
echo -e "  ${RED}Errors:  ${ERROR_COUNT}${NC}"
echo "========================================"
echo ""

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All workflows imported successfully!${NC}"
    echo ""
    echo "📋 Workflows imported:"
    ls -1 "$WORKFLOWS_DIR"/*.json | xargs -n1 basename | sed 's/.json$//' | while read workflow; do
        echo "  • $workflow"
    done
    echo ""
    echo "🎯 Next steps:"
    echo "1. Open n8n: http://localhost:5678"
    echo "2. Check imported workflows in the Workflows tab"
    echo "3. Configure credentials:"
    echo "   • PostgreSQL: Already configured (id: 1)"
    echo "   • Telegram Bot: Already configured (id: 1)"
    echo "   • No other credentials needed (Ollama uses HTTP)"
    echo "4. Activate workflows you want to run:"
    echo "   • healthcheck (recommended - monitors services)"
    echo "   • batch-generate (runs Mon/Wed/Fri 8AM)"
    echo "   • daily-digest (runs daily 7AM)"
    echo ""
    echo "🔍 Check workflow status:"
    echo "  curl -s http://localhost:5678/api/v1/workflows"
else
    echo -e "${YELLOW}⚠ Import had issues${NC}"
    echo "Check n8n UI: http://localhost:5678"
fi
