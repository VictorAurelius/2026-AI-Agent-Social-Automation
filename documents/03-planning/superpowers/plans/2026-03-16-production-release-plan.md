# AI Agent Personal - Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build production-stable LinkedIn automation system with local LLM (Ollama), running 30+ days without issues.

**Architecture:** Docker Compose on WSL2 with n8n (orchestration), PostgreSQL (storage), Ollama (LLM), Redis (cache), Telegram (notifications).

**Tech Stack:** Docker, n8n, PostgreSQL 15, Ollama + Llama 3.1 8B, Redis 7, Telegram Bot API

**Spec Document:** `documents/03-planning/superpowers/specs/2026-03-16-production-release-design.md`

---

## Chunk 1: Infrastructure Setup (Week 1-2)

### Task 1.1: Create Docker Compose Configuration

**Files:**
- Create: `infrastructure/docker/docker-compose.yml`
- Create: `infrastructure/docker/.env.example`
- Create: `infrastructure/docker/README.md`

- [ ] **Step 1: Create docker directory**

```bash
mkdir -p docker
```

- [ ] **Step 2: Create .env.example file**

```bash
cat > infrastructure/docker/.env.example << 'EOF'
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=agent_personal

# n8n
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_n8n_password_here
N8N_ENCRYPTION_KEY=your_random_32_char_key_here

# Timezone
TZ=Asia/Ho_Chi_Minh
EOF
```

- [ ] **Step 3: Create docker-compose.yml**

```bash
cat > infrastructure/docker/docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=${TZ}
      - N8N_LOG_LEVEL=info
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost:5678/healthz || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      - automation-network

  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - automation-network

  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:11434/api/tags || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    networks:
      - automation-network
    deploy:
      resources:
        limits:
          memory: 12G

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
    command: redis-server --appendonly yes
    networks:
      - automation-network

volumes:
  n8n_data:
  postgres_data:
  ollama_data:
  redis_data:

networks:
  automation-network:
    driver: bridge
EOF
```

- [ ] **Step 4: Create docker README**

```bash
cat > infrastructure/docker/README.md << 'EOF'
# Docker Setup

## Quick Start

1. Copy environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your passwords

3. Start services:
   ```bash
   docker-compose up -d
   ```

4. Pull Llama model:
   ```bash
   docker exec -it ollama ollama pull llama3.1:8b
   ```

5. Access n8n: http://localhost:5678

## Services

| Service | Port | Purpose |
|---------|------|---------|
| n8n | 5678 | Workflow automation |
| PostgreSQL | 5432 | Data storage |
| Ollama | 11434 | Local LLM |
| Redis | 6379 | Caching |

## Commands

```bash
# View logs
docker-compose logs -f

# Stop all
docker-compose down

# Restart specific service
docker-compose restart n8n

# Check status
docker-compose ps
```
EOF
```

- [ ] **Step 5: Commit changes**

```bash
git add docker/
git commit -m "feat(docker): add docker-compose configuration

- n8n for workflow automation
- PostgreSQL for data storage
- Ollama for local LLM
- Redis for caching
- Health checks for all services

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 1.2: Create Database Schema

**Files:**
- Create: `infrastructure/docker/init-db/01-schema.sql`
- Create: `infrastructure/docker/init-db/02-seed-prompts.sql`

- [ ] **Step 1: Create init-db directory**

```bash
mkdir -p docker/init-db
```

- [ ] **Step 2: Create schema SQL**

```bash
cat > infrastructure/docker/init-db/01-schema.sql << 'EOF'
-- AI Agent Personal Database Schema
-- Version: 1.0
-- Created: 2026-03-16

