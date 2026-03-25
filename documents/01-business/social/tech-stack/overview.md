# 🛠️ Tech Stack Overview - AI Agent Social Media Automation

> Tổng quan về công nghệ, công cụ và infrastructure cho AI Agents tự động hóa nội dung social media
>
> **Kiến trúc: 100% Local (WSL2 + Docker) - Chi phí: $0/tháng**

---

## 📋 Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Core Components](#2-core-components)
3. [So sánh Tools](#3-so-sánh-tools)
4. [Chi phí & Pricing](#4-chi-phí--pricing)
5. [Setup & Configuration](#5-setup--configuration)
6. [Best Practices](#6-best-practices)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Tổng quan kiến trúc

### 1.1 High-level Architecture (Local Server)

```
┌─────────────────────────────────────────────────────────────────┐
│                     WINDOWS 10/11 (32GB RAM)                    │
├─────────────────────────────────────────────────────────────────┤
│                         WSL2 (Ubuntu)                           │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                   DOCKER COMPOSE                          │ │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────┐  │ │
│  │  │    n8n     │  │ PostgreSQL │  │      Ollama        │  │ │
│  │  │   :5678    │  │   :5432    │  │ Llama 3.1 8B       │  │ │
│  │  │            │  │            │  │      :11434        │  │ │
│  │  │ Workflow   │  │ Content    │  │ Content            │  │ │
│  │  │ Automation │  │ Storage    │  │ Generation         │  │ │
│  │  └────────────┘  └────────────┘  └────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │       EXTERNAL SERVICES       │
              │   (Free APIs - No Cost)       │
              │  ┌─────────────────────────┐  │
              │  │ Meta Graph API (FB)     │  │
              │  │ LinkedIn API            │  │
              │  │ Telegram Bot API        │  │
              │  └─────────────────────────┘  │
              └───────────────────────────────┘
```

### 1.2 Lợi ích của Local Setup

| Aspect | Local (WSL2) | Cloud |
|--------|--------------|-------|
| **Chi phí** | $0/tháng | $30-100/tháng |
| **Latency** | <1ms | 50-200ms |
| **Privacy** | 100% local | Data on 3rd party |
| **Control** | Full control | Limited |
| **Scalability** | Limited by hardware | Unlimited |
| **Uptime** | Depends on PC | 99.9%+ |

**Kết luận:** Local setup phù hợp cho:
- Solo creators / small projects
- Privacy-conscious users
- Cost-sensitive projects
- Learning & experimentation

### 1.3 Workflow tổng quát

```
1. CONTENT REQUEST
   ├─ Manual trigger (n8n UI)
   ├─ Scheduled (cron: daily, weekly)
   └─ Webhook (external trigger)

2. AI PROCESSING (Ollama + Llama 3.1)
   ├─ Generate content from prompt
   ├─ Multiple content types supported
   ├─ Vietnamese language capable
   └─ ~2-5 seconds per generation

3. CONTENT MANAGEMENT (PostgreSQL)
   ├─ Save to content_queue table
   ├─ Tag & categorize
   ├─ Queue for review
   └─ Track status

4. HUMAN REVIEW
   ├─ Telegram notification
   ├─ Review in n8n or direct SQL
   ├─ Approve or reject
   └─ Schedule posting time

5. PUBLISHING
   ├─ Auto-post to Facebook (Meta Graph API)
   ├─ LinkedIn (manual or API)
   └─ Telegram channel (if applicable)

6. TRACKING & OPTIMIZATION
   ├─ Store metrics in PostgreSQL
   ├─ Weekly analysis
   └─ Fine-tune prompts
```

---

## 2. Core Components

### 2.1 Orchestration: n8n (Self-Hosted)

**Vai trò:** Workflow automation engine

**Tại sao n8n?**
- ✅ **Free & Open Source**: Unlimited operations
- ✅ **Self-hosted**: Full control, no vendor lock-in
- ✅ **Powerful**: 400+ integrations, custom code (JS)
- ✅ **Local**: Runs on WSL2, no cloud needed
- ✅ **Visual**: Drag-and-drop workflow builder

**Requirements:**
- Docker
- 1GB RAM (minimum)
- Port 5678

**Docker setup:**
```yaml
# docker-compose.yml
services:
  n8n:
    image: n8nio/n8n
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=your_password
      - WEBHOOK_URL=http://localhost:5678/
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
```

**Access:** http://localhost:5678

---

### 2.2 AI Engine: Ollama + Llama 3.1 8B

**Vai trò:** Local LLM for content generation

**Tại sao Ollama + Llama?**
- ✅ **Free**: No API costs
- ✅ **Private**: Data never leaves your machine
- ✅ **Fast**: Local inference, no network latency
- ✅ **Capable**: Llama 3.1 8B handles most content tasks well
- ✅ **Multilingual**: Vietnamese support

**Model comparison:**

| Model | VRAM | Speed | Quality | Use Case |
|-------|------|-------|---------|----------|
| **Llama 3.1 8B** | ~8GB | Fast | Good | General content |
| Llama 3.1 70B | ~40GB | Slow | Excellent | Complex tasks |
| Mistral 7B | ~6GB | Fast | Good | Quick drafts |
| Qwen2 7B | ~6GB | Fast | Good | Multilingual |

**Recommended:** Llama 3.1 8B (balance of speed & quality)

**Docker setup:**
```yaml
services:
  ollama:
    image: ollama/ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

**API Usage:**
```bash
# Generate content
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Write a LinkedIn post about AI automation for developers",
  "stream": false
}'

# Chat format
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.1:8b",
  "messages": [
    {"role": "system", "content": "You are a social media content creator."},
    {"role": "user", "content": "Write a Facebook post about learning Chinese."}
  ],
  "stream": false
}'
```

**n8n Integration:**
- Use HTTP Request node
- URL: `http://ollama:11434/api/generate` (Docker network)
- Method: POST
- Body: JSON with model and prompt

---

### 2.3 Database: PostgreSQL (Local)

**Vai trò:** Content storage, metrics tracking, workflow logs

**Tại sao PostgreSQL?**
- ✅ **Free**: Open source
- ✅ **Powerful**: Full SQL, JSON support
- ✅ **Reliable**: ACID compliant
- ✅ **Scalable**: Handles millions of records
- ✅ **n8n native**: Built-in PostgreSQL nodes

**Docker setup:**
```yaml
services:
  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=your_password
      - POSTGRES_DB=agent_personal
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

**Database Schema:**

```sql
-- Content Queue
CREATE TABLE content_queue (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  platform VARCHAR(50) NOT NULL, -- 'linkedin', 'facebook_tech', 'facebook_chinese'
  content_type VARCHAR(50), -- 'thought_leadership', 'tutorial', 'news', etc.
  status VARCHAR(20) DEFAULT 'draft', -- 'draft', 'review', 'approved', 'scheduled', 'published'
  original_prompt TEXT,
  generated_content TEXT,
  final_content TEXT,
  scheduled_date TIMESTAMP,
  published_date TIMESTAMP,
  post_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Metrics
CREATE TABLE metrics (
  id SERIAL PRIMARY KEY,
  content_id INTEGER REFERENCES content_queue(id),
  platform VARCHAR(50),
  reach INTEGER DEFAULT 0,
  impressions INTEGER DEFAULT 0,
  engagement INTEGER DEFAULT 0,
  likes INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  shares INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workflow Logs
CREATE TABLE workflow_logs (
  id SERIAL PRIMARY KEY,
  workflow_name VARCHAR(100),
  status VARCHAR(20), -- 'success', 'error', 'warning'
  message TEXT,
  execution_time_ms INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Prompt Library
CREATE TABLE prompts (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  platform VARCHAR(50),
  content_type VARCHAR(50),
  system_prompt TEXT,
  user_prompt_template TEXT,
  version INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### 2.4 Notifications: Telegram Bot

**Vai trò:** Real-time alerts for workflow status

**Setup:**
1. Message @BotFather on Telegram
2. Create new bot: `/newbot`
3. Save bot token
4. Get your chat ID from @userinfobot

**n8n Integration:**
- Use Telegram node (built-in)
- Configure with bot token
- Send notifications on workflow events

**Use cases:**
- ✅ Content ready for review
- ✅ Workflow errors
- ✅ Daily/weekly summaries
- ✅ Publishing confirmations

---

### 2.5 Publishing: Platform APIs

#### Meta Graph API (Facebook)

**Setup:**
1. Create Facebook App: developers.facebook.com
2. Get Page Access Token
3. Permissions: `pages_manage_posts`, `pages_read_engagement`

**API endpoint:**
```bash
POST https://graph.facebook.com/v18.0/{page-id}/feed
Body: {
  "message": "Your post content",
  "access_token": "PAGE_ACCESS_TOKEN"
}
```

#### LinkedIn API

**Note:** LinkedIn API requires approval process. Options:
1. **API**: Apply for Marketing Developer Platform access
2. **Manual**: Copy content from n8n → paste to LinkedIn (1-2 min)
3. **Buffer**: Use Buffer integration ($6/month)

**Recommendation:** Start with manual posting, automate later.

---

## 3. So sánh Tools

### 3.1 Orchestration: n8n vs Cloud Alternatives

| Feature | n8n (Local) | Make.com | Zapier |
|---------|-------------|----------|--------|
| **Cost** | $0 | $9-29/mo | $20+/mo |
| **Operations** | Unlimited | 1k-10k/mo | 750-10k/mo |
| **Ease of use** | Medium | Easy | Easiest |
| **Flexibility** | Highest | Medium | Low |
| **Privacy** | Full control | Cloud | Cloud |
| **Setup time** | 1-2 hours | 15 mins | 10 mins |
| **Best for** | Cost-conscious, technical | Beginners | Enterprise |

**Verdict:** n8n for local setup (free, unlimited, full control)

---

### 3.2 AI: Local LLM vs Cloud API

| Feature | Ollama (Local) | Claude API | OpenAI API |
|---------|----------------|------------|------------|
| **Cost** | $0 | $3-15/1M tokens | $2.50-10/1M tokens |
| **Privacy** | 100% local | Cloud | Cloud |
| **Speed** | 2-5s/response | 1-3s | 1-2s |
| **Quality** | Good (8B) | Excellent | Excellent |
| **Vietnamese** | Good | Excellent | Very good |
| **Offline** | Yes | No | No |
| **Best for** | Cost-sensitive | Best quality | Multi-modal |

**Verdict:** Ollama for $0 cost; Claude API if budget allows for better quality

---

### 3.3 Storage: PostgreSQL vs Alternatives

| Feature | PostgreSQL (Local) | Notion | Airtable |
|---------|-------------------|--------|----------|
| **Cost** | $0 | Free tier | Free tier |
| **Ease of use** | SQL knowledge | Easy UI | Easy UI |
| **Capacity** | Unlimited | Limited | 1000 records |
| **API** | Full SQL | REST API | REST API |
| **Privacy** | Local | Cloud | Cloud |
| **Best for** | Technical users | Visual review | Spreadsheet fans |

**Verdict:** PostgreSQL for full control; Notion for easier content review UI

---

## 4. Chi phí & Pricing

### 4.1 Local Setup (Recommended)

| Component | Tool | Cost |
|-----------|------|------|
| Orchestration | n8n (self-hosted) | $0 |
| AI Engine | Ollama + Llama 3.1 8B | $0 |
| Database | PostgreSQL (local) | $0 |
| Notifications | Telegram Bot | $0 |
| Publishing | Meta Graph API | $0 |
| Design | Canva Free | $0 |
| **TOTAL** | | **$0/month** |

### 4.2 Optional Upgrades

| Upgrade | Cost | Benefit |
|---------|------|---------|
| Canva Pro | $13/mo | Better templates, brand kit |
| Buffer | $6/mo | Easier LinkedIn posting |
| Cloud backup | $5/mo | Off-site backup (optional) |
| Claude API | $5-20/mo | Better content quality |

### 4.3 Hardware Requirements

**Minimum (8B model):**
- RAM: 16GB (8GB for model + 8GB system)
- Storage: 20GB free
- CPU: Modern 4+ cores

**Recommended (your setup - 32GB):**
- ✅ Can run 8B model comfortably
- ✅ Can run multiple Docker containers
- ✅ Room for larger models if needed

---

## 5. Setup & Configuration

### 5.1 Complete Docker Compose

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=changeme
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_DB=agent_personal
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  ollama:
    image: ollama/ollama
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    # Uncomment for GPU support (NVIDIA)
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
```

### 5.2 Setup Steps

**Day 1: Docker Environment**

```bash
# 1. Install Docker on WSL2 (if not already)
sudo apt update
sudo apt install docker.io docker-compose

# 2. Create project directory
mkdir -p ~/social-automation
cd ~/social-automation

# 3. Create docker-compose.yml (copy from above)
nano docker-compose.yml

# 4. Start services
docker-compose up -d

# 5. Verify all running
docker ps

# 6. Pull Llama model (takes 5-10 minutes)
docker exec -it ollama ollama pull llama3.1:8b

# 7. Test Ollama
docker exec -it ollama ollama run llama3.1:8b "Hello, test!"
```

**Day 2: Configure n8n**

1. Access n8n: http://localhost:5678
2. Login with admin/changeme
3. Add PostgreSQL credentials:
   - Host: `postgres`
   - Port: `5432`
   - Database: `agent_personal`
   - User: `postgres`
   - Password: `changeme`

4. Create first workflow:
   - Manual Trigger → HTTP Request (Ollama) → PostgreSQL Insert

**Day 3: Create Database Tables**

```bash
# Connect to PostgreSQL
docker exec -it postgres psql -U postgres -d agent_personal

# Run schema SQL (from section 2.3)
```

### 5.3 Security Best Practices

**Credentials:**
- ✅ Change default passwords in docker-compose.yml
- ✅ Use environment variables for sensitive data
- ✅ Don't expose ports to internet (local only)

**Backups:**
```bash
# Backup PostgreSQL
docker exec postgres pg_dump -U postgres agent_personal > backup.sql

# Backup n8n workflows
# Export from n8n UI → Workflows → Export
```

---

## 6. Best Practices

### 6.1 Prompt Engineering for Local LLM

**Key differences from cloud LLMs:**
- Llama 3.1 8B needs clearer instructions
- Shorter prompts = better results
- Use system prompts effectively

**Good prompt structure:**
```
System: You are a social media content creator for Vietnamese IT professionals.

User: Create a LinkedIn post about [topic].

Requirements:
- 150-200 words
- Professional but conversational tone
- Include 3-5 hashtags
- Start with a hook
- End with a question or CTA
```

**Example prompts (store in PostgreSQL):**
```sql
INSERT INTO prompts (name, platform, content_type, system_prompt, user_prompt_template) VALUES
('linkedin_thought_leadership', 'linkedin', 'thought_leadership',
 'You are a senior software engineer creating LinkedIn content. Write in a professional but approachable tone.',
 'Write a LinkedIn post about {{topic}}. Include personal insights and practical advice. 150-200 words, 3-5 hashtags.'),

('facebook_tech_tutorial', 'facebook_tech', 'tutorial',
 'You are a tech educator creating Facebook content for Vietnamese developers.',
 'Write a Facebook post explaining {{topic}} in simple terms. Use examples and code snippets if relevant. Include emojis.');
```

### 6.2 Content Quality Control

**Review checklist:**
- [ ] Factually accurate
- [ ] Good Vietnamese (if applicable)
- [ ] Appropriate tone for platform
- [ ] No AI artifacts ("As an AI...", etc.)
- [ ] Engaging hook
- [ ] Clear call-to-action

**Automation levels:**
1. **Level 1**: AI generates → Manual review → Manual post
2. **Level 2**: AI generates → Auto-queue → Manual review → Manual post
3. **Level 3**: AI generates → Auto-queue → Manual review → Auto-post
4. **Level 4**: AI generates → Auto-post (NOT recommended initially)

### 6.3 Workflow Optimization

**Batch processing:**
- Generate 7 posts in one batch (weekly)
- Review all at once
- Schedule for week

**Error handling:**
- Add error branches in n8n
- Log errors to PostgreSQL
- Send Telegram alerts on failure

---

## 7. Troubleshooting

### 7.1 Common Issues

**Ollama slow or hanging:**
```bash
# Check container resources
docker stats ollama

# Restart container
docker restart ollama

# Check model loaded
docker exec ollama ollama list
```

**n8n workflow errors:**
- Check n8n execution logs
- Verify PostgreSQL connection
- Test Ollama endpoint manually

**PostgreSQL connection refused:**
```bash
# Check container running
docker ps | grep postgres

# Check logs
docker logs postgres

# Test connection
docker exec -it postgres psql -U postgres
```

### 7.2 Performance Tips

**For 32GB RAM system:**
- Ollama: Can use 8-10GB comfortably
- PostgreSQL: 1-2GB
- n8n: 1GB
- System: 8-10GB
- Buffer: 10GB for other tasks

**Speed up Ollama:**
- Use GPU if available (NVIDIA)
- Reduce context length in requests
- Use smaller models for simple tasks

---

## 📝 Conclusion

**Your setup (32GB RAM + WSL2):**
- ✅ Perfect for local AI automation
- ✅ Zero monthly costs
- ✅ Full privacy and control
- ✅ Sufficient for 3 social platforms
- ✅ Room to grow (larger models, more workflows)

**Start simple:**
1. Day 1: Docker + all services running
2. Day 2: First n8n workflow
3. Day 3: PostgreSQL tables + Telegram
4. Week 2: Facebook integration
5. Month 2: Full automation pipeline

**Remember:**
- Start with manual review (100% of content)
- Gradually automate as you trust the system
- Quality > Quantity
- Your voice > AI voice (edit and personalize)

---

**Last updated**: 2026-03-16
**Version**: 2.0 (Local LLM Edition)
