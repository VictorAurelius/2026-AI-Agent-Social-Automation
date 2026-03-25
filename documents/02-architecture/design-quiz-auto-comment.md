# Thiết kế: Tech Quiz Content + Auto-Comment Workflow

**Created:** 2026-03-19
**Status:** Proposed
**Goal:** Thêm content type "Tech Quiz" và workflow tự động comment đáp án

---

## 1. Vấn đề

Content dạng quiz/câu hỏi thi (AWS, Azure, coding challenges) có engagement rất cao:
- Comment rate cao: Mọi người tranh luận đáp án
- Save rate cao: Người xem save để ôn thi
- Share rate cao: Tag bạn bè cùng giải

Hiện tại hệ thống chỉ tạo content dạng bài viết, chưa có:
1. Content type quiz/exam question
2. Workflow auto-comment đáp án sau N giờ

## 2. Content Type: Tech Quiz

### Cấu trúc Quiz Post

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

### Sau 4 giờ - Auto-Comment:

```
✅ Đáp án: C

📖 Giải thích:
[Giải thích chi tiết tại sao C đúng]
[Phân tích tại sao A, B, D sai]

💡 Key concepts:
- Concept 1: giải thích ngắn
- Concept 2: giải thích ngắn

🔖 Save bài này để ôn thi!
```

### Các chủ đề Quiz

| Chủ đề | Platform | Audience |
|--------|----------|----------|
| AWS Certification (SAA, SAP) | LinkedIn, FB Tech | Cloud engineers |
| System Design | LinkedIn, FB Tech | Software engineers |
| Coding Challenges | FB Tech | Developers |
| Database/SQL | LinkedIn, FB Tech | Backend devs |
| DevOps/Docker/K8s | LinkedIn, FB Tech | DevOps engineers |
| Networking basics | FB Tech | IT professionals |

## 3. Database Changes

### Thêm cột cho quiz data

```sql
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS content_format VARCHAR(20) DEFAULT 'post';
-- Giá trị: 'post', 'quiz', 'carousel', 'infographic'

ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS quiz_answer TEXT;
-- Lưu đáp án + giải thích (JSON)

ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS comment_scheduled_at TIMESTAMP;
-- Thời gian sẽ auto-comment đáp án

ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS comment_posted BOOLEAN DEFAULT false;
-- Đã comment đáp án chưa
```

### Quiz answer JSON format:
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
    {"name": "AWS Snowball", "description": "Thiết bị transfer data offline..."},
    {"name": "AWS Glue", "description": "Serverless ETL service..."}
  ]
}
```

## 4. Prompt Templates

### Quiz Generator Prompt
Ollama tạo quiz + đáp án cùng lúc, lưu riêng.

### Quiz Answer Prompt
Ollama giải thích chi tiết cho đáp án, phân tích từng option.

## 5. WF11: Quiz Content Generator

```
[Trigger: Manual hoặc Telegram /quiz <topic>]
       │
       ▼
[Get Quiz Prompt] ── Lấy prompt template
       │
       ▼
[Call Ollama] ── Generate quiz JSON (câu hỏi + 4 options + đáp án + giải thích)
       │
       ▼
[Parse Quiz] ── Tách: question_text (post) + answer_data (comment)
       │
       ▼
[Save to DB] ── INSERT content_queue:
       │          content_format = 'quiz'
       │          generated_content = question text
       │          quiz_answer = answer JSON
       │          comment_scheduled_at = NOW() + 4 hours
       ▼
[Telegram] ── "Quiz created! Review and approve"
```

## 6. WF12: Auto-Comment Scheduler

```
[Cron: Every 30 minutes]
       │
       ▼
[Get Due Comments] ── SELECT from content_queue WHERE:
       │                status = 'published'
       │                content_format = 'quiz'
       │                comment_posted = false
       │                comment_scheduled_at <= NOW()
       ▼
[Has Items?]
       │
       ├── YES ──► [Loop Each]
       │               │
       │               ▼
       │          [Format Comment] ── Build comment text from quiz_answer JSON
       │               │
       │               ▼
       │          [Post Comment] ── Facebook: POST /{post-id}/comments
       │               │             LinkedIn: manual via Telegram
       │               ▼
       │          [Mark Done] ── UPDATE comment_posted = true
       │               │
       │               ▼
       │          [Telegram] ── "Đã comment đáp án cho quiz #ID"
       │
       └── NO ──► (end, no action)
```

## 7. Facebook Comment API

```
POST https://graph.facebook.com/v18.0/{post-id}/comments
Body: {
  "message": "✅ Đáp án: C\n\n📖 Giải thích:\n...",
  "access_token": "PAGE_TOKEN"
}
```

**Permissions cần:** `pages_manage_engagement`

## 8. Telegram Bot Commands

| Lệnh | Mô tả |
|-------|--------|
| `/quiz <topic>` | Tạo quiz về chủ đề |
| `/quiz_aws` | Tạo quiz AWS certification |
| `/quiz_system` | Tạo quiz System Design |
| `/quiz_answer <id>` | Xem đáp án (trước khi publish) |

## 9. Kế hoạch triển khai

### Phase 1: Quiz Generation (Week 1)
- Schema migration (thêm cột quiz)
- Quiz prompt templates
- WF11 workflow
- Telegram /quiz command

### Phase 2: Auto-Comment (Week 2)
- WF12 scheduler workflow
- Facebook comment integration
- LinkedIn: manual comment via Telegram

### Phase 3: Optimization (Week 3)
- A/B test comment timing (4h vs 6h vs 12h)
- Track engagement difference quiz vs normal post
- Add more quiz categories

## 10. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Ollama quiz quality | High | Detailed prompts with examples, human review |
| Wrong answers posted | High | Always preview via /quiz_answer before approve |
| Facebook comment spam flag | Medium | Limit 1 comment/post, natural language |
| LinkedIn no comment API | Low | Use Telegram for manual commenting |
