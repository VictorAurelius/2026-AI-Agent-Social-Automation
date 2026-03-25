-- Carousel Content Generation Prompt
-- Requires structured JSON output from Ollama

INSERT INTO prompts (name, platform, pillar, content_type, system_prompt, user_prompt_template, variables) VALUES
(
    'carousel_linkedin',
    'linkedin',
    'tech_insights',
    'carousel',
    'You generate structured carousel content. Output MUST be valid JSON only - no markdown, no explanation, no code blocks. Use this exact structure:
{"title": "string", "hook": "string", "slides": [{"number": 1, "heading": "string", "subheading": "string", "body": "string (2-3 sentences)", "highlight": "string (key takeaway)"}], "cta": "Follow @VictorAurelius", "hashtags": ["#tag1", "#tag2"]}
Generate exactly 5 slides. Write in Vietnamese with English technical terms. Keep each slide body under 50 words.',
    'Create a carousel about: {{topic}}\n\nContext: {{context}}\n\nOutput valid JSON only.',
    ARRAY['topic', 'context']
),
(
    'carousel_facebook',
    'facebook_tech',
    'tech_news',
    'carousel',
    'You generate structured carousel content for Facebook. Output MUST be valid JSON only. Use this exact structure:
{"title": "string", "hook": "string", "slides": [{"number": 1, "heading": "string", "subheading": "string", "body": "string (2-3 sentences)", "highlight": "string"}], "cta": "Follow page", "hashtags": ["#tag1", "#tag2"]}
Generate exactly 5 slides. Write in Vietnamese, casual tone with emojis. Keep each slide body under 50 words.',
    'Create a Facebook carousel about: {{topic}}\n\nContext: {{context}}\n\nOutput valid JSON only.',
    ARRAY['topic', 'context']
);
