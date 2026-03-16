#!/bin/bash
# AI Agent Social Automation - Backup Script
# Usage: ./scripts/backup.sh
# Cron:  0 3 * * * /path/to/scripts/backup.sh >> /path/to/logs/backup.log 2>&1

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/social-automation}"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS="${RETENTION_DAYS:-7}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors (only for interactive mode)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

echo "========================================"
echo "  Backup - $(date)"
echo "========================================"
echo ""

# Create backup directory
mkdir -p "${BACKUP_DIR}"
echo -e "${YELLOW}Backup directory: ${BACKUP_DIR}${NC}"
echo ""

# Check if containers are running
if ! docker ps | grep -q postgres; then
    echo -e "${RED}ERROR: PostgreSQL container not running!${NC}"
    exit 1
fi

# Backup PostgreSQL
echo -e "${YELLOW}[1/4] Backing up PostgreSQL...${NC}"
POSTGRES_FILE="${BACKUP_DIR}/postgres_${DATE}.sql"
docker exec postgres pg_dump -U postgres social_automation > "${POSTGRES_FILE}"
gzip "${POSTGRES_FILE}"
POSTGRES_SIZE=$(du -h "${POSTGRES_FILE}.gz" | cut -f1)
echo -e "${GREEN}✓ PostgreSQL: postgres_${DATE}.sql.gz (${POSTGRES_SIZE})${NC}"

# Backup n8n data
echo -e "${YELLOW}[2/4] Backing up n8n data...${NC}"
N8N_FILE="${BACKUP_DIR}/n8n_${DATE}.tar.gz"
docker cp n8n:/home/node/.n8n "${BACKUP_DIR}/n8n_temp_${DATE}"
tar -czf "${N8N_FILE}" -C "${BACKUP_DIR}" "n8n_temp_${DATE}"
rm -rf "${BACKUP_DIR}/n8n_temp_${DATE}"
N8N_SIZE=$(du -h "${N8N_FILE}" | cut -f1)
echo -e "${GREEN}✓ n8n: n8n_${DATE}.tar.gz (${N8N_SIZE})${NC}"

# Export workflows from git (if available)
echo -e "${YELLOW}[3/4] Backing up workflow files...${NC}"
WORKFLOWS_DIR="${PROJECT_DIR}/workflows"
if [ -d "${WORKFLOWS_DIR}" ]; then
    WORKFLOWS_FILE="${BACKUP_DIR}/workflows_${DATE}.tar.gz"
    tar -czf "${WORKFLOWS_FILE}" -C "${PROJECT_DIR}" "workflows"
    WORKFLOWS_SIZE=$(du -h "${WORKFLOWS_FILE}" | cut -f1)
    echo -e "${GREEN}✓ Workflows: workflows_${DATE}.tar.gz (${WORKFLOWS_SIZE})${NC}"
else
    echo -e "${YELLOW}○ No workflows directory found, skipping${NC}"
fi

# Cleanup old backups
echo -e "${YELLOW}[4/4] Cleaning up old backups (>${RETENTION_DAYS} days)...${NC}"
DELETED=$(find "${BACKUP_DIR}" -name "*.gz" -mtime +${RETENTION_DAYS} -delete -print | wc -l)
DELETED_SQL=$(find "${BACKUP_DIR}" -name "*.sql" -mtime +${RETENTION_DAYS} -delete -print | wc -l)
TOTAL_DELETED=$((DELETED + DELETED_SQL))
echo -e "${GREEN}✓ Deleted ${TOTAL_DELETED} old backup files${NC}"

# Summary
echo ""
echo "========================================"
echo "  Backup Complete!"
echo "========================================"
echo ""
echo "Files created:"
ls -lh "${BACKUP_DIR}"/*_${DATE}* 2>/dev/null || echo "  (none)"
echo ""

# Calculate total backup size
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
FILE_COUNT=$(ls -1 "${BACKUP_DIR}"/*.gz 2>/dev/null | wc -l)
echo "Backup directory: ${BACKUP_DIR}"
echo "Total size: ${TOTAL_SIZE} (${FILE_COUNT} files)"
echo ""

# Verify backup integrity
echo "Verifying backup integrity..."
if gzip -t "${BACKUP_DIR}/postgres_${DATE}.sql.gz" 2>/dev/null; then
    echo -e "${GREEN}✓ PostgreSQL backup verified${NC}"
else
    echo -e "${RED}✗ PostgreSQL backup may be corrupted${NC}"
fi

echo ""
echo "To restore PostgreSQL:"
echo "  gunzip -c ${BACKUP_DIR}/postgres_${DATE}.sql.gz | docker exec -i postgres psql -U postgres -d social_automation"
echo ""