-- Content Queue Table
CREATE TABLE content_queue (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    platform VARCHAR(50) NOT NULL DEFAULT 'linkedin',
    content_type VARCHAR(50),
    pillar VARCHAR(50),
    status VARCHAR(20) DEFAULT 'draft'
        CHECK (status IN ('draft', 'generating', 'pending_review', 'approved', 'rejected', 'scheduled', 'published')),
    original_prompt TEXT,
    generated_content TEXT,
    final_content TEXT,
    rejection_reason TEXT,
    scheduled_date TIMESTAMP,
    published_date TIMESTAMP,
    post_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Prompts Library Table
CREATE TABLE prompts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    platform VARCHAR(50) DEFAULT 'linkedin',
    pillar VARCHAR(50),
    content_type VARCHAR(50),
    system_prompt TEXT NOT NULL,
    user_prompt_template TEXT NOT NULL,
    variables TEXT[],
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Metrics Table
CREATE TABLE metrics (
    id SERIAL PRIMARY KEY,
    content_id INTEGER REFERENCES content_queue(id) ON DELETE CASCADE,
    platform VARCHAR(50),
    impressions INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    engagement_rate DECIMAL(5,2),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workflow Logs Table
CREATE TABLE workflow_logs (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(100) NOT NULL,
    execution_id VARCHAR(100),
    status VARCHAR(20) CHECK (status IN ('started', 'success', 'error', 'warning')),
    message TEXT,
    details JSONB,
    execution_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Topic Ideas Table (for content planning)
CREATE TABLE topic_ideas (
    id SERIAL PRIMARY KEY,
    topic VARCHAR(255) NOT NULL,
    pillar VARCHAR(50),
    notes TEXT,
    priority INTEGER DEFAULT 5,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_content_status ON content_queue(status);
CREATE INDEX idx_content_platform ON content_queue(platform);
CREATE INDEX idx_content_scheduled ON content_queue(scheduled_date);
CREATE INDEX idx_content_pillar ON content_queue(pillar);
CREATE INDEX idx_prompts_active ON prompts(is_active);
CREATE INDEX idx_prompts_pillar ON prompts(pillar);
CREATE INDEX idx_metrics_content ON metrics(content_id);
CREATE INDEX idx_logs_workflow ON workflow_logs(workflow_name);
CREATE INDEX idx_logs_status ON workflow_logs(status);
CREATE INDEX idx_topics_unused ON topic_ideas(used) WHERE used = false;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to tables
CREATE TRIGGER update_content_queue_updated_at
    BEFORE UPDATE ON content_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prompts_updated_at
    BEFORE UPDATE ON prompts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions (for n8n connection)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
EOF
```

- [ ] **Step 3: Create seed prompts SQL**

```bash
cat > infrastructure/docker/init-db/02-seed-prompts.sql << 'EOF'
-- Seed Prompts for LinkedIn Content Generation
-- Version: 1.0

-- Tech Insights Pillar (40%)
INSERT INTO prompts (name, platform, pillar, content_type, system_prompt, user_prompt_template, variables) VALUES
(
    'linkedin_tech_insights',
    'linkedin',
    'tech_insights',
    'thought_leadership',
    'You are a senior software engineer with 10+ years of experience. You write LinkedIn posts that share genuine insights about technology trends, tools, and practices. Your tone is professional but approachable, analytical but practical. You write in a mix of Vietnamese and English technical terms as appropriate for Vietnamese IT professionals.',
    'Write a LinkedIn post about: {{topic}}

Requirements:
- Start with a compelling hook (question, bold statement, or surprising fact)
- Share 2-3 key insights from your experience
- Include practical takeaways readers can apply
- End with a thought-provoking question to encourage discussion
- Length: 150-200 words
- Add 3-5 relevant hashtags at the end

Context: {{context}}',
    ARRAY['topic', 'context']
),

-- Career/Productivity Pillar (30%)
(
    'linkedin_career_tips',
    'linkedin',
    'career_productivity',
    'tips',
    'You are a tech professional who shares practical career and productivity advice. Your posts are actionable, based on real experience, and resonate with developers and tech workers. Write in Vietnamese with English technical terms.',
    'Write a LinkedIn post sharing tips about: {{topic}}

Requirements:
- Open with a relatable scenario or problem
- Provide 3-5 actionable tips
- Keep each tip concise and practical
- Share a personal example or lesson learned
- End with encouragement or a call to try these tips
- Length: 150-200 words
- Add 3-5 relevant hashtags

Context: {{context}}',
    ARRAY['topic', 'context']
),

-- Product/Project Pillar (20%)
(
    'linkedin_project_showcase',
    'linkedin',
    'product_project',
    'showcase',
    'You are sharing behind-the-scenes insights about your projects and products. Your tone is authentic, showing both successes and challenges. You aim to provide value by sharing lessons learned.',
    'Write a LinkedIn post about this project/product: {{topic}}

Requirements:
- Start with the problem you were solving
- Share key decisions and why you made them
- Include a challenge you faced and how you solved it
- Highlight results or learnings
- End with what you would do differently or next steps
- Length: 150-200 words
- Add 3-5 relevant hashtags

Context: {{context}}',
    ARRAY['topic', 'context']
),

-- Personal Stories Pillar (10%)
(
    'linkedin_personal_story',
    'linkedin',
    'personal_stories',
    'reflection',
    'You share personal experiences and reflections that connect with your professional journey. Your tone is authentic, vulnerable yet professional, and aims to inspire or teach through storytelling.',
    'Write a LinkedIn post reflecting on: {{topic}}

Requirements:
- Start with a specific moment or experience
- Share the emotions and thoughts you had
- Extract a lesson or insight
- Connect it to professional growth
- End with a question that invites others to share
- Length: 150-200 words
- Add 3-5 relevant hashtags

Context: {{context}}',
    ARRAY['topic', 'context']
);

-- Seed initial topic ideas
INSERT INTO topic_ideas (topic, pillar, notes, priority) VALUES
('AI đang thay đổi cách developers làm việc như thế nào', 'tech_insights', 'Focus on practical tools like Copilot, Claude', 1),
('5 tools automation giúp tiết kiệm 10 giờ/tuần', 'tech_insights', 'n8n, Zapier, scripting', 2),
('Tại sao tôi chuyển từ cloud sang local LLM', 'tech_insights', 'Privacy, cost, performance', 3),
('Cách tôi organize một ngày làm việc hiệu quả', 'career_productivity', 'Time blocking, deep work', 4),
('3 sai lầm khi học programming mà tôi ước biết sớm hơn', 'career_productivity', 'Tutorial hell, not building', 5),
('Từ idea đến MVP trong 2 tuần - lessons learned', 'product_project', 'AI Agent project', 6),
('Khi automation project đầu tiên thất bại', 'personal_stories', 'Lessons from failure', 7),
('Docker cho người mới - không khó như bạn nghĩ', 'tech_insights', 'Beginner friendly', 8),
('Remote work 3 năm - những điều không ai nói', 'personal_stories', 'Work-life balance', 9),
('Tại sao tôi vẫn dùng Vim sau 5 năm', 'tech_insights', 'Productivity tools', 10);
EOF
```

- [ ] **Step 4: Commit database schema**

```bash
git add infrastructure/docker/init-db/
git commit -m "feat(db): add PostgreSQL schema and seed data

Tables:
- content_queue: content lifecycle management
- prompts: prompt templates library
- metrics: engagement tracking
- workflow_logs: automation logging
- topic_ideas: content planning

Includes 4 LinkedIn prompt templates and 10 seed topics.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 1.3: Create Helper Scripts

**Files:**
- Create: `scripts/setup.sh`
- Create: `scripts/backup.sh`
- Create: `scripts/healthcheck.sh`

- [ ] **Step 1: Create scripts directory structure**

```bash
mkdir -p scripts
```

- [ ] **Step 2: Create setup script**

```bash
cat > scripts/setup.sh << 'EOF'
#!/bin/bash
# AI Agent Personal - Setup Script
# Usage: ./scripts/setup.sh

set -e

echo "========================================"
echo "AI Agent Personal Setup"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Docker
echo -e "\n${YELLOW}[1/6] Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker not found. Please install Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}Docker found: $(docker --version)${NC}"

# Check Docker Compose
echo -e "\n${YELLOW}[2/6] Checking Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose not found. Please install it first.${NC}"
    exit 1
fi
echo -e "${GREEN}Docker Compose found: $(docker-compose --version)${NC}"

# Setup environment file
echo -e "\n${YELLOW}[3/6] Setting up environment...${NC}"
cd docker
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${YELLOW}Created .env file. Please edit it with your passwords.${NC}"
    echo -e "${YELLOW}Then run this script again.${NC}"
    exit 0
else
    echo -e "${GREEN}.env file exists${NC}"
fi

# Start services
echo -e "\n${YELLOW}[4/6] Starting Docker services...${NC}"
docker-compose up -d

# Wait for services
echo -e "\n${YELLOW}[5/6] Waiting for services to be healthy...${NC}"
sleep 10

# Check health
echo -e "\n${YELLOW}[6/6] Checking service health...${NC}"
docker-compose ps

# Pull Ollama model
echo -e "\n${YELLOW}Pulling Llama 3.1 8B model (this may take a while)...${NC}"
docker exec -it ollama ollama pull llama3.1:8b

echo -e "\n${GREEN}========================================"
echo "Setup Complete!"
echo "========================================"
echo -e "n8n UI: http://localhost:5678"
echo -e "PostgreSQL: localhost:5432"
echo -e "Ollama API: localhost:11434"
echo -e "========================================${NC}"
EOF
chmod +x scripts/setup.sh
```

- [ ] **Step 3: Create backup script**

```bash
cat > scripts/backup.sh << 'EOF'
#!/bin/bash
# AI Agent Personal - Backup Script
# Usage: ./scripts/backup.sh
# Cron: 0 3 * * * /path/to/scripts/backup.sh

set -e

# Configuration
BACKUP_DIR="${HOME}/backups/social-automation"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting backup: ${DATE}${NC}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Backup PostgreSQL
echo -e "${YELLOW}Backing up PostgreSQL...${NC}"
docker exec postgres pg_dump -U postgres agent_personal > "${BACKUP_DIR}/postgres_${DATE}.sql"
gzip "${BACKUP_DIR}/postgres_${DATE}.sql"
echo -e "${GREEN}PostgreSQL backup: postgres_${DATE}.sql.gz${NC}"

# Backup n8n workflows (export command)
echo -e "${YELLOW}Backing up n8n data...${NC}"
docker cp n8n:/home/node/.n8n "${BACKUP_DIR}/n8n_${DATE}"
tar -czf "${BACKUP_DIR}/n8n_${DATE}.tar.gz" -C "${BACKUP_DIR}" "n8n_${DATE}"
rm -rf "${BACKUP_DIR}/n8n_${DATE}"
echo -e "${GREEN}n8n backup: n8n_${DATE}.tar.gz${NC}"

# Cleanup old backups
echo -e "${YELLOW}Cleaning up backups older than ${RETENTION_DAYS} days...${NC}"
find "${BACKUP_DIR}" -name "*.gz" -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "*.sql" -mtime +${RETENTION_DAYS} -delete

# List current backups
echo -e "\n${GREEN}Current backups:${NC}"
ls -lh "${BACKUP_DIR}"

echo -e "\n${GREEN}Backup complete!${NC}"
EOF
chmod +x scripts/backup.sh
```

- [ ] **Step 4: Create healthcheck script**

```bash
cat > scripts/healthcheck.sh << 'EOF'
#!/bin/bash
# AI Agent Personal - Health Check Script
# Usage: ./scripts/healthcheck.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "Health Check - $(date)"
echo "========================================"

HEALTHY=true

# Check n8n
echo -ne "n8n:        "
if curl -sf http://localhost:5678/healthz > /dev/null 2>&1; then
    echo -e "${GREEN}HEALTHY${NC}"
else
    echo -e "${RED}UNHEALTHY${NC}"
    HEALTHY=false
fi

# Check PostgreSQL
echo -ne "PostgreSQL: "
if docker exec postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}HEALTHY${NC}"
else
    echo -e "${RED}UNHEALTHY${NC}"
    HEALTHY=false
fi

# Check Ollama
echo -ne "Ollama:     "
if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}HEALTHY${NC}"
else
    echo -e "${RED}UNHEALTHY${NC}"
    HEALTHY=false
fi

# Check Redis
echo -ne "Redis:      "
if docker exec redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}HEALTHY${NC}"
else
    echo -e "${RED}UNHEALTHY${NC}"
    HEALTHY=false
fi

echo "========================================"

# Check disk usage
echo -e "\n${YELLOW}Disk Usage:${NC}"
df -h / | tail -1 | awk '{print "Used: "$3" / "$2" ("$5")"}'

# Check memory
echo -e "\n${YELLOW}Memory Usage:${NC}"
free -h | grep Mem | awk '{print "Used: "$3" / "$2}'

# Check Docker stats
echo -e "\n${YELLOW}Container Resources:${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""

if [ "$HEALTHY" = true ]; then
    echo -e "${GREEN}All services healthy!${NC}"
    exit 0
else
    echo -e "${RED}Some services unhealthy!${NC}"
    exit 1
fi
EOF
chmod +x scripts/healthcheck.sh
```

- [ ] **Step 5: Commit scripts**

```bash
git add scripts/
git commit -m "feat(scripts): add setup, backup, and healthcheck scripts

- setup.sh: automated Docker environment setup
- backup.sh: PostgreSQL and n8n daily backup with retention
- healthcheck.sh: service health monitoring

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 1.4: Create Telegram Bot Configuration

**Files:**
- Create: `infrastructure/docker/telegram-config.md`

- [ ] **Step 1: Create Telegram setup guide**

```bash
cat > infrastructure/docker/telegram-config.md << 'EOF'
# Telegram Bot Setup Guide

## 1. Create Bot

1. Open Telegram and search for `@BotFather`
2. Send `/newbot`
3. Follow prompts:
   - Bot name: `AI Agent Notifier` (or your choice)
   - Username: `your_agent_bot` (must end in `bot`)
4. Save the **API Token** (looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

## 2. Get Your Chat ID

1. Message your new bot (send any message)
2. Open this URL in browser (replace TOKEN):
   ```
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
3. Find `"chat":{"id":123456789}` - that's your Chat ID

## 3. Test Bot

```bash
# Replace with your values
TOKEN="your_bot_token"
CHAT_ID="your_chat_id"

curl -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "text=Hello from AI Agent!"
```

## 4. Configure in n8n

1. Open n8n: http://localhost:5678
2. Go to **Credentials** → **Add Credential**
3. Search for **Telegram**
4. Enter:
   - **Credential Name**: `Telegram Bot`
   - **Access Token**: Your bot token
5. Save and test

## 5. Environment Variables

Add to `infrastructure/docker/.env`:
```
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id
```

## Message Formatting

n8n Telegram node supports Markdown:
```
*Bold text*
_Italic text_
`Code`
[Link](https://example.com)
```

## Common Notification Templates

**Content Ready:**
```
📝 *New Content Ready for Review*

Title: {{title}}
Platform: {{platform}}
Status: Pending Review

Review at: http://localhost:5678
```

**Error Alert:**
```
🚨 *Workflow Error*

Workflow: {{workflow_name}}
Error: {{error_message}}
Time: {{timestamp}}
```

**Daily Digest:**
```
📊 *Daily Digest - {{date}}*

Pending Review: {{pending_count}}
Scheduled: {{scheduled_count}}
Published Today: {{published_count}}
```
EOF
```

- [ ] **Step 2: Commit Telegram guide**

```bash
git add infrastructure/docker/telegram-config.md
git commit -m "docs(telegram): add bot setup and configuration guide

Includes:
- Bot creation steps
- Chat ID retrieval
- n8n credential setup
- Message templates

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 1.5: Verify Infrastructure Setup

**Files:**
- None (verification only)

- [ ] **Step 1: Copy and configure environment**

```bash
cd docker
cp .env.example .env
# Edit .env with actual passwords
```

- [ ] **Step 2: Start all services**

```bash
docker-compose up -d
```

Run: `docker-compose up -d`
Expected: All 4 containers starting

- [ ] **Step 3: Wait for healthy status**

```bash
sleep 30
docker-compose ps
```

Expected output:
```
NAME       STATUS                   PORTS
n8n        Up (healthy)             0.0.0.0:5678->5678/tcp
ollama     Up (healthy)             0.0.0.0:11434->11434/tcp
postgres   Up (healthy)             0.0.0.0:5432->5432/tcp
redis      Up (healthy)             0.0.0.0:6379->6379/tcp
```

- [ ] **Step 4: Pull Llama model**

```bash
docker exec -it ollama ollama pull llama3.1:8b
```

Expected: Model download completes (~4.7GB)

- [ ] **Step 5: Test Ollama**

```bash
curl -s http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Xin chào, bạn có thể viết một câu ngắn về AI không?",
  "stream": false
}' | jq .response
```

Expected: Vietnamese response about AI

- [ ] **Step 6: Test PostgreSQL**

```bash
docker exec postgres psql -U postgres -d agent_personal -c "SELECT COUNT(*) FROM prompts;"
```

Expected: `count = 4` (seed prompts)

- [ ] **Step 7: Test Redis**

```bash
docker exec redis redis-cli ping
```

Expected: `PONG`

- [ ] **Step 8: Access n8n UI**

Open browser: http://localhost:5678
Expected: n8n login page

- [ ] **Step 9: Run healthcheck script**

```bash
./scripts/healthcheck.sh
```

Expected: All services HEALTHY

---

## Chunk 2: Core Workflows (Week 3-4)

### Task 2.1: Create n8n Workflow - Content Generate

**Files:**
- Create: `modules/social/workflows/content-generate.json`
- Docs: Manual workflow creation in n8n UI

- [ ] **Step 1: Create workflows directory**

```bash
mkdir -p workflows/n8n
```

- [ ] **Step 2: Document workflow structure**

```bash
cat > workflows/n8n/README.md << 'EOF'
# n8n Workflows

## Workflow List

| # | Name | Trigger | Purpose |
|---|------|---------|---------|
| WF1 | content-generate | Manual | Generate single content |
| WF2 | batch-generate | Cron | Generate weekly batch |
| WF3 | daily-digest | Cron | Send pending items summary |
| WF4 | format-validate | Webhook | Format approved content |
| WF5 | healthcheck | Cron | Monitor services |

## Import Workflows

1. Open n8n: http://localhost:5678
2. Go to Workflows → Import
3. Select JSON file from this directory

## Credentials Required

Before importing, create these credentials in n8n:

1. **PostgreSQL - Agent Personal**
   - Host: `postgres`
   - Port: `5432`
   - Database: `agent_personal`
   - User: `postgres`
   - Password: (from .env)

2. **Telegram Bot**
   - Access Token: (from BotFather)

## Workflow Details

### WF1: content-generate
```
Manual Trigger
    → Set topic/pillar/type
    → PostgreSQL: Get prompt template
    → HTTP: Call Ollama API
    → Code: Parse response
    → PostgreSQL: Insert to content_queue
    → Telegram: Notify
```

### WF2: batch-generate
```
Cron (Mon/Wed/Fri 8:00)
    → PostgreSQL: Get unused topics
    → Loop: For each topic (limit 3)
        → Execute content-generate workflow
        → Wait 30s
    → Telegram: Send summary
```

### WF3: daily-digest
```
Cron (Daily 9:00)
    → PostgreSQL: Count by status
    → PostgreSQL: Get pending_review items
    → Code: Format message
    → Telegram: Send digest
```
EOF
```

- [ ] **Step 3: Create content-generate workflow JSON**

```bash
cat > modules/social/workflows/content-generate.json << 'EOF'
{
  "name": "WF1: Content Generate",
  "nodes": [
    {
      "parameters": {},
      "name": "Manual Trigger",
      "type": "n8n-nodes-base.manualTrigger",
      "position": [250, 300]
    },
    {
      "parameters": {
        "values": {
          "string": [
            {"name": "topic", "value": "AI đang thay đổi cách developers làm việc"},
            {"name": "pillar", "value": "tech_insights"},
            {"name": "content_type", "value": "thought_leadership"},
            {"name": "context", "value": "Focus on practical tools and daily impact"}
          ]
        }
      },
      "name": "Set Input",
      "type": "n8n-nodes-base.set",
      "position": [450, 300]
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT system_prompt, user_prompt_template FROM prompts WHERE pillar = '{{ $json.pillar }}' AND is_active = true LIMIT 1"
      },
      "name": "Get Prompt",
      "type": "n8n-nodes-base.postgres",
      "position": [650, 300],
      "credentials": {
        "postgres": "PostgreSQL - Agent Personal"
      }
    },
    {
      "parameters": {
        "jsCode": "const input = $('Set Input').first().json;\nconst prompt = $('Get Prompt').first().json;\n\nlet userPrompt = prompt.user_prompt_template;\nuserPrompt = userPrompt.replace('{{topic}}', input.topic);\nuserPrompt = userPrompt.replace('{{context}}', input.context);\n\nreturn {\n  system_prompt: prompt.system_prompt,\n  user_prompt: userPrompt,\n  topic: input.topic,\n  pillar: input.pillar,\n  content_type: input.content_type\n};"
      },
      "name": "Prepare Prompt",
      "type": "n8n-nodes-base.code",
      "position": [850, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://ollama:11434/api/chat",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "model",
              "value": "llama3.1:8b"
            },
            {
              "name": "messages",
              "value": "=[{\"role\": \"system\", \"content\": \"{{ $json.system_prompt }}\"}, {\"role\": \"user\", \"content\": \"{{ $json.user_prompt }}\"}]"
            },
            {
              "name": "stream",
              "value": "false"
            }
          ]
        },
        "options": {
          "timeout": 120000
        }
      },
      "name": "Call Ollama",
      "type": "n8n-nodes-base.httpRequest",
      "position": [1050, 300]
    },
    {
      "parameters": {
        "jsCode": "const ollamaResponse = $input.first().json;\nconst preparedData = $('Prepare Prompt').first().json;\n\nconst content = ollamaResponse.message?.content || 'Generation failed';\n\nreturn {\n  title: preparedData.topic,\n  platform: 'linkedin',\n  pillar: preparedData.pillar,\n  content_type: preparedData.content_type,\n  generated_content: content,\n  status: 'pending_review'\n};"
      },
      "name": "Parse Response",
      "type": "n8n-nodes-base.code",
      "position": [1250, 300]
    },
    {
      "parameters": {
        "operation": "insert",
        "table": "content_queue",
        "columns": "title, platform, pillar, content_type, generated_content, status",
        "values": "={{ $json.title }}, {{ $json.platform }}, {{ $json.pillar }}, {{ $json.content_type }}, {{ $json.generated_content }}, {{ $json.status }}"
      },
      "name": "Save to DB",
      "type": "n8n-nodes-base.postgres",
      "position": [1450, 300],
      "credentials": {
        "postgres": "PostgreSQL - Agent Personal"
      }
    },
    {
      "parameters": {
        "chatId": "={{ $env.TELEGRAM_CHAT_ID }}",
        "text": "=📝 *New Content Ready*\n\nTopic: {{ $('Parse Response').first().json.title }}\nPillar: {{ $('Parse Response').first().json.pillar }}\nStatus: Pending Review\n\nReview at: http://localhost:5678",
        "additionalFields": {
          "parse_mode": "Markdown"
        }
      },
      "name": "Notify Telegram",
      "type": "n8n-nodes-base.telegram",
      "position": [1650, 300],
      "credentials": {
        "telegramApi": "Telegram Bot"
      }
    }
  ],
  "connections": {
    "Manual Trigger": {"main": [[{"node": "Set Input", "type": "main", "index": 0}]]},
    "Set Input": {"main": [[{"node": "Get Prompt", "type": "main", "index": 0}]]},
    "Get Prompt": {"main": [[{"node": "Prepare Prompt", "type": "main", "index": 0}]]},
    "Prepare Prompt": {"main": [[{"node": "Call Ollama", "type": "main", "index": 0}]]},
    "Call Ollama": {"main": [[{"node": "Parse Response", "type": "main", "index": 0}]]},
    "Parse Response": {"main": [[{"node": "Save to DB", "type": "main", "index": 0}]]},
    "Save to DB": {"main": [[{"node": "Notify Telegram", "type": "main", "index": 0}]]}
  }
}
EOF
```

- [ ] **Step 4: Commit workflow**

```bash
git add workflows/
git commit -m "feat(workflows): add content-generate n8n workflow

WF1: Manual trigger → Ollama → PostgreSQL → Telegram
Includes workflow documentation and import instructions.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 2.2: Create Batch Generate Workflow

**Files:**
- Create: `modules/social/workflows/batch-generate.json`

- [ ] **Step 1: Create batch-generate workflow**

```bash
cat > modules/social/workflows/batch-generate.json << 'EOF'
{
  "name": "WF2: Batch Generate",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [
            {
              "triggerAtHour": 8,
              "triggerAtMinute": 0
            }
          ]
        }
      },
      "name": "Cron Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "position": [250, 300],
      "typeVersion": 1.1
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT id, topic, pillar, notes FROM topic_ideas WHERE used = false ORDER BY priority ASC LIMIT 3"
      },
      "name": "Get Topics",
      "type": "n8n-nodes-base.postgres",
      "position": [450, 300],
      "credentials": {
        "postgres": "PostgreSQL - Agent Personal"
      }
    },
    {
      "parameters": {
        "batchSize": 1,
        "options": {}
      },
      "name": "Loop Topics",
      "type": "n8n-nodes-base.splitInBatches",
      "position": [650, 300]
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT system_prompt, user_prompt_template FROM prompts WHERE pillar = '{{ $json.pillar }}' AND is_active = true LIMIT 1"
      },
      "name": "Get Prompt",
      "type": "n8n-nodes-base.postgres",
      "position": [850, 300],
      "credentials": {
        "postgres": "PostgreSQL - Agent Personal"
      }
    },
    {
      "parameters": {
        "jsCode": "const topic = $('Loop Topics').first().json;\nconst prompt = $('Get Prompt').first().json;\n\nlet userPrompt = prompt.user_prompt_template;\nuserPrompt = userPrompt.replace('{{topic}}', topic.topic);\nuserPrompt = userPrompt.replace('{{context}}', topic.notes || '');\n\nreturn {\n  topic_id: topic.id,\n  system_prompt: prompt.system_prompt,\n  user_prompt: userPrompt,\n  topic: topic.topic,\n  pillar: topic.pillar\n};"
      },
      "name": "Prepare",
      "type": "n8n-nodes-base.code",
      "position": [1050, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://ollama:11434/api/chat",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {"name": "model", "value": "llama3.1:8b"},
            {"name": "messages", "value": "=[{\"role\": \"system\", \"content\": \"{{ $json.system_prompt }}\"}, {\"role\": \"user\", \"content\": \"{{ $json.user_prompt }}\"}]"},
            {"name": "stream", "value": "false"}
          ]
        },
        "options": {"timeout": 120000}
      },
      "name": "Generate",
      "type": "n8n-nodes-base.httpRequest",
      "position": [1250, 300]
    },
    {
      "parameters": {
        "operation": "insert",
        "table": "content_queue",
        "columns": "title, platform, pillar, content_type, generated_content, status",
        "values": "={{ $('Prepare').first().json.topic }}, linkedin, {{ $('Prepare').first().json.pillar }}, thought_leadership, {{ $json.message.content }}, pending_review"
      },
      "name": "Save Content",
      "type": "n8n-nodes-base.postgres",
      "position": [1450, 300],
      "credentials": {
        "postgres": "PostgreSQL - Agent Personal"
      }
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "UPDATE topic_ideas SET used = true WHERE id = {{ $('Prepare').first().json.topic_id }}"
      },
      "name": "Mark Used",
      "type": "n8n-nodes-base.postgres",
      "position": [1650, 300],
      "credentials": {
        "postgres": "PostgreSQL - Agent Personal"
      }
    },
    {
      "parameters": {
        "amount": 30,
        "unit": "seconds"
      },
      "name": "Wait",
      "type": "n8n-nodes-base.wait",
      "position": [1850, 300]
    },
    {
      "parameters": {
        "chatId": "={{ $env.TELEGRAM_CHAT_ID }}",
        "text": "=📦 *Batch Generation Complete*\n\nGenerated: 3 posts\nStatus: Pending Review\n\nReview at: http://localhost:5678",
        "additionalFields": {"parse_mode": "Markdown"}
      },
      "name": "Summary",
      "type": "n8n-nodes-base.telegram",
      "position": [1250, 500],
      "credentials": {
        "telegramApi": "Telegram Bot"
      }
    }
  ],
  "connections": {
    "Cron Trigger": {"main": [[{"node": "Get Topics", "type": "main", "index": 0}]]},
    "Get Topics": {"main": [[{"node": "Loop Topics", "type": "main", "index": 0}]]},
    "Loop Topics": {"main": [[{"node": "Get Prompt", "type": "main", "index": 0}], [{"node": "Summary", "type": "main", "index": 0}]]},
    "Get Prompt": {"main": [[{"node": "Prepare", "type": "main", "index": 0}]]},
    "Prepare": {"main": [[{"node": "Generate", "type": "main", "index": 0}]]},
    "Generate": {"main": [[{"node": "Save Content", "type": "main", "index": 0}]]},
    "Save Content": {"main": [[{"node": "Mark Used", "type": "main", "index": 0}]]},
    "Mark Used": {"main": [[{"node": "Wait", "type": "main", "index": 0}]]},
    "Wait": {"main": [[{"node": "Loop Topics", "type": "main", "index": 0}]]}
  }
}
EOF
```

- [ ] **Step 2: Commit workflow**

```bash
git add modules/social/workflows/batch-generate.json
git commit -m "feat(workflows): add batch-generate workflow

WF2: Cron (Mon/Wed/Fri 8AM) → Get topics → Loop generate → Notify
Generates 3 posts per batch with 30s delay between.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 2.3: Create Daily Digest Workflow

**Files:**
- Create: `workflows/n8n/daily-digest.json`

- [ ] **Step 1: Create daily-digest workflow**

```bash
cat > workflows/n8n/daily-digest.json << 'EOF'
{
  "name": "WF3: Daily Digest",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [{"triggerAtHour": 9, "triggerAtMinute": 0}]
        }
      },
      "name": "Daily 9AM",
      "type": "n8n-nodes-base.scheduleTrigger",
      "position": [250, 300]
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT status, COUNT(*) as count FROM content_queue GROUP BY status"
      },
      "name": "Get Stats",
      "type": "n8n-nodes-base.postgres",
      "position": [450, 300],
      "credentials": {"postgres": "PostgreSQL - Agent Personal"}
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT id, title, pillar FROM content_queue WHERE status = 'pending_review' ORDER BY created_at DESC LIMIT 5"
      },
      "name": "Get Pending",
      "type": "n8n-nodes-base.postgres",
      "position": [450, 450],
      "credentials": {"postgres": "PostgreSQL - Agent Personal"}
    },
    {
      "parameters": {
        "jsCode": "const stats = $('Get Stats').all().map(i => i.json);\nconst pending = $('Get Pending').all().map(i => i.json);\n\nconst statusCounts = {};\nstats.forEach(s => statusCounts[s.status] = s.count);\n\nlet message = `📊 *Daily Digest - ${new Date().toLocaleDateString('vi-VN')}*\\n\\n`;\nmessage += `📝 Draft: ${statusCounts.draft || 0}\\n`;\nmessage += `⏳ Pending Review: ${statusCounts.pending_review || 0}\\n`;\nmessage += `✅ Approved: ${statusCounts.approved || 0}\\n`;\nmessage += `📅 Scheduled: ${statusCounts.scheduled || 0}\\n`;\nmessage += `🚀 Published: ${statusCounts.published || 0}\\n`;\n\nif (pending.length > 0) {\n  message += `\\n*Pending Review:*\\n`;\n  pending.forEach((p, i) => {\n    message += `${i+1}. ${p.title} (${p.pillar})\\n`;\n  });\n}\n\nmessage += `\\n_Review at: http://localhost:5678_`;\n\nreturn { message };"
      },
      "name": "Format Message",
      "type": "n8n-nodes-base.code",
      "position": [700, 375]
    },
    {
      "parameters": {
        "chatId": "={{ $env.TELEGRAM_CHAT_ID }}",
        "text": "={{ $json.message }}",
        "additionalFields": {"parse_mode": "Markdown"}
      },
      "name": "Send Digest",
      "type": "n8n-nodes-base.telegram",
      "position": [900, 375],
      "credentials": {"telegramApi": "Telegram Bot"}
    }
  ],
  "connections": {
    "Daily 9AM": {"main": [[{"node": "Get Stats", "type": "main", "index": 0}, {"node": "Get Pending", "type": "main", "index": 0}]]},
    "Get Stats": {"main": [[{"node": "Format Message", "type": "main", "index": 0}]]},
    "Get Pending": {"main": [[{"node": "Format Message", "type": "main", "index": 0}]]},
    "Format Message": {"main": [[{"node": "Send Digest", "type": "main", "index": 0}]]}
  }
}
EOF
```

- [ ] **Step 2: Commit workflow**

```bash
git add workflows/n8n/daily-digest.json
git commit -m "feat(workflows): add daily-digest workflow

