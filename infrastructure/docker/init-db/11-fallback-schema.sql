-- ============================================================
-- Fallback Templates Schema
-- Rule-based fallback khi Ollama không khả dụng
-- ============================================================

-- Bảng lưu template cho fallback content (không cần LLM)
CREATE TABLE IF NOT EXISTS fallback_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    platform VARCHAR(50),
    template_text TEXT NOT NULL,
    variables TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed data: các template mặc định
INSERT INTO fallback_templates (name, platform, template_text, variables) VALUES
('rss_share', 'facebook_tech', E'📰 {{title}}\n\n🔗 Đọc thêm: {{url}}\n\n💬 Các bạn dev nghĩ sao về tin này?\n\n#TechNews #DevVietnam', ARRAY['title', 'url']),
('weekly_best', 'linkedin', E'🔥 Bài viết được quan tâm nhất tuần:\n\n{{title}}\n\n👍 {{engagement}} tương tác\n\nBạn đã đọc chưa?\n\n#BestOfWeek #TechVietnam', ARRAY['title', 'engagement']),
('tip_template', 'linkedin', E'💡 Dev Tip #{{number}}\n\n{{tip}}\n\n💬 Bạn có tip nào hay hơn không?\n\n#DevTips #CodingLife', ARRAY['number', 'tip']),
('quote_template', 'linkedin', E'💭 "{{quote}}"\n\n— {{author}}\n\n🤔 Bạn đồng ý không?\n\n#TechQuotes #Motivation', ARRAY['quote', 'author'])
ON CONFLICT DO NOTHING;
