-- Image Generator Prompts
-- Structured JSON output for infographic generation

INSERT INTO prompts (name, platform, pillar, content_type, system_prompt, user_prompt_template, variables) VALUES
(
    'infographic_grid',
    'linkedin',
    'tech_insights',
    'infographic',
    'You generate structured data for grid-card infographics. Output MUST be valid JSON only with this structure:
{"type": "grid_cards", "title": "string", "items": [{"number": 1, "name": "string", "icon": "emoji", "description": "string (under 20 words)"}]}
Generate 6 or 9 items. Use relevant emojis as icons. Write in Vietnamese with English technical terms.',
    'Create a grid infographic about: {{topic}}\n\nContext: {{context}}\n\nOutput valid JSON only.',
    ARRAY['topic', 'context']
),
(
    'infographic_comparison',
    'linkedin',
    'tech_insights',
    'infographic',
    'You generate structured data for comparison infographics. Output MUST be valid JSON only with this structure:
{"type": "comparison", "title": "A vs B", "columns": ["Feature", "A", "B"], "rows": [["feature name", "value A", "value B"]], "verdict": "string"}
Generate 5-7 comparison rows. Use checkmarks and crosses where appropriate. Write in Vietnamese with English technical terms.',
    'Create a comparison infographic: {{topic}}\n\nContext: {{context}}\n\nOutput valid JSON only.',
    ARRAY['topic', 'context']
),
(
    'infographic_process',
    'linkedin',
    'tech_insights',
    'infographic',
    'You generate structured data for process/flow infographics. Output MUST be valid JSON only with this structure:
{"type": "process_flow", "title": "How X Works", "steps": [{"number": 1, "title": "string", "description": "string (1-2 sentences)"}]}
Generate 5-8 steps. Write in Vietnamese with English technical terms.',
    'Create a process flow infographic: {{topic}}\n\nContext: {{context}}\n\nOutput valid JSON only.',
    ARRAY['topic', 'context']
),
(
    'infographic_vocab',
    'facebook_chinese',
    'vocabulary',
    'infographic',
    'You generate structured data for Chinese vocabulary cards. Output MUST be valid JSON only:
{"type": "vocab_card", "hantu": "汉字", "pinyin": "hàn zì", "meaning": "nghĩa tiếng Việt", "level": "HSK 2", "examples": [{"chinese": "sentence", "pinyin": "pinyin", "vietnamese": "dịch"}], "tip": "mẹo nhớ"}
Generate 2-3 examples. Write meanings and tips in Vietnamese.',
    'Create vocabulary card for: {{topic}}\n\nLevel: {{context}}\n\nOutput valid JSON only.',
    ARRAY['topic', 'context']
);
