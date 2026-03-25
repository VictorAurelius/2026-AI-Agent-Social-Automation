-- Prompt for AI-powered topic suggestion
INSERT INTO prompts (name, platform, pillar, content_type, system_prompt, user_prompt_template, variables) VALUES
(
    'suggest_ideas_linkedin',
    'linkedin',
    'tech_insights',
    'suggestion',
    'You are a social media strategist for Vietnamese IT professionals. Suggest creative, engaging topic ideas that would perform well on LinkedIn. Output as a numbered list with brief descriptions. Write in Vietnamese with English technical terms.',
    'Suggest 5 LinkedIn post topic ideas about: {{topic}}\n\nPillar focus: {{context}}\n\nFor each idea, include:\n- Topic title\n- Why it would engage the audience\n- Suggested pillar (tech_insights, career_productivity, product_project, personal_stories)\n\nOutput as numbered list.',
    ARRAY['topic', 'context']
),
(
    'suggest_ideas_facebook',
    'facebook_tech',
    'tech_news',
    'suggestion',
    'You are a Facebook content strategist for Vietnamese developer community. Suggest fun, shareable topic ideas. Output as numbered list. Write in Vietnamese.',
    'Suggest 5 Facebook post topic ideas about: {{topic}}\n\nPillar focus: {{context}}\n\nFor each idea, include:\n- Topic title\n- Content type (news, tutorial, tool, discussion)\n- Why it would get shares/comments\n\nOutput as numbered list.',
    ARRAY['topic', 'context']
);
