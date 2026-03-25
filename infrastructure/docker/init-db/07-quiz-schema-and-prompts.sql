-- Quiz Content Type Schema Extension and Prompts
-- Version: 1.0
-- Created: 2026-03-19

-- ============================================
-- SCHEMA CHANGES
-- Add quiz-related columns to content_queue
-- ============================================

ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS content_format VARCHAR(20) DEFAULT 'post';
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS quiz_answer JSONB;
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS comment_scheduled_at TIMESTAMP;
ALTER TABLE content_queue ADD COLUMN IF NOT EXISTS comment_posted BOOLEAN DEFAULT false;

-- Index for auto-comment scheduler
CREATE INDEX IF NOT EXISTS idx_content_quiz_comment
ON content_queue(comment_scheduled_at)
WHERE content_format = 'quiz' AND comment_posted = false AND status = 'published';

COMMENT ON COLUMN content_queue.content_format IS 'Content format: post, quiz, carousel, infographic';
COMMENT ON COLUMN content_queue.quiz_answer IS 'JSON: correct_answer, explanation, wrong_answers, key_concepts';
COMMENT ON COLUMN content_queue.comment_scheduled_at IS 'When to auto-post the answer comment';
COMMENT ON COLUMN content_queue.comment_posted IS 'Whether the answer comment has been posted';

-- ============================================
-- QUIZ PROMPT TEMPLATES
-- ============================================

INSERT INTO prompts (name, platform, pillar, content_type, system_prompt, user_prompt_template, variables) VALUES
(
    'quiz_tech_linkedin',
    'linkedin',
    'tech_insights',
    'quiz',
    'You create technical quiz questions for Vietnamese IT professionals. Output MUST be valid JSON only with this exact structure:
{
  "question_scenario": "A detailed scenario/context (3-5 sentences in Vietnamese with English tech terms)",
  "question": "The specific question being asked",
  "options": {
    "A": "Option A text",
    "B": "Option B text",
    "C": "Option C text",
    "D": "Option D text"
  },
  "correct_answer": "C",
  "explanation": "Detailed explanation of why the correct answer is right (in Vietnamese, 3-5 sentences)",
  "wrong_explanations": {
    "A": "Why A is wrong (1-2 sentences)",
    "B": "Why B is wrong (1-2 sentences)",
    "D": "Why D is wrong (1-2 sentences)"
  },
  "key_concepts": [
    {"name": "Concept Name", "description": "Brief explanation in Vietnamese"},
    {"name": "Concept Name 2", "description": "Brief explanation"}
  ],
  "difficulty": "intermediate",
  "tags": ["AWS", "CloudComputing"]
}
Create realistic, exam-quality questions. The scenario should be practical and detailed.',
    'Create a tech quiz question about: {{topic}}\n\nDifficulty: {{context}}\n\nOutput valid JSON only, no markdown.',
    ARRAY['topic', 'context']
),
(
    'quiz_tech_facebook',
    'facebook_tech',
    'tech_news',
    'quiz',
    'You create fun technical quiz questions for Vietnamese developer community on Facebook. Same JSON structure as LinkedIn quiz but more casual tone, shorter scenario. Use emojis in question text.
{
  "question_scenario": "Fun scenario with emojis (2-3 sentences)",
  "question": "The question",
  "options": {"A": "...", "B": "...", "C": "...", "D": "..."},
  "correct_answer": "B",
  "explanation": "Fun explanation with emojis",
  "wrong_explanations": {"A": "...", "C": "...", "D": "..."},
  "key_concepts": [{"name": "...", "description": "..."}],
  "difficulty": "beginner",
  "tags": ["coding", "quiz"]
}',
    'Create a fun tech quiz about: {{topic}}\n\nDifficulty: {{context}}\n\nOutput valid JSON only.',
    ARRAY['topic', 'context']
),
(
    'quiz_aws',
    'linkedin',
    'tech_insights',
    'quiz',
    'You create AWS certification-style exam questions (SAA-C03 level). Output valid JSON with realistic AWS scenarios involving specific services, configurations, and best practices.
{
  "question_scenario": "Detailed AWS scenario (like real exam, 3-5 sentences)",
  "question": "Which solution meets these requirements with the LEAST operational overhead?",
  "options": {"A": "...", "B": "...", "C": "...", "D": "..."},
  "correct_answer": "C",
  "explanation": "Why C is correct based on AWS best practices",
  "wrong_explanations": {"A": "...", "B": "...", "D": "..."},
  "key_concepts": [
    {"name": "AWS Service", "description": "What it does and when to use it"}
  ],
  "difficulty": "intermediate",
  "tags": ["AWS", "SAA-C03", "CloudArchitecture"]
}
Write in Vietnamese with English AWS service names.',
    'Create an AWS certification quiz about: {{topic}}\n\nServices to cover: {{context}}\n\nOutput valid JSON only.',
    ARRAY['topic', 'context']
),
(
    'quiz_system_design',
    'linkedin',
    'tech_insights',
    'quiz',
    'You create system design quiz questions for software engineers. Focus on scalability, reliability, performance trade-offs. Output valid JSON.
{
  "question_scenario": "System design scenario requiring architectural decisions",
  "question": "Which architecture best addresses these requirements?",
  "options": {"A": "...", "B": "...", "C": "...", "D": "..."},
  "correct_answer": "B",
  "explanation": "Why this architecture is optimal",
  "wrong_explanations": {"A": "...", "C": "...", "D": "..."},
  "key_concepts": [{"name": "Design Pattern", "description": "..."}],
  "difficulty": "advanced",
  "tags": ["SystemDesign", "Architecture"]
}
Write in Vietnamese with English technical terms.',
    'Create a system design quiz about: {{topic}}\n\nFocus: {{context}}\n\nOutput valid JSON only.',
    ARRAY['topic', 'context']
);

