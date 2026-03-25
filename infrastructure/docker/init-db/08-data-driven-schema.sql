-- Data-Driven Content Schema Extension
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS source_url VARCHAR(500);
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS source_title VARCHAR(255);
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS content_source VARCHAR(50) DEFAULT 'manual';
COMMENT ON COLUMN content_queue.content_source IS 'Content origin: manual, rss, trending, quiz';

CREATE INDEX IF NOT EXISTS idx_content_source ON content_queue(content_source);
CREATE INDEX IF NOT EXISTS idx_content_source_url ON content_queue(source_url);

-- RSS feed registry
CREATE TABLE IF NOT EXISTS rss_feeds (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    url VARCHAR(500) NOT NULL UNIQUE,
    platform VARCHAR(50) DEFAULT 'linkedin',
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    last_fetched_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed RSS feeds
INSERT INTO rss_feeds (name, url, platform, category) VALUES
('Hacker News', 'https://hnrss.org/frontpage?count=10', 'linkedin', 'tech_news'),
('Dev.to', 'https://dev.to/feed', 'facebook_tech', 'tutorials'),
('TechCrunch', 'https://techcrunch.com/feed/', 'linkedin', 'tech_news'),
('Reddit Programming', 'https://www.reddit.com/r/programming/.rss', 'facebook_tech', 'community'),
('GitHub Blog', 'https://github.blog/feed/', 'linkedin', 'tech_news')
ON CONFLICT (url) DO NOTHING;

-- Prompt for RSS content
INSERT INTO prompts (name, platform, pillar, content_type, system_prompt, user_prompt_template, variables) VALUES
('rss_linkedin_analysis', 'linkedin', 'tech_insights', 'rss_analysis',
'Bạn là tech analyst viết LinkedIn post dựa trên tin tức thực. Phân tích sâu, đưa ra nhận định cá nhân và takeaway thực tế. Viết Vietnamese + English tech terms. KHÔNG chỉ tóm tắt - phải thêm GIÁ TRỊ.',
'Dựa trên bài viết sau, viết LinkedIn post phân tích:

Tiêu đề: {{topic}}
Tóm tắt: {{context}}

YÊU CẦU:
- Hook mạnh dựa trên tin tức
- Phân tích: tại sao tin này quan trọng
- Nhận định cá nhân
- Takeaway thực tế cho developers
- 150-200 từ
- 3-5 hashtags
- Kết thúc bằng câu hỏi thảo luận',
ARRAY['topic', 'context']),
('rss_facebook_share', 'facebook_tech', 'tech_news', 'rss_share',
'Bạn chia sẻ tin tech thú vị cho cộng đồng dev Việt Nam trên Facebook. Tone casual, có emoji. KHÔNG chỉ copy - phải thêm ý kiến cá nhân.',
'Chia sẻ tin tech này cho cộng đồng:

Tiêu đề: {{topic}}
Tóm tắt: {{context}}

YÊU CẦU:
- Tóm tắt ngắn gọn (2-3 câu)
- Tại sao tin này đáng chú ý
- Ý kiến cá nhân
- 100-150 từ, emoji phù hợp
- 3-5 hashtags',
ARRAY['topic', 'context'])
ON CONFLICT (name) DO NOTHING;
