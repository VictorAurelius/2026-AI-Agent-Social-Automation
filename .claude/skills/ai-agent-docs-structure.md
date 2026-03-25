# Documentation & Reports Structure - AI Agent Project

**Adapted from:** documentation-structure.md (KiteClass project)

## Overview

Quy tắc tổ chức files documentation, reports, scripts cho AI Agent Personal project để tránh làm loãng folder gốc.

## Trigger Phrases

- "tạo documentation"
- "tạo md file"
- "tạo script"
- "documentation structure"
- "folder organization"
- "organize files"

---

## 📁 Standard Folder Structure

### For AI Agent Personal Project

```
ai-agent-social-automation/
├── documents/                      # All strategy & documentation
│   ├── strategies/                 # Platform strategies
│   │   ├── linkedin/              # LinkedIn AI Agent strategy
│   │   ├── facebook-tech/         # Facebook Tech Page strategy
│   │   └── facebook-chinese/      # Facebook Chinese Page strategy
│   │
│   ├── tech-stack/                # Technical documentation
│   │   ├── overview.md            # Tech stack overview
│   │   ├── make-vs-n8n.md        # Tool comparisons
│   │   └── api-setup.md          # API setup guides
│   │
│   ├── workflows/                 # Workflow documentation
│   │   ├── content-generation.md  # Content generation workflow
│   │   ├── publishing.md         # Publishing workflow
│   │   └── analytics.md          # Analytics workflow
│   │
│   ├── templates/                 # Documentation templates
│   │   ├── content-template.md   # Content template reference
│   │   └── post-checklist.md     # Post quality checklist
│   │
│   └── archived/                  # Old/deprecated documents
│       └── old-strategy.md
│
├── workflows/                      # Automation workflow exports
│   ├── make.com/                  # Make.com workflow files
│   │   ├── linkedin-auto-post.json
│   │   ├── facebook-scheduler.json
│   │   └── content-generator.json
│   │
│   └── n8n/                       # n8n workflow files
│       ├── linkedin-workflow.json
│       └── facebook-workflow.json
│
├── prompts/                       # AI prompt templates
│   ├── linkedin/                  # LinkedIn prompts
│   │   ├── thought-leadership.txt
│   │   ├── product-showcase.txt
│   │   └── engagement.txt
│   │
│   ├── facebook-tech/             # Facebook Tech prompts
│   │   ├── tech-news.txt
│   │   ├── tutorial.txt
│   │   └── tool-review.txt
│   │
│   └── facebook-chinese/          # Facebook Chinese prompts
│       ├── vocabulary.txt
│       ├── grammar.txt
│       └── culture.txt
│
├── templates/                     # Design & content templates
│   ├── canva/                     # Canva templates
│   │   ├── linkedin-banner.png
│   │   └── facebook-post.png
│   │
│   └── content/                   # Content templates
│       ├── linkedin-4-pillars.md
│       └── facebook-tech-7-types.md
│
├── scripts/                       # Utility scripts
│   ├── setup/                     # Setup scripts
│   │   ├── setup-make.sh
│   │   ├── setup-notion.sh
│   │   └── setup-apis.sh
│   │
│   ├── testing/                   # Testing scripts
│   │   ├── test-claude-api.sh
│   │   ├── test-make-workflow.sh
│   │   └── test-posting.sh
│   │
│   └── utils/                     # Utility scripts
│       ├── export-notion.sh
│       └── backup-workflows.sh
│
├── .claude/                       # Claude skills & configuration
│   └── skills/                    # Project skills
│
├── README.md                      # Project overview (keep in root)
├── .gitignore
└── .env.example                   # Environment variables template
```

---

## 📝 Naming Conventions

### Strategy Documents

**Format:** `{platform}-strategy.md` or `{topic}.md`

**Examples:**
- `linkedin/strategy.md` - LinkedIn overall strategy
- `linkedin/content-pillars.md` - Content pillar breakdown
- `facebook-tech/posting-schedule.md` - Posting schedule

**Location:** `documents/strategies/{platform}/`

### Workflow Files

**Format:** `{platform}-{function}.json`

