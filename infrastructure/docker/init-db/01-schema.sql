-- AI Agent Personal Database Schema
-- Version: 1.0
-- Created: 2026-03-16
-- This file runs automatically when PostgreSQL container starts

-- ============================================
-- CONTENT QUEUE TABLE
-- Main table for content lifecycle management
-- ============================================
CREATE TABLE content_queue (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    platform VARCHAR(50) NOT NULL DEFAULT 'linkedin',
    content_type VARCHAR(50),
    pillar VARCHAR(50),
    status VARCHAR(20) DEFAULT 'draft'
        CHECK (status IN ('draft', 'generating', 'pending_review', 'approved', 'rejected', 'scheduled', 'published')),
    original_prompt TEXT,
    generated_content TEXT,
    final_content TEXT,
    rejection_reason TEXT,
    scheduled_date TIMESTAMP,
    published_date TIMESTAMP,
    post_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE content_queue IS 'Main content lifecycle management table';
COMMENT ON COLUMN content_queue.status IS 'draft → generating → pending_review → approved/rejected → scheduled → published';
COMMENT ON COLUMN content_queue.pillar IS 'Content pillar: tech_insights, career_productivity, product_project, personal_stories';

-- ============================================
-- PROMPTS LIBRARY TABLE
-- Store prompt templates for content generation
-- ============================================
CREATE TABLE prompts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    platform VARCHAR(50) DEFAULT 'linkedin',
    pillar VARCHAR(50),
    content_type VARCHAR(50),
    system_prompt TEXT NOT NULL,
    user_prompt_template TEXT NOT NULL,
    variables TEXT[],
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE prompts IS 'Prompt templates library for AI content generation';
COMMENT ON COLUMN prompts.variables IS 'Array of variable names used in template, e.g., {topic, context}';

-- ============================================
-- METRICS TABLE
-- Track engagement metrics for published content
-- ============================================
CREATE TABLE metrics (
    id SERIAL PRIMARY KEY,
    content_id INTEGER REFERENCES content_queue(id) ON DELETE CASCADE,
    platform VARCHAR(50),
    impressions INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    engagement_rate DECIMAL(5,2),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE metrics IS 'Engagement metrics tracking for published content';

-- ============================================
-- WORKFLOW LOGS TABLE
-- Log automation workflow executions
-- ============================================
CREATE TABLE workflow_logs (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(100) NOT NULL,
    execution_id VARCHAR(100),
    status VARCHAR(20) CHECK (status IN ('started', 'success', 'error', 'warning')),
    message TEXT,
    details JSONB,
    execution_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE workflow_logs IS 'Automation workflow execution logs';

-- ============================================
-- TOPIC IDEAS TABLE
-- Content planning and topic management
-- ============================================
CREATE TABLE topic_ideas (
    id SERIAL PRIMARY KEY,
    topic VARCHAR(255) NOT NULL,
    pillar VARCHAR(50),
    notes TEXT,
    priority INTEGER DEFAULT 5 CHECK (priority >= 1 AND priority <= 10),
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE topic_ideas IS 'Topic ideas for content planning';
COMMENT ON COLUMN topic_ideas.priority IS '1 = highest priority, 10 = lowest';

-- ============================================
-- INDEXES
-- Optimize query performance
-- ============================================
CREATE INDEX idx_content_status ON content_queue(status);
CREATE INDEX idx_content_platform ON content_queue(platform);
CREATE INDEX idx_content_scheduled ON content_queue(scheduled_date);
CREATE INDEX idx_content_pillar ON content_queue(pillar);
CREATE INDEX idx_content_created ON content_queue(created_at DESC);

CREATE INDEX idx_prompts_active ON prompts(is_active);
CREATE INDEX idx_prompts_pillar ON prompts(pillar);
CREATE INDEX idx_prompts_platform ON prompts(platform);

CREATE INDEX idx_metrics_content ON metrics(content_id);
CREATE INDEX idx_metrics_recorded ON metrics(recorded_at DESC);

CREATE INDEX idx_logs_workflow ON workflow_logs(workflow_name);
CREATE INDEX idx_logs_status ON workflow_logs(status);
CREATE INDEX idx_logs_created ON workflow_logs(created_at DESC);

CREATE INDEX idx_topics_unused ON topic_ideas(used) WHERE used = false;
CREATE INDEX idx_topics_priority ON topic_ideas(priority) WHERE used = false;

-- ============================================
-- TRIGGERS
-- Auto-update updated_at timestamp
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_content_queue_updated_at
    BEFORE UPDATE ON content_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prompts_updated_at
    BEFORE UPDATE ON prompts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS
-- Useful queries as views
-- ============================================
CREATE VIEW v_content_stats AS
SELECT
    status,
    COUNT(*) as count,
    platform
FROM content_queue
GROUP BY status, platform
ORDER BY platform, status;

CREATE VIEW v_pending_review AS
SELECT
    id,
    title,
    pillar,
    content_type,
    created_at,
    LENGTH(generated_content) as content_length
FROM content_queue
WHERE status = 'pending_review'
ORDER BY created_at DESC;

CREATE VIEW v_unused_topics AS
SELECT
    id,
    topic,
    pillar,
    priority,
    notes
FROM topic_ideas
WHERE used = false
ORDER BY priority ASC, created_at ASC;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Schema created successfully!';
END $$;
