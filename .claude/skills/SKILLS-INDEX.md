# Skills Index - AI Agent Personal

**Last Updated:** 2026-03-13
**Total Active Skills:** 11
**Total Reference Skills:** 12 (archived)
**Total Deprecated Skills:** 21 (deleted)

---

## 📚 Active Skills

### Git & Development Workflow

**commit-workflow.md**
- Purpose: Git workflow & conventional commits
- Use when: Creating commits, reviewing git history
- Key features: Conventional commit format, co-authoring, HEREDOC usage
- Status: ✅ Active (created 2026-03-13)

**git-pr-workflow.md**
- Purpose: Pull request process & GitHub CLI usage
- Use when: Creating PRs, managing branches, merging code
- Key features: Branching strategy, PR templates, GitHub CLI commands
- Status: ✅ Active (adapted from development-workflow.md)
- Adapted from: KiteClass project

**setup-github-cli.md**
- Purpose: GitHub CLI setup and usage
- Use when: Configuring gh CLI, creating PRs via CLI
- Status: ✅ Active (from KiteClass, no changes needed)

---

### Project Organization

**ai-agent-organize.md**
- Purpose: File organization rules for AI Agent project
- Use when: Creating new files, organizing imports/exports, cleaning up structure
- Key features: Decision algorithm for file placement, platform-specific routing
- Status: ✅ Active (adapted from organize.md)
- Adapted from: KiteClass project

**ai-agent-docs-structure.md**
- Purpose: Documentation structure & naming conventions
- Use when: Creating documentation, organizing strategies/workflows/templates
- Key features: Folder structure, migration process, anti-patterns
- Status: ✅ Active (adapted from documentation-structure.md)
- Adapted from: KiteClass project

---

### AI Agent Core Skills

**automation-setup.md** ⭐ CRITICAL
- Purpose: Complete setup guide for Make.com/n8n automation
- Use when: Setting up automation for first time, configuring integrations
- Key features:
  - Tool comparison (Make.com vs n8n)
  - Integration guides (Notion, Claude API, LinkedIn, Meta Graph API, Telegram)
  - First workflow creation
  - Testing & debugging
  - Error handling & optimization
- Status: ✅ Active (created 2026-03-13)

**content-templates.md** ⭐ CRITICAL
- Purpose: Reusable content templates for all platforms
- Use when: Creating social media posts, setting up AI prompts
- Key features:
  - LinkedIn templates (4 pillars: Thought Leadership, Tutorial, Product Showcase, Career)
  - Facebook Tech templates (7 types: News, Tutorial, Tool Review, Code Snippet, Comparison, Meme, Resource List)
  - Facebook Chinese templates (8 types: Vocabulary, Grammar, Listening, Culture, Pronunciation, HSK Tips, Flashcards, Conversation)
  - Template usage with AI integration
- Status: ✅ Active (created 2026-03-13)

**prompt-engineering.md** ⭐ CRITICAL
- Purpose: AI prompt library & best practices
- Use when: Creating AI prompts, optimizing content generation
- Key features:
  - System prompts by platform
  - Prompt templates & examples
  - Optimization techniques (few-shot, iterative, constrained generation)
  - Testing framework
  - Claude API parameter recommendations
- Status: ✅ Active (created 2026-03-13)

**notion-database.md** ⭐ CRITICAL
- Purpose: Notion database schemas & setup
- Use when: Setting up Notion workspace, configuring automation
- Key features:
  - Content Queue database (central workflow hub)
  - Metrics Dashboard (analytics tracking)
  - Workflow Logs (automation monitoring)
  - Prompt Library (version control)
  - API integration patterns
- Status: ✅ Active (created 2026-03-13)

**analytics-tracking.md** ⭐ CRITICAL
- Purpose: Metrics framework & optimization
- Use when: Weekly reviews, monthly analysis, A/B testing
- Key features:
  - Key metrics by platform (LinkedIn, Facebook)
  - Weekly review process
  - Monthly analysis framework
  - A/B testing guidelines
  - Optimization strategies
  - Red flags & alerts
