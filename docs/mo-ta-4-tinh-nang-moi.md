# Mô tả 4 Tính năng Mới (PR #7 - #10)

> Tài liệu tổng hợp mô tả chi tiết 4 Pull Requests đã merge ngày 2026-03-19.
> Mỗi PR giải quyết một thiếu sót trong hệ thống ban đầu.

**Ngày merge:** 2026-03-19
**Tổng files thêm mới:** 12 files

---

## Mục lục

1. [PR #7: Telegram Bot Tương tác](#pr-7-telegram-bot-tương-tác)
2. [PR #10: Workflows Đăng bài Tự động](#pr-10-workflows-đăng-bài-tự-động)
3. [PR #8: Chiến lược Tạo Hình ảnh](#pr-8-chiến-lược-tạo-hình-ảnh)
4. [PR #9: Mở rộng Facebook Tech + Tiếng Trung](#pr-9-mở-rộng-facebook-tech--tiếng-trung)
5. [Tổng quan hệ thống sau khi merge](#tổng-quan-hệ-thống-sau-khi-merge)

---

## PR #7: Telegram Bot Tương tác

**Branch:** `feature/telegram-bot-interactive`
**Files:** `telegram-bot.json`, `design-telegram-bot-interactive.md`

### Vấn đề giải quyết

Hệ thống cũ dùng Telegram Bot **một chiều** - chỉ gửi thông báo cho user. User không thể tương tác lại, phải mở n8n UI hoặc chạy SQL để quản lý content. Điều này bất tiện, đặc biệt khi dùng điện thoại.

### Giải pháp

Nâng cấp thành bot **hai chiều** - user gửi lệnh qua Telegram, bot nhận và xử lý, trả kết quả ngay.

```
TRƯỚC:  n8n → Bot → User  (chỉ nhận thông báo)
SAU:    User ←→ Bot ←→ n8n ←→ DB/Ollama  (tương tác đầy đủ)
```

### 12 Lệnh Bot

#### Nhóm 1: Tạo nội dung
| Lệnh | Chức năng | Ví dụ |
|-------|-----------|-------|
| `/generate <topic>` | Tạo bài LinkedIn từ chủ đề | `/generate AI tools cho developers` |
| `/generate_fb <topic>` | Tạo bài Facebook | `/generate_fb Docker explained` |
| `/batch` | Chạy batch generate ngay | `/batch` |

#### Nhóm 2: Quản lý nội dung
| Lệnh | Chức năng | Ví dụ |
|-------|-----------|-------|
| `/status` | Thống kê content queue | Hiển thị số bài theo status |
| `/pending` | Liệt kê bài chờ review | Top 10 bài mới nhất |
| `/view <id>` | Xem nội dung đầy đủ | `/view 15` |
| `/approve <id>` | Duyệt bài viết | `/approve 15` |
| `/reject <id> <lý do>` | Từ chối + ghi lý do | `/reject 15 cần thêm ví dụ` |

#### Nhóm 3: Quản lý & hệ thống
| Lệnh | Chức năng |
|-------|-----------|
| `/topics` | Xem topics chưa dùng |
| `/addtopic` | Thêm topic mới |
| `/health` | Kiểm tra sức khỏe services |
| `/help` | Hiển thị danh sách lệnh |

### Cách hoạt động kỹ thuật

Workflow WF6 gồm 20 nodes:

```
[Telegram Trigger] → [Extract Command] → [Switch Router (9 routes)]
    │
    ├── /help     → Reply text hướng dẫn
    ├── /status   → Query PostgreSQL → Format → Reply
    ├── /pending  → Query pending_review → Format → Reply
    ├── /view     → Query by ID → Format full content → Reply
    ├── /approve  → UPDATE status='approved' → Reply confirmation
    ├── /reject   → UPDATE status='rejected' + reason → Reply
    ├── /generate → Get prompt → Call Ollama → Save DB → Reply result
    ├── /topics   → Query unused topics → Format list → Reply
    └── /health   → Check Ollama + Postgres → Reply status
```

**Extract Command** parse tin nhắn thành:
- `command`: tên lệnh (help, status, ...)
- `args`: tham số (topic text, ID, ...)
- `contentId`: ID bài viết (nếu có)
- `chatId`: ID chat để reply

**Security:** Chỉ owner's chat_id mới được phép tương tác. Log mọi commands vào `workflow_logs`.

### Ví dụ tương tác thực tế

```
User: /generate AI đang thay đổi cách developers làm việc

Bot:  🤖 Đang tạo nội dung...

      📝 Kết quả:
      [Nội dung bài viết 150-200 từ]

      📋 ID: #23
      📌 Platform: LinkedIn
      🏷️ Pillar: tech_insights
      ⏳ Status: pending_review

      Dùng /approve 23 để duyệt hoặc /reject 23 <lý do>

User: /approve 23

Bot:  ✅ Đã duyệt!
      #23 - AI đang thay đổi cách developers làm việc
      Status: approved
```

### Yêu cầu cấu hình

1. Setup commands trong BotFather: `/setcommands`
2. n8n: Import `telegram-bot.json` + activate (always on)
3. Cần `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` trong Docker

---

## PR #10: Workflows Đăng bài Tự động

**Branch:** `feature/auto-posting-workflows`
**Files:** `facebook-post.json`, `linkedin-post-helper.json`, `design-auto-posting.md`, `.env.example`

### Vấn đề giải quyết

Hệ thống chỉ có workflows TẠO nội dung (WF1, WF2) nhưng không có workflow ĐĂNG BÀI. User phải tự copy nội dung từ database và paste lên social media thủ công.

### Giải pháp: 2 Workflows mới

#### WF7: Facebook Auto-Post

Đăng bài **tự động** lên Facebook Page qua Meta Graph API.

```
[Trigger] → [Get Approved Content] → [Has Content?]
                                         │
                    ┌────── YES ──────────┼────── NO ──────┐
                    ▼                                       ▼
            [POST Facebook API]                   [Telegram: "Không có bài"]
                    │
              ┌─────┴──────┐
              ▼            ▼
          [Success]    [Error]
              │            │
              ▼            ▼
    [Update published]  [Log + Alert]
              │
              ▼
    [Telegram: "Đã đăng!"]
```

**API call:**
```
POST https://graph.facebook.com/v18.0/{PAGE_ID}/feed
Body: { "message": "nội dung bài", "access_token": "PAGE_TOKEN" }
```

**Yêu cầu:**
- Tạo Facebook App tại developers.facebook.com
- Lấy Page Access Token (long-lived, 60 ngày)
- Thêm `FACEBOOK_PAGE_ID` và `FACEBOOK_PAGE_TOKEN` vào `.env`

#### WF8: LinkedIn Post Helper

LinkedIn API cần apply và chờ approve (vài tuần), nên workflow này dùng phương pháp **bán tự động**: gửi nội dung formatted qua Telegram để user copy → paste → đăng.

```
[Trigger] → [Get Approved LinkedIn Content] → [Has Content?]
                                                   │
                              ┌─── YES ────────────┼─── NO ───┐
                              ▼                                ▼
                     [Send to Telegram]               [Telegram: "Không có"]
                     Message chứa:
                     - Nội dung đầy đủ
                     - Hướng dẫn đăng
                     - Lệnh /published <id> <url>
```

**Tin nhắn Telegram:**
```
📋 LinkedIn Post Ready - #15

Title: AI đang thay đổi cách developers làm việc
Pillar: tech_insights

---
[Nội dung bài viết đầy đủ]
---

📌 Hướng dẫn:
1. Copy nội dung trên
2. Mở LinkedIn → Create a post
3. Paste nội dung
4. Đăng bài
5. Dùng lệnh: /published 15 <URL bài viết>
```

### Chiến lược triển khai

| Giai đoạn | Platform | Phương pháp | Timeline |
|-----------|----------|-------------|----------|
| Phase 1 | Facebook | Auto-post (API) | Week 1 |
| Phase 2 | LinkedIn | Manual (Telegram helper) | Week 2 |
| Phase 3 | LinkedIn | Auto-post (API) | Khi được approve |

### Security

- Page token lưu trong `.env`, KHÔNG commit vào git
- Token Facebook cần renew mỗi 60 ngày
- Rate limit: max 5 bài/ngày/page

---

## PR #8: Chiến lược Tạo Hình ảnh

**Branch:** `feature/image-generation`
**Files:** `design-image-generation.md`, `quote-card.svg`, `templates/social-media/README.md`

### Vấn đề giải quyết

Hệ thống chỉ tạo content **chữ**. Nghiên cứu cho thấy posts có hình ảnh engagement cao hơn **2-3 lần** so với text-only.

### Phân tích 4 giải pháp

| Option | Chi phí | GPU | Tốc độ | Chất lượng | Phù hợp? |
|--------|---------|-----|--------|------------|----------|
| **A: Template + ImageMagick** | $0 | Không | ~1s/ảnh | Consistent | **RECOMMENDED** |
| B: Stable Diffusion | $0 | Cần NVIDIA | 5-10 min | Creative | Không (thiếu GPU) |
| C: Canva API | $13/mo | Không | Fast | Professional | Tốn tiền |
| D: DALL-E API | $0.04/ảnh | Không | Fast | Cao | Tốn tiền |

### Recommendation: Option A (Template-based)

**Lý do chọn:**
1. $0 chi phí - đúng mục tiêu dự án
2. Không cần GPU
3. Brand consistency - mọi ảnh đều đồng bộ
4. Nhanh (~1 giây/ảnh)
5. Dễ maintain và thêm template mới

**Cách hoạt động:**
```
Content text → Trích xuất key points → Chọn template → Overlay text lên ảnh → Output PNG
```

### 5 Template Types

| Template | Platform | Kích thước | Dùng cho |
|----------|----------|-----------|----------|
| Quote Card | LinkedIn, FB | 1200x628 | Thought leadership, tips |
| Tech Tip | FB Tech | 1080x1080 | Tutorial, code snippets |
| List Post | LinkedIn | 1200x1500 | Numbered lists |
| Story Card | FB, IG | 1080x1920 | Quick tips |
| Chinese Vocab | FB Chinese | 1080x1080 | HSK vocabulary |

### Brand Guidelines

```
Colors:
  Primary:    #2563EB (blue)
  Secondary:  #10B981 (green)
  Accent:     #F59E0B (amber)
  Dark BG:    #1E293B
  Light BG:   #F8FAFC

Fonts:
  Title:  Noto Sans Bold
  Body:   Noto Sans Regular
  Code:   JetBrains Mono
```

### Ví dụ ImageMagick Command

```bash
convert template-quote.png \
  -font "Noto-Sans-Bold" -pointsize 48 -fill white \
  -gravity center -annotate +0-50 "AI Tools Every Developer\nShould Know in 2026" \
  -pointsize 24 -annotate +0+80 "@VictorAurelius | #TechInsights" \
  output.png
```

### Kế hoạch triển khai

| Phase | Nội dung | Timeline |
|-------|----------|----------|
| Phase 1 | Tạo 5 SVG templates, test ImageMagick | Week 1 |
| Phase 2 | Tạo WF9 Image Generator trong n8n | Week 2 |
| Phase 3 | Tích hợp với WF1/WF2 (text → image) | Week 3 |

### Sample Template (đã có trong repo)

File `templates/social-media/quote-card.svg` - template 1200x628 với:
- Gradient dark background
- Blue accent line
- Title placeholder `{{TITLE_LINE_1}}`, `{{TITLE_LINE_2}}`
- Body text area `{{BODY_TEXT}}`
- Bottom bar với author và hashtags

---

## PR #9: Mở rộng Facebook Tech + Tiếng Trung

**Branch:** `feature/facebook-platforms`
**Files:** `03-facebook-prompts.sql`, `design-facebook-platforms.md`, `content-pillars-facebook.md`

### Vấn đề giải quyết

Hệ thống chỉ có prompts và workflows cho **LinkedIn**. Theo plan ban đầu, dự án cần hỗ trợ 3 platforms:
1. LinkedIn (đã có)
2. Facebook Tech Page (chưa có)
3. Facebook Chinese Learning Page (chưa có)

### Giải pháp: Prompts + Topics + Pillars cho 2 Facebook Pages

#### Facebook Tech Page

**Audience:** Developers Việt Nam
**Tone:** Casual, friendly (khác LinkedIn professional)
**Ngôn ngữ:** Vietnamese + English technical terms
**Tần suất:** 5-6 bài/tuần

| Pillar | % | Tần suất | Prompt |
|--------|---|----------|--------|
| Tech News | 35% | 2-3/tuần | `fb_tech_news` |
| Tutorials | 30% | 2/tuần | `fb_tech_tutorial` |
| Tools & Tips | 20% | 1-2/tuần | `fb_tech_tools` |
| Community | 15% | 1/tuần | `fb_tech_community` |

**Posting Schedule:**
```
Thứ 2: Tech News (8AM)     Thứ 5: Tools & Tips (12PM)
Thứ 3: Tutorial (12PM)     Thứ 6: Community (6PM)
Thứ 4: Tech News (8AM)     Thứ 7: Tutorial (10AM)
```

**10 Topic Ideas (sẵn trong DB):**
1. GitHub Copilot vs Claude Code comparison
2. 5 VS Code extensions không thể thiếu
3. Docker containers from zero to hero
4. Tại sao mọi dev nên biết Linux CLI
5. REST API vs GraphQL
6. Git workflow cho team nhỏ
7. Free hosting: Vercel, Railway, Fly.io
8. JavaScript frameworks 2026
9. Bạn đang dùng IDE nào? (poll)
10. Cách setup dev environment từ đầu

#### Facebook Chinese Learning Page

**Audience:** Người Việt học tiếng Trung (HSK 1-4)
**Tone:** Supportive, encouraging (giáo viên thân thiện)
**Ngôn ngữ:** Vietnamese + Chinese (有标注拼音)
**Tần suất:** 5-7 bài/tuần

| Pillar | % | Tần suất | Prompt |
|--------|---|----------|--------|
| Vocabulary | 35% | Hàng ngày | `fb_chinese_vocab` |
| Grammar | 25% | 2-3/tuần | `fb_chinese_grammar` |
| Culture | 20% | 1-2/tuần | `fb_chinese_culture` |
| Practice | 20% | 1-2/tuần | `fb_chinese_practice` |

**Posting Schedule:**
```
Hàng ngày 7AM: Vocabulary
Thứ 2, 4: Grammar (10AM)
Thứ 3, 6: Practice/Quiz (6PM)
Thứ 7: Culture (10AM)
```

**10 Topic Ideas (sẵn trong DB):**
1. 你好 (nǐ hǎo) và 10 cách chào hỏi
2. Đếm số 1-100 - quy luật dễ nhớ
3. Cấu trúc 是...的 (shì...de)
4. Từ vựng đi chợ: 多少钱
5. Tết Trung Thu 中秋节
6. Quiz: Trái cây bằng tiếng Trung
7. 了 (le) - Particle khó nhất explained
8. Từ vựng công nghệ: 电脑 手机 网络
9. Văn hóa trà đạo 茶文化
10. Điền từ: Câu tiếng Trung cơ bản

### Database Changes

**File:** `docker/init-db/03-facebook-prompts.sql`

Thêm vào PostgreSQL:
- **8 prompt templates** (4 FB Tech + 4 FB Chinese)
- **20 topic ideas** (10 per page)
- Platform values: `facebook_tech`, `facebook_chinese`

**Chạy lệnh:**
```bash
docker exec -i postgres psql -U postgres -d social_automation < docker/init-db/03-facebook-prompts.sql
```

### Rủi ro đã xác định

| Rủi ro | Mức độ | Giải pháp |
|--------|--------|-----------|
| Llama 3.1 8B yếu Chinese | Cao | Thử Qwen2 7B (tốt hơn cho Chinese) |
| Content volume tăng 3x | Trung bình | Batch generate cho tất cả pages |
| Quality inconsistent | Trung bình | Fine-tune prompts theo platform |

---

## Tổng quan hệ thống sau khi merge

### Trước và Sau 4 PRs

| Khả năng | Trước | Sau |
|----------|-------|-----|
| **Tương tác** | Chỉ nhận thông báo | 12 lệnh Telegram bot |
| **Đăng bài** | Thủ công hoàn toàn | Facebook auto + LinkedIn helper |
| **Platforms** | LinkedIn only | LinkedIn + FB Tech + FB Chinese |
| **Hình ảnh** | Không có | Strategy + templates + brand guide |
| **Prompts** | 4 (LinkedIn) | 12 (4 LinkedIn + 4 FB Tech + 4 FB Chinese) |
| **Topics** | 10 | 30 (10 per platform) |
| **Workflows** | 4 (WF1-WF5) | 7 (WF1-WF8) |

### Kiến trúc hệ thống hoàn chỉnh

```
┌─────────────────────────────────────────────────────────────────┐
│  WSL2 Docker Compose                                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │   n8n    │  │ Postgres │  │  Ollama  │  │  Redis   │       │
│  │  :5678   │  │  :5432   │  │  :11434  │  │  :6379   │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│       │              │             │                            │
│  7 Workflows:                                                   │
│  ├── WF1: Content Generate      (manual, LinkedIn)             │
│  ├── WF2: Batch Generate        (Mon/Wed/Fri 8AM)              │
│  ├── WF3: Daily Digest          (Daily 9AM)                    │
│  ├── WF5: Healthcheck           (Every 5min)                   │
│  ├── WF6: Telegram Bot          (Always on) ← PR #7           │
│  ├── WF7: Facebook Auto-Post    (manual/cron) ← PR #10        │
│  └── WF8: LinkedIn Post Helper  (manual) ← PR #10             │
│                                                                 │
│  Database:                                                      │
│  ├── 12 prompt templates        (4 LI + 4 FB Tech + 4 FB CN)  │
│  ├── 30 topic ideas             (10 per platform)              │
│  └── 5 tables                   (content, prompts, metrics...) │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼────────────────┐
              ▼               ▼                ▼
        ┌──────────┐   ┌──────────┐    ┌──────────┐
        │ LinkedIn │   │ Facebook │    │ Telegram │
        │ (manual) │   │ (API)    │    │ (bot 2  │
        │ via TG   │   │ auto     │    │  chiều) │
        └──────────┘   └──────────┘    └──────────┘
```

### Files tham khảo chi tiết

| PR | Design Doc | Workflow | Dữ liệu |
|----|-----------|----------|----------|
| #7 | `docs/design-telegram-bot-interactive.md` | `workflows/n8n/telegram-bot.json` | - |
| #8 | `docs/design-image-generation.md` | - (Phase 2) | `templates/social-media/` |
| #9 | `docs/design-facebook-platforms.md` | - (dùng WF2 mở rộng) | `docker/init-db/03-facebook-prompts.sql` |
| #10 | `docs/design-auto-posting.md` | `facebook-post.json` + `linkedin-post-helper.json` | `docker/.env.example` |

---

**Tác giả:** VictorAurelius + Claude
**Cập nhật:** 2026-03-19
