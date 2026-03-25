#!/bin/bash

# Check workflows status in n8n
# Usage: bash scripts/check-workflows.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "  n8n Workflows Status"
echo "========================================"
echo ""

# Check n8n is running
if ! docker ps | grep -q "n8n"; then
    echo -e "${RED}❌ n8n container is not running!${NC}"
    exit 1
fi

echo -e "${BLUE}Existing Workflows:${NC}"
docker exec n8n n8n list:workflow 2>&1 | while read line; do
    workflow_id=$(echo "$line" | cut -d'|' -f1)
    workflow_name=$(echo "$line" | cut -d'|' -f2)
    echo -e "  ${GREEN}✓${NC} $workflow_name (ID: $workflow_id)"
done

echo ""
echo -e "${BLUE}Expected Workflows (11 total):${NC}"

# List all workflow files
workflows=(
    "content-generate.json:WF1: Content Generate"
    "batch-generate.json:WF2: Batch Generate"
    "daily-digest.json:WF3: Daily Digest"
    "healthcheck.json:WF5: Healthcheck"
    "auto-comment.json:WF6: Auto Comment"
    "data-collector.json:WF7: Data Collector"
    "facebook-post.json:WF8: Facebook Post"
    "linkedin-post-helper.json:WF9: LinkedIn Post Helper"
    "quiz-generator.json:WF10: Quiz Generator"
    "telegram-bot.json:WF11: Telegram Bot"
    "trending-detector.json:WF12: Trending Detector"
)

existing_list=$(docker exec n8n n8n list:workflow 2>&1)

for workflow in "${workflows[@]}"; do
    file=$(echo "$workflow" | cut -d':' -f1)
    name=$(echo "$workflow" | cut -d':' -f2-)

    if echo "$existing_list" | grep -q "$name"; then
        echo -e "  ${GREEN}✓${NC} $name"
    else
        echo -e "  ${YELLOW}⭕${NC} $name ${RED}(not imported)${NC}"
    fi
done

echo ""
echo "========================================"
echo -e "${BLUE}Import Instructions:${NC}"
echo "1. Read guide: documents/05-guides/huong-dan-import-workflows.md"
echo "2. Open n8n: http://localhost:5678"
echo "3. Import workflows from: modules/social/workflows/"
echo ""
echo -e "${BLUE}Quick Test:${NC}"
echo "  curl -s http://localhost:5678/healthz"
echo ""