**Examples:**
- `linkedin-auto-post.json` - LinkedIn auto-posting
- `facebook-content-generator.json` - Facebook content generation
- `notion-sync.json` - Notion database sync

**Location:** `workflows/{make.com,n8n}/`

### Prompt Templates

**Format:** `{content-type}.txt` or `{content-type}-{variant}.txt`

**Examples:**
- `thought-leadership.txt` - Thought leadership prompt
- `tech-news-short.txt` - Short tech news format
- `vocabulary-hsk3.txt` - HSK 3 vocabulary prompt

**Location:** `prompts/{platform}/`

### Scripts

**Format:** `{action}-{target}.sh` (lowercase with hyphens)

**Examples:**
- `setup-make.sh` - Setup Make.com
- `test-claude-api.sh` - Test Claude API
- `backup-workflows.sh` - Backup workflow files

**Location:** `scripts/{category}/`

---

## 🚫 Anti-Patterns (DON'T DO THIS)

### ❌ BAD: Files in Root

```
ai-agent-social-automation/
├── linkedin-strategy.md           # ❌ Bad
├── facebook-tech-strategy.md      # ❌ Bad
├── tech-stack-overview.md         # ❌ Bad
├── content-template.txt           # ❌ Bad
├── linkedin-prompt.txt            # ❌ Bad
├── setup-make.sh                  # ❌ Bad
├── README.md
└── .gitignore
```

**Problems:**
- Root folder cluttered
- Hard to find specific docs
- No categorization
- Confusing for collaborators

### ✅ GOOD: Organized Structure

```
ai-agent-social-automation/
├── documents/
│   ├── strategies/
│   │   ├── linkedin/
│   │   │   └── strategy.md        # ✅ Good
│   │   └── facebook-tech/
│   │       └── strategy.md        # ✅ Good
│   └── tech-stack/
│       └── overview.md            # ✅ Good
├── prompts/
│   └── linkedin/
│       └── thought-leadership.txt # ✅ Good
├── scripts/
│   └── setup/
│       └── setup-make.sh          # ✅ Good
└── README.md                       # ✅ Keep in root
```

**Benefits:**
- Clean root folder
- Easy to navigate
- Clear categorization
- Professional structure

---

## 📋 Migration Process

When reorganizing existing files:

### Step 1: Create Folder Structure

```bash
mkdir -p documents/{strategies/{linkedin,facebook-tech,facebook-chinese},tech-stack,workflows,templates,archived}
mkdir -p workflows/{make.com,n8n}
mkdir -p prompts/{linkedin,facebook-tech,facebook-chinese}
mkdir -p templates/{canva,content}
mkdir -p scripts/{setup,testing,utils}
```

### Step 2: Move Files

```bash
# Move strategy documents
git mv documents/linkedin/*.md documents/strategies/linkedin/
git mv documents/facebook/tech-page/*.md documents/strategies/facebook-tech/
git mv documents/facebook/chinese-page/*.md documents/strategies/facebook-chinese/

# Move tech stack docs
git mv documents/tech-stack/*.md documents/tech-stack/

# Move old documents to archived
git mv documents/99-archived/*.md documents/archived/
```

### Step 3: Update References

Update all internal links in moved files:
- Relative paths in README.md
- Links between documentation
- References in skills files

### Step 4: Commit

```bash
git add -A
git commit -m "docs: reorganize documentation into structured folders

- Reorganize strategies by platform
- Create workflows/ for automation exports
- Create prompts/ for AI templates
- Create scripts/ for utilities
- Move old docs to archived/

This improves project organization and makes resources easier to find.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## 🎯 When to Create Files

### Always Create in Correct Folder

**Strategy Document:**
```bash
# ❌ Bad
touch linkedin-strategy.md

# ✅ Good
touch documents/strategies/linkedin/content-pillars.md
```

**Workflow File:**
```bash
# ❌ Bad
touch linkedin-workflow.json

# ✅ Good
touch workflows/make.com/linkedin-auto-post.json
```

**Prompt Template:**
```bash
# ❌ Bad
touch linkedin-prompt.txt