- Status: ✅ Active (created 2026-03-13)

---

### General Utilities

**troubleshooting.md**
- Purpose: Debugging patterns & common issues
- Use when: Encountering errors, debugging workflows
- Status: ✅ Active (from KiteClass, minimal changes)
- Note: Consider adding AI Agent specific troubleshooting scenarios

---

## 📂 Reference Only (Not Tracked in Git)

Located in `.claude/skills-reference/` (ignored by .gitignore):

1. **api-design.md** - API design patterns from KiteClass
2. **database-design.md** - Database schema design principles
3. **architecture-overview.md** - System architecture patterns
4. **frontend-development.md** - Frontend development guide (React/Next.js)
5. **frontend-code-quality.md** - Frontend quality standards
6. **plantuml-diagrams.md** - Diagram creation guide
7. **skills-compliance-checklist.md** - Skills quality checklist
8. **project-schedule.md** - Project timeline management
9. **required-knowledge.md** - Prerequisites documentation
10. **_README-quality-docs-status.md** - Documentation tracking
11. **log-management.md** - Log management patterns
12. **deployment-quality-standards.md** - Deployment standards

**Note:** These are kept for reference but not actively used in AI Agent project. They may provide useful patterns for future features.

---

## 🗑️ Deprecated/Deleted (Removed 2026-03-13)

### Java/Spring Boot Specific (21 files deleted)
- spring-boot-testing-quality.md
- testing-guide.md
- ci-cd-best-practices.md
- ci-cd-quality-enforcement.md
- ci-cleanup-workflow.md
- maven-dependencies.md
- spring-boot-upgrade-checklist.md
- e2e-testing-standards.md
- security-testing-standards.md
- performance-testing-standards.md
- frontend-testing-requirements.md
- kiteclass-backend-testing-patterns.md
- kiteclass-frontend-testing-patterns.md
- ide-problem-check.md
- ide-testcontainers-warnings.md
- ide-warnings-best-practices.md
- cross-service-data-strategy.md
- email-service.md
- error-logging.md
- enums-constants.md
- cloud-infrastructure.md

**Reason:** Not applicable to AI Agent project (no Java/Spring Boot stack)

---

## 🔄 Adapted Skills (From KiteClass)

### Successfully Adapted (4 skills)

1. **ai-agent-organize.md** ← organize.md
   - Adapted file type mappings for AI Agent (.md, .json, .txt, .sh)
   - Platform-specific routing (LinkedIn, Facebook Tech, Facebook Chinese)
   - Removed Java/Spring Boot patterns

2. **ai-agent-docs-structure.md** ← documentation-structure.md
   - New folder structure for automation workflows
   - Strategy/workflow/template organization
   - Removed test reports and PR summaries structure

3. **git-pr-workflow.md** ← development-workflow.md
   - Simplified branching (no develop branch)
   - AI Agent commit scopes
   - Removed Java testing sections

4. **commit-workflow.md** (already adapted earlier)
   - No changes needed from KiteClass version

### Not Yet Adapted (2 skills)

**Low priority, adapt when needed:**

1. **code-style.md** → Would become **typescript-style.md**
   - Only if building frontend UI
   - Extract TypeScript/React sections
   - Delete Java sections

2. **environment-setup.md** → Would become **dev-environment.md**
   - Prerequisites for AI Agent (Python 3.10+, Node.js 18+, Docker)
   - Quick start for Make.com, Claude API, Notion
   - Remove Java/Maven setup

---

## 🎯 Skills by Use Case

### When Setting Up the Project

1. automation-setup.md - Setup automation infrastructure
2. notion-database.md - Configure Notion databases
3. setup-github-cli.md - Setup GitHub CLI
4. ai-agent-docs-structure.md - Understand project structure
5. ai-agent-organize.md - Learn file organization rules