WF3: Cron (9AM) → Stats query → Pending items → Telegram digest
Shows content pipeline status and pending review items.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 2.4: Create Healthcheck Workflow

**Files:**
- Create: `workflows/n8n/healthcheck.json`

- [ ] **Step 1: Create healthcheck workflow**

```bash
cat > workflows/n8n/healthcheck.json << 'EOF'
{
  "name": "WF5: Healthcheck",
  "nodes": [
    {
      "parameters": {
        "rule": {"interval": [{"field": "minutes", "minutesInterval": 5}]}
      },
      "name": "Every 5 Min",
      "type": "n8n-nodes-base.scheduleTrigger",
      "position": [250, 300]
    },
    {
      "parameters": {
        "url": "http://ollama:11434/api/tags",
        "options": {"timeout": 5000}
      },
      "name": "Check Ollama",
      "type": "n8n-nodes-base.httpRequest",
      "position": [450, 200],
      "continueOnFail": true
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT 1 as health"
      },
      "name": "Check Postgres",
      "type": "n8n-nodes-base.postgres",
      "position": [450, 350],
      "credentials": {"postgres": "PostgreSQL - Agent Personal"},
      "continueOnFail": true
    },
    {
      "parameters": {
        "url": "http://redis:6379",
        "options": {"timeout": 5000}
      },
      "name": "Check Redis",
      "type": "n8n-nodes-base.httpRequest",
      "position": [450, 500],
      "continueOnFail": true
    },
    {
      "parameters": {
        "jsCode": "const ollama = $('Check Ollama').first();\nconst postgres = $('Check Postgres').first();\n\nconst results = {\n  ollama: !ollama.error,\n  postgres: !postgres.error,\n  timestamp: new Date().toISOString()\n};\n\nconst allHealthy = results.ollama && results.postgres;\n\nreturn { ...results, allHealthy };"
      },
      "name": "Evaluate",
      "type": "n8n-nodes-base.code",
      "position": [700, 300]
    },
    {
      "parameters": {
        "conditions": {
          "boolean": [{"value1": "={{ $json.allHealthy }}", "value2": true}]
        }
      },
      "name": "Is Healthy?",
      "type": "n8n-nodes-base.if",
      "position": [900, 300]
    },
    {
      "parameters": {
        "operation": "insert",
        "table": "workflow_logs",
        "columns": "workflow_name, status, message",
        "values": "healthcheck, success, All services healthy"
      },
      "name": "Log Success",
      "type": "n8n-nodes-base.postgres",
      "position": [1100, 200],
      "credentials": {"postgres": "PostgreSQL - Agent Personal"}
    },
    {
      "parameters": {
        "chatId": "={{ $env.TELEGRAM_CHAT_ID }}",
        "text": "=🚨 *ALERT: Service Unhealthy*\\n\\nOllama: {{ $json.ollama ? '✅' : '❌' }}\\nPostgres: {{ $json.postgres ? '✅' : '❌' }}\\n\\nTime: {{ $json.timestamp }}",
        "additionalFields": {"parse_mode": "Markdown"}
      },
      "name": "Alert",
      "type": "n8n-nodes-base.telegram",
      "position": [1100, 400],
      "credentials": {"telegramApi": "Telegram Bot"}
    }
  ],
  "connections": {
    "Every 5 Min": {"main": [[{"node": "Check Ollama", "type": "main", "index": 0}, {"node": "Check Postgres", "type": "main", "index": 0}, {"node": "Check Redis", "type": "main", "index": 0}]]},
    "Check Ollama": {"main": [[{"node": "Evaluate", "type": "main", "index": 0}]]},
    "Check Postgres": {"main": [[{"node": "Evaluate", "type": "main", "index": 0}]]},
    "Check Redis": {"main": [[{"node": "Evaluate", "type": "main", "index": 0}]]},
    "Evaluate": {"main": [[{"node": "Is Healthy?", "type": "main", "index": 0}]]},
    "Is Healthy?": {"main": [[{"node": "Log Success", "type": "main", "index": 0}], [{"node": "Alert", "type": "main", "index": 0}]]}
  }
}
EOF
```

