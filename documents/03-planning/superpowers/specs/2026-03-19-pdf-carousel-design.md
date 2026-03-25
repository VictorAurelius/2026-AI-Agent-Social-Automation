# PDF Carousel Generator - Design Spec

**Created:** 2026-03-19
**Status:** Proposed
**Goal:** Tu dong tao LinkedIn/Facebook carousel posts (PDF document) tu AI-generated content

---

## 1. Van de

LinkedIn Document posts (carousel) co engagement cao hon 2-3x so voi text-only posts. Hien tai he thong chi tao text content, khong co kha nang tao visual content dang carousel.

### Du lieu engagement LinkedIn:
- Text-only post: ~2-3% engagement rate
- Image post: ~3-5% engagement rate
- **Document/Carousel: ~5-8% engagement rate** (cao nhat)
- Video: ~4-6% engagement rate

## 2. Giai phap

Tao WF9: PDF Carousel Generator - workflow n8n tu dong tao carousel PDF tu content text.

### Luong xu ly

```
Ollama tao content (structured JSON)
       |
       v
Parse thanh slides (title + 5-7 content slides + CTA)
       |
       v
HTML template cho moi slide
       |
       v
Puppeteer render -> Screenshot moi slide
       |
       v
Combine screenshots -> PDF (A4 hoac square)
       |
       v
Save PDF -> Attach to content_queue
```

## 3. Carousel Structure

### 7-Slide Template (Standard)

| Slide | Noi dung | Muc dich |
|-------|----------|----------|
| 1 | Cover: Title + Hook + Author | Thu hut swipe |
| 2-6 | Content slides (1 point/slide) | Deliver value |
| 7 | CTA: Follow + Hashtags + Summary | Drive engagement |

### Vi du: "Top 5 AI Tools cho Developers"

```
Slide 1: Top 5 AI Tools Every Developer Should Know in 2026
         Swipe -> to discover

Slide 2: 1. GitHub Copilot
         AI pair programmer
         [icon] [short description]

Slide 3: 2. Claude Code
         CLI coding assistant
         [icon] [short description]

Slide 4: 3. Cursor
         AI-powered IDE
         [icon] [short description]

Slide 5: 4. v0 by Vercel
         UI generation from text
         [icon] [short description]

Slide 6: 5. Ollama
         Run LLMs locally
         [icon] [short description]

Slide 7: Follow @VictorAurelius for more
         #AI #DevTools #Programming
```

## 4. Thiet ke ky thuat

### Docker: Browserless Chrome

```yaml
# Them vao docker-compose.yml
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

### Ollama Prompt cho Carousel Content

System prompt can yeu cau output **structured JSON**:

```json
{
  "title": "Top 5 AI Tools cho Developers",
  "hook": "Swipe de kham pha 5 cong cu AI dang thay doi cach developers lam viec",
  "slides": [
    {
      "number": 1,
      "heading": "GitHub Copilot",
      "subheading": "AI Pair Programmer",
      "body": "Autocomplete code thong minh, ho tro 20+ ngon ngu",
      "highlight": "Tiet kiem 40% thoi gian coding"
    }
  ],
  "cta": "Follow @VictorAurelius",
  "hashtags": ["#AI", "#DevTools", "#Programming"]
}
```

### HTML Slide Template

Moi slide la 1 HTML page 1080x1080px:

```html
<!-- Cover Slide -->
<div style="width:1080px; height:1080px; background: linear-gradient(135deg, #1E293B 0%, #0F172A 100%);
     display:flex; flex-direction:column; justify-content:center; align-items:center; padding:80px;
     font-family:'Noto Sans', sans-serif; color:white;">
  <div style="width:4px; height:60px; background:#2563EB; margin-bottom:40px;"></div>
  <h1 style="font-size:52px; text-align:center; line-height:1.3;">{{title}}</h1>
  <p style="font-size:24px; color:#94A3B8; margin-top:30px;">{{hook}}</p>
  <div style="margin-top:60px; display:flex; align-items:center; gap:12px;">
    <span style="font-size:18px; color:#2563EB;">Swipe -></span>
  </div>
  <p style="position:absolute; bottom:40px; font-size:16px; color:#64748B;">@VictorAurelius</p>
</div>