-- ============================================
-- QUIZ TOPIC IDEAS
-- ============================================

INSERT INTO topic_ideas (topic, pillar, notes, priority) VALUES
-- AWS Quiz Topics
('AWS S3 Storage Classes - khi nào dùng Standard vs Glacier', 'tech_insights', 'quiz_aws, SAA-C03, storage optimization', 1),
('AWS Lambda vs EC2 vs ECS - chọn compute service nào', 'tech_insights', 'quiz_aws, SAA-C03, compute comparison', 2),
('AWS VPC Security - Security Group vs NACL', 'tech_insights', 'quiz_aws, SAA-C03, networking', 3),
('AWS Data Transfer - Snowball vs DataSync vs Transfer Family', 'tech_insights', 'quiz_aws, SAA-C03, data migration', 4),

-- System Design Quiz Topics
('Design URL Shortener - requirements và trade-offs', 'tech_insights', 'quiz_system_design, classic problem', 5),
('Database Sharding vs Replication - khi nào dùng gì', 'tech_insights', 'quiz_system_design, database scaling', 6),

-- General Tech Quiz Topics
('Git merge vs rebase - scenario nào dùng cái nào', 'tech_news', 'quiz_tech_facebook, beginner friendly', 7),
('REST vs GraphQL vs gRPC - comparison quiz', 'tech_news', 'quiz_tech_facebook, API design', 8),
('Docker container vs VM - bạn chọn gì cho scenario này', 'tech_news', 'quiz_tech_facebook, containers', 9),
('JavaScript: var vs let vs const - tricky cases', 'tech_news', 'quiz_tech_facebook, coding fundamentals', 10);

-- Verify
DO $$
DECLARE
    quiz_prompts INTEGER;
    quiz_topics INTEGER;
BEGIN
    SELECT COUNT(*) INTO quiz_prompts FROM prompts WHERE content_type = 'quiz';
    SELECT COUNT(*) INTO quiz_topics FROM topic_ideas WHERE notes LIKE 'quiz_%';
    RAISE NOTICE 'Quiz data loaded: % prompts, % topics', quiz_prompts, quiz_topics;
END $$;
