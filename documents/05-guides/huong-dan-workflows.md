# Hướng dẫn chi tiết 11 Workflows n8n

> Tài liệu giải thích từng workflow trong hệ thống AI Agent Personal.
> Mỗi workflow được mô tả: mục đích, cách hoạt động, từng node, và lưu ý quan trọng.

**Cập nhật lần cuối:** 2026-03-19

---

## Mục lục

1. [WF1: Content Generate](#wf1-content-generate) - Tạo nội dung thủ công
2. [WF2: Batch Generate](#wf2-batch-generate) - Tạo nội dung theo lịch
3. [WF3: Daily Digest](#wf3-daily-digest) - Báo cáo hàng ngày
4. [WF5: Healthcheck](#wf5-healthcheck) - Giám sát hệ thống
5. [WF6: Telegram Bot Interactive](#wf6-telegram-bot-interactive) - Bot tương tác 2 chiều
6. [WF7: Facebook Auto-Post](#wf7-facebook-auto-post) - Đăng bài Facebook tự động
7. [WF8: LinkedIn Post Helper](#wf8-linkedin-post-helper) - Hỗ trợ đăng bài LinkedIn
8. [WF11: Quiz Generator](#wf11-quiz-generator) - Tạo câu hỏi trắc nghiệm
9. [WF12: Auto-Comment Scheduler](#wf12-auto-comment-scheduler) - Tự động comment đáp án
10. [WF13: Data Collector](#wf13-data-collector) - Thu thập RSS feeds
11. [WF14: Trending Detector](#wf14-trending-detector) - Phát hiện topic trending
12. [Tổng quan kiến trúc](#tổng-quan-kiến-trúc)
13. [Lưu ý bảo mật](#lưu-ý-bảo-mật)
14. [FAQ & Xử lý sự cố](#faq--xử-lý-sự-cố)

---

## WF1: Content Generate

### Mục đích

Tạo **một bài viết LinkedIn** từ chủ đề bạn nhập vào. Đây là workflow dùng thủ công khi bạn muốn tạo nội dung theo yêu cầu cụ thể.

### Khi nào dùng?

- Khi có ý tưởng mới muốn viết ngay
- Khi cần tạo bài viết cho sự kiện cụ thể
- Khi test chất lượng prompt mới
- Khi muốn kiểm soát chủ đề và nội dung chính xác

### Sơ đồ luồng

```
[1. Manual Trigger]
      │
      ▼
[2. Set Input] ─── Nhập: topic, pillar, content_type, context
      │
      ▼
[3. Get Prompt] ── Lấy prompt template từ PostgreSQL
      │               theo pillar (tech_insights, career_productivity, ...)
      ▼
[4. Prepare Prompt] ── Thay thế {{topic}} và {{context}}
      │                   trong template bằng giá trị thật
      ▼
[5. Call Ollama] ── Gửi prompt đến Llama 3.1 8B
      │               POST http://ollama:11434/api/chat
      │               Timeout: 120 giây
      ▼
[6. Parse Response] ── Trích xuất nội dung từ response
      │                   + Escape SQL để chống injection
      ▼
[7. Save to DB] ── Lưu vào bảng content_queue
      │               status = 'pending_review'
      ▼
[8. Notify Telegram] ── Gửi thông báo "New Content Ready"
```

### Giải thích từng Node

#### Node 1: Manual Trigger
- **Loại:** `manualTrigger`
- **Vai trò:** Cho phép bạn nhấn nút "Execute" trong n8n để chạy workflow
- **Lưu ý:** Workflow này KHÔNG tự động chạy. Bạn phải trigger thủ công

#### Node 2: Set Input
- **Loại:** `set` (gán biến)
- **Vai trò:** Định nghĩa 4 tham số đầu vào

| Tham số | Ý nghĩa | Ví dụ |
|---------|---------|-------|
| `topic` | Chủ đề bài viết | "AI đang thay đổi cách developers làm việc" |
| `pillar` | Trụ cột nội dung | `tech_insights`, `career_productivity`, `product_project`, `personal_stories` |
| `content_type` | Loại nội dung | `thought_leadership`, `tips`, `showcase`, `reflection` |
| `context` | Bối cảnh bổ sung | "Focus on practical tools and daily impact" |

- **Cách dùng:** Mở node này trong n8n, sửa giá trị các field trước khi chạy

#### Node 3: Get Prompt
- **Loại:** `postgres` (truy vấn database)
- **Vai trò:** Lấy prompt template phù hợp từ bảng `prompts`
- **SQL:**
  ```sql
  SELECT system_prompt, user_prompt_template
  FROM prompts
  WHERE pillar = '{{ $json.pillar }}' AND is_active = true
  LIMIT 1
  ```
- **Giải thích:** Dựa vào `pillar` bạn chọn, hệ thống lấy đúng template. Ví dụ pillar `tech_insights` sẽ lấy prompt hướng phân tích công nghệ

#### Node 4: Prepare Prompt
- **Loại:** `code` (JavaScript)
- **Vai trò:** Ghép dữ liệu đầu vào vào template prompt
- **Cách hoạt động:**
  1. Lấy `system_prompt` và `user_prompt_template` từ Node 3
  2. Thay thế `{{topic}}` bằng chủ đề thật
  3. Thay thế `{{context}}` bằng bối cảnh thật
  4. Trả về prompt hoàn chỉnh

#### Node 5: Call Ollama
- **Loại:** `httpRequest` (gọi API)
- **Vai trò:** Gửi prompt đến Ollama để Llama 3.1 8B tạo nội dung
- **Chi tiết:**
  - URL: `http://ollama:11434/api/chat`
  - Method: POST
  - Model: `llama3.1:8b`
  - Timeout: 120,000ms (2 phút)
  - Format: Gửi `system_prompt` + `user_prompt` theo chat format
- **Lưu ý:** Nếu Ollama đang bận hoặc model chưa load, node này sẽ timeout

#### Node 6: Parse Response
- **Loại:** `code` (JavaScript)
- **Vai trò:** Xử lý response từ Ollama
- **Cách hoạt động:**
  1. Lấy `message.content` từ response
  2. Nếu không có content → trả về "Generation failed"
  3. **Escape SQL** tất cả giá trị (chống SQL injection)
  4. Chuẩn bị dữ liệu để INSERT vào database
- **Bảo mật:** Function `escapeSql()` thay thế dấu `'` thành `''` để ngăn SQL injection

#### Node 7: Save to DB
- **Loại:** `postgres` (INSERT)
- **Vai trò:** Lưu nội dung đã tạo vào bảng `content_queue`
- **Dữ liệu lưu:**

| Cột | Giá trị |
|-----|---------|
| `title` | Chủ đề bài viết |
| `platform` | `linkedin` |
| `pillar` | Trụ cột nội dung |
| `content_type` | Loại nội dung |
| `generated_content` | Nội dung AI tạo ra |
| `status` | `pending_review` |

- **Trả về:** `id` của record mới (dùng `RETURNING id`)

#### Node 8: Notify Telegram
- **Loại:** `telegram` (gửi tin nhắn)
- **Vai trò:** Thông báo bạn qua Telegram rằng có nội dung mới cần review
- **Tin nhắn mẫu:**
  ```
  📝 New Content Ready for Review

  Title: AI đang thay đổi cách developers làm việc
  Pillar: tech_insights
  Status: Pending Review

  Review at: http://localhost:5678
  ```

### Sau khi chạy xong

Nội dung được lưu với status `pending_review`. Bạn cần:
1. Đọc nội dung trong database
2. Approve → đổi status sang `approved`
3. Hoặc Reject → đổi status sang `rejected` kèm lý do

---

## WF2: Batch Generate (Multi-Platform)

> **Update:** WF2 now supports all 3 platforms (LinkedIn, Facebook Tech, Facebook Chinese).
> Pillar-to-platform mapping is automatic. LIMIT increased from 3 to 5 topics per batch.
>
> **Pillar mapping:**
> | Pillar | Platform |
> |--------|----------|
> | `tech_insights`, `career_productivity`, `product_project`, `personal_stories` | `linkedin` |
> | `tech_news`, `tutorials`, `tools_tips`, `community` | `facebook_tech` |
> | `vocabulary`, `grammar`, `culture`, `practice` | `facebook_chinese` |

### Mục đích

Tự động tạo **nhiều bài viết** cùng lúc từ danh sách topic ideas. Chạy theo lịch **Thứ 2, Thứ 4, Thứ 6 lúc 8 giờ sáng**.

### Khi nào dùng?

- Workflow này chạy tự động, bạn không cần trigger
- Tạo tối đa 5 bài/batch (Mon/Wed/Fri) cho cả 3 platforms
- Lấy topic từ bảng `topic_ideas` theo thứ tự ưu tiên
- Platform được tự động xác định từ pillar của topic

### Sơ đồ luồng

```
[1. Cron: Mon/Wed/Fri 8AM]
      │
      ▼
[2. Get Topics] ── Lấy 5 topics chưa dùng từ DB
      │               (ORDER BY priority ASC)
      ▼
[3. Loop Topics] ── Xử lý từng topic một
      │
      ├── Còn topic ──────────────────────────┐
      │                                        │
      ▼                                        │
[4. Get Prompt] ── Lấy prompt theo pillar     │
      │                                        │
      ▼                                        │
[5. Prepare] ── Thay {{topic}}, {{context}}   │
      │                                        │
      ▼                                        │
[6. Generate] ── Gọi Ollama API              │
      │                                        │
      ▼                                        │
[7. Parse Response] ── Escape SQL + format    │
      │                                        │
      ▼                                        │
[8. Save Content] ── INSERT vào content_queue │
      │                                        │
      ▼                                        │
[9. Mark Used] ── UPDATE topic SET used=true  │
      │                                        │
      ▼                                        │
[10. Wait 30s] ── Chờ 30 giây               │
      │                                        │
      └────── Quay lại [3] ────────────────────┘

      └── Hết topic ──►  [11. Send Summary] ── Telegram
```

### Giải thích từng Node

#### Node 1: Mon/Wed/Fri 8AM
- **Loại:** `scheduleTrigger` (Cron)
- **Cron expression:** `0 8 * * 1,3,5`
  - `0` = phút 0
  - `8` = 8 giờ sáng
  - `*` = mọi ngày trong tháng
  - `*` = mọi tháng
  - `1,3,5` = Thứ 2, Thứ 4, Thứ 6
- **Timezone:** Theo `GENERIC_TIMEZONE` trong docker-compose (Asia/Ho_Chi_Minh)

#### Node 2: Get Topics
- **SQL:**
  ```sql
  SELECT id, topic, pillar, notes
  FROM topic_ideas
  WHERE used = false
  ORDER BY priority ASC
  LIMIT 5
  ```
- **Giải thích:** Lấy 5 topic chưa dùng, ưu tiên số nhỏ nhất (priority 1 = quan trọng nhất). Platform được tự động map từ pillar
- **Lưu ý:** Nếu không còn topic nào (`used = false`), workflow sẽ không tạo gì

#### Node 3: Loop Topics
- **Loại:** `splitInBatches`
- **Vai trò:** Xử lý từng topic một (không xử lý song song)
- **Output 1:** Topic tiếp theo → đi đến Get Prompt
- **Output 2:** Hết topic → đi đến Send Summary

#### Node 4-7: Giống WF1
Các node Get Prompt, Prepare, Generate, Parse Response hoạt động giống WF1 Content Generate.

#### Node 8: Save Content
- **Giống WF1** nhưng không dùng `RETURNING id`

#### Node 9: Mark Used
- **SQL:** `UPDATE topic_ideas SET used = true WHERE id = {{ topic_id }}`
- **Vai trò:** Đánh dấu topic đã dùng để không lặp lại
- **Quan trọng:** Đảm bảo mỗi topic chỉ dùng 1 lần

#### Node 10: Wait 30s
- **Loại:** `wait`
- **Vai trò:** Chờ 30 giây giữa các lần generate
- **Lý do:**
  - Tránh quá tải Ollama
  - Cho model thời gian giải phóng bộ nhớ
  - Đảm bảo chất lượng ổn định

#### Node 11: Send Summary
- **Chạy khi:** Tất cả topics đã được xử lý
- **Tin nhắn:**
  ```
  📦 Batch Generation Complete

  ✅ Generated posts from topic queue
  📋 Status: Pending Review

  Review at: http://localhost:5678
  ```

### Cách thêm Topic mới

```sql
-- Thêm 1 topic mới
INSERT INTO topic_ideas (topic, pillar, notes, priority)
VALUES (
  'Chủ đề bài viết',
  'tech_insights',     -- hoặc: career_productivity, product_project, personal_stories
  'Bối cảnh bổ sung',
  5                    -- 1=cao nhất, 10=thấp nhất
);
```

---

## WF3: Daily Digest

### Mục đích

Gửi **báo cáo tổng hợp hàng ngày** qua Telegram về tình trạng nội dung: bao nhiêu bài chờ review, bao nhiêu đã duyệt, đã đăng, v.v.

### Khi nào chạy?

- **Tự động** mỗi ngày lúc 9 giờ sáng
- Không cần trigger thủ công

### Sơ đồ luồng

```
[1. Daily 9AM]
      │
      ├────────────────────┐
      ▼                    ▼
[2. Get Stats]      [3. Get Pending]
  Đếm số bài          Lấy 5 bài
  theo status          pending_review
      │                    │
      └────────┬───────────┘
               ▼
        [4. Format Message]
          Tạo tin nhắn Markdown
               │
               ▼
        [5. Send Digest]
          Gửi Telegram
```

### Giải thích từng Node

#### Node 1: Daily 9AM
- **Cron:** `0 9 * * *` = Mỗi ngày lúc 9:00 sáng
- **Sau trigger:** Chạy 2 query song song (Node 2 và Node 3)

#### Node 2: Get Stats
- **SQL:**
  ```sql
  SELECT status, COUNT(*) as count
  FROM content_queue
  GROUP BY status
  ORDER BY status
  ```
- **Kết quả mẫu:**

  | status | count |
  |--------|-------|
  | approved | 3 |
  | draft | 2 |
  | pending_review | 5 |
  | published | 10 |

#### Node 3: Get Pending
- **SQL:**
  ```sql
  SELECT id, title, pillar, created_at
  FROM content_queue
  WHERE status = 'pending_review'
  ORDER BY created_at DESC
  LIMIT 5
  ```
- **Vai trò:** Lấy danh sách 5 bài mới nhất cần review

#### Node 4: Format Message
- **Loại:** `code` (JavaScript)
- **Vai trò:** Gom dữ liệu từ 2 query trên thành tin nhắn Markdown
- **Tin nhắn mẫu:**
  ```
  📊 Daily Digest - Thứ tư, 19 tháng 3, 2026

  📋 Content Status:
  • Draft: 2
  • Generating: 0
  • ⏳ Pending Review: 5
  • ✅ Approved: 3
  • 📅 Scheduled: 1
  • 🚀 Published: 10
  • ❌ Rejected: 1

  📝 Pending Review:
  1. AI đang thay đổi cách developers làm việc (tech_insights)
  2. 5 automation tools tiết kiệm thời gian (tech_insights)
  3. Cách organize ngày làm việc hiệu quả (career_productivity)

  Review at: http://localhost:5678
  ```

#### Node 5: Send Digest
- Gửi tin nhắn đã format qua Telegram với Markdown parse mode

### Tại sao cần Daily Digest?

- **Nhắc nhở:** Biết có bao nhiêu bài cần review
- **Theo dõi:** Thấy được progress tổng thể
- **Không bỏ sót:** Nếu batch generate tạo nội dung ban đêm, sáng bạn biết ngay
- **Thống kê nhanh:** Không cần mở database hay n8n

---

## WF5: Healthcheck

### Mục đích

Giám sát **3 dịch vụ cốt lõi** (Ollama, PostgreSQL, Redis) mỗi 5 phút. Nếu có dịch vụ nào bị lỗi, gửi cảnh báo qua Telegram ngay lập tức.

### Khi nào chạy?

- **Tự động** mỗi 5 phút, 24/7
- Không cần trigger thủ công

### Sơ đồ luồng

```
[1. Every 5 Min]
      │
      ▼
[2. Check Ollama] ── GET http://ollama:11434/api/tags
      │
      ▼
[3. Check Postgres] ── SELECT 1 as health
      │
      ▼
[4. Check Redis] ── HTTP check port 6379
      │
      ▼
[5. Evaluate] ── Đánh giá: tất cả OK?
      │
      ▼
[6. Is Healthy?] ── Phân nhánh
      │
      ├── TRUE ──► [7. Log Success]  ── Ghi log "healthy"
      │
      └── FALSE ──► [8. Log Error]   ── Ghi log "error"
                         │
                         ▼
                    [9. Alert]        ── Gửi Telegram cảnh báo!
```

### Giải thích từng Node

#### Node 1: Every 5 Min
- **Loại:** `scheduleTrigger`
- **Interval:** Mỗi 5 phút
- **Lưu ý:** Workflow này tạo nhiều log. Cân nhắc tăng interval (10-15 phút) nếu log quá nhiều

#### Node 2: Check Ollama
- **Method:** GET `http://ollama:11434/api/tags`
- **Timeout:** 5 giây
- **Khi thành công:** Trả về danh sách models (`{ "models": [...] }`)
- **Khi thất bại:** Error (Ollama down hoặc timeout)
- **`onError: continueRegularOutput`:** Workflow tiếp tục chạy ngay cả khi node lỗi

#### Node 3: Check Postgres
- **SQL:** `SELECT 1 as health, NOW() as checked_at`
- **Khi thành công:** Trả về `{ "health": 1 }`
- **Khi thất bại:** PostgreSQL không phản hồi
- **`onError: continueRegularOutput`:** Tiếp tục chạy

#### Node 4: Check Redis
- **Method:** HTTP request đến `http://redis:6379`
- **Timeout:** 5 giây
- **Lưu ý:** Redis không phải HTTP server nên request sẽ fail, nhưng nếu port mở = Redis đang chạy

#### Node 5: Evaluate
- **Loại:** `code` (JavaScript)
- **Logic đánh giá:**
  ```javascript
  ollamaOk = !error && response.models !== undefined
  postgresOk = !error && response.health === 1
  redisOk = !error
  allHealthy = ollamaOk && postgresOk && redisOk
  ```
- **Output:** Object chứa trạng thái từng dịch vụ + `allHealthy` boolean

#### Node 6: Is Healthy?
- **Loại:** `if` (điều kiện)
- **Điều kiện:** `allHealthy === true`
- **Output 1 (TRUE):** → Log Success
- **Output 2 (FALSE):** → Log Error + Alert

#### Node 7: Log Success
- **SQL:**
  ```sql
  INSERT INTO workflow_logs (workflow_name, status, message)
  VALUES ('healthcheck', 'success', 'All services healthy at ...')
  ```

#### Node 8: Log Error
- **SQL:**
  ```sql
  INSERT INTO workflow_logs (workflow_name, status, message, details)
  VALUES ('healthcheck', 'error', 'Service unhealthy at ...',
    '{"ollama": false, "postgres": true, "redis": true}')
  ```
- **Cột `details`:** Lưu JSON chi tiết service nào lỗi

#### Node 9: Alert (Telegram)
- **Chỉ gửi khi** có dịch vụ bị lỗi
- **Tin nhắn mẫu:**
  ```
  🚨 Service Health Alert

  Time: 2026-03-19T08:30:00.000Z

  Service Status:
  • Ollama: ❌ DOWN
  • PostgreSQL: ✅ Healthy
  • Redis: ✅ Healthy

  ⚠️ Please check immediately!
  ```

### Lưu ý về Sequential Execution

Workflow này kiểm tra **tuần tự** (không song song):
```
Ollama → PostgreSQL → Redis → Evaluate
```

**Lý do (PR #5 → #6):** Ban đầu thiết kế song song, nhưng n8n Merge Node phức tạp và gây lỗi. Chuyển sang sequential đơn giản và ổn định hơn. Thời gian check vẫn nhanh (~10-15 giây).

---

## WF6: Telegram Bot Interactive

### Mục đích

Nâng cấp Telegram Bot từ **chỉ thông báo 1 chiều** thành **tương tác 2 chiều**. Cho phép bạn điều khiển toàn bộ hệ thống qua Telegram: tạo nội dung, review, duyệt, đăng bài, kiểm tra sức khỏe hệ thống.

### Khi nào dùng?

- Workflow này **luôn chạy** (Always Active) để nhận message từ Telegram
- Bạn gửi lệnh qua Telegram bất cứ lúc nào
- Không cần mở n8n hay database để quản lý nội dung
- Điều khiển mọi thứ từ điện thoại

### 15 Commands

#### Tạo nội dung
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/generate <topic>` | Tạo bài viết LinkedIn (Ollama -> DB -> Reply) | `/generate AI tools cho developers` |
| `/suggest` | AI gợi ý 5 topic ideas | `/suggest` |
| `/addtopic <topic>\|<pillar>\|<priority>` | Thêm topic mới vào DB | `/addtopic AI trends\|tech_insights\|3` |

#### Quản lý nội dung
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/status` | Thống kê content queue | `/status` |
| `/pending` | Liệt kê bài chờ review | `/pending` |
| `/view <id>` | Xem nội dung đầy đủ | `/view 15` |
| `/approve <id>` | Duyệt bài viết | `/approve 15` |
| `/reject <id> <lý do>` | Từ chối bài viết | `/reject 15 cần thêm ví dụ` |

#### Đăng bài
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/post_linkedin` | Lấy bài LinkedIn approved để copy-paste | `/post_linkedin` |
| `/post_fb` | Lấy bài Facebook approved | `/post_fb` |
| `/published <id> <url>` | Cập nhật trạng thái đã đăng + URL | `/published 15 https://linkedin.com/post/123` |

#### Hệ thống
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/topics` | Xem topics chưa dùng | `/topics` |
| `/health` | Kiểm tra Ollama + PostgreSQL status | `/health` |
| `/help` | Hiển thị danh sách lệnh | `/help` |

### Sơ đồ luồng

```
[Telegram Trigger] ── Nhận message từ user
       │
       ▼
[Extract Command] ── Parse lệnh và tham số
       │
       ▼
[Switch/Router] ── Phân loại lệnh
       │
       ├── /help ─────────► [Reply Help Text]
       ├── /status ────────► [Query Stats] → [Format] → [Reply]
       ├── /pending ───────► [Query Pending] → [Format] → [Reply]
       ├── /view ──────────► [Query Content] → [Format] → [Reply]
       ├── /approve ───────► [Update Status] → [Reply]
       ├── /reject ────────► [Prepare Reject] → [Do Reject] → [Reply]
       ├── /generate ──────► [Get Prompt] → [Prepare] → [Ollama] → [Parse+Save] → [Reply]
       ├── /topics ────────► [Query Topics] → [Format] → [Reply]
       ├── /health ────────► [Check Ollama] → [Check Postgres] → [Evaluate] → [Reply]
       ├── /addtopic ──────► [Parse Args] → [INSERT topic_ideas] → [Reply]
       ├── /published ─────► [Parse Args] → [UPDATE content_queue] → [Reply]
       ├── /suggest ───────► [Call Ollama] → [Format] → [Reply]
       ├── /post_fb ───────► [Get FB Content] → [Format] → [Reply]
       ├── /post_linkedin ─► [Get LI Content] → [Format] → [Reply]
       └── fallback ───────► [Reply Help Text]
```

### Giải thích từng Node quan trọng

#### Node 1: Telegram Trigger
- **Loại:** `n8n-nodes-base.telegramTrigger`
- **Updates:** `message`
- **Vai trò:** Nhận mọi tin nhắn gửi đến bot
- **Lưu ý:** Workflow PHẢI luôn ACTIVE để nhận messages

#### Node 2: Extract Command (Code)
- **Loại:** `code` (JavaScript)
- **Vai trò:** Parse lệnh và tham số từ tin nhắn
- **Logic:**
  ```javascript
  const message = $json.message.text || '';
  const parts = message.split(' ');
  const command = parts[0].toLowerCase();
  const args = parts.slice(1).join(' ');
  const chatId = $json.message.chat.id;
  return { command, args, chatId, rawMessage: message };
  ```

#### Node 3: Switch/Router
- **Loại:** `switch`
- **Vai trò:** Phân loại lệnh dựa trên giá trị `command`
- **15 routes:** Mỗi route xử lý 1 lệnh cụ thể
- **Fallback:** Nếu lệnh không nhận dạng được → trả về Help text

#### Node Security Check
- **Vai trò:** Chỉ cho phép `chat_id` của owner tương tác
- **Reject:** Mọi message từ chat_id khác bị bỏ qua
- **Log:** Tất cả commands được ghi vào `workflow_logs`

### Cách cấu hình BotFather

1. Mở Telegram, tìm `@BotFather`
2. Gửi `/setcommands`
3. Chọn bot của bạn
4. Paste danh sách commands:
```
generate - Tạo bài viết LinkedIn từ chủ đề
suggest - AI gợi ý 5 topic ideas
addtopic - Thêm topic mới (topic|pillar|priority)
status - Xem thống kê content queue
pending - Liệt kê bài chờ review
view - Xem nội dung đầy đủ (dùng: /view ID)
approve - Duyệt bài viết (dùng: /approve ID)
reject - Từ chối bài (dùng: /reject ID lý do)
topics - Xem danh sách topics chưa dùng
post_linkedin - Lấy bài LinkedIn approved để đăng
post_fb - Lấy bài Facebook approved
published - Cập nhật đã đăng (dùng: /published ID URL)
health - Kiểm tra Ollama + PostgreSQL
help - Hiển thị trợ giúp
```

### Ví dụ tương tác

#### `/generate AI tools cho developers`
```
🤖 Đang tạo nội dung...

📝 *Kết quả:*

[Nội dung bài viết đầy đủ ở đây]

---
📋 ID: #23
📌 Platform: LinkedIn
🏷️ Pillar: tech_insights
⏳ Status: pending_review

Dùng `/approve 23` để duyệt hoặc `/reject 23 <lý do>` để từ chối.
```

#### `/status`
```
📊 *Content Queue Status*

• Draft: 2
• ⏳ Pending Review: 5
• ✅ Approved: 3
• 📅 Scheduled: 1
• 🚀 Published: 12
• ❌ Rejected: 2

📝 Unused Topics: 7

Dùng `/pending` để xem chi tiết bài chờ review.
```

#### `/view 15`
```
📄 *Content #15*

*Title:* AI đang thay đổi cách developers làm việc
*Platform:* LinkedIn
*Pillar:* tech_insights
*Status:* pending_review
*Created:* 2026-03-19 08:30

---

[Nội dung đầy đủ bài viết]

---

✅ `/approve 15` | ❌ `/reject 15 <lý do>`
```

---

## WF7: Facebook Auto-Post

### Mục đích

Tự động **đăng bài Facebook** cho các content đã được approve. Sử dụng Meta Graph API để post trực tiếp lên Facebook Page.

### Khi nào dùng?

- Trigger thủ công hoặc theo cron schedule
- Khi có bài Facebook đã được approve (`status = 'approved'` và `platform LIKE 'facebook%'`)
- Hỗ trợ cả Facebook Tech và Facebook Chinese pages

### Sơ đồ luồng

```
[Manual/Cron Trigger]
       │
       ▼
[Get Approved Content] ── SELECT WHERE status='approved'
       │                    AND platform LIKE 'facebook%'
       ▼
[Has Content?]
       │
       ├── YES ──► [Post to Facebook] ── POST Meta Graph API
       │                  │                 /{page-id}/feed
       │                  │
       │                  ├── Success ──► [Update Status] ── status='published'
       │                  │                    │               post_url = FB URL
       │                  │                    ▼
       │                  │              [Telegram: "Đã đăng bài!"]
       │                  │
       │                  └── Error ──► [Log Error]
       │                                    │
       │                                    ▼
       │                              [Telegram: "Lỗi đăng bài!"]
       │
       └── NO ──► [Telegram: "Không có bài approved"]
```

### Giải thích từng Node quan trọng

#### Node 1: Trigger
- **Loại:** `manualTrigger` hoặc `scheduleTrigger`
- **Vai trò:** Khởi động quy trình đăng bài

#### Node 2: Get Approved Content
- **Loại:** `postgres`
- **SQL:**
  ```sql
  SELECT id, title, generated_content, platform
  FROM content_queue
  WHERE status = 'approved'
    AND platform LIKE 'facebook%'
  ORDER BY created_at ASC
  LIMIT 1
  ```

#### Node 3: Post to Facebook
- **Loại:** `httpRequest`
- **URL:** `https://graph.facebook.com/v18.0/{{ $env.FACEBOOK_PAGE_ID }}/feed`
- **Method:** POST
- **Body:**
  ```json
  {
    "message": "{{ $json.generated_content }}",
    "access_token": "{{ $env.FACEBOOK_PAGE_TOKEN }}"
  }
  ```
- **Rate limit:** Không đăng quá 5 bài/ngày/page

#### Node 4: Update Status
- **SQL:**
  ```sql
  UPDATE content_queue
  SET status = 'published',
      post_url = 'https://facebook.com/{{ post_id }}',
      published_at = NOW()
  WHERE id = {{ content_id }}
  ```

### Yêu cầu

#### Facebook App Setup
1. Tạo Facebook App tại `developers.facebook.com`
2. Thêm product "Facebook Login"
3. Lấy Page Access Token (long-lived, 60 ngày)
4. Cần permissions: `pages_manage_posts`, `pages_read_engagement`

#### Environment Variables
```bash
# Thêm vào infrastructure/docker/.env
FACEBOOK_PAGE_ID=your_page_id
FACEBOOK_PAGE_TOKEN=your_long_lived_token
```

Sau khi thêm, recreate n8n container:
```bash
docker-compose up -d --force-recreate n8n
```

#### Security
- Token PHẢI lưu trong `.env`, KHÔNG commit vào git
- Page tokens cần renew mỗi 60 ngày
- Rate limiting: Không đăng quá 5 bài/ngày/page

### Ví dụ output

Khi đăng thành công, Telegram nhận thông báo:
```
✅ Đã đăng bài Facebook!

📋 ID: #18
📌 Platform: facebook_tech
🔗 URL: https://facebook.com/123456789

📊 Thống kê: 3 bài approved còn lại
```

---

## WF8: LinkedIn Post Helper

### Mục đích

Hỗ trợ **đăng bài LinkedIn** bằng cách gửi nội dung đã approve qua Telegram để bạn copy-paste lên LinkedIn. Đây là workflow **manual** vì LinkedIn API cần approval process.

### Khi nào dùng?

- Trigger thủ công hoặc qua lệnh `/post_linkedin` trong Telegram Bot
- Khi có bài LinkedIn đã được approve

### Tại sao dùng manual posting?

LinkedIn API có nhiều hạn chế:
- **Approval process dài:** Cần apply Marketing Developer Platform, chờ vài tuần
- **Personal profile hạn chế:** API chủ yếu cho Company Pages
- **An toàn hơn:** Manual posting tránh bị LinkedIn flag spam
- **Tạm thời:** Có thể chuyển sang API sau khi được approve

### Sơ đồ luồng

```
[Manual Trigger hoặc Telegram /post_linkedin]
       │
       ▼
[Get Approved LinkedIn Content]
       │  SELECT WHERE status='approved' AND platform='linkedin'
       ▼
[Has Content?]
       │
       ├── YES ──► [Format for LinkedIn]
       │               │
       │               ▼
       │          [Send to Telegram] ── Gửi nội dung + hướng dẫn:
       │               │               "1. Copy nội dung trên
       │               │                2. Mở LinkedIn → Create a post
       │               │                3. Paste và đăng
       │               │                4. Dùng /published <id> <url>"
       │               ▼
       │          [Update Status] ── status = 'scheduled'
       │
       └── NO ──► [Telegram: "Không có bài LinkedIn approved"]
```

### Giải thích từng Node quan trọng

#### Node 1: Get Approved LinkedIn Content
- **Loại:** `postgres`
- **SQL:**
  ```sql
  SELECT id, title, generated_content, pillar
  FROM content_queue
  WHERE status = 'approved' AND platform = 'linkedin'
  ORDER BY created_at ASC
  LIMIT 1
  ```

#### Node 2: Format for LinkedIn
- **Loại:** `code` (JavaScript)
- **Vai trò:** Định dạng nội dung phù hợp LinkedIn
- **Xử lý:** Thêm hashtags, format emoji, đảm bảo chiều dài phù hợp

#### Node 3: Send to Telegram
- **Loại:** `telegram`
- **Vai trò:** Gửi nội dung kèm hướng dẫn đăng bài

### Ví dụ output

Telegram nhận tin nhắn:
```
📋 *Bài LinkedIn #15 - Sẵn sàng đăng*

---

[Toàn bộ nội dung bài viết LinkedIn đã format]

---

📌 *Hướng dẫn đăng:*
1. Copy nội dung phía trên
2. Mở LinkedIn → Create a post
3. Paste nội dung và đăng
4. Sau khi đăng xong, gửi:
   `/published 15 https://linkedin.com/post/xxx`
```

---

## WF11: Quiz Generator

### Mục đích

Tạo **câu hỏi trắc nghiệm tech** (quiz) bằng AI. Quiz có engagement cao vì mọi người tranh luận đáp án, save để ôn thi, và tag bạn bè.

### Khi nào dùng?

- Trigger thủ công hoặc qua lệnh `/quiz <topic>` trong Telegram
- Khi muốn tạo content dạng quiz cho LinkedIn hoặc Facebook
- Các chủ đề phổ biến: AWS Certification, System Design, Coding Challenges, DevOps

### Sơ đồ luồng

```
[Trigger: Manual hoặc Telegram /quiz <topic>]
       │
       ▼
[Get Quiz Prompt] ── Lấy prompt template cho quiz
       │
       ▼
[Call Ollama] ── Generate structured JSON
       │          (câu hỏi + 4 options + đáp án + giải thích)
       │          Model: Llama 3.1 8B
       ▼
[Parse Quiz] ── Tách thành 2 phần:
       │          1. question_text → generated_content (hiển thị)
       │          2. answer_data → quiz_answer JSONB (ẩn)
       ▼
[Save to DB] ── INSERT content_queue:
       │          content_format = 'quiz'
       │          generated_content = question text
       │          quiz_answer = answer JSON
       │          comment_scheduled_at = NOW() + 4 hours
       ▼
[Telegram] ── "Quiz created! Review and approve"
```

### Giải thích từng Node quan trọng

#### Node 1: Get Quiz Prompt
- **Loại:** `postgres`
- **Vai trò:** Lấy prompt template đặc biệt cho quiz
- **Prompt yêu cầu Ollama:** Trả về structured JSON gồm scenario, 4 options, correct answer, và giải thích chi tiết

#### Node 2: Call Ollama
- **Loại:** `httpRequest`
- **URL:** `http://ollama:11434/api/chat`
- **Vai trò:** Generate quiz dưới dạng structured JSON
- **Output mẫu:**
  ```json
  {
    "question": "Công ty cần transfer 50TB data lên AWS...",
    "options": {
      "A": "Dùng AWS Direct Connect",
      "B": "Upload qua S3 multi-part",
      "C": "Dùng AWS Snowball",
      "D": "Dùng AWS DataSync"
    },
    "correct_answer": "C",
    "explanation": "AWS Snowball phù hợp cho transfer >10TB..."
  }
  ```

#### Node 3: Parse Quiz (Code)
- **Loại:** `code` (JavaScript)
- **Vai trò:** Tách JSON thành 2 phần riêng biệt
- **Phần 1 - Question text** (sẽ đăng):
  ```
  📝 [Câu hỏi - Scenario]

  A. Option A
  B. Option B
  C. Option C
  D. Option D

  💬 Comment đáp án của bạn!
  ⏰ Đáp án sẽ được công bố sau 4 giờ

  #AWS #CloudComputing #TechQuiz
  ```
- **Phần 2 - Answer data** (lưu riêng trong `quiz_answer`):
  ```json
  {
    "correct_answer": "C",
    "explanation": "Giải thích chi tiết...",
    "wrong_answers": {
      "A": "Tại sao A sai...",
      "B": "Tại sao B sai...",
      "D": "Tại sao D sai..."
    },
    "key_concepts": [
      {"name": "AWS Snowball", "description": "Thiết bị transfer data offline..."}
    ]
  }
  ```

#### Node 4: Save to DB
- **Loại:** `postgres`
- **INSERT:**

| Cột | Giá trị |
|-----|---------|
| `generated_content` | Question text (câu hỏi + 4 options) |
| `content_format` | `quiz` |
| `quiz_answer` | Answer JSON (đáp án + giải thích) |
| `comment_scheduled_at` | `NOW() + INTERVAL '4 hours'` |
| `status` | `pending_review` |

### Quiz Format

**Câu hỏi đăng lên social:**
```
📝 Công ty XYZ cần transfer 50TB dữ liệu từ on-premise lên AWS S3.
Kết nối internet hiện tại là 100Mbps.
Deadline: 1 tuần.

Giải pháp nào phù hợp nhất?

A. AWS Direct Connect
B. S3 Multi-part Upload
C. AWS Snowball
D. AWS DataSync qua VPN

💬 Comment đáp án của bạn!
⏰ Đáp án sẽ được công bố sau 4 giờ

#AWS #SAA #CloudComputing #TechQuiz
```

**Đáp án auto-comment sau 4 giờ:**
```
✅ Đáp án: C - AWS Snowball

📖 Giải thích:
50TB qua 100Mbps mất ~46 ngày, vượt deadline 1 tuần.
AWS Snowball cho phép transfer offline, gửi thiết bị vật lý.

❌ Tại sao các đáp án khác sai:
• A: Direct Connect mất vài tuần setup
• B: 100Mbps quá chậm cho 50TB
• D: DataSync vẫn phụ thuộc bandwidth

💡 Key concepts:
• AWS Snowball: Transfer >10TB offline
• AWS Snowball Edge: Có compute capability

🔖 Save bài này để ôn thi!
```

### Ví dụ output

Telegram nhận thông báo:
```
📝 Quiz Created!

📋 ID: #25
📌 Topic: AWS Data Transfer
🏷️ Format: quiz
⏰ Auto-comment: 4 giờ sau khi đăng

Preview:
[Câu hỏi scenario + 4 options]

Dùng `/approve 25` để duyệt.
```

---

## WF12: Auto-Comment Scheduler

### Mục đích

Tự động **comment đáp án quiz** lên bài viết đã đăng sau khoảng thời gian định trước (mặc định 4 giờ). Hỗ trợ Facebook (tự động qua API) và LinkedIn (manual qua Telegram).

### Khi nào chạy?

- **Tự động** mỗi 30 phút (Cron)
- Kiểm tra xem có quiz nào đã đến giờ comment đáp án chưa
- Không cần trigger thủ công

### Sơ đồ luồng

```
[Cron: Every 30 minutes]
       │
       ▼
[Get Due Comments] ── SELECT FROM content_queue WHERE:
       │                status = 'published'
       │                content_format = 'quiz'
       │                comment_posted = false
       │                comment_scheduled_at <= NOW()
       ▼
[Has Items?]
       │
       ├── YES ──► [Loop Each Quiz]
       │               │
       │               ▼
       │          [Format Comment] ── Build comment text
       │               │              từ quiz_answer JSON
       │               ▼
       │          [Check Platform]
       │               │
       │               ├── Facebook ──► [POST /{post-id}/comments]
       │               │                   Meta Graph API
       │               │                   │
       │               │                   ▼
       │               │              [Mark Done] ── comment_posted = true
       │               │                   │
       │               │                   ▼
       │               │              [Telegram: "Đã comment đáp án #ID"]
       │               │
       │               └── LinkedIn ──► [Send to Telegram]
       │                                  "Hãy comment đáp án sau
       │                                   trên LinkedIn post #ID"
       │                                   │
       │                                   ▼
       │                              [Mark Done] ── comment_posted = true
       │
       └── NO ──► (kết thúc, không làm gì)
```

### Giải thích từng Node quan trọng

#### Node 1: Cron Every 30 Min
- **Loại:** `scheduleTrigger`
- **Interval:** Mỗi 30 phút
- **Lý do 30 phút:** Cân bằng giữa tính kịp thời và tải hệ thống

#### Node 2: Get Due Comments
- **Loại:** `postgres`
- **SQL:**
  ```sql
  SELECT id, title, platform, post_url, quiz_answer
  FROM content_queue
  WHERE status = 'published'
    AND content_format = 'quiz'
    AND comment_posted = false
    AND comment_scheduled_at <= NOW()
  ORDER BY comment_scheduled_at ASC
  ```

#### Node 3: Format Comment (Code)
- **Loại:** `code` (JavaScript)
- **Vai trò:** Parse `quiz_answer` JSON và build comment text
- **Output:** Comment text hoàn chỉnh với đáp án + giải thích + key concepts

#### Node 4: Post Comment (Facebook)
- **Loại:** `httpRequest`
- **URL:** `https://graph.facebook.com/v18.0/{{ post_id }}/comments`
- **Method:** POST
- **Body:**
  ```json
  {
    "message": "✅ Đáp án: C\n\n📖 Giải thích:\n...",
    "access_token": "{{ $env.FACEBOOK_PAGE_TOKEN }}"
  }
  ```
- **Permission cần:** `pages_manage_engagement`

#### Node 5: Mark Done
- **SQL:**
  ```sql
  UPDATE content_queue
  SET comment_posted = true
  WHERE id = {{ quiz_id }}
  ```

### Platform Routing

| Platform | Phương thức | Chi tiết |
|----------|-------------|----------|
| **Facebook** | Auto (API) | POST `/{post-id}/comments` qua Meta Graph API |
| **LinkedIn** | Manual (Telegram) | Gửi nội dung comment qua Telegram để user copy-paste |

**Lý do LinkedIn manual:** LinkedIn API không cho phép comment trên personal posts qua API. Cần Company Page + Marketing Developer Platform approval.

### Ví dụ output

#### Facebook (tự động)
Telegram nhận thông báo:
```
✅ Đã comment đáp án quiz!

📋 Quiz ID: #25
📌 Platform: facebook_tech
🔗 Post: https://facebook.com/123456789
⏰ Comment sau: 4 giờ

Đáp án: C - AWS Snowball
```

#### LinkedIn (manual)
Telegram nhận tin nhắn:
```
📝 Cần comment đáp án quiz LinkedIn!

📋 Quiz ID: #26
🔗 Post: https://linkedin.com/post/xxx

📋 Nội dung comment:
---
✅ Đáp án: C - AWS Snowball

📖 Giải thích:
[Chi tiết giải thích]
---

Hãy copy và paste comment này lên LinkedIn post.
Sau khi xong, gửi: `/published 26 done`
```

---

## WF13: Data Collector

### Mục đích

Thu thập tin tức thực từ RSS feeds (Hacker News, Dev.to, TechCrunch, Reddit, GitHub) và tạo content dựa trên data thật thay vì LLM tự nghĩ.

### Khi nào chạy?

- Tự động mỗi ngày lúc 6:00 AM
- Lấy tin mới nhất → Ollama phân tích + viết bài → Save vào content queue

### Sơ đồ luồng

```
[Cron 6AM] → [Get Active Feeds from DB] → [Fetch RSS] → [Parse XML]
  → [Filter Duplicates] → [Select Top Stories] → [Ollama Generate]
  → [Save to DB (content_source='rss')] → [Telegram Summary]
```

### RSS Feeds đã đăng ký

| Nguồn | URL | Platform |
|-------|-----|----------|
| Hacker News | hnrss.org/frontpage | LinkedIn |
| Dev.to | dev.to/feed | FB Tech |
| TechCrunch | techcrunch.com/feed | LinkedIn |
| Reddit Programming | reddit.com/r/programming/.rss | FB Tech |
| GitHub Blog | github.blog/feed | LinkedIn |

### Database mới

- Bảng `rss_feeds`: Registry các RSS feeds
- Cột `content_source` trong content_queue: 'manual', 'rss', 'trending'
- Cột `source_url`: Link bài gốc
- Cột `source_title`: Tiêu đề bài gốc

### Lợi ích

- Content dựa trên tin thật, không generic
- Luôn có topic mới
- Source links tăng credibility

---

## WF14: Trending Detector

### Mục đích

Tự động phát hiện topic đang trending bằng cách cross-reference nhiều nguồn. Topic xuất hiện ở 2+ nguồn = trending → auto-add vào topic_ideas.

### Khi nào chạy?

- Tự động mỗi ngày lúc 7:00 AM (sau Data Collector 1 giờ)

### Sơ đồ luồng

```
[Cron 7AM] → [Fetch HN + Reddit + GitHub (parallel)]
  → [Extract Keywords] → [Cross-Reference (2+ sources)]
  → [Filter Existing Topics] → [INSERT topic_ideas (priority=1)]
  → [Telegram: "🔥 Trending topics detected"]
```

### Keyword Extraction

- Scan tiêu đề từ 3 nguồn
- Tìm tech terms: AI, Docker, Kubernetes, React, etc.
- Đếm tần suất xuất hiện

### Cross-Reference Logic

- Term xuất hiện ở 1 source = bình thường
- Term xuất hiện ở 2+ sources = TRENDING
- Auto-add với priority=1 (cao nhất)

### Database

- Bảng `trending_log`: Lưu keywords detected, sources, timestamps

---

## Tổng quan kiến trúc

### Mối quan hệ giữa các Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                   HỆ THỐNG 11 WORKFLOWS                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │ WF13: Data   │  │ WF14:        │                             │
│  │ Collector    │  │ Trending     │   THU THẬP DỮ LIỆU         │
│  │ (RSS 6AM)   │  │ Detector 7AM │                             │
│  └──────┬───────┘  └──────┬───────┘                             │
│         │                 │                                     │
│         └────────┬────────┘                                     │
│                  ▼                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ WF1: Manual  │  │ WF2: Batch   │  │ WF11: Quiz   │          │
│  │ Content Gen  │  │ Content Gen  │  │ Generator    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                  │   TẠO NỘI DUNG   │
│         └────────┬────────┴──────────────────┘                  │
│                  ▼                                              │
│         ┌─────────────────┐                                     │
│         │   PostgreSQL    │                                     │
│         │ content_queue   │    LƯU TRỮ                         │
│         │ topic_ideas     │                                     │
│         │ workflow_logs   │                                     │
│         │ rss_feeds       │                                     │
│         │ trending_log    │                                     │
│         └───┬─────┬───┬──┘                                     │
│             │     │   │                                         │
│     ┌───────┘     │   └──────────┐                              │
│     ▼             ▼              ▼                              │
│  ┌────────┐  ┌────────┐  ┌──────────────┐                      │
│  │ WF3:   │  │ WF5:   │  │ WF12: Auto-  │   GIÁM SÁT          │
│  │ Digest │  │ Health │  │ Comment      │                      │
│  └───┬────┘  └───┬────┘  └──────┬───────┘                      │
│      │           │               │                              │
│      └─────┬─────┴───────────────┘                              │
│            ▼                                                    │
│  ┌─────────────────────────────────────────┐                    │
│  │   WF6: Telegram Bot Interactive         │   ĐIỀU KHIỂN      │
│  │   (15 commands, luôn active)            │                    │
│  └───────┬─────────────────┬───────────────┘                    │
│          │                 │                                    │
│          ▼                 ▼                                    │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │ WF7: FB      │  │ WF8: LI      │          ĐĂNG BÀI          │
│  │ Auto-Post    │  │ Post Helper  │                             │
│  └──────┬───────┘  └──────┬───────┘                             │
│         │                 │                                     │
│         ▼                 ▼                                     │
│  ┌──────────┐      ┌──────────┐                                 │
│  │ Facebook │      │ LinkedIn │                                 │
│  │ (API)    │      │ (manual) │                                 │
│  └──────────┘      └──────────┘                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Bảng tổng hợp

| Workflow | Trigger | Tần suất | Mục đích | Cần activate? |
|----------|---------|----------|----------|---------------|
| WF1 | Manual | Khi cần | Tạo 1 bài theo yêu cầu | Không (manual) |
| WF2 | Cron | Mon/Wed/Fri 8AM | Tạo batch 5 bài (multi-platform) | Có |
| WF3 | Cron | Hàng ngày 9AM | Báo cáo tổng hợp | Có |
| WF5 | Cron | Mỗi 5 phút | Giám sát services | Có |
| WF6 | Telegram Trigger | Always on | Bot tương tác 15 commands | Có |
| WF7 | Manual/Cron | Khi cần | Đăng bài Facebook tự động | Có |
| WF8 | Manual/Telegram | Khi cần | Hỗ trợ đăng bài LinkedIn | Không (manual) |
| WF11 | Manual/Telegram | Khi cần | Tạo quiz trắc nghiệm | Không (manual) |
| WF12 | Cron | Mỗi 30 phút | Auto-comment đáp án quiz | Có |
| WF13 | Cron | Hàng ngày 6AM | Thu thập RSS feeds, tạo content | Có |
| WF14 | Cron | Hàng ngày 7AM | Phát hiện trending topics | Có |

### Database Tables liên quan

| Bảng | Workflows sử dụng | Vai trò |
|------|-------------------|---------|
| `content_queue` | WF1, WF2, WF3, WF6, WF7, WF8, WF11, WF12, WF13 | Lưu nội dung, theo dõi status |
| `topic_ideas` | WF2, WF6, WF14 | Nguồn chủ đề cho batch generate |
| `prompts` | WF1, WF2, WF11, WF13 | Template prompt cho AI |
| `workflow_logs` | WF5, WF6 | Log kết quả healthcheck và commands |
| `metrics` | (chưa dùng) | Theo dõi engagement sau khi publish |
| `rss_feeds` | WF13 | Registry các RSS feeds |
| `trending_log` | WF14 | Lưu keywords detected, sources, timestamps |

### Cột mới trong `content_queue`

| Cột | Kiểu | Mô tả | Workflows |
|-----|------|-------|-----------|
| `content_format` | `VARCHAR(20)` | Loại content: `post`, `quiz`, `carousel`, `infographic` | WF11, WF12 |
| `quiz_answer` | `JSONB` | Đáp án + giải thích (JSON) | WF11, WF12 |
| `comment_scheduled_at` | `TIMESTAMP` | Thời gian sẽ auto-comment đáp án | WF11, WF12 |
| `comment_posted` | `BOOLEAN` | Đã comment đáp án chưa | WF12 |
| `content_source` | `VARCHAR(20)` | Nguồn content: `manual`, `rss`, `trending` | WF13, WF14 |
| `source_url` | `TEXT` | Link bài gốc (RSS) | WF13 |
| `source_title` | `TEXT` | Tiêu đề bài gốc | WF13 |

### Content Status Flow

```
                    WF1/WF2 tạo
                        │
draft ──► generating ──► pending_review
                              │
                    ┌─────────┼──────────┐
                    ▼                    ▼
              approved              rejected
                 │                   (kèm lý do)
                 ▼
             scheduled
                 │
                 ▼
             published
            (kèm post_url)
```

---

## Lưu ý bảo mật

### SQL Injection Prevention (PR #2)

Tất cả workflows đã được cập nhật với function `escapeSql()`:
```javascript
function escapeSql(str) {
  if (!str) return '';
  return str.replace(/'/g, "''");
}
```

**Vấn đề gốc:** Nội dung AI tạo ra có thể chứa dấu `'` (ví dụ: "it's", "don't"), gây lỗi SQL hoặc tạo lỗ hổng SQL injection.

**Giải pháp:** Escape tất cả giá trị trước khi INSERT vào database.

### Environment Variables (PR #3)

Docker Compose cần setting:
```yaml
N8N_BLOCK_ENV_ACCESS_IN_NODE=false
```

Điều này cho phép workflows truy cập `$env.TELEGRAM_CHAT_ID`. Nếu thiếu setting này, Telegram notifications sẽ không hoạt động.

---

## FAQ & Xử lý sự cố

### Q: Batch Generate không tạo bài nào?
**A:** Kiểm tra bảng `topic_ideas` có topic nào `used = false` không:
```sql
SELECT COUNT(*) FROM topic_ideas WHERE used = false;
```
Nếu = 0, thêm topic mới.

### Q: Ollama quá chậm (>2 phút)?
**A:**
- Kiểm tra RAM: `docker stats ollama`
- Nếu thiếu RAM, đóng ứng dụng khác
- Giảm context trong prompt (prompt ngắn hơn)
- Xem xét dùng model nhỏ hơn (Mistral 7B)

### Q: Telegram không gửi được tin nhắn?
**A:**
1. Kiểm tra `TELEGRAM_BOT_TOKEN` và `TELEGRAM_CHAT_ID` trong `.env`
2. Kiểm tra `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` trong docker-compose
3. Recreate n8n container sau khi đổi env: `docker-compose up -d --force-recreate n8n`

### Q: Healthcheck báo lỗi liên tục?
**A:**
- Kiểm tra container: `docker ps`
- Restart service lỗi: `docker-compose restart ollama`
- Xem log: `docker-compose logs --tail 50 ollama`

### Q: Nội dung AI tạo ra chất lượng kém?
**A:**
1. Sửa prompt trong bảng `prompts` (thêm hướng dẫn cụ thể hơn)
2. Thêm context chi tiết hơn trong `topic_ideas.notes`
3. Thử model khác: `ollama pull mistral` hoặc `ollama pull qwen2:7b`

### Q: Muốn đổi lịch chạy Batch Generate?
**A:** Sửa cron expression trong node "Mon/Wed/Fri 8AM":
```
0 8 * * 1,3,5    # Mon/Wed/Fri 8AM (hiện tại)
0 8 * * *        # Mỗi ngày 8AM
0 20 * * 0       # Chủ nhật 8PM
30 7 * * 1-5     # Weekdays 7:30AM
```

---

## Tham khảo thêm

| Tài liệu | Đường dẫn |
|-----------|-----------|
| Hướng dẫn cấu hình n8n | `documents/05-guides/n8n-setup-guide.md` |
| Content Pillars | `documents/01-business/social/content-pillars.md` |
| Operations Runbook | `documents/05-guides/runbook.md` |
| Database Schema | `infrastructure/docker/init-db/01-schema.sql` |
| Prompt Templates | `infrastructure/docker/init-db/02-seed-prompts.sql` |
| Telegram Setup | `infrastructure/docker/telegram-config.md` |
| Bugfix History | `documents/04-quality/bugfix-2026-03-19-*.md` |

---

**Tác giả:** VictorAurelius + Claude
**Phiên bản:** 2.0
**Cập nhật:** 2026-03-19
