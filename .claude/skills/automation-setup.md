# Automation Setup Guide - AI Agent Project

**Version:** 2.0 (Local LLM Edition)
**Last Updated:** 2026-03-16
**Purpose:** Setup n8n + Ollama + PostgreSQL on WSL2 for AI-powered social media automation

---

## 📋 Overview

This skill provides a complete guide for setting up a **100% local** automation stack:

```
┌─────────────────────────────────────────────────┐
│  MÁY CHỦ LOCAL 32GB (WSL2)                      │
├─────────────────────────────────────────────────┤
│  Docker Compose:                                │
│  ┌────────┐ ┌────────────┐ ┌─────────────────┐ │
│  │  n8n   │ │ PostgreSQL │ │ Ollama          │ │
│  │ :5678  │ │   :5432    │ │ Llama 3.1 8B    │ │
│  └────────┘ └────────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────┘

Chi phí: $0/tháng (hoàn toàn miễn phí)
```

## 🎯 When to Use This Skill

**Use this skill when:**
- ✅ Setting up local automation infrastructure
- ✅ Configuring Docker services (n8n, PostgreSQL, Ollama)
- ✅ Creating n8n workflows for content generation
- ✅ Integrating with social media APIs
- ✅ Troubleshooting automation issues

---

## 🚀 Part 1: Docker Environment Setup

### Step 1: Install Docker on WSL2 (15 minutes)

**Prerequisites:**
- Windows 10/11 with WSL2 enabled
- Ubuntu (or similar) installed on WSL2
- 32GB RAM recommended (16GB minimum)

**Installation:**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install docker.io docker-compose -y

# Add your user to docker group (avoids using sudo)
sudo usermod -aG docker $USER

# Restart WSL (run in PowerShell)
# wsl --shutdown
# Then reopen Ubuntu terminal

# Verify installation
docker --version
docker-compose --version
```

### Step 2: Create Project Structure (5 minutes)

```bash
# Create directory
mkdir -p ~/social-automation
cd ~/social-automation

# Create docker-compose.yml
touch docker-compose.yml

# Create data directories
mkdir -p data/postgres data/n8n data/ollama
```

### Step 3: Docker Compose Configuration (10 minutes)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # Workflow Automation
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      # Security
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=your_secure_password
      # Configuration
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - N8N_ENCRYPTION_KEY=your_random_encryption_key
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
      - ollama
    networks:
      - automation-network

  # Database
  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=your_db_password
      - POSTGRES_DB=agent_personal
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - automation-network

  # Local LLM
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - automation-network
    # GPU Support (uncomment if you have NVIDIA GPU)
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

volumes:
  n8n_data:
  postgres_data:
  ollama_data:

networks:
  automation-network:
    driver: bridge
```

### Step 4: Start Services (5 minutes)

```bash
# Start all services
docker-compose up -d

# Check status
docker ps

# Expected output:
# CONTAINER ID   IMAGE              STATUS    PORTS
# xxx            n8nio/n8n          Up        0.0.0.0:5678->5678/tcp
# xxx            postgres:15        Up        0.0.0.0:5432->5432/tcp
# xxx            ollama/ollama      Up        0.0.0.0:11434->11434/tcp
```

### Step 5: Download Llama Model (10-30 minutes)

```bash
# Pull Llama 3.1 8B model (~4.7GB download)
docker exec -it ollama ollama pull llama3.1:8b

# Verify model
docker exec -it ollama ollama list

# Test model
docker exec -it ollama ollama run llama3.1:8b "Hello! Write a short LinkedIn post about AI."
```

---

## 🗄️ Part 2: PostgreSQL Setup

### Step 1: Create Database Schema

```bash
# Connect to PostgreSQL
docker exec -it postgres psql -U postgres -d agent_personal
```

Run the following SQL:

