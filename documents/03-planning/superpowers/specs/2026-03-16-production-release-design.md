# AI Agent Personal - Production Release Design

**Created:** 2026-03-16
**Status:** Approved
**Timeline:** 8 weeks + 30-day stability period
**Target:** Production stable system for LinkedIn automation

---

## 1. Overview

### 1.1 Goal

Build a production-stable AI-powered social media automation system that:
- Generates LinkedIn content using local LLM (Ollama + Llama 3.1 8B)
- Provides human review workflow before publishing
- Runs stable for 30+ days with monitoring and backup
- Costs $0/month (100% self-hosted)

### 1.2 Key Decisions

| Aspect | Decision |
|--------|----------|
| **Release Definition** | Production stable (30 days stable + backup + monitoring) |
| **First Platform** | LinkedIn |
| **Timeline** | 2 months (8 weeks + 30-day stability) |
| **Post Frequency** | 3 posts/week (Mon/Wed/Fri) |
| **Review Level** | 100% human review |
| **Approach** | Sequential phases (A) |

---

## 2. Architecture

### 2.1 System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRODUCTION ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────┤
│  WSL2 (Ubuntu) - Docker Compose                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │   n8n    │  │ Postgres │  │  Ollama  │  │  Redis   │       │
│  │  :5678   │  │  :5432   │  │  :11434  │  │  :6379   │       │
│  │ Workflow │  │ Storage  │  │ LLM 8B   │  │  Cache   │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│       │              │             │             │              │
│       └──────────────┴─────────────┴─────────────┘              │
│                           │                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    MONITORING LAYER                       │  │
│  │  Healthcheck │ Telegram Alerts │ Daily Backup │ Logs     │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │     EXTERNAL SERVICES         │
              │  LinkedIn API │ Telegram Bot  │
              └───────────────────────────────┘
```

### 2.2 Components

| Component | Purpose | Port |
|-----------|---------|------|
| **n8n** | Workflow orchestration, scheduling | 5678 |
| **PostgreSQL** | Content queue, metrics, prompts, logs | 5432 |
| **Ollama** | Local LLM (Llama 3.1 8B) | 11434 |
| **Redis** | Caching, rate limiting | 6379 |

### 2.3 Data Flow

```
Content Generation Flow:
Topic Input → Ollama (generate) → PostgreSQL (draft)
    → Telegram (notify) → Human Review
    → Approve/Reject → PostgreSQL (update status)
    → Ready for posting

Posting Flow (Manual):
PostgreSQL (approved) → Telegram (reminder)
    → Human copies to LinkedIn → Update DB with URL
    → Track metrics later
