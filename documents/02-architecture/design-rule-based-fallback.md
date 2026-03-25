# Thiết kế: Rule-Based Fallback (Hoạt động khi không có LLM)

## Vấn đề
Hệ thống 100% phụ thuộc Ollama. Khi Ollama down hoặc quá tải:
- Không tạo được content
- Telegram bot /generate fail
- Batch generate fail
- Toàn bộ pipeline dừng

## Giải pháp
Rule-based engine hoạt động độc lập, không cần LLM:

### Khi Ollama DOWN, hệ thống vẫn:
1. ✅ Gửi daily digest
2. ✅ Handle /status, /pending, /approve, /reject, /topics
3. ✅ Curate content từ RSS (share link + template)
4. ✅ Repost top performing content từ tuần trước
5. ✅ Schedule posts từ approved queue
6. ✅ Auto-comment đáp án quiz (đã có sẵn trong DB)

### Khi Ollama DOWN, hệ thống KHÔNG:
1. ❌ Generate new content (/generate)
2. ❌ Suggest topic ideas (/suggest)
3. ❌ Translate novels

## Implementation

### 1. Ollama Health Check trước mỗi LLM call
```javascript
async function isOllamaAvailable() {
  try {
    const response = await fetch('http://ollama:11434/api/tags', {timeout: 3000});
    return response.ok;
  } catch {
    return false;
  }
}
```

### 2. Fallback Content Templates (no LLM needed)
```javascript
const templates = {
  rss_share: (title, url) =>
    `📰 ${title}\n\n🔗 Đọc thêm: ${url}\n\n💬 Bạn nghĩ sao?\n\n#TechNews #Programming`,

  weekly_best: (title, engagement) =>
    `🔥 Top bài tuần này:\n\n${title}\n\n👍 ${engagement} tương tác\n\n#BestOf #TechVietnam`,

  tip_of_day: (tip) =>
    `💡 Tip of the Day\n\n${tip}\n\n#DevTips #Programming`
};
```

### 3. WF15: Fallback Content Pipeline
```
[Cron hoặc Manual]
    │
    ▼
[Check Ollama Status]
    │
    ├── Online ──► Normal WF1/WF2 flow
    │
    └── Offline ──► [Fallback Mode]
                        │
                        ├── [Get RSS top stories] → Template → Save
                        ├── [Get best posts last week] → Reformat → Save
                        └── [Get approved queue] → Schedule post
```

### 4. Telegram Bot graceful degradation
When /generate is called and Ollama is down:
```
❌ Ollama đang offline.

Các lệnh vẫn hoạt động:
/status, /pending, /approve, /reject, /topics, /view

Content thay thế:
- RSS news đã được thu thập tự động
- Dùng /pending để xem bài có sẵn
```

## Database
```sql
-- Fallback content templates
CREATE TABLE IF NOT EXISTS fallback_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    platform VARCHAR(50),
    template_text TEXT NOT NULL,
    variables TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO fallback_templates (name, platform, template_text, variables) VALUES
('rss_share', 'facebook_tech', '📰 {{title}}\n\n🔗 Đọc thêm: {{url}}\n\n💬 Các bạn dev nghĩ sao về tin này?\n\n#TechNews #DevVietnam', ARRAY['title', 'url']),
('weekly_best', 'linkedin', '🔥 Bài viết được quan tâm nhất tuần:\n\n{{title}}\n\n👍 {{engagement}} tương tác\n\nBạn đã đọc chưa?\n\n#BestOfWeek #TechVietnam', ARRAY['title', 'engagement']),
('tip_template', 'linkedin', '💡 Dev Tip #{{number}}\n\n{{tip}}\n\n💬 Bạn có tip nào hay hơn không?\n\n#DevTips #CodingLife', ARRAY['number', 'tip']),
('quote_template', 'linkedin', '💭 "{{quote}}"\n\n— {{author}}\n\n🤔 Bạn đồng ý không?\n\n#TechQuotes #Motivation', ARRAY['quote', 'author'])
ON CONFLICT DO NOTHING;
```
