#!/bin/bash
# Install n8n workflows by copying to container
# Usage: ./scripts/install-workflows.sh

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORKFLOWS_DIR="$PROJECT_DIR/workflows/n8n"
ENV_FILE="$PROJECT_DIR/docker/.env"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  Install n8n Workflows"
echo "========================================"
echo ""

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}ERROR: .env file not found${NC}"
    exit 1
fi

# Check if n8n container is running
echo "Checking n8n container..."
if ! docker ps | grep -q n8n; then
    echo -e "${RED}ERROR: n8n container is not running${NC}"
    echo "Please start services first:"
    echo "  cd docker && docker-compose up -d"
    exit 1
fi
echo -e "${GREEN}✓ n8n container is running${NC}"
echo ""

# Create credentials in database directly
echo "Setting up PostgreSQL credential in database..."
POSTGRES_CRED_SQL="
INSERT INTO public.credentials_entity (name, type, data, \"createdAt\", \"updatedAt\")
VALUES (
  'Social Automation DB',
  'postgres',
  '{\"host\":\"postgres\",\"port\":5432,\"database\":\"$POSTGRES_DB\",\"user\":\"$POSTGRES_USER\",\"password\":\"$POSTGRES_PASSWORD\",\"ssl\":false}',
  NOW(),
  NOW()
)
ON CONFLICT DO NOTHING;
"

docker exec postgres psql -U "$POSTGRES_USER" -d n8n -c "$POSTGRES_CRED_SQL" 2>/dev/null || echo -e "${YELLOW}⚠️  Could not create credential (may need manual setup)${NC}"

# Install workflows
echo ""
echo "Installing workflows..."
WORKFLOW_COUNT=0

for workflow_file in "$WORKFLOWS_DIR"/*.json; do
    if [ -f "$workflow_file" ]; then
        workflow_name=$(basename "$workflow_file" .json)
        echo -n "  Copying $workflow_name.json... "

        # Copy to container temp directory
        docker cp "$workflow_file" n8n:/tmp/workflow.json

        # Import using n8n CLI
        if docker exec n8n n8n import:workflow --input=/tmp/workflow.json 2>/dev/null; then
            echo -e "${GREEN}OK${NC}"
            WORKFLOW_COUNT=$((WORKFLOW_COUNT + 1))
        else
            echo -e "${YELLOW}SKIP (may already exist)${NC}"
        fi
    fi
done

echo ""
echo -e "${GREEN}✓ Processed $WORKFLOW_COUNT workflows${NC}"
echo ""

# Restart n8n to reload
echo "Restarting n8n to apply changes..."
cd "$PROJECT_DIR/docker"
docker-compose restart n8n

# Wait for n8n to be ready
echo "Waiting for n8n to be ready..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -sf http://localhost:5678/healthz &>/dev/null; then
        echo -e "${GREEN}✓ n8n is ready${NC}"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
done

echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "Access n8n: http://localhost:5678"
echo ""
echo "Installed workflows:"
echo "  - content-generate (Manual trigger)"
echo "  - batch-generate (Cron: Mon/Wed/Fri 8AM)"
echo "  - daily-digest (Cron: Daily 9AM)"
echo "  - healthcheck (Cron: Every 5min)"
echo ""
echo "Next steps:"
echo "  1. Open n8n UI"
echo "  2. Check Workflows tab"
echo "  3. Open each workflow and configure PostgreSQL credential"
echo "  4. Activate workflows you want to run"
echo ""