```sql
-- Content Queue Table
CREATE TABLE content_queue (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    platform VARCHAR(50) NOT NULL CHECK (platform IN ('linkedin', 'facebook_tech', 'facebook_chinese')),
    content_type VARCHAR(50),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'approved', 'scheduled', 'published', 'rejected')),
    original_prompt TEXT,
    generated_content TEXT,
    final_content TEXT,
    scheduled_date TIMESTAMP,
    published_date TIMESTAMP,
    post_url VARCHAR(500),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Metrics Table
CREATE TABLE metrics (
    id SERIAL PRIMARY KEY,
    content_id INTEGER REFERENCES content_queue(id) ON DELETE CASCADE,
    platform VARCHAR(50),
    reach INTEGER DEFAULT 0,
    impressions INTEGER DEFAULT 0,
    engagement INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    engagement_rate DECIMAL(5,2),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workflow Logs
CREATE TABLE workflow_logs (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(100),
    execution_id VARCHAR(100),
    status VARCHAR(20) CHECK (status IN ('success', 'error', 'warning')),
    message TEXT,
    execution_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Prompt Library
CREATE TABLE prompts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    platform VARCHAR(50),
    content_type VARCHAR(50),
    system_prompt TEXT NOT NULL,
    user_prompt_template TEXT NOT NULL,
    variables TEXT[], -- Array of variable names like ['topic', 'context']
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_content_status ON content_queue(status);
CREATE INDEX idx_content_platform ON content_queue(platform);
CREATE INDEX idx_content_scheduled ON content_queue(scheduled_date);
CREATE INDEX idx_metrics_content ON metrics(content_id);
CREATE INDEX idx_prompts_active ON prompts(is_active);

-- Insert sample prompts
INSERT INTO prompts (name, platform, content_type, system_prompt, user_prompt_template, variables) VALUES
(
    'linkedin_thought_leadership',
    'linkedin',
    'thought_leadership',
    'You are a senior software engineer creating LinkedIn content for Vietnamese IT professionals. Write in a professional but approachable tone. Use Vietnamese or English based on the topic.',
    'Write a LinkedIn post about {{topic}}.

Requirements:
- 150-200 words
- Start with an attention-grabbing hook
- Share a personal insight or experience
- Include practical advice
- End with a question to encourage engagement
- Add 3-5 relevant hashtags

Additional context: {{context}}',
    ARRAY['topic', 'context']
),
(
    'facebook_tech_news',
    'facebook_tech',
    'tech_news',
    'You are a tech enthusiast creating Facebook content for Vietnamese developers. Use a casual, friendly tone with emojis.',
    'Write a Facebook post about this tech news: {{topic}}

Requirements:
- Keep it concise (100-150 words)
- Explain why it matters
- Include your opinion
- Use 2-3 relevant emojis
- End with a discussion question

Source/context: {{context}}',
    ARRAY['topic', 'context']
),
(
    'facebook_chinese_vocab',
    'facebook_chinese',
    'vocabulary',
    'You are a Chinese language teacher creating educational content for Vietnamese learners. Mix Vietnamese explanations with Chinese examples.',
    'Create a vocabulary post about: {{topic}}

Requirements:
- Include Chinese characters, pinyin, and Vietnamese meaning
- Provide 2-3 example sentences
- Add memory tips or mnemonics
- Keep it beginner-friendly (HSK 1-3)
- Use encouraging, supportive tone

Level: {{context}}',
    ARRAY['topic', 'context']
);

-- Exit psql
\q
```

### Step 2: Verify Setup

```bash
# List tables
docker exec -it postgres psql -U postgres -d agent_personal -c "\dt"

# Check prompts
docker exec -it postgres psql -U postgres -d agent_personal -c "SELECT name, platform FROM prompts;"
```

---

## 🔧 Part 3: n8n Configuration

### Step 1: Access n8n

1. Open browser: http://localhost:5678
2. Login with credentials from docker-compose.yml
3. Complete initial setup wizard

### Step 2: Add PostgreSQL Credentials