<!-- Content Slide -->
<div style="width:1080px; height:1080px; background:white; padding:80px;
     font-family:'Noto Sans', sans-serif;">
  <div style="display:flex; align-items:center; gap:16px; margin-bottom:40px;">
    <span style="background:#2563EB; color:white; width:56px; height:56px; border-radius:50%;
           display:flex; align-items:center; justify-content:center; font-size:28px; font-weight:bold;">
      {{number}}
    </span>
    <h2 style="font-size:42px; color:#1E293B;">{{heading}}</h2>
  </div>
  <p style="font-size:28px; color:#2563EB; margin-bottom:30px;">{{subheading}}</p>
  <p style="font-size:24px; color:#475569; line-height:1.6;">{{body}}</p>
  <div style="margin-top:auto; padding:24px; background:#F0F9FF; border-radius:12px; border-left:4px solid #2563EB;">
    <p style="font-size:22px; color:#1E293B; font-weight:bold;">{{highlight}}</p>
  </div>
</div>

<!-- CTA Slide -->
<div style="width:1080px; height:1080px; background: linear-gradient(135deg, #2563EB 0%, #1D4ED8 100%);
     display:flex; flex-direction:column; justify-content:center; align-items:center; padding:80px;
     font-family:'Noto Sans', sans-serif; color:white;">
  <h2 style="font-size:48px; text-align:center;">Thay huu ich?</h2>
  <p style="font-size:28px; margin-top:20px;">Like + Save + Share</p>
  <div style="margin-top:60px; padding:24px 48px; border:2px solid white; border-radius:12px;">
    <p style="font-size:24px;">Follow {{cta}}</p>
  </div>
  <p style="margin-top:40px; font-size:20px; color:#93C5FD;">{{hashtags}}</p>
</div>
```

### n8n Workflow: WF9

```
[Manual Trigger + topic/type input]
       |
       v
[Get or Generate Content] -- Ollama API (structured JSON output)
       |
       v
[Parse Slides] -- Code node: parse JSON into slide array
       |
       v
[Loop Slides] -- For each slide:
       |
       |-- [Build HTML] -- Code: inject data into template
       |        |
       |        v
       |   [Screenshot] -- HTTP: POST to browserless /screenshot
       |        |
       |        v
       |   [Collect Image] -- Store base64 image
       |
       +-- All done --> [Combine to PDF] -- Code: images -> PDF
              |
              v
       [Save PDF] -- Write to filesystem or attach to content_queue
              |
              v
       [Telegram Notify] -- "Carousel PDF created!"
```

## 5. Prompt Template cho Carousel

```sql
INSERT INTO prompts (name, platform, pillar, content_type, system_prompt, user_prompt_template, variables) VALUES
(
    'carousel_generator',
    'linkedin',
    'tech_insights',
    'carousel',
    'You generate structured carousel content in JSON format. Output MUST be valid JSON with exactly this structure: {"title": "...", "hook": "...", "slides": [{"number": N, "heading": "...", "subheading": "...", "body": "...", "highlight": "..."}], "cta": "...", "hashtags": ["...", "..."]}. Generate exactly 5 content slides. Write in Vietnamese with English technical terms.',
    'Create a carousel about: {{topic}}\n\nPlatform: {{context}}\n\nOutput valid JSON only, no markdown or explanation.',
    ARRAY['topic', 'context']
);
```

## 6. Kich thuoc ho tro

| Platform | Kich thuoc | Ty le | Format |
|----------|-----------|--------|--------|
| LinkedIn | 1080x1080 | 1:1 | PDF Document |
| LinkedIn | 1080x1350 | 4:5 | PDF Document |
| Facebook | 1080x1080 | 1:1 | Image album |
| Instagram | 1080x1350 | 4:5 | Carousel post |

**Default:** 1080x1080 (works everywhere)

## 7. Ke hoach trien khai

### Phase 1: HTML Templates + Browserless (Week 1)
- Tao 3 HTML slide templates (cover, content, CTA)
- Add browserless to Docker Compose
- Test screenshot API

### Phase 2: n8n Workflow WF9 (Week 2)
- Create carousel workflow
- Integrate Ollama structured output
- Test end-to-end

### Phase 3: Integration (Week 3)
- Add carousel option to Telegram Bot (/carousel command)
- Auto-generate carousel for high-value topics
- A/B test carousel vs text-only

## 8. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Ollama JSON output unreliable | High | Add JSON validation + retry logic |
| Browserless memory usage | Medium | Limit concurrent sessions, set memory cap |
| PDF quality on mobile | Low | Test on multiple devices, optimize font sizes |
