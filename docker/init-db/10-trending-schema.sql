-- Trending topic detection schema
-- Used by WF14: Trending Detector

CREATE TABLE IF NOT EXISTS trending_log (
    id SERIAL PRIMARY KEY,
    keyword VARCHAR(100),
    sources TEXT[],           -- e.g. ARRAY['hackernews', 'reddit', 'github']
    source_count INTEGER,
    sample_titles TEXT[],
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    converted_to_topic BOOLEAN DEFAULT false
);

-- Index for quick lookup of recent trending keywords
CREATE INDEX IF NOT EXISTS idx_trending_log_detected_at
    ON trending_log (detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_trending_log_keyword
    ON trending_log (keyword);