- [ ] **Step 2: Commit all remaining workflows**

```bash
git add workflows/n8n/
git commit -m "feat(workflows): add healthcheck workflow

WF5: Every 5min → Check services → Alert if unhealthy
Monitors Ollama, PostgreSQL, Redis and sends Telegram alerts.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Chunk 3: LinkedIn MVP (Week 5-6)

### Task 3.1: Create Content Pillar Documentation

**Files:**
- Create: `documents/01-business/social/content-pillars.md`

- [ ] **Step 1: Create content pillars documentation**

```bash
cat > documents/01-business/social/content-pillars.md << 'EOF'
# LinkedIn Content Pillars

## Overview

| Pillar | % | Posting Day | Time |
|--------|---|-------------|------|
| Tech Insights | 40% | Monday | 09:00 |
| Career/Productivity | 30% | Wednesday | 12:00 |
| Product/Project | 20% | Friday (alt) | 17:00 |
| Personal Stories | 10% | Friday (alt) | 17:00 |

## Pillar Details

### 1. Tech Insights (40%)

**Focus:** AI, automation, developer tools, tech trends

**Topics:**
- AI tools for developers (Copilot, Claude, etc.)
- Automation workflows and tools
- New frameworks and technologies
- Industry trends and predictions

**Tone:** Analytical, forward-looking, practical