### When Creating Content

1. content-templates.md - Choose template for post
2. prompt-engineering.md - Create AI prompts
3. automation-setup.md - Configure workflows
4. notion-database.md - Add to content queue

### When Committing Code

1. commit-workflow.md - Create proper commits
2. git-pr-workflow.md - Create pull requests
3. ai-agent-organize.md - Ensure files in correct location

### When Analyzing Performance

1. analytics-tracking.md - Review metrics
2. notion-database.md - Update metrics dashboard
3. content-templates.md - Adjust templates based on performance

### When Troubleshooting

1. troubleshooting.md - Debug common issues
2. automation-setup.md - Check automation configuration
3. notion-database.md - Verify database setup

---

## 📊 Skills Coverage Map

```
Project Lifecycle Coverage:

Setup         ████████████ 100% (automation-setup, notion-database, github-cli)
Organization  ████████████ 100% (organize, docs-structure)
Development   ████████████ 100% (commit-workflow, git-pr-workflow)
Content       ████████████ 100% (content-templates, prompt-engineering)
Analytics     ████████████ 100% (analytics-tracking, notion-database)
Troubleshoot  ████████░░░░  70% (basic troubleshooting, needs AI Agent scenarios)
```

---

## 🚀 Quick Start Guide

**For new contributors:**

1. Read `ai-agent-docs-structure.md` - Understand folder organization
2. Read `ai-agent-organize.md` - Learn file placement rules
3. Read `commit-workflow.md` - Learn commit conventions
4. Read `git-pr-workflow.md` - Learn PR process

**For automation setup:**

1. Read `automation-setup.md` - Complete setup guide
2. Read `notion-database.md` - Setup databases
3. Read `prompt-engineering.md` - Create AI prompts
4. Read `content-templates.md` - Understand content structure

**For ongoing operations:**

1. Use `content-templates.md` - Create posts
2. Use `analytics-tracking.md` - Weekly/monthly reviews
3. Use `troubleshooting.md` - Debug issues
4. Update skills as you learn new patterns

---

## 🔗 Skills Dependencies

```
automation-setup.md
  ↓ requires ↓
  - notion-database.md (database schemas)
  - prompt-engineering.md (AI prompts)
  - content-templates.md (template structure)

analytics-tracking.md
  ↓ requires ↓
  - notion-database.md (metrics storage)
  - content-templates.md (template performance)

git-pr-workflow.md
  ↓ uses ↓
  - ai-agent-organize.md (file placement validation)
  - commit-workflow.md (commit message format)
```

---

## 📝 Creating New Skills

**When to create a new skill:**
- Repeated pattern that needs documentation
- Complex process requiring step-by-step guide
- Best practices that should be consistent
- Integration with new tool/service

**Skill template:**
```markdown
# Skill Name - AI Agent Project

**Version:** 1.0
**Last Updated:** YYYY-MM-DD
**Purpose:** [One-line purpose]

---

## Overview
[What this skill covers]

## When to Use This Skill
[Use cases]

## [Main Content Sections]
[Step-by-step guides, examples, best practices]

---

**Last Updated:** YYYY-MM-DD
**Version:** 1.0.0
**Author:** VictorAurelius + Claude Sonnet 4.5
```

**After creating:**
1. Add to this index
2. Update relevant documentation (README.md if important)
3. Commit with `feat(skills): add [skill-name]` message

---

## 🛠️ Skill Maintenance

### Monthly Review
- [ ] Check for outdated information
- [ ] Update examples based on new learnings
- [ ] Archive deprecated skills
- [ ] Add new skills for repeated patterns
- [ ] Update this index

### Version Control
- All skills tracked in git
- Commit messages use `feat(skills)`, `fix(skills)`, `docs(skills)` prefixes
- Major updates bump version number in skill file

---

**Last Updated:** 2026-03-13
**Maintained By:** VictorAurelius + Claude Sonnet 4.5