1. Go to **Credentials** → **Add Credential**
2. Search for "PostgreSQL"
3. Configure:
   ```
   Host: postgres
   Port: 5432
   Database: agent_personal
   User: postgres
   Password: your_db_password
   ```
4. Test connection
5. Save as "PostgreSQL - Agent Personal"

### Step 3: Create First Workflow - Content Generation

Create a new workflow with these nodes:

**Node 1: Manual Trigger**
- Allows manual execution for testing

**Node 2: Set Variables**
- Configure input data:
  ```json
  {
    "topic": "How AI is changing software development",
    "platform": "linkedin",
    "content_type": "thought_leadership",
    "context": "Focus on practical implications for developers"
  }
  ```

**Node 3: PostgreSQL - Get Prompt**
- Operation: Execute Query
- Query:
  ```sql
  SELECT system_prompt, user_prompt_template
  FROM prompts
  WHERE platform = '{{ $json.platform }}'
    AND content_type = '{{ $json.content_type }}'
    AND is_active = true
  LIMIT 1
  ```

**Node 4: Code - Prepare Prompt**
- JavaScript code:
  ```javascript
  const systemPrompt = $input.first().json.system_prompt;
  let userPrompt = $input.first().json.user_prompt_template;

  // Replace variables
  const topic = $('Set Variables').first().json.topic;
  const context = $('Set Variables').first().json.context;

  userPrompt = userPrompt.replace('{{topic}}', topic);
  userPrompt = userPrompt.replace('{{context}}', context);

  return {
    system_prompt: systemPrompt,
    user_prompt: userPrompt
  };
  ```

**Node 5: HTTP Request - Ollama**
- Method: POST
- URL: `http://ollama:11434/api/chat`
- Body (JSON):
  ```json
  {
    "model": "llama3.1:8b",
    "messages": [
      {
        "role": "system",
        "content": "{{ $json.system_prompt }}"
      },
      {
        "role": "user",
        "content": "{{ $json.user_prompt }}"
      }
    ],
    "stream": false
  }
  ```
- Timeout: 60000 (60 seconds)

**Node 6: Code - Extract Content**
- JavaScript:
  ```javascript
  const response = $input.first().json;
  const content = response.message?.content || 'Generation failed';

  return {
    generated_content: content,
    topic: $('Set Variables').first().json.topic,
    platform: $('Set Variables').first().json.platform,
    content_type: $('Set Variables').first().json.content_type
  };
  ```

**Node 7: PostgreSQL - Save Content**
- Operation: Insert
- Table: content_queue
- Columns:
  - title: `{{ $json.topic }}`
  - platform: `{{ $json.platform }}`
  - content_type: `{{ $json.content_type }}`
  - generated_content: `{{ $json.generated_content }}`
  - status: `review`

**Node 8: Telegram - Notify (Optional)**
- Configure Telegram credentials
- Message: `New content ready for review: {{ $json.topic }}`

### Step 4: Test Workflow

1. Click "Execute Workflow"
2. Check each node output
3. Verify content saved in PostgreSQL:
   ```bash
   docker exec -it postgres psql -U postgres -d agent_personal -c "SELECT id, title, status FROM content_queue;"
   ```

---

## 🔗 Part 4: Platform Integrations

### Telegram Bot Setup

1. **Create Bot:**
   - Message @BotFather on Telegram
   - Send `/newbot`
   - Follow instructions, save the token

2. **Get Chat ID:**
   - Message your new bot
   - Visit: `https://api.telegram.org/bot<TOKEN>/getUpdates`
   - Find `chat.id` in the response

3. **Add to n8n:**
   - Credentials → Add → Telegram
   - Enter bot token
   - Test with a simple message node

### Meta Graph API (Facebook)

1. **Create Facebook App:**
   - Go to developers.facebook.com
   - Create new app
   - Add "Facebook Login" product

