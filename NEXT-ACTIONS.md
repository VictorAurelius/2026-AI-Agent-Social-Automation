# Next Actions - AI Agent Personal

**Last Updated:** 2026-03-19
**Project Status:** All 18 PRs Merged - Ready for n8n Configuration & Go Live

---

## Project Progress

```
Phase 1: Infrastructure     ██████████████████ 100% ✅
Phase 2: Core Workflows     ██████████████████ 100% ✅ (11 workflows ready)
Phase 3: Content Types      ██████████████████ 100% ✅ (Post, Quiz, Carousel*, Infographic*)
Phase 4: Data Intelligence   ██████████████████ 100% ✅ (RSS, Trending)
Phase 5: Reliability         ██████████████████ 100% ✅ (Fallback, Alerts, Tests, CI)
Phase 6: Documentation      ██████████████████ 100% ✅ (20+ docs, Vietnamese)
Phase 7: UI                  ██████████████████ 100% ✅ (Web Dashboard prototype)
Phase 8: Go Live             ░░░░░░░░░░░░░░░░░░   0% ← YOU ARE HERE
```

---

## All 18 PRs Merged

| PR | Title | Category |
|----|-------|----------|
| #7 | Telegram Bot Interactive (WF6) | Core Platform |
| #8 | Image Generation Strategy | Content Types |
| #9 | Facebook Tech + Chinese Plans | Core Platform |
| #10 | Auto-posting Workflows (WF7, WF8) | Core Platform |
| #11 | PDF Carousel Generator | Content Types |
| #12 | Infographic Image Generator | Content Types |
| #13 | Multi-platform Batch Generate | Core Platform |
| #14 | Fix Telegram Bot Commands | Core Platform |
| #15 | Quiz + Auto-Comment (WF11, WF12) | Content Types |
| #16 | Test Automation | Reliability |
| #17 | Vietnamese Docs Complete | Documentation |
| #18 | GitHub Actions CI | Reliability |
| #19 | Novel Translation | Bonus Module |
| #20 | Rule-Based Fallback | Reliability |
| #21 | Alert Priority System | Reliability |
| #22 | Data-Driven Content - RSS (WF13) | Data Intelligence |
| #23 | Trending Topic Detection (WF14) | Data Intelligence |
| #24 | Web Dashboard | UI |

---

## NEXT: Go Live Checklist

### Step 1: Import Workflows vao n8n (30 min)

Tren may co Docker, mo http://localhost:5678:

| # | Workflow | File | Activate? |
|---|----------|------|-----------|
| 1 | WF1: Content Generate | `content-generate.json` | No (manual trigger) |
| 2 | WF2: Batch Generate | `batch-generate.json` | Yes (Mon/Wed/Fri 8AM) |
| 3 | WF3: Daily Digest | `daily-digest.json` | Yes (Daily 9AM) |
| 4 | WF5: Healthcheck | `healthcheck.json` | Yes (Every 5min) |
| 5 | WF6: Telegram Bot | `telegram-bot.json` | Yes (Always on) |
| 6 | WF7: Facebook Auto-Post | `facebook-post.json` | No (after FB setup) |
| 7 | WF8: LinkedIn Post Helper | `linkedin-post-helper.json` | No (manual trigger) |
| 8 | WF11: Quiz Generator | `quiz-generator.json` | No (manual trigger) |
| 9 | WF12: Auto-Comment | `auto-comment.json` | Yes (Every 30min) |
| 10 | WF13: Data Collector | `data-collector.json` | Yes (Daily 6AM) |
| 11 | WF14: Trending Detector | `trending-detector.json` | Yes (Daily 7AM) |

**Path:** Social: `modules/social/workflows/` | Common: `workflows/n8n/` | Novel: `modules/novel/workflows/`

### Step 2: Setup Credentials trong n8n (15 min)

| Credential | Type | Settings |
|------------|------|----------|
| PostgreSQL | Postgres | Host: `postgres`, Port: `5432`, DB: `agent_personal` |
| Telegram Bot | Telegram | Token tu @BotFather |

### Step 3: Load Database Scripts (10 min)

```bash
# Schema + seed data
docker exec -i postgres psql -U postgres -d agent_personal < infrastructure/docker/init-db/01-schema.sql
docker exec -i postgres psql -U postgres -d agent_personal < infrastructure/docker/init-db/02-seed-prompts.sql
docker exec -i postgres psql -U postgres -d agent_personal < infrastructure/docker/init-db/03-facebook-prompts.sql
```

### Step 4: Test Telegram Bot (10 min)

1. Gui `/help` cho bot → Nhan danh sach lenh
2. Gui `/status` → Nhan thong ke content queue
3. Gui `/topics` → Nhan danh sach topics
4. Gui `/health` → Kiem tra services

### Step 5: Generate First Content (15 min)

1. Gui `/generate AI tools cho developers` cho Telegram bot
2. Hoac chay WF1 manual trong n8n
3. Review output quality
4. Dung `/approve <id>` neu OK

### Step 6: First LinkedIn Post! (5 min)

