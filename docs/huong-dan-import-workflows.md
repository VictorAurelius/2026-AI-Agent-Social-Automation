# Hướng Dẫn Import Workflows vào n8n

## 📋 Tổng Quan

Dự án có **11 workflows** cần import vào n8n để test:

### ✅ Workflows Đã Có (4/11)
1. ✓ WF1: Content Generate
2. ✓ WF2: Batch Generate
3. ✓ WF3: Daily Digest
4. ✓ WF5: Healthcheck

### 🆕 Workflows Cần Import (7/11)
5. ⭕ WF6: Auto Comment (Quiz interaction)
6. ⭕ WF7: Data Collector (RSS/API feeds)
7. ⭕ WF8: Facebook Post
8. ⭕ WF9: LinkedIn Post Helper
9. ⭕ WF10: Quiz Generator
10. ⭕ WF11: Telegram Bot (Interactive)
11. ⭕ WF12: Trending Detector (HN/Reddit/GitHub)

---

## 🚀 Cách 1: Import Nhanh Qua n8n UI

### Bước 1: Mở n8n
```bash
# Đảm bảo n8n đang chạy
bash scripts/healthcheck.sh

# Mở browser
xdg-open http://localhost:5678  # Linux
open http://localhost:5678      # Mac
start http://localhost:5678     # Windows
```

### Bước 2: Import Từng Workflow

Với mỗi workflow chưa có, làm theo các bước sau:

#### 2.1. Click "Add Workflow" (góc trên bên phải)
- Hoặc nhấn phím tắt: `Ctrl + Alt + N`

#### 2.2. Click vào menu "..." (3 chấm) → "Import from File"

#### 2.3. Chọn file workflow:
```
📁 workflows/n8n/
  ├── auto-comment.json         ← WF6: Auto Comment
  ├── data-collector.json       ← WF7: Data Collector
  ├── facebook-post.json        ← WF8: Facebook Post
  ├── linkedin-post-helper.json ← WF9: LinkedIn Post Helper
  ├── quiz-generator.json       ← WF10: Quiz Generator
  ├── telegram-bot.json         ← WF11: Telegram Bot
  └── trending-detector.json    ← WF12: Trending Detector
```

#### 2.4. Click "Import"

#### 2.5. Save workflow (Ctrl + S)

#### 2.6. Lặp lại cho các workflow còn lại

---

## 🔧 Bước 3: Cấu Hình Credentials

Sau khi import, các workflows cần credentials sau:

### ✅ Đã Có (Configured)
- **PostgreSQL**: `PostgreSQL - Social Automation` (ID: 1)
- **Telegram Bot**: `Telegram Bot` (ID: 1)

### ⚙️ Workflows Cần Credentials

| Workflow | Credentials Cần | Đã Có? |
|----------|----------------|---------|
| Content Generate | PostgreSQL, (Ollama HTTP) | ✅ |
| Batch Generate | PostgreSQL, (Ollama HTTP) | ✅ |
| Daily Digest | PostgreSQL, Telegram | ✅ |
| Healthcheck | PostgreSQL, Telegram, (Ollama HTTP) | ✅ |
| Auto Comment | PostgreSQL | ✅ |
| Data Collector | PostgreSQL | ✅ |
| Facebook Post | PostgreSQL, **Facebook API** | ❌ Cần setup |
| LinkedIn Post Helper | **LinkedIn API** | ❌ Cần setup |
| Quiz Generator | PostgreSQL | ✅ |
| Telegram Bot | PostgreSQL, Telegram | ✅ |
| Trending Detector | PostgreSQL, (HTTP requests) | ✅ |

**Lưu ý:** Ollama sử dụng HTTP Request node, không cần credential riêng.

### Cấu Hình Facebook API (Nếu Cần)
```
1. Click "Credentials" (sidebar bên trái, icon chìa khóa)
2. Click "Add Credential"
3. Chọn "Facebook Graph API"
4. Điền:
   - Access Token: [Your Facebook Page Access Token]
   - Page ID: [Your Facebook Page ID]
5. Test connection → Save
```

