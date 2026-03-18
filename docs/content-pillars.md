# LinkedIn Content Pillars

## Overview

| Pillar | % | Posting Day | Time | Prompt Template |
|--------|---|-------------|------|-----------------|
| Tech Insights | 40% | Monday | 09:00 | `linkedin_tech_insights` |
| Career/Productivity | 30% | Wednesday | 12:00 | `linkedin_career_tips` |
| Product/Project | 20% | Friday (alt) | 17:00 | `linkedin_project_showcase` |
| Personal Stories | 10% | Friday (alt) | 17:00 | `linkedin_personal_story` |

## Posting Schedule

```
Week N:
├── Monday    09:00 → Tech Insights
├── Wednesday 12:00 → Career/Productivity
└── Friday    17:00 → Product/Project

Week N+1:
├── Monday    09:00 → Tech Insights
├── Wednesday 12:00 → Career/Productivity
└── Friday    17:00 → Personal Stories
```

**Why these times?**
- Monday 9AM: Professionals starting the week, checking LinkedIn
- Wednesday 12PM: Lunch break browsing
- Friday 5PM: End-of-week reflection mode

## Pillar 1: Tech Insights (40%)

**Focus:** AI, automation, developer tools, tech trends, best practices

**Topic Examples:**
- AI tools changing developer workflows (Copilot, Claude, etc.)
- Automation tools saving time (n8n, scripting, CI/CD)
- New frameworks and when to adopt them
- Local LLM vs Cloud API trade-offs
- Docker/DevOps tips for developers
- Open source tools worth trying

**Tone:** Analytical, forward-looking, practical
**Hook Types:** Surprising stats, bold predictions, "I just discovered..."

**Example Post Structure:**
```
[Hook: Bold statement or question]

[2-3 key insights with practical examples]

[Actionable takeaway]

[Discussion question]

#hashtags
```

**Sample Topics (ready in DB):**
1. AI đang thay đổi cách developers làm việc
2. 5 automation tools giúp tiết kiệm 10 giờ/tuần
3. Tại sao tôi chuyển từ cloud APIs sang local LLM
4. Docker cho người mới - không khó như bạn nghĩ

## Pillar 2: Career/Productivity (30%)

**Focus:** Practical career tips, productivity hacks, lessons learned

**Topic Examples:**
- Time management techniques (time blocking, deep work)
- Common programming mistakes to avoid
- How to learn new technologies effectively
- Remote work productivity tips
- Code review best practices
- Building good developer habits

**Tone:** Practical, actionable, supportive, relatable
**Hook Types:** "I used to...", relatable scenario, numbered list

**Sample Topics (ready in DB):**
5. Cách organize một ngày làm việc hiệu quả
6. 3 sai lầm khi học programming mà tôi ước biết sớm hơn

## Pillar 3: Product/Project (20%)

**Focus:** Behind-the-scenes, project showcases, technical decisions

**Topic Examples:**
- Building an AI automation system from scratch
- Technical architecture decisions and why
- Challenges faced and solutions found
- MVP development process
- Open source project updates

**Tone:** Authentic, storytelling, educational, showing vulnerability
**Hook Types:** "Here's what happened when...", problem → solution

**Sample Topics (ready in DB):**
7. Từ idea đến MVP trong 2 tuần
8. Behind the scenes: Xây dựng hệ thống content automation

## Pillar 4: Personal Stories (10%)

**Focus:** Career reflections, personal growth, industry observations

**Topic Examples:**
- Career turning points and lessons
- Failures and what they taught
- Observations about the tech industry
- Work-life balance reflections
- Mentorship experiences

**Tone:** Reflective, vulnerable but professional, inspiring
**Hook Types:** Specific moment in time, emotional opener

**Sample Topics (ready in DB):**
9. Khi dự án automation đầu tiên thất bại
10. Remote work 3 năm - những điều không ai nói

## Content Quality Checklist

Before approving ANY post, verify:

### Must Have
- [ ] Compelling hook (first 2 lines grab attention)
- [ ] Clear value for reader (they learn something)
- [ ] Appropriate length (150-200 words)
- [ ] 3-5 relevant hashtags
- [ ] Call-to-action or discussion question

### Must NOT Have
- [ ] "As an AI..." or similar AI artifacts
- [ ] Generic/vague advice without examples
- [ ] More than 5 hashtags
- [ ] Overly promotional tone
- [ ] Grammatical errors in Vietnamese or English

### Nice to Have
- [ ] Personal anecdote or experience
- [ ] Specific numbers or data
- [ ] Actionable tip reader can try today
- [ ] Emoji usage (2-4, not excessive)

## Hashtag Strategy

### Primary Hashtags (use 2-3 per post)
```
#SoftwareDevelopment #TechVietnam #AI
#Automation #DevLife #Programming
```

### Pillar-Specific
```
Tech:        #AITools #DevOps #OpenSource #MachineLearning
Career:      #CareerGrowth #ProductivityTips #CodingLife
Product:     #BuildInPublic #StartupLife #SideProject
Personal:    #TechCareer #LessonsLearned #RemoteWork
```

### Rotate (use 1-2 per post)
```
#LinkedIn #VietnamTech #Developer #Innovation
#LearnToCode #TechTrends #WorkLifeBalance
```

## Content Calendar Template

| Week | Monday (Tech) | Wednesday (Career) | Friday (Mixed) |
|------|--------------|-------------------|----------------|
| 1 | AI tools for devs | Time management | Project update |
| 2 | Local LLM setup | Learning tips | Career reflection |
| 3 | Docker tips | Code review | Behind the scenes |
| 4 | Automation tools | Remote work | Personal story |

## Prompt Optimization Guide

### If AI output is too generic:
1. Add more specific context in the `context` field
2. Include a personal angle or example
3. Specify the target audience more precisely

### If AI output is too long:
1. Reduce word count in prompt (e.g., "100-150 words")
2. Limit to 2 key points instead of 3

### If AI output sounds like AI:
1. Add "Write as if you're sharing with a colleague over coffee"
2. Add "Use conversational Vietnamese, avoid formal tone"
3. Remove or edit any "As someone who..." phrases