1. Chay WF8 LinkedIn Post Helper
2. Bot gui noi dung formatted qua Telegram
3. Copy → Paste vao LinkedIn
4. Dang bai
5. Dung `/published <id> <url>` de cap nhat DB

---

## Week-by-Week Plan

### Week 1: LinkedIn Launch
- [ ] Import all 11 workflows vao n8n
- [ ] Test Telegram Bot commands (15 commands)
- [ ] Verify WF13 RSS collector runs at 6AM
- [ ] Verify WF14 Trending detector runs at 7AM
- [ ] Generate 5 bai LinkedIn
- [ ] Review & approve 3 bai
- [ ] Dang 3 bai (Mon/Wed/Fri)
- [ ] Track engagement

### Week 2: Facebook Tech Launch
- [ ] Tao Facebook Tech Page
- [ ] Setup Meta Developer Account
- [ ] Lay Page Access Token
- [ ] Cap nhat `.env` voi Facebook credentials
- [ ] Test WF7 Facebook Auto-Post
- [ ] Dang 5 bai Facebook Tech

### Week 3: Facebook Chinese + Data Intelligence
- [ ] Tao Facebook Chinese Page
- [ ] Test Chinese content quality
- [ ] Neu kem → thu Qwen2 7B model
- [ ] Review RSS-based content quality
- [ ] Review trending topic accuracy
- [ ] Dang 3-5 bai test

### Week 4: Optimization
- [ ] Review engagement metrics
- [ ] Fine-tune prompts dua tren data
- [ ] Optimize posting schedule
- [ ] Test fallback system (stop Ollama, verify fallback works)
- [ ] Review alert priority levels
- [ ] Setup cron backup
- [ ] Try Web Dashboard for content management

---

## All 11 Workflows

| # | Workflow | Trigger | Platform |
|---|----------|---------|----------|
| WF1 | Content Generate | Manual | LinkedIn |
| WF2 | Batch Generate | Mon/Wed/Fri 8AM | All (3 platforms) |
| WF3 | Daily Digest | Daily 9AM | All |
| WF5 | Healthcheck | Every 5min | System |
| WF6 | Telegram Bot | Always on | All |
| WF7 | Facebook Post | Manual/Cron | Facebook |
| WF8 | LinkedIn Helper | Manual | LinkedIn |
| WF11 | Quiz Generator | Manual/Telegram | All |
| WF12 | Auto-Comment | Every 30min | All |
| WF13 | Data Collector | Daily 6AM | All (RSS feeds) |
| WF14 | Trending Detector | Daily 7AM | System (topic_ideas) |

## New Features (PR #19-#24)

| Feature | PR | Description |
|---------|----|-------------|
| Novel Translation | #19 | Dich truyen Trung → Viet qua Telegram (Qwen2 7B) |
| Rule-Based Fallback | #20 | He thong hoat dong khi Ollama down |
| Alert Priority | #21 | 3 levels: FLASH, PRIORITY, ROUTINE |
| RSS Data Collector | #22 | WF13: Thu thap tin tu 5 RSS feeds |
| Trending Detection | #23 | WF14: Cross-reference HN + Reddit + GitHub |
| Web Dashboard | #24 | HTML + Tailwind + Alpine.js prototype |

## Documentation

| Doc | Path | Lang |
|-----|------|------|
| Huong dan Workflows | `documents/05-guides/huong-dan-workflows.md` | VN |
| Mo ta tat ca tinh nang | `documents/03-planning/mo-ta-tat-ca-tinh-nang.md` | VN |
| Tong quan du an | `documents/05-guides/tong-quan-du-an.md` | VN |
| Content Pillars LinkedIn | `documents/01-business/social/content-pillars.md` | EN |
| Content Pillars Facebook | `documents/01-business/social/content-pillars-facebook.md` | VN |
| Operations Runbook | `documents/05-guides/runbook.md` | EN |
| n8n Setup Guide | `documents/05-guides/n8n-setup-guide.md` | EN |
| Design: Telegram Bot | `documents/02-architecture/design-telegram-bot-interactive.md` | VN |
| Design: Auto-posting | `documents/02-architecture/design-auto-posting.md` | VN |
| Design: Image Generation | `documents/02-architecture/design-image-generation.md` | VN |
| Design: Facebook Plans | `documents/02-architecture/design-facebook-platforms.md` | VN |
| Design: Quiz + Auto-comment | `documents/02-architecture/design-quiz-auto-comment.md` | VN |

---

## Telegram Bot Commands (15 total)

```
/help        - Hien thi tro giup
/generate    - Tao bai viet tu chu de
/suggest     - AI goi y 5 topics
/addtopic    - Them topic moi
/status      - Thong ke content queue
/pending     - Bai cho review
/view <id>   - Xem noi dung day du
/approve <id> - Duyet bai
/reject <id>  - Tu choi bai
/topics      - Xem topics chua dung
/health      - Kiem tra services
/post_linkedin - Lay bai LI de dang
/post_fb     - Lay bai FB de dang
/published   - Cap nhat da dang
/quiz        - Tao quiz (planned)
```

---

**Last Updated:** 2026-03-19 (All 18 PRs merged, 11 workflows, ready for go-live)