### Cấu Hình LinkedIn API (Nếu Cần)
```
1. Click "Credentials" (sidebar bên trái)
2. Click "Add Credential"
3. Chọn "LinkedIn OAuth2 API"
4. Làm theo hướng dẫn OAuth2 flow
5. Test → Save
```

---

## ✅ Bước 4: Test Workflows

### Test Manual Workflows

#### WF1: Content Generate
```
1. Mở workflow "WF1: Content Generate"
2. Click "Execute Workflow" (góc trên phải)
3. Kiểm tra:
   ✓ Get Prompt node trả về prompt từ DB
   ✓ Call Ollama node generate content
   ✓ Parse Response node có SQL escaping
   ✓ Insert Content node lưu vào content_queue
4. Check database:
   SELECT * FROM content_queue ORDER BY created_at DESC LIMIT 1;
```

#### WF6: Auto Comment (Quiz)
```
1. Mở workflow "WF6: Auto Comment"
2. Trigger: Webhook hoặc Manual
3. Test với sample quiz response
4. Kiểm tra:
   ✓ Parse Quiz Answer
   ✓ Check Correct Answer
   ✓ Generate Comment (correct/incorrect)
   ✓ Post Comment
```

#### WF7: Data Collector
```
1. Mở workflow "WF7: Data Collector"
2. Execute workflow
3. Kiểm tra:
   ✓ Fetch RSS Feeds (HN, Medium, Dev.to)
   ✓ Parse & Filter
   ✓ Store in data_driven_content table
4. Check DB:
   SELECT * FROM data_driven_content ORDER BY fetched_at DESC LIMIT 5;
```

#### WF10: Quiz Generator
```
1. Mở workflow "WF10: Quiz Generator"
2. Execute với sample topic
3. Kiểm tra:
   ✓ Generate Quiz (4 options, 1 correct)
   ✓ Format JSON properly
   ✓ Store in quiz_content table
4. Verify quiz structure có hợp lệ
```

#### WF12: Trending Detector
```
1. Mở workflow "WF12: Trending Detector"
2. Execute workflow
3. Kiểm tra:
   ✓ Fetch Hacker News frontpage
   ✓ Fetch Reddit r/programming
   ✓ Fetch GitHub trending
   ✓ Merge & rank trending topics
   ✓ Store in trending_topics table
4. Check DB:
   SELECT * FROM trending_topics WHERE detected_at > NOW() - INTERVAL '1 hour';
```

### Test Scheduled Workflows

#### WF2: Batch Generate (Mon/Wed/Fri 8AM)
```
1. Mở workflow
2. Check Schedule Trigger cron: "0 8 * * 1,3,5"
3. Test manually trước
4. Activate workflow (toggle switch góc trên phải)
5. Đợi đến 8AM thứ 2/4/6 để test tự động
```

#### WF3: Daily Digest (Daily 7AM)
```
1. Mở workflow
2. Check Schedule Trigger: "0 7 * * *"
3. Test manually:
   - Kiểm tra có pending content không
   - Kiểm tra digest message format
   - Verify Telegram gửi thành công
4. Activate workflow
```

#### WF5: Healthcheck (Every 5 minutes)
```
1. Mở workflow
2. Check sequential execution: Ollama → Postgres → Redis → Evaluate
3. Execute manually
4. Verify:
   ✓ All services healthy
   ✓ No "node not executed" errors
   ✓ Log success to workflow_logs table
5. Activate workflow
6. Check logs sau 5 phút:
   SELECT * FROM workflow_logs WHERE workflow_name = 'healthcheck' ORDER BY created_at DESC LIMIT 5;
```

---

## 📊 Bước 5: Kiểm Tra Tổng Thể

### Check Workflow List
```bash
curl -s http://localhost:5678/api/v1/workflows | python3 -m json.tool
```

### Check Database
```sql
-- Check content queue
SELECT status, COUNT(*) FROM content_queue GROUP BY status;

-- Check workflow logs
SELECT workflow_name, status, COUNT(*)
FROM workflow_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY workflow_name, status;

-- Check quiz content
SELECT COUNT(*) FROM quiz_content WHERE created_at > NOW() - INTERVAL '7 days';

-- Check trending topics
SELECT source, COUNT(*) FROM trending_topics
WHERE detected_at > NOW() - INTERVAL '24 hours'
GROUP BY source;
```