# ✅ Good
touch prompts/linkedin/thought-leadership.txt
```

**Script:**
```bash
# ❌ Bad
touch setup.sh

# ✅ Good
touch scripts/setup/setup-make.sh
chmod +x scripts/setup/setup-make.sh
```

---

## 📚 README.md Updates

After reorganization, update README.md with documentation links:

```markdown
# AI Agent Personal

## Documentation

- [LinkedIn Strategy](documents/strategies/linkedin/strategy.md)
- [Facebook Tech Strategy](documents/strategies/facebook-tech/strategy.md)
- [Tech Stack Overview](documents/tech-stack/overview.md)

## Workflows

- [Make.com Workflows](workflows/make.com/)
- [n8n Workflows](workflows/n8n/)

## Prompts & Templates

- [LinkedIn Prompts](prompts/linkedin/)
- [Facebook Tech Prompts](prompts/facebook-tech/)
- [Content Templates](templates/content/)

## Scripts

- [Setup Scripts](scripts/setup/)
- [Testing Scripts](scripts/testing/)
```

---

## 🔍 Quick Reference

| Type | Location | Format | Example |
|------|----------|--------|---------|
| Strategy | `documents/strategies/{platform}/` | `{topic}.md` | `strategy.md` |
| Tech Docs | `documents/tech-stack/` | `{topic}.md` | `overview.md` |
| Workflow | `workflows/{make.com,n8n}/` | `{platform}-{function}.json` | `linkedin-auto-post.json` |
| Prompt | `prompts/{platform}/` | `{content-type}.txt` | `thought-leadership.txt` |
| Content Template | `templates/content/` | `{platform}-{type}.md` | `linkedin-4-pillars.md` |
| Design Template | `templates/canva/` | `{platform}-{type}.png` | `linkedin-banner.png` |
| Setup Script | `scripts/setup/` | `setup-{target}.sh` | `setup-make.sh` |
| Test Script | `scripts/testing/` | `test-{target}.sh` | `test-claude-api.sh` |
| Utility Script | `scripts/utils/` | `{action}-{target}.sh` | `backup-workflows.sh` |

---

## ✅ Checklist for New Files

Before creating any file, ask:

- [ ] Is this a strategy document? → `documents/strategies/{platform}/`
- [ ] Is this tech documentation? → `documents/tech-stack/`
- [ ] Is this a workflow export? → `workflows/{make.com,n8n}/`
- [ ] Is this an AI prompt? → `prompts/{platform}/`
- [ ] Is this a content/design template? → `templates/{canva,content}/`
- [ ] Is this a script? → `scripts/{category}/`
- [ ] Does the filename follow naming convention?
- [ ] Are all internal links relative and correct?
- [ ] Is README.md updated with link (if important)?

---

## 🚀 Benefits of This Structure

1. **Clean Root Folder**
   - Only essential files (README, .gitignore, .env.example)
   - Professional appearance
   - Easy to navigate

2. **Easy to Find**
   - Categorized by type and platform
   - Predictable locations
   - Searchable structure

3. **Scalable**
   - Add new platforms easily
   - Supports growth
   - No folder bloat

4. **Professional**
   - Industry standard
   - Easy for collaborators
   - Clear organization

5. **Git-Friendly**
   - Easy to track changes
   - Logical grouping
   - Clean diffs

---

## 📖 Platform-Specific Organization

### LinkedIn Files
```
documents/strategies/linkedin/
prompts/linkedin/
templates/content/linkedin-*.md
workflows/{make.com,n8n}/linkedin-*.json
```

### Facebook Tech Files
```
documents/strategies/facebook-tech/
prompts/facebook-tech/
templates/content/facebook-tech-*.md
workflows/{make.com,n8n}/facebook-tech-*.json
```

### Facebook Chinese Files
```
documents/strategies/facebook-chinese/
prompts/facebook-chinese/
templates/content/facebook-chinese-*.md
workflows/{make.com,n8n}/facebook-chinese-*.json
```

---

**Last Updated:** 2026-03-13
**Version:** 1.0.0 (Adapted for AI Agent Personal)
**Author:** VictorAurelius + Claude Sonnet 4.5
