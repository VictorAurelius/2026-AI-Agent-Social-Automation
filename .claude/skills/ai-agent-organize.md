# File Organization Skill - AI Agent Project

**Adapted from:** organize.md (KiteClass project)

## Purpose
Automatically determine correct location for files/folders in AI Agent Social Automation project.

## Project Structure Rules

### Strategy Documents (`documents/strategies/`)
**What belongs here**:
- Platform-specific strategies (LinkedIn, Facebook Tech, Facebook Chinese)
- Content pillars documentation
- Posting schedules
- Platform-specific tactics

**Naming conventions**:
- strategy.md: Main platform strategy
- content-pillars.md: Content pillar breakdown
- posting-schedule.md: Publishing schedule
- monetization.md: Revenue strategy

**Examples**:
- documents/strategies/linkedin/strategy.md
- documents/strategies/facebook-tech/content-pillars.md

---

### Tech Stack Documentation (`documents/tech-stack/`)
**What belongs here**:
- Tool comparisons and evaluations
- API setup guides
- Integration documentation
- Cost analysis

**Naming conventions**:
- overview.md: Tech stack overview
- {tool1}-vs-{tool2}.md: Tool comparisons
- {service}-setup.md: Setup guides
- cost-analysis.md: Cost breakdown

**Examples**:
- documents/tech-stack/overview.md
- documents/tech-stack/make-vs-n8n.md
- documents/tech-stack/claude-api-setup.md

---

### Workflow Documentation (`documents/workflows/`)
**What belongs here**:
- Workflow process documentation
- Automation logic explanations
- Integration patterns
- Troubleshooting guides

**Naming conventions**:
- {process}-workflow.md: Workflow descriptions
- {integration}-guide.md: Integration guides

**Examples**:
- documents/workflows/content-generation.md
- documents/workflows/publishing.md
- documents/workflows/analytics.md

---

### Automation Workflow Exports (`workflows/`)
**What belongs here**:
- Make.com workflow JSON exports
- n8n workflow JSON exports
- Workflow backup files

**Structure**:
- `make.com/`: Make.com workflow files
- `n8n/`: n8n workflow files

**Naming conventions**:
- {platform}-{function}.json: Workflow exports
- {platform}-{function}-v{version}.json: Versioned workflows

**Examples**:
- workflows/make.com/linkedin-auto-post.json
- workflows/n8n/facebook-content-generator.json
- workflows/make.com/notion-sync-v2.json

---

### AI Prompt Templates (`prompts/`)
**What belongs here**:
- Platform-specific AI prompts
- System prompts
- Content generation templates
- Prompt variations

**Structure**:
- `linkedin/`: LinkedIn prompts
- `facebook-tech/`: Facebook Tech prompts
- `facebook-chinese/`: Facebook Chinese prompts

**Naming conventions**:
- {content-type}.txt: Basic prompt templates
- {content-type}-{variant}.txt: Prompt variations
- system-prompt.txt: System prompts

**Examples**:
- prompts/linkedin/thought-leadership.txt
- prompts/facebook-tech/tech-news-short.txt
- prompts/facebook-chinese/vocabulary-hsk3.txt

---

### Design & Content Templates (`templates/`)
**What belongs here**:
- Canva design templates
- Content structure templates
- Post format examples

**Structure**:
- `canva/`: Design templates and exports
- `content/`: Content structure templates

**Naming conventions**:
- {platform}-{type}.{ext}: Template files
- {platform}-{type}-example.md: Example posts

**Examples**:
- templates/canva/linkedin-banner.png
- templates/content/linkedin-4-pillars.md
- templates/content/facebook-tech-tutorial-format.md

---

### Utility Scripts (`scripts/`)
**What belongs here**:
- Setup scripts
- Testing scripts
- Backup utilities
- Data export scripts

**Structure**:
- `setup/`: Setup and initialization scripts
- `testing/`: Testing and validation scripts
- `utils/`: General utilities

**Naming conventions**:
- setup-{service}.sh: Setup scripts
- test-{component}.sh: Testing scripts
- {action}-{target}.sh: Utility scripts
- backup-{resource}.sh: Backup scripts

**Examples**:
- scripts/setup/setup-make.sh
- scripts/testing/test-claude-api.sh
- scripts/utils/backup-workflows.sh
- scripts/utils/export-notion.sh

---

### Archived Documents (`documents/archived/`)
**What belongs here**:
- Old/deprecated strategies
- Outdated documentation
- Historical reference materials
- Deprecated templates

**Examples**:
- documents/archived/old-linkedin-strategy.md
- documents/archived/action-1.md

---

### Root-Level Files
**What belongs here**:
- README.md: Project overview
- SKILLS-README.md: Skills quick reference
- .gitignore: Git ignore patterns
- .env.example: Environment variables template
- LICENSE: License file

**Why root**: High discoverability, project-level configuration

---

## Decision Algorithm

Given a file/folder, suggest location based on:

### 1. File Extension Analysis
- `.md` (strategy) → documents/strategies/{platform}/
- `.md` (tech docs) → documents/tech-stack/
- `.md` (workflow docs) → documents/workflows/
- `.md` (templates) → templates/content/
- `.json` (workflows) → workflows/{make.com,n8n}/
- `.txt` (prompts) → prompts/{platform}/
- `.sh` (scripts) → scripts/{category}/
- `.png`, `.jpg` (design) → templates/canva/
- `.env` → root (add to .gitignore)