### Check Active Workflows
```bash
# List tất cả workflows và trạng thái
docker exec n8n n8n list:workflow

# Hoặc qua UI: Check toggle switches màu xanh (active)
```

---

## 🐛 Troubleshooting

### Issue 1: "Credential not found"
**Solution:**
```
1. Mở workflow có lỗi
2. Click vào node màu đỏ
3. Click "Select Credential" → Chọn credential đã setup
4. Save workflow
```

### Issue 2: "Node 'X' hasn't been executed"
**Solution:**
```
Kiểm tra workflow connections:
- Đảm bảo nodes được kết nối đúng thứ tự
- Sequential workflows: A → B → C (không parallel)
- Check execution order trong Settings
```

### Issue 3: "SQL Injection Error"
**Solution:**
```
Workflows đã được fix với SQL escaping:
- content-generate.json: escapeSql() function
- batch-generate.json: escapeSql() function
Nếu vẫn lỗi, check Parse Response node có đúng code không
```

### Issue 4: "Environment variable access denied"
**Solution:**
```bash
# Verify env var setting
docker exec n8n env | grep N8N_BLOCK_ENV_ACCESS_IN_NODE
# Phải trả về: N8N_BLOCK_ENV_ACCESS_IN_NODE=false

# Nếu không, update docker-compose.yml và recreate
bash scripts/recreate-service.sh n8n
```

### Issue 5: Import bị duplicate workflows
**Solution:**
```
1. Vào n8n UI
2. Xóa workflows duplicate (3 dots menu → Delete)
3. Chỉ giữ lại 1 version của mỗi workflow
4. Import các workflows còn thiếu
```

---

## 📝 Checklist Import Hoàn Chỉnh

### Pre-Import
- [ ] n8n đang chạy (check healthcheck)
- [ ] PostgreSQL connected
- [ ] Telegram Bot configured
- [ ] Backup existing workflows (nếu cần)

### Import Workflows (7 new)
- [ ] WF6: Auto Comment
- [ ] WF7: Data Collector
- [ ] WF8: Facebook Post
- [ ] WF9: LinkedIn Post Helper
- [ ] WF10: Quiz Generator
- [ ] WF11: Telegram Bot
- [ ] WF12: Trending Detector

### Configure
- [ ] All credentials assigned
- [ ] Test manual execution cho mỗi workflow
- [ ] Fix any errors
- [ ] Activate scheduled workflows

### Verify
- [ ] Healthcheck running every 5min
- [ ] Database có data mới
- [ ] Telegram notifications working
- [ ] No errors in workflow_logs

---

## 🎯 Recommended Activation Order

1. **Healthcheck** (WF5) - Monitor services first
2. **Data Collector** (WF7) - Collect trending data
3. **Trending Detector** (WF12) - Detect hot topics
4. **Quiz Generator** (WF10) - Generate quiz content
5. **Batch Generate** (WF2) - Generate content regularly
6. **Daily Digest** (WF3) - Send daily summary
7. **Auto Comment** (WF6) - Auto-respond to quiz answers
8. **Telegram Bot** (WF11) - Interactive commands
9. **Facebook/LinkedIn** (WF8/WF9) - Auto-posting (when ready)

---

## 📚 Tài Liệu Liên Quan

- [docs/huong-dan-workflows.md](./huong-dan-workflows.md) - Chi tiết từng workflow
- [docs/mo-ta-tat-ca-tinh-nang.md](./mo-ta-tat-ca-tinh-nang.md) - Mô tả đầy đủ tính năng
- [README.md](../README.md) - Tổng quan dự án

---

**Lưu ý:**
- Import từng workflow một để dễ debug
- Test kỹ trước khi activate scheduled workflows
- Monitor workflow_logs table để track errors
- Facebook/LinkedIn APIs cần setup riêng nếu muốn auto-post