**Template:** See `prompts.linkedin_tech_insights`

### 2. Career/Productivity (30%)

**Focus:** Tips, workflows, lessons learned

**Topics:**
- Time management techniques
- Learning strategies
- Common mistakes to avoid
- Tool recommendations

**Tone:** Practical, actionable, supportive

**Template:** See `prompts.linkedin_career_tips`

### 3. Product/Project (20%)

**Focus:** Showcase work, behind-the-scenes

**Topics:**
- Current project updates
- Technical decisions explained
- Challenges and solutions
- Results and learnings

**Tone:** Authentic, storytelling, educational

**Template:** See `prompts.linkedin_project_showcase`

### 4. Personal Stories (10%)

**Focus:** Experiences, reflections

**Topics:**
- Career journey moments
- Lessons from failures
- Industry observations
- Personal opinions

**Tone:** Reflective, vulnerable, engaging

**Template:** See `prompts.linkedin_personal_story`

## Posting Schedule

```
Week N:
├── Monday 09:00    - Tech Insights
├── Wednesday 12:00 - Career/Productivity
└── Friday 17:00    - Product OR Personal (alternate)

Week N+1:
├── Monday 09:00    - Tech Insights
├── Wednesday 12:00 - Career/Productivity
└── Friday 17:00    - Personal OR Product (alternate)
```

