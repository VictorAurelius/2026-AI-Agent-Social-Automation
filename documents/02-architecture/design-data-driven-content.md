# Thiết kế: Data-Driven Content từ RSS Feeds

## Tổng quan
Hiện tại hệ thống tạo content bằng cách cho LLM "tự nghĩ" từ topic ideas. Content thường generic, không timely, thiếu data thực tế.

Cải tiến: Thu thập tin tức thực từ RSS feeds → Ollama phân tích + viết bài dựa trên data thật → Content có giá trị hơn, timely hơn.

## Kiến trúc

```
TRƯỚC: Topic idea → Ollama tự nghĩ → Generic content
SAU:   RSS feeds → Filter → Ollama phân tích + viết → Data-backed content
```

## Nguồn RSS miễn phí

| Nguồn | URL | Loại | Platform |
|-------|-----|------|----------|
| Hacker News | hnrss.org/frontpage | Tech news | LinkedIn, FB Tech |
| GitHub Trending | github-trending-api | New repos/tools | FB Tech |
| Dev.to | dev.to/feed | Dev articles | LinkedIn, FB Tech |
| TechCrunch | feeds.feedburner.com/TechCrunch | Startup news | LinkedIn |
| Reddit r/programming | reddit.com/r/programming/.json | Community | FB Tech |
| Product Hunt | producthunt.com/feed | New products | FB Tech |

## WF13: Data Collector

### Flow
```
[Cron Daily 6AM]
    │
    ▼
[Fetch RSS Feeds] ── Parallel fetch 5+ feeds
    │
    ▼
[Parse & Filter] ── Extract title, link, summary
    │                 Filter: relevance score, duplicates
    ▼
[Select Top Stories] ── Pick 3-5 most relevant
    │
    ▼
[Generate Content] ── For each story:
    │                   Ollama summarize + add insights
    ▼
[Save to DB] ── content_queue with source_url
    │
    ▼
[Telegram] ── "📰 3 trending topics found, content generated"
```

### Database changes
```sql
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS source_url VARCHAR(500);
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS source_title VARCHAR(255);
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS content_source VARCHAR(50) DEFAULT 'manual';
-- Values: 'manual', 'rss', 'trending', 'quiz'
```

### Prompt for RSS-based content
System: "You are a tech content creator. Based on the following news article, write an engaging social media post with your analysis and insights. Add value beyond just summarizing."
User: "Article: [title]\nSummary: [description]\nSource: [link]\n\nWrite a [platform] post about this. Include your opinion and practical takeaway."

### Schedule
- 6:00 AM: Fetch RSS → Generate content
- 9:00 AM: Daily digest includes new RSS-based content
- WF2 Batch: Can also pick RSS-generated topics

## Lợi ích
1. Content dựa trên tin thật, timely
2. Luôn có topic mới (không hết ideas)
3. Source links tăng credibility
4. Tự động, không cần thêm topic thủ công

## Risks
- RSS feed down/changed → Retry + multiple sources
- Duplicate content → Check source_url unique
- Quality varies → Human review vẫn 100%
