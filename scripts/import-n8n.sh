#!/bin/bash
# Import n8n workflows and credentials automatically
# Usage: ./scripts/import-n8n.sh

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORKFLOWS_DIR="$PROJECT_DIR/modules/social/workflows"
ENV_FILE="$PROJECT_DIR/infrastructure/docker/.env"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  n8n Auto Import"
echo "========================================"
echo ""

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}ERROR: .env file not found${NC}"
    exit 1
fi

# Check if n8n is running
echo "Checking n8n status..."
if ! curl -sf http://localhost:5678/healthz &>/dev/null; then
    echo -e "${RED}ERROR: n8n is not running or not ready${NC}"
    echo "Please start services first:"
    echo "  cd docker && docker-compose up -d"
    exit 1
fi
echo -e "${GREEN}✓ n8n is running${NC}"
echo ""

# Prompt for n8n owner credentials
echo -e "${YELLOW}You need to provide n8n owner account credentials${NC}"
echo "These are the credentials you created during n8n first setup."
echo ""
read -p "Email: " N8N_EMAIL
read -sp "Password: " N8N_PASSWORD
echo ""
echo ""

# Get API key by logging in
echo "Authenticating with n8n..."
AUTH_RESPONSE=$(curl -s -X POST http://localhost:5678/rest/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$N8N_EMAIL\",\"password\":\"$N8N_PASSWORD\"}")

if echo "$AUTH_RESPONSE" | grep -q "error"; then
    echo -e "${RED}ERROR: Authentication failed${NC}"
    echo "Please check your email and password"
    exit 1
fi

# Extract API key/session
COOKIE=$(echo "$AUTH_RESPONSE" | grep -o '"sessionId":"[^"]*"' | cut -d'"' -f4)
if [ -z "$COOKIE" ]; then
    echo -e "${RED}ERROR: Could not get session from n8n${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated successfully${NC}"
echo ""

# Create PostgreSQL credential
echo "Creating PostgreSQL credential..."
POSTGRES_CRED=$(curl -s -X POST http://localhost:5678/rest/credentials \
  -H "Content-Type: application/json" \
  -H "Cookie: n8n-auth=$COOKIE" \
  -d "{
    \"name\": \"Agent Personal DB\",
    \"type\": \"postgres\",
    \"data\": {
      \"host\": \"postgres\",
      \"port\": 5432,
      \"database\": \"$POSTGRES_DB\",
      \"user\": \"$POSTGRES_USER\",
      \"password\": \"$POSTGRES_PASSWORD\",
      \"ssl\": false
    }
  }")

if echo "$POSTGRES_CRED" | grep -q "error"; then
    echo -e "${YELLOW}⚠️  PostgreSQL credential may already exist${NC}"
else
    echo -e "${GREEN}✓ PostgreSQL credential created${NC}"
fi
echo ""

# Create Telegram credential (if configured)
if [ "$TELEGRAM_BOT_TOKEN" != "your_bot_token_here" ]; then
    echo "Creating Telegram credential..."
    TELEGRAM_CRED=$(curl -s -X POST http://localhost:5678/rest/credentials \
      -H "Content-Type: application/json" \
      -H "Cookie: n8n-auth=$COOKIE" \
      -d "{
        \"name\": \"Telegram Bot\",
        \"type\": \"telegramApi\",
        \"data\": {
          \"accessToken\": \"$TELEGRAM_BOT_TOKEN\"
        }
      }")

    if echo "$TELEGRAM_CRED" | grep -q "error"; then
        echo -e "${YELLOW}⚠️  Telegram credential may already exist${NC}"
    else
        echo -e "${GREEN}✓ Telegram credential created${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping Telegram (not configured in .env)${NC}"
fi
echo ""

# Import workflows
echo "Importing workflows..."
WORKFLOW_COUNT=0

for workflow_file in "$WORKFLOWS_DIR"/*.json; do
    if [ -f "$workflow_file" ]; then
        workflow_name=$(basename "$workflow_file" .json)
        echo -n "  Importing $workflow_name... "

        # Read workflow file and import
        IMPORT_RESPONSE=$(curl -s -X POST http://localhost:5678/rest/workflows \
          -H "Content-Type: application/json" \
          -H "Cookie: n8n-auth=$COOKIE" \
          -d @"$workflow_file")

        if echo "$IMPORT_RESPONSE" | grep -q "error"; then
            echo -e "${RED}FAILED${NC}"
            echo "    Error: $(echo $IMPORT_RESPONSE | grep -o '"message":"[^"]*"' | cut -d'"' -f4)"
        else
            echo -e "${GREEN}OK${NC}"
            WORKFLOW_COUNT=$((WORKFLOW_COUNT + 1))
        fi
    fi
done

echo ""
echo -e "${GREEN}✓ Imported $WORKFLOW_COUNT workflows${NC}"
echo ""

# Summary
echo "========================================"
echo "  Import Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Open http://localhost:5678"
echo "  2. Go to Workflows tab"
echo "  3. Review imported workflows"
echo "  4. Activate workflows you want to run"
echo ""
echo "Imported workflows:"
echo "  - content-generate (Manual trigger)"
echo "  - batch-generate (Cron: Mon/Wed/Fri 8AM)"
echo "  - daily-digest (Cron: Daily 9AM)"
echo "  - healthcheck (Cron: Every 5min)"
echo ""
