#!/bin/bash
# AI Agent Social Automation - Health Check Script
# Usage: ./scripts/healthcheck.sh
# Exit codes: 0 = all healthy, 1 = some unhealthy

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track overall health
ALL_HEALTHY=true

echo "========================================"
echo "  Health Check - $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# Service checks
echo -e "${BLUE}Services:${NC}"

# Check n8n
echo -n "  n8n:        "
if curl -sf http://localhost:5678/healthz > /dev/null 2>&1; then
    echo -e "${GREEN}HEALTHY${NC}"
else
    echo -e "${RED}UNHEALTHY${NC}"
    ALL_HEALTHY=false
fi

# Check PostgreSQL
echo -n "  PostgreSQL: "
if docker exec postgres pg_isready -U postgres -d social_automation > /dev/null 2>&1; then
    echo -e "${GREEN}HEALTHY${NC}"
else
    echo -e "${RED}UNHEALTHY${NC}"
    ALL_HEALTHY=false
fi

# Check Ollama
echo -n "  Ollama:     "
if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
    # Also check if model is loaded
    if curl -sf http://localhost:11434/api/tags | grep -q "llama3.1"; then
        echo -e "${GREEN}HEALTHY (llama3.1 loaded)${NC}"
    else
        echo -e "${YELLOW}RUNNING (no model loaded)${NC}"
    fi
else
    echo -e "${RED}UNHEALTHY${NC}"
    ALL_HEALTHY=false
fi

# Check Redis
echo -n "  Redis:      "
if docker exec redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}HEALTHY${NC}"
else
    echo -e "${RED}UNHEALTHY${NC}"
    ALL_HEALTHY=false
fi

# Container status
echo ""
echo -e "${BLUE}Container Status:${NC}"
docker ps --format "  {{.Names}}: {{.Status}}" | grep -E "n8n|postgres|ollama|redis" || echo "  No containers found"

# Database stats
echo ""
echo -e "${BLUE}Database Stats:${NC}"
if docker exec postgres psql -U postgres -d social_automation -t -c "SELECT 1" > /dev/null 2>&1; then
    # Content queue stats
    STATS=$(docker exec postgres psql -U postgres -d social_automation -t -c "
        SELECT
            COALESCE(SUM(CASE WHEN status = 'draft' THEN 1 ELSE 0 END), 0) as draft,
            COALESCE(SUM(CASE WHEN status = 'pending_review' THEN 1 ELSE 0 END), 0) as pending,
            COALESCE(SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END), 0) as approved,
            COALESCE(SUM(CASE WHEN status = 'published' THEN 1 ELSE 0 END), 0) as published
        FROM content_queue;
    " 2>/dev/null | tr -d ' ')

    if [ -n "$STATS" ]; then
        IFS='|' read -r DRAFT PENDING APPROVED PUBLISHED <<< "$STATS"
        echo "  Content Queue:"
        echo "    Draft: $DRAFT | Pending: $PENDING | Approved: $APPROVED | Published: $PUBLISHED"
    fi

    # Unused topics
    UNUSED=$(docker exec postgres psql -U postgres -d social_automation -t -c "SELECT COUNT(*) FROM topic_ideas WHERE used = false" 2>/dev/null | tr -d ' ')
    echo "  Unused Topics: $UNUSED"

    # Active prompts
    PROMPTS=$(docker exec postgres psql -U postgres -d social_automation -t -c "SELECT COUNT(*) FROM prompts WHERE is_active = true" 2>/dev/null | tr -d ' ')
    echo "  Active Prompts: $PROMPTS"
else
    echo "  Unable to connect to database"
fi

# Resource usage
echo ""
echo -e "${BLUE}Resource Usage:${NC}"

# Disk
DISK_USAGE=$(df -h / 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
DISK_USED=$(df -h / 2>/dev/null | tail -1 | awk '{print $3}')
DISK_TOTAL=$(df -h / 2>/dev/null | tail -1 | awk '{print $2}')
if [ -n "$DISK_USAGE" ]; then
    if [ "$DISK_USAGE" -gt 80 ]; then
        echo -e "  Disk: ${RED}${DISK_USED}/${DISK_TOTAL} (${DISK_USAGE}%)${NC}"
        ALL_HEALTHY=false
    else
        echo -e "  Disk: ${GREEN}${DISK_USED}/${DISK_TOTAL} (${DISK_USAGE}%)${NC}"
    fi
fi

# Memory
MEM_INFO=$(free -h 2>/dev/null | grep Mem)
if [ -n "$MEM_INFO" ]; then
    MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
    MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
    echo "  Memory: ${MEM_USED}/${MEM_TOTAL}"
fi

# Docker container resources
echo ""
echo -e "${BLUE}Container Resources:${NC}"
docker stats --no-stream --format "  {{.Name}}: CPU {{.CPUPerc}}, Mem {{.MemUsage}}" 2>/dev/null | grep -E "n8n|postgres|ollama|redis" || echo "  Unable to get stats"

# Recent errors in workflow logs
echo ""
echo -e "${BLUE}Recent Workflow Errors (last 24h):${NC}"
ERROR_COUNT=$(docker exec postgres psql -U postgres -d social_automation -t -c "
    SELECT COUNT(*) FROM workflow_logs
    WHERE status = 'error'
    AND created_at > NOW() - INTERVAL '24 hours'
" 2>/dev/null | tr -d ' ')

if [ -n "$ERROR_COUNT" ] && [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "  ${RED}$ERROR_COUNT errors in last 24 hours${NC}"
    docker exec postgres psql -U postgres -d social_automation -t -c "
        SELECT workflow_name, message, created_at
        FROM workflow_logs
        WHERE status = 'error'
        AND created_at > NOW() - INTERVAL '24 hours'
        ORDER BY created_at DESC
        LIMIT 3
    " 2>/dev/null | while read -r line; do
        echo "    $line"
    done
else
    echo "  No errors in last 24 hours"
fi

# Summary
echo ""
echo "========================================"
if [ "$ALL_HEALTHY" = true ]; then
    echo -e "  ${GREEN}All services healthy!${NC}"
    exit 0
else
    echo -e "  ${RED}Some services unhealthy!${NC}"
    exit 1
fi