2. **Get Page Access Token:**
   - Tools → Graph API Explorer
   - Select your page
   - Generate token with permissions:
     - `pages_show_list`
     - `pages_read_engagement`
     - `pages_manage_posts`

3. **n8n HTTP Request for Posting:**
   ```
   Method: POST
   URL: https://graph.facebook.com/v18.0/{page-id}/feed
   Body:
   {
     "message": "{{ $json.final_content }}",
     "access_token": "YOUR_PAGE_TOKEN"
   }
   ```

### LinkedIn (Manual or Buffer)

**Option A: Manual Posting (Recommended for start)**
- n8n generates content → PostgreSQL
- Review in database or simple web UI
- Copy & paste to LinkedIn manually

**Option B: Buffer Integration**
- Sign up for Buffer ($6/month)
- Use Buffer API in n8n
- Automate scheduling

---

## 📊 Part 5: Monitoring & Maintenance

### Daily Checks

```bash
# Check all services running
docker ps

# Check n8n logs
docker logs n8n --tail 50

# Check Ollama logs
docker logs ollama --tail 50
```

### Weekly Maintenance

```bash
# Backup PostgreSQL
docker exec postgres pg_dump -U postgres agent_personal > ~/backups/agent_personal_$(date +%Y%m%d).sql

# Export n8n workflows (from UI)
# n8n → Workflows → Select all → Export
```

### Troubleshooting

**Ollama slow or timeout:**
```bash
# Check resources
docker stats

# Restart Ollama
docker restart ollama

# Check model loaded
docker exec ollama ollama list
```

**n8n workflow fails:**
- Check execution logs in n8n UI
- Verify PostgreSQL connection
- Test Ollama endpoint:
  ```bash
  curl http://localhost:11434/api/generate -d '{"model":"llama3.1:8b","prompt":"test"}'
  ```

**PostgreSQL connection issues:**
```bash
# Check container
docker logs postgres

# Test connection
docker exec -it postgres psql -U postgres -c "SELECT 1;"
```

---

## ☁️ Part 6: Cloud Alternative (Make.com)

**When to consider Make.com instead:**
- Don't want to manage Docker
- Need 99.9% uptime guarantee
- Team collaboration features
- Faster setup (15 mins vs 2-4 hours)

**Make.com Setup (if choosing cloud):**

1. Sign up at make.com (free tier: 1000 ops/month)
2. Add integrations:
   - Notion (for content queue instead of PostgreSQL)
   - HTTP module (for Claude API)
   - Telegram
   - Facebook Pages

3. Cost: $9-29/month

**Recommendation:** Start with local setup (free), migrate to cloud later if needed.

---

## ✅ Setup Completion Checklist

After completing this guide:

- [ ] Docker installed and running on WSL2
- [ ] docker-compose.yml created with all services
- [ ] All containers running (n8n, postgres, ollama)
- [ ] Llama 3.1 8B model downloaded and tested
- [ ] PostgreSQL schema created with tables
- [ ] Sample prompts inserted
- [ ] n8n accessible at localhost:5678
- [ ] PostgreSQL credentials added to n8n
- [ ] First workflow created and tested
- [ ] Telegram bot configured (optional)
- [ ] Content generation working end-to-end
- [ ] Backup strategy documented

---

## 📚 Related Skills

- **prompt-engineering.md** - AI prompt best practices
- **content-templates.md** - Content structure templates
- **analytics-tracking.md** - Metrics and optimization

---

## 🔗 Resources

### Documentation
- n8n: https://docs.n8n.io
- Ollama: https://ollama.ai/docs
- PostgreSQL: https://www.postgresql.org/docs
- Meta Graph API: https://developers.facebook.com/docs/graph-api

### Community
- n8n Community: https://community.n8n.io
- Ollama GitHub: https://github.com/ollama/ollama

---

**Last Updated:** 2026-03-16
**Version:** 2.0.0
**Author:** VictorAurelius + Claude