### 2. Name Pattern Analysis
- `*-strategy.md` → documents/strategies/{platform}/
- `*-setup.md` → documents/tech-stack/
- `*-vs-*.md` → documents/tech-stack/
- `linkedin-*.json` → workflows/{make.com,n8n}/
- `facebook-*.json` → workflows/{make.com,n8n}/
- `notion-*.json` → workflows/{make.com,n8n}/
- `*-prompt.txt` → prompts/{platform}/
- `setup-*.sh` → scripts/setup/
- `test-*.sh` → scripts/testing/
- `backup-*.sh` → scripts/utils/
- `export-*.sh` → scripts/utils/

### 3. Content Analysis (if available)
- Contains platform strategy → documents/strategies/{platform}/
- Contains workflow logic → workflows/{make.com,n8n}/
- Contains AI prompt → prompts/{platform}/
- Contains bash commands → scripts/{category}/
- Contains cost analysis → documents/tech-stack/

### 4. Platform Context
- LinkedIn-related → linkedin/ subdirectory
- Facebook Tech-related → facebook-tech/ subdirectory
- Facebook Chinese-related → facebook-chinese/ subdirectory
- General/cross-platform → root of category

## Output Format

When suggesting location:
```
📍 Suggested Location: prompts/linkedin/product-showcase.txt

Reasoning:
✅ File extension: .txt (prompt template)
✅ Name pattern: LinkedIn-related content
✅ Platform: LinkedIn-specific prompt
✅ Existing pattern: Other LinkedIn prompts in prompts/linkedin/

Alternative considerations:
⚠️ Could be in templates/content/, but prompts/ is for AI templates
⚠️ Ensure prompt follows AI template format

Recommendation: Place in prompts/linkedin/ and reference in:
- documents/strategies/linkedin/content-pillars.md
- SKILLS-INDEX.md (if core prompt)
```

## Implementation Steps

When user confirms:
1. Create directory if needed: `mkdir -p [directory]`
2. Move/create file: `touch [destination]` or `git mv [source] [destination]`
3. Update permissions if script: `chmod +x [destination]`
4. Search for references: `grep -r "[filename]" .`
5. Update found references
6. Commit changes with descriptive message

## Examples

### Example 1: New LinkedIn prompt
```
Input: thought-leadership-tech.txt (prompt)
Output: prompts/linkedin/thought-leadership-tech.txt
Reason: LinkedIn-specific AI prompt template
```

### Example 2: New Make.com workflow
```
Input: facebook-scheduler.json (workflow export)
Output: workflows/make.com/facebook-scheduler.json
Reason: Make.com workflow for Facebook automation
```

### Example 3: New strategy document
```
Input: facebook-chinese-hsk-strategy.md (strategy)
Output: documents/strategies/facebook-chinese/hsk-content-strategy.md
Reason: Platform-specific strategy for Facebook Chinese page
```

### Example 4: New setup script
```
Input: setup-claude-api.sh (script)
Output: scripts/setup/setup-claude-api.sh
Reason: Setup script for Claude API integration
```

### Example 5: Content template
```
Input: linkedin-4-pillars-examples.md (template)
Output: templates/content/linkedin-4-pillars-examples.md
Reason: Content structure template for LinkedIn
```

### Example 6: Tech comparison
```
Input: claude-vs-gpt4.md (comparison)
Output: documents/tech-stack/claude-vs-gpt4.md
Reason: AI tool comparison for tech stack decision
```

## Platform-Specific Routing

### LinkedIn Files
- Strategies → `documents/strategies/linkedin/`
- Prompts → `prompts/linkedin/`
- Workflows → `workflows/{make.com,n8n}/linkedin-*.json`
- Templates → `templates/content/linkedin-*.md`

### Facebook Tech Files
- Strategies → `documents/strategies/facebook-tech/`
- Prompts → `prompts/facebook-tech/`
- Workflows → `workflows/{make.com,n8n}/facebook-tech-*.json`
- Templates → `templates/content/facebook-tech-*.md`

### Facebook Chinese Files
- Strategies → `documents/strategies/facebook-chinese/`
- Prompts → `prompts/facebook-chinese/`
- Workflows → `workflows/{make.com,n8n}/facebook-chinese-*.json`
- Templates → `templates/content/facebook-chinese-*.md`

### Cross-Platform/General Files
- Workflows → `workflows/{make.com,n8n}/notion-*.json`, `*/claude-*.json`
- Scripts → `scripts/{category}/` (no platform prefix needed)
- Tech docs → `documents/tech-stack/` (applies to all platforms)

## Anti-Patterns (What NOT to do)

❌ **Don't put strategies in root** (belongs in documents/strategies/{platform}/)
❌ **Don't mix platforms** (LinkedIn prompts with Facebook prompts)
❌ **Don't put workflows in documents/** (belongs in workflows/)
❌ **Don't put prompts in templates/** (prompts/ is for AI, templates/ is for structure)
❌ **Don't break naming conventions** (follow existing patterns)
❌ **Don't put scripts in root** (belongs in scripts/{category}/)

## Validation Checklist

Before confirming location:
- [ ] Does location follow existing pattern?
- [ ] Is platform correctly identified (if platform-specific)?
- [ ] Are similar files in the same location?
- [ ] Is file type mapped correctly (strategy/prompt/workflow/template)?
- [ ] Will this location require updating many references?
- [ ] Is the file easily discoverable in this location?
- [ ] Does naming convention match directory standards?

## Integration with Development Workflow

**When to use this skill**:
- Before creating a new file/folder
- When adding new prompts or workflows
- When organizing imported/exported files
- When cleaning up project structure
- When onboarding collaborators

**Automation opportunity**:
- Pre-commit hook: Check if new files are in correct location
- File naming linter: Validate naming conventions
- Documentation: Link to this skill in SKILLS-README.md

---

**Last Updated:** 2026-03-13
**Version:** 1.0.0 (Adapted for AI Agent Social Automation)
**Author:** VictorAurelius + Claude Sonnet 4.5
