#!/bin/bash
# Migrate data from local to Oracle Cloud
# Usage: ./scripts/migrate-data.sh <oracle-ip> <ssh-key-path>

set -e

ORACLE_IP="${1:?Usage: $0 <oracle-ip> <ssh-key-path>}"
SSH_KEY="${2:?Usage: $0 <oracle-ip> <ssh-key-path>}"
SSH_USER="${3:-ubuntu}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  Data Migration to Oracle Cloud"
echo "  Target: ${SSH_USER}@${ORACLE_IP}"
echo "========================================"

# Step 1: Backup local database
echo -e "\n${YELLOW}[1/4] Backing up local database...${NC}"
docker exec postgres pg_dump -U postgres agent_personal > /tmp/migration_backup.sql
echo -e "${GREEN}✓ Database backed up ($(wc -l < /tmp/migration_backup.sql) lines)${NC}"

# Step 2: Transfer to Oracle
echo -e "\n${YELLOW}[2/4] Transferring to Oracle Cloud...${NC}"
scp -i "$SSH_KEY" /tmp/migration_backup.sql "${SSH_USER}@${ORACLE_IP}:~/migration_backup.sql"
echo -e "${GREEN}✓ File transferred${NC}"

# Step 3: Restore on Oracle
echo -e "\n${YELLOW}[3/4] Restoring database on Oracle...${NC}"
ssh -i "$SSH_KEY" "${SSH_USER}@${ORACLE_IP}" \
  "docker exec -i postgres psql -U postgres -d agent_personal < ~/migration_backup.sql"
echo -e "${GREEN}✓ Database restored${NC}"

# Step 4: Verify
echo -e "\n${YELLOW}[4/4] Verifying...${NC}"
LOCAL_COUNT=$(docker exec postgres psql -U postgres -d agent_personal -t -c "SELECT COUNT(*) FROM content_queue" | tr -d ' ')
REMOTE_COUNT=$(ssh -i "$SSH_KEY" "${SSH_USER}@${ORACLE_IP}" \
  "docker exec postgres psql -U postgres -d agent_personal -t -c 'SELECT COUNT(*) FROM content_queue'" | tr -d ' ')

echo "  Local content_queue:  $LOCAL_COUNT records"
echo "  Remote content_queue: $REMOTE_COUNT records"

if [ "$LOCAL_COUNT" = "$REMOTE_COUNT" ]; then
  echo -e "${GREEN}✓ Migration verified!${NC}"
else
  echo -e "${RED}⚠ Record count mismatch! Please check manually.${NC}"
fi

# Cleanup
rm -f /tmp/migration_backup.sql

echo -e "\n${GREEN}Migration complete!${NC}"
echo "Next: Update Telegram webhook URL to point to Oracle server"
