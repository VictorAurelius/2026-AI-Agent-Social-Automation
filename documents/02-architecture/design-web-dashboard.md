# Thiet ke: Web Dashboard cho Content Management

## Van de
Hien tai quan ly content qua Telegram Bot + SQL. Thieu:
- Preview bai viet truoc khi approve
- Metrics visualization
- Content calendar view
- Batch operations

## Giai phap: Lightweight Web Dashboard

### Tai sao lightweight?
- Khong dung framework nang (React, Vue)
- Dung HTML + Tailwind CSS + Alpine.js
- n8n webhook lam API backend
- Serve static files tu n8n hoac simple HTTP server
- Khong can build step

### Dashboard Pages

#### 1. Content Queue (Trang chinh)
- Bang danh sach content voi status badges
- Filter theo: platform, status, content_format
- Preview noi dung (expand row)
- One-click Approve/Reject buttons
- Bulk actions (approve all, delete rejected)

#### 2. Topic Ideas
- Danh sach topics voi priority
- Add new topic form
- Mark as used/unused
- Filter by pillar

#### 3. Analytics
- Posts per platform (bar chart)
- Status distribution (pie chart)
- Weekly posting trend (line chart)
- Top performing posts

#### 4. System Status
- Service health (Ollama, Postgres, Redis)
- Recent workflow logs
- Error rate chart
- Disk/Memory usage

### API Endpoints (n8n webhooks)

| Method | Path | Purpose |
|--------|------|---------|
| GET | /api/content | List content queue |
| GET | /api/content/:id | Get single content |
| POST | /api/content/:id/approve | Approve content |
| POST | /api/content/:id/reject | Reject content |
| GET | /api/topics | List topic ideas |
| POST | /api/topics | Add topic |
| GET | /api/stats | Get statistics |
| GET | /api/health | System health |

### Tech Stack
- HTML5 + Tailwind CSS (CDN)
- Alpine.js (lightweight reactivity)
- Chart.js (charts)
- No build step, no node_modules

### Docker
Static files served by simple nginx container or n8n static file serving.

## Ke hoach
Phase 1: API endpoints (n8n webhooks)
Phase 2: Content Queue page
Phase 3: Analytics page
Phase 4: Full dashboard