## Quality Checklist

Before approving any post:

- [ ] Hook is compelling (first line grabs attention)
- [ ] Value is clear (reader learns something)
- [ ] Length is appropriate (150-200 words)
- [ ] Hashtags are relevant (3-5)
- [ ] No AI artifacts ("As an AI...", etc.)
- [ ] Tone matches pillar
- [ ] Call-to-action included
EOF
```

- [ ] **Step 2: Commit documentation**

```bash
git add documents/01-business/social/content-pillars.md
git commit -m "docs: add LinkedIn content pillars guide

Defines 4 content pillars with posting schedule:
- Tech Insights (40%) - Monday
- Career/Productivity (30%) - Wednesday
- Product/Project (20%) - Friday
- Personal Stories (10%) - Friday alternate

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 3.2: Create Runbook

**Files:**
- Create: `documents/05-guides/runbook.md`

- [ ] **Step 1: Create operations runbook**

```bash
cat > documents/05-guides/runbook.md << 'EOF'
# Operations Runbook

## Daily Checklist

### Morning (9:00 AM)
- [ ] Check Telegram for daily digest
- [ ] Review pending content (if any)
- [ ] Approve/reject with feedback

### Evening (if posting day)
- [ ] Copy approved content
- [ ] Post to LinkedIn
- [ ] Update DB with post URL
- [ ] Confirm in Telegram

## Weekly Checklist

### Monday
- [ ] Review previous week's metrics
- [ ] Add new topic ideas (if < 10 unused)
- [ ] Check workflow execution logs

### Friday
- [ ] Backup verification
- [ ] Review error logs
- [ ] Plan next week's content

## Common Operations

### Start Services
```bash
cd docker
docker-compose up -d
```

### Stop Services
```bash
cd docker
docker-compose down
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f n8n
```

### Restart Service
```bash
docker-compose restart n8n
```

### Manual Backup
```bash
./scripts/backup.sh
```

### Health Check
```bash
./scripts/healthcheck.sh
```

### Access PostgreSQL
```bash
docker exec -it postgres psql -U postgres -d agent_personal
```

### Test Ollama
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Hello",
  "stream": false
}'
```

