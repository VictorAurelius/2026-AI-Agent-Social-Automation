# Hướng dẫn chi tiết 4 Workflows n8n

> Tài liệu giải thích từng workflow trong hệ thống AI Agent Social Automation.
> Mỗi workflow được mô tả: mục đích, cách hoạt động, từng node, và lưu ý quan trọng.

**Cập nhật lần cuối:** 2026-03-19

---

## Mục lục

1. [WF1: Content Generate](#wf1-content-generate) - Tạo nội dung thủ công
2. [WF2: Batch Generate](#wf2-batch-generate) - Tạo nội dung theo lịch
3. [WF3: Daily Digest](#wf3-daily-digest) - Báo cáo hàng ngày
4. [WF5: Healthcheck](#wf5-healthcheck) - Giám sát hệ thống
5. [Tổng quan kiến trúc](#tổng-quan-kiến-trúc)
6. [Lưu ý bảo mật](#lưu-ý-bảo-mật)
7. [FAQ & Xử lý sự cố](#faq--xử-lý-sự-cố)

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

## Tổng quan kiến trúc

### Mối quan hệ giữa các Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    HỆ THỐNG WORKFLOW                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐    ┌──────────────┐                      │
│  │ WF1: Manual  │    │ WF2: Batch   │   TẠO NỘI DUNG      │
│  │ Content Gen  │    │ Content Gen  │                      │
│  └──────┬───────┘    └──────┬───────┘                      │
│         │                   │                               │
│         └─────────┬─────────┘                               │
│                   ▼                                         │
│         ┌─────────────────┐                                 │
│         │   PostgreSQL    │                                 │
│         │ content_queue   │    LƯU TRỮ                     │
│         │ topic_ideas     │                                 │
│         │ workflow_logs   │                                 │
│         └────────┬────────┘                                 │
│                  │                                          │
│         ┌────────┴────────┐                                 │
│         ▼                 ▼                                 │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ WF3: Daily   │  │ WF5: Health  │   GIÁM SÁT            │
│  │ Digest       │  │ Check        │                        │
│  └──────┬───────┘  └──────┬───────┘                        │
│         │                 │                                 │
│         └─────────┬───────┘                                 │
│                   ▼                                         │
│         ┌─────────────────┐                                 │
│         │   Telegram Bot  │    THÔNG BÁO                   │
│         └─────────────────┘                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Bảng tổng hợp

| Workflow | Trigger | Tần suất | Mục đích | Cần activate? |
|----------|---------|----------|----------|---------------|
| WF1 | Manual | Khi cần | Tạo 1 bài theo yêu cầu | Không (manual) |
| WF2 | Cron | Mon/Wed/Fri 8AM | Tạo batch 5 bài (multi-platform) | Có |
| WF3 | Cron | Hàng ngày 9AM | Báo cáo tổng hợp | Có |
| WF5 | Cron | Mỗi 5 phút | Giám sát services | Có |

### Database Tables liên quan

| Bảng | Workflows sử dụng | Vai trò |
|------|-------------------|---------|
| `content_queue` | WF1, WF2, WF3 | Lưu nội dung, theo dõi status |
| `topic_ideas` | WF2 | Nguồn chủ đề cho batch generate |
| `prompts` | WF1, WF2 | Template prompt cho AI |
| `workflow_logs` | WF5 | Log kết quả healthcheck |
| `metrics` | (chưa dùng) | Theo dõi engagement sau khi publish |

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
| Hướng dẫn cấu hình n8n | `docs/n8n-setup-guide.md` |
| Content Pillars | `docs/content-pillars.md` |
| Operations Runbook | `docs/runbook.md` |
| Database Schema | `docker/init-db/01-schema.sql` |
| Prompt Templates | `docker/init-db/02-seed-prompts.sql` |
| Telegram Setup | `docker/telegram-config.md` |
| Bugfix History | `docs/bugfix-2026-03-19-*.md` |

---

**Tác giả:** VictorAurelius + Claude
**Phiên bản:** 1.0
**Cập nhật:** 2026-03-19