```

---

## 3. Phase 1: Infrastructure (Week 1-2)

### 3.1 Week 1: Docker Environment

**Day 1-2: Docker Setup**
- Install Docker Engine on WSL2
- Create docker-compose.yml with 4 services
- Configure networking between containers

**Day 3-4: Verify Services**
- n8n UI accessible at localhost:5678
- PostgreSQL accepting connections
- Ollama API responding
- Pull Llama 3.1 8B model (~4.7GB)

**Day 5: Backup Setup**
- pg_dump cron job (daily 3AM)
- n8n workflow export script

### 3.2 Week 2: Database & Integrations

**Day 1-2: Database Schema**

```sql
-- Core tables
CREATE TABLE content_queue (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    platform VARCHAR(50) DEFAULT 'linkedin',
    content_type VARCHAR(50),
    pillar VARCHAR(50),
    status VARCHAR(20) DEFAULT 'draft',
    generated_content TEXT,
    final_content TEXT,
    scheduled_date TIMESTAMP,
    published_date TIMESTAMP,
    post_url VARCHAR(500),
    engagement_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE prompts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    pillar VARCHAR(50),
    content_type VARCHAR(50),
    system_prompt TEXT NOT NULL,
    user_prompt_template TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE metrics (
    id SERIAL PRIMARY KEY,
    content_id INTEGER REFERENCES content_queue(id),
    impressions INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    engagement_rate DECIMAL(5,2),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE workflow_logs (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(100),
    status VARCHAR(20),
    message TEXT,
    execution_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Day 3-4: Telegram Bot**
- Create bot via @BotFather
- Get chat ID
- Configure n8n Telegram credentials
- Test notification sending

**Day 5: Redis + Healthcheck**
- Add Redis container
- Configure Docker healthchecks
- Create healthcheck script

### 3.3 Exit Criteria Phase 1

```bash
# All 4 containers running
docker ps | grep -E "n8n|postgres|ollama|redis" | wc -l  # Expected: 4

# Ollama responds in Vietnamese
curl -s localhost:11434/api/generate -d '{"model":"llama3.1:8b","prompt":"Xin chào","stream":false}'

# PostgreSQL has tables
docker exec postgres psql -U postgres -d agent_personal -c "\dt"

# Telegram bot works
# (manual test - send message)
```

---

## 4. Phase 2: Core Workflows (Week 3-4)

### 4.1 Workflow Definitions

| # | Workflow | Trigger | Description |
|---|----------|---------|-------------|
| WF1 | content-generate | Manual | Single topic → Ollama → DB |
| WF2 | batch-generate | Cron Mon/Wed/Fri 8AM | Generate 3 posts for week |
| WF3 | daily-digest | Cron 9AM daily | Pending posts → Telegram |
| WF4 | format-validate | On status change | Format content for LinkedIn |

### 4.2 Content Status Flow

```
draft → generating → pending_review → approved → scheduled → published
                  ↘ rejected (with feedback for regeneration)
```

### 4.3 Week 3: Generation Workflows

**WF1: content-generate**
```
Manual Trigger (topic, pillar, content_type)
    → Get prompt template from DB
    → Call Ollama API
    → Validate response (length, format)
    → Save to content_queue (status: pending_review)
    → Send Telegram notification
```

**WF2: batch-generate**
```
Cron Trigger (Mon/Wed/Fri 8:00 AM)
    → Get topics from queue (status: draft, limit 3)
    → For each topic:
        → Generate content via WF1
        → Wait 30s (rate limiting)
    → Send summary to Telegram
```

### 4.4 Week 4: Review & Validation

**WF3: daily-digest**
```
Cron Trigger (9:00 AM daily)
    → Query pending_review posts
    → Format summary message
    → Send to Telegram with action hints
```

**WF4: format-validate**
```
On status = approved
    → Apply LinkedIn formatting
    → Check character limits (<3000)
    → Add hashtags (3-5)
    → Validate final content
    → Update status: scheduled
```

### 4.5 Exit Criteria Phase 2

- [ ] All 4 workflows created and tested
- [ ] 5+ prompt templates in database
- [ ] Telegram notifications working
- [ ] Error handling with retry logic
- [ ] Full flow test: topic → review → approve

---

## 5. Phase 3: LinkedIn MVP (Week 5-6)

### 5.1 Content Pillars

| Pillar | % | Topics | Prompt Style |
|--------|---|--------|--------------|
| Tech Insights | 40% | AI, automation, dev tools | Analytical, forward-looking |
| Career/Productivity | 30% | Tips, workflows, lessons | Practical, actionable |
| Product/Project | 20% | Showcase, behind-scenes | Storytelling, authentic |
| Personal Stories | 10% | Experiences, opinions | Reflective, engaging |

### 5.2 Posting Schedule

```
Monday    09:00  - Tech Insights
Wednesday 12:00  - Career/Productivity
Friday    17:00  - Rotate (Product/Personal)
```

### 5.3 Week 5: Setup & Seeding

**Day 1-2: LinkedIn Profile**
- Optimize headline and about section
- Define content pillars in DB
- Create prompt templates per pillar

**Day 3-4: Content Seeding**
- Create 10 topic ideas in content_queue
- Generate first batch (5 posts)
- Review and refine prompts based on quality

**Day 5: Dry Run**
- Full workflow test
- Content quality check
- Timing validation

### 5.4 Week 6: Go Live

**Day 1-2: First Real Posts**
- Generate 5 posts
- Human review all (100%)
- Schedule 3 for the week

**Day 3-4: Manual Posting**
```
For each scheduled post:
1. Receive Telegram reminder
2. Copy content from system
3. Post to LinkedIn manually
4. Record post URL in DB
5. Confirm in Telegram
```

**Day 5: Metrics Setup**
- Manual metrics entry workflow
- Weekly report generation
- Engagement tracking baseline

### 5.5 Exit Criteria Phase 3

- [ ] 3 content pillars with prompt templates
- [ ] 10+ posts generated and reviewed
- [ ] 6 posts published to LinkedIn
- [ ] Posting workflow documented
- [ ] Metrics tracking operational
- [ ] >80% content quality (minimal edits)

---

## 6. Phase 4: Stabilization (Week 7-8)

### 6.1 Monitoring Setup

**Healthcheck Workflow (every 5 minutes):**
```
Check all services:
  - n8n: HTTP 200 on /healthz
  - PostgreSQL: SELECT 1
  - Ollama: GET /api/tags
  - Redis: PING

If any fails:
  - Log to workflow_logs
  - Send Telegram ALERT
  - Retry 3 times before alerting
```

**Alert Thresholds:**
- Container down > 1 minute
- Disk usage > 80%
- Workflow failure rate > 10%
- No posts generated in 48 hours

### 6.2 Backup Strategy

| Type | Frequency | Retention | Location |
|------|-----------|-----------|----------|
| PostgreSQL dump | Daily 3AM | 7 days | ~/backups/ |
| PostgreSQL dump | Weekly Sun | 4 weeks | Cloud (optional) |
| n8n workflows | On change | Git history | Repository |
| Docker volumes | Weekly | 2 weeks | External drive |

**Recovery Test Procedure:**
1. Stop all containers
2. Delete PostgreSQL data
3. Restore from backup
4. Verify data integrity
5. Document time taken

### 6.3 Production Hardening

```yaml
# Docker Compose production settings
services:
  n8n:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 2G
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1G
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s

  ollama:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 10G

  redis:
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
```

### 6.4 Documentation Deliverables

1. **Runbook** (`documents/05-guides/runbook.md`)
   - Daily operations checklist
   - Common tasks procedures
   - Escalation contacts

2. **Troubleshooting Guide** (`docs/troubleshooting.md`)
   - Common errors and fixes
   - Log locations
   - Debug procedures

3. **Recovery Procedures** (`docs/recovery.md`)
   - Backup restoration
   - Service restart procedures
   - Data recovery steps

### 6.5 Exit Criteria Phase 4

- [ ] Monitoring workflow with Telegram alerts
- [ ] Automated backup (daily + weekly)
- [ ] Recovery procedure tested successfully
- [ ] Runbook documentation complete
- [ ] Stress test passed (20 posts batch)
- [ ] 30-day stability tracking started

---

## 7. Success Criteria

### 7.1 Milestone Checkpoints

| Milestone | Week | Exit Gate |
|-----------|------|-----------|
| M1: Infra Ready | 2 | 4 containers stable, DB schema ready |
| M2: Workflows Ready | 4 | 4 workflows operational, full flow tested |
| M3: First Posts Live | 6 | 6 LinkedIn posts published |
| M4: Production Ready | 8 | Monitoring, backup, docs complete |
| M5: Stable Release | 12 | 30 days stable operation |

### 7.2 Final Production Checklist

**Infrastructure:**
- [ ] 30 days uptime (no unplanned downtime)
- [ ] Daily backups running automatically
- [ ] Recovery tested and documented
- [ ] Resource usage stable (<70% RAM, <80% disk)

**Workflows:**
- [ ] 3 posts/week generated consistently
- [ ] <10% manual content edits needed
- [ ] Zero workflow failures in 7 days
- [ ] Telegram notifications reliable

**LinkedIn:**
- [ ] 18+ posts published (6 weeks × 3)
- [ ] Engagement rate tracked
- [ ] Content quality consistent
- [ ] Posting schedule maintained

**Operations:**
- [ ] Runbook documented
- [ ] <2 hours/week maintenance
- [ ] Alerts configured and tested
- [ ] Troubleshooting guide complete

---

## 8. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Ollama quality insufficient | High | Medium | Fine-tune prompts; fallback to Claude API ($5-10/mo) |
| Docker container crashes | Medium | Low | Restart policies, healthchecks, alerts |
| LinkedIn changes/blocks | Medium | Low | Manual posting; no API dependency |
| Content becomes repetitive | Medium | Medium | Diverse prompts, pillar rotation, topic variety |
| WSL2 performance issues | Low | Low | Resource limits, monitoring |

---

## 9. Timeline Summary

```
Week 1-2: INFRASTRUCTURE
├── Docker Compose (n8n, Postgres, Ollama, Redis)
├── Database schema & seed data
├── Telegram bot integration
└── Backup scripts

Week 3-4: CORE WORKFLOWS
├── WF1: content-generate
├── WF2: batch-generate
├── WF3: daily-digest
├── WF4: format-validate
└── Error handling & testing

Week 5-6: LINKEDIN MVP
├── Content pillars & prompts
├── First 6 posts live
├── Manual posting workflow
└── Metrics tracking

Week 7-8: STABILIZATION
├── Monitoring & alerts
├── Backup & recovery testing
├── Documentation
└── 30-day countdown start

Week 9-12: STABILITY PERIOD
├── Normal operations
├── Weekly reviews
├── Incident response
└── Final sign-off
```

---

## 10. Next Steps

1. **Approve this design** - User review
2. **Create implementation plan** - Using writing-plans skill
3. **Execute Phase 1** - Infrastructure setup
4. **Iterate** - Adjust based on learnings

---

**Document Version:** 1.0
**Last Updated:** 2026-03-16
**Author:** Claude + VictorAurelius