## Content Operations

### Add New Topic
```sql
INSERT INTO topic_ideas (topic, pillar, notes, priority)
VALUES ('Your topic here', 'tech_insights', 'Additional context', 5);
```

### View Pending Content
```sql
SELECT id, title, pillar, created_at
FROM content_queue
WHERE status = 'pending_review'
ORDER BY created_at DESC;
```

### Approve Content
```sql
UPDATE content_queue
SET status = 'approved',
    scheduled_date = '2026-03-18 09:00:00'
WHERE id = 123;
```

### Reject Content
```sql
UPDATE content_queue
SET status = 'rejected',
    rejection_reason = 'Needs more specific examples'
WHERE id = 123;
```

### Mark as Published
```sql
UPDATE content_queue
SET status = 'published',
    published_date = NOW(),
    post_url = 'https://linkedin.com/posts/...'
WHERE id = 123;
```

## Troubleshooting

### Ollama Not Responding
```bash
# Check container
docker logs ollama

# Restart
docker-compose restart ollama

# Verify model
docker exec ollama ollama list
```

### n8n Workflow Failing
1. Check n8n UI execution logs
2. Verify credentials are valid
3. Check PostgreSQL connection
4. Review error in workflow_logs table

### Database Connection Issues
```bash
# Check PostgreSQL
docker logs postgres

# Test connection
docker exec postgres pg_isready -U postgres

# Restart if needed
docker-compose restart postgres
```

