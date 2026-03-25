# Thiết kế: Tự động Phát hiện Topic Trending

## Vấn đề

Topic ideas hiện tại thêm thủ công hoặc AI suggest random, không phản ánh xu hướng thực tế. Content không timely.

## Giải pháp

Cross-reference nhiều nguồn để phát hiện topic đang trending:

- Topic xuất hiện ở 2+ nguồn = trending
- Auto-add vào topic_ideas với priority cao
- Telegram alert: "🔥 Trending topic detected"

## Nguồn detection

| Nguồn | Method | Check |
|-------|--------|-------|
| Hacker News | API top stories | Title keywords |
| GitHub Trending | Scrape/API | Repo descriptions |
| Reddit r/programming | JSON API | Hot post titles |
| Dev.to | RSS/API | Popular articles |
| Google Trends | Unofficial API | Search volume |

## WF14: Trending Detector

### Flow

```
[Cron Daily 7AM]
    │
    ▼
[Fetch Sources] ── Parallel: HN + GitHub + Reddit
    │
    ▼
[Extract Keywords] ── NLP-lite: extract tech terms from titles
    │
    ▼
[Cross-Reference] ── Count term frequency across sources
    │                  Term in 2+ sources = trending
    ▼
[Filter Existing] ── Check not already in topic_ideas
    │
    ▼
[Add to Queue] ── INSERT topic_ideas (priority=1, notes="trending")
    │
    ▼
[Telegram] ── "🔥 3 trending topics detected: [list]"
```

### Keyword extraction (Code node)

```javascript
// Simple keyword extraction from titles
function extractKeywords(titles) {
  const techTerms = titles
    .join(' ')
    .toLowerCase()
    .match(/\b(ai|llm|gpt|claude|docker|kubernetes|rust|python|react|vue|nextjs|typescript|golang|postgres|redis|aws|azure|gcp|devops|cicd|microservices|serverless|blockchain|web3|api|graphql|grpc)\b/gi);

  // Count frequency
  const freq = {};
  techTerms.forEach(t => { freq[t.toLowerCase()] = (freq[t.toLowerCase()] || 0) + 1; });

  // Sort by frequency
  return Object.entries(freq)
    .sort((a,b) => b[1] - a[1])
    .slice(0, 10);
}
```

### Cross-reference logic

```javascript
// Topic trending if mentioned in 2+ sources
const trending = allKeywords.filter(kw => {
  const sources = Object.keys(sourceKeywords).filter(src =>
    sourceKeywords[src].includes(kw)
  );
  return sources.length >= 2;
});
```

## Database

```sql
CREATE TABLE IF NOT EXISTS trending_log (
    id SERIAL PRIMARY KEY,
    keyword VARCHAR(100),
    sources TEXT[], -- ['hackernews', 'reddit', 'github']
    source_count INTEGER,
    sample_titles TEXT[],
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    converted_to_topic BOOLEAN DEFAULT false
);
```
