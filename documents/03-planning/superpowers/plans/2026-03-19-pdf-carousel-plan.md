# PDF Carousel Generator - Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan.

**Goal:** Create WF9 n8n workflow that auto-generates LinkedIn/Facebook carousel PDFs from AI content.

**Architecture:** Ollama (structured JSON) -> HTML templates -> Browserless Chrome (screenshots) -> PDF

**Tech Stack:** n8n, Browserless Chrome, Ollama, PostgreSQL

**Spec Document:** `documents/03-planning/superpowers/specs/2026-03-19-pdf-carousel-design.md`

---

### Task 1: Add Browserless to Docker Compose

**Files:**
- Modify: `infrastructure/docker/docker-compose.yml`

- [ ] **Step 1: Add browserless service**

Add to docker-compose.yml:
```yaml
  browserless:
    image: browserless/chrome:latest
    container_name: browserless
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - MAX_CONCURRENT_SESSIONS=2
      - CONNECTION_TIMEOUT=60000
    deploy:
      resources:
        limits:
          memory: 1G
    networks:
      - automation-network
```

- [ ] **Step 2: Verify service starts**
```bash
docker-compose up -d browserless
curl http://localhost:3000/json/version
```

- [ ] **Step 3: Commit**
```bash
git add infrastructure/docker/docker-compose.yml
git commit -m "feat(docker): add browserless chrome for PDF generation"
```

---

### Task 2: Create HTML Slide Templates

**Files:**
- Create: `infrastructure/templates/carousel/cover.html`
- Create: `infrastructure/templates/carousel/content.html`
- Create: `infrastructure/templates/carousel/cta.html`
- Create: `infrastructure/templates/carousel/README.md`

- [ ] **Step 1: Create template directory**
```bash
mkdir -p templates/carousel
```

- [ ] **Step 2: Create cover slide template**
(Dark gradient background, centered title, hook, swipe indicator)

- [ ] **Step 3: Create content slide template**
(White background, numbered heading, body, highlight box)

- [ ] **Step 4: Create CTA slide template**
(Blue gradient, follow prompt, hashtags)

- [ ] **Step 5: Create README**

- [ ] **Step 6: Commit**

---

### Task 3: Add Carousel Prompt to Database

**Files:**
- Create: `infrastructure/docker/init-db/04-carousel-prompt.sql`

- [ ] **Step 1: Create SQL file with carousel prompt**
- [ ] **Step 2: Commit**

---

### Task 4: Create WF9 Carousel Workflow

**Files:**
- Create: `workflows/n8n/carousel-generator.json`

- [ ] **Step 1: Create workflow with nodes:**
1. Manual Trigger (topic, slide_count)
2. Get/Generate structured JSON from Ollama
3. Parse slides from JSON
4. Loop slides -> Build HTML -> Screenshot via browserless
5. Combine to PDF
6. Save and notify

- [ ] **Step 2: Commit**

---

### Task 5: Update Documentation

**Files:**
- Update: `documents/05-guides/huong-dan-workflows.md` (add WF9 section)
- Update: `workflows/n8n/README.md` (add WF9 to table)

- [ ] **Step 1: Add WF9 documentation**
- [ ] **Step 2: Commit**