### Backup Failed
```bash
# Check disk space
df -h

# Manual backup
docker exec postgres pg_dump -U postgres agent_personal > backup.sql

# Check cron
crontab -l
```

## Emergency Contacts

- **System**: Check Docker logs first
- **n8n Issues**: https://community.n8n.io
- **Ollama Issues**: https://github.com/ollama/ollama/issues
EOF
```

- [ ] **Step 2: Commit runbook**

```bash
git add documents/05-guides/runbook.md
git commit -m "docs: add operations runbook

Includes:
- Daily/weekly checklists
- Common operations commands
- Content management SQL
- Troubleshooting guides

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Execution Checklist

### Phase 1 Complete When:
- [ ] Docker Compose running 4 services
- [ ] PostgreSQL has schema + seed data
- [ ] Ollama responds to prompts
- [ ] Telegram bot configured
- [ ] Backup script working
- [ ] Healthcheck passing

### Phase 2 Complete When:
- [ ] WF1: content-generate working
- [ ] WF2: batch-generate scheduled
- [ ] WF3: daily-digest sending
- [ ] WF5: healthcheck monitoring
- [ ] All credentials configured

### Phase 3 Complete When:
- [ ] Content pillars documented
- [ ] 10+ topics in database
- [ ] 6 posts published to LinkedIn
- [ ] Metrics tracking started
- [ ] Runbook documented

### Phase 4 Complete When:
- [ ] 30-day stability started
- [ ] Monitoring alerts working
- [ ] Backup/restore tested
- [ ] <2 hours/week maintenance

---

**Plan Complete!**

Ready to execute with `superpowers:subagent-driven-development` or `superpowers:executing-plans`.
