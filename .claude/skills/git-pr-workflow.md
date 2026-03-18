# Skill: Git & Pull Request Workflow

**Adapted from:** development-workflow.md (KiteClass project)
**Version:** 1.0 (AI Agent Project)
**Last Updated:** 2026-03-13
**Purpose:** Git workflow and pull request process for AI Agent Social Automation project

---

## 📋 Overview

This skill covers:
- **Git Workflow**: Branching, commits, pull requests
- **Commit Conventions**: Conventional commits format
- **PR Process**: Creating and managing pull requests
- **Quality Assurance**: Merge criteria and best practices

---

## 🎯 When to Use This Skill

**Use this workflow for ALL development work:**
- ✅ Adding new features (automation workflows, skills, prompts)
- ✅ Fixing bugs
- ✅ Updating documentation
- ✅ Refactoring code or reorganizing files
- ✅ Before merging PRs

---

## 🌳 Branching Strategy (Simplified Git Flow)

```
main ────●────────────────●────────────────●─────────────► (Production)
         │                │                │
         │  feature/      │                │
         │  new-skill ────┘                │
         │                                 │
         │              feature/           │
         │              update-docs ───────┘
```

### Branch Types

| Branch | Pattern | From | Merge To | Purpose |
|--------|---------|------|----------|---------|
| `main` | `main` | - | - | Production-ready code |
| `feature` | `feature/{description}` | `main` | `main` | New features, skills, workflows |
| `bugfix` | `bugfix/{description}` | `main` | `main` | Bug fixes |
| `docs` | `docs/{description}` | `main` | `main` | Documentation updates |

### Branch Naming Rules

**Format:**
```
{type}/{short-description}
```

**Examples:**
```bash
# Features
feature/automation-setup-skill
feature/linkedin-prompt-templates
feature/make-workflow-export

# Bug fixes
bugfix/fix-gitignore-patterns
bugfix/broken-link-readme

# Documentation
docs/update-strategy-docs
docs/add-setup-guide
```

**Rules:**
- Use lowercase only
- Use `-` instead of spaces
- Keep it short (< 50 chars)
- Be descriptive but concise

---

## ⚠️ Git Rules & Restrictions

### 🚨 CRITICAL ENFORCEMENT: NO DIRECT COMMITS TO MAIN

**ABSOLUTE RULE:**
```
❌ NEVER commit directly to main branch
✅ ALWAYS use branch → PR → merge workflow
```

**Before ANY commit, AI MUST:**
1. ✅ Check current branch: `git branch --show-current`
2. ✅ If on `main`, STOP and create feature branch first
3. ✅ Only commit when on feature/bugfix/docs branch

### CRITICAL: Git Operations with GitHub CLI

**✅ ALLOWED - AI CAN:**
- Check current branch: `git branch --show-current`
- Create branches: `git checkout -b feature/new-branch`
- Commit changes on feature branches: `git commit -m "message"`
- Check status: `git status`, `git log`, `gh pr status`
- Create pull requests: `gh pr create --title "..." --body "..."`
- Push feature branches: `git push origin <feature-branch>` (after user confirmation)

**❌ ABSOLUTELY FORBIDDEN:**
- ❌ Commit to main: `git commit` when on main branch
- ❌ Push to main directly: `git push origin main`
- ❌ Force push: `git push --force` (NEVER without explicit user request)
- ❌ Destructive operations: `git reset --hard`, `git clean -f`
- ❌ Amend commits without user approval: `git commit --amend`

**⏳ MANDATORY WORKFLOW:**
1. AI: Check branch: `git branch --show-current`
2. AI: If on main → Create feature branch: `git checkout -b bugfix/issue-name`
3. AI: Implement fix/feature → commit locally on feature branch
4. AI: Ask user: "Ready to push to remote and create PR?"
5. **User**: Confirm "yes" or request changes
6. AI: Push to remote: `git push -u origin feature/branch`
7. AI: Create PR: `gh pr create --title "..." --body "..."`
8. AI: Return PR URL to user
9. **User**: Review PR → Merge via GitHub UI
10. AI: After merge, cleanup: `git checkout main && git pull && git branch -d feature/branch`

**IMPORTANT:**
- Always ask before pushing to remote, even with GitHub CLI
- Never skip branch creation step
- Every change MUST go through PR review

---

## 📝 Commit Messages (Conventional Commits)

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Commit Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(skills): add automation-setup skill` |
| `fix` | Bug fix | `fix(gitignore): add missing workflow patterns` |
| `docs` | Documentation | `docs(readme): update setup instructions` |
| `chore` | Maintenance | `chore: reorganize file structure` |
| `refactor` | Refactoring | `refactor(prompts): consolidate LinkedIn prompts` |
| `style` | Formatting | `style: format markdown files` |

### Commit Scope Examples

**For AI Agent Project:**
- `skills`: Skills files
- `workflows`: Automation workflows
- `prompts`: AI prompt templates
- `docs`: Documentation
- `templates`: Content/design templates
- `scripts`: Utility scripts
- `strategy`: Strategy documents

### Commit Examples

```bash
# Feature with body
feat(skills): add automation-setup skill

Add comprehensive skill for Make.com/n8n automation setup.

Sections:
- Tool comparison (Make.com vs n8n)
- Make.com account setup
- API integrations (Notion, Claude)
- First workflow creation
- Testing & debugging

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

# Bug fix
fix(gitignore): add workflow credential patterns

Prevent accidentally committing workflow exports with credentials.

Patterns added:
- workflows/**/*-with-credentials.json
- *.env.local

# Documentation update
docs(strategy): update LinkedIn content pillars

Update content pillar breakdown based on market research.

Changes:
- Add 5th pillar: Product showcases
- Update posting frequency recommendations
- Add examples for each pillar

# Chore
chore(skills): remove Java-specific skills

Delete 21 skills not applicable to AI Agent project.

Removed:
- Testing frameworks (JUnit, Mockito)
- Spring Boot patterns
- CI/CD for Java/Maven
```

### Commit Message Rules

- **Subject**: Imperative mood, lowercase, no period (< 72 chars)
- **Body**: Wrap at 72 chars, explain what & why
- **Footer**: Reference issues, breaking changes
- **Co-Authored-By**: ALWAYS include for AI assistance

### Using HEREDOC for Complex Commits

```bash
git commit -m "$(cat <<'EOF'
feat(workflows): add LinkedIn automation workflow

Add complete Make.com workflow for LinkedIn auto-posting.

Features:
- Notion integration for content queue
- Claude API for content generation
- LinkedIn API for publishing
- Error notification via Telegram

Files:
- workflows/make.com/linkedin-auto-post.json
- documents/workflows/linkedin-automation.md

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## 🔀 Pull Request Process

### 1. Creating a Feature Branch

```bash
# Ensure you're on main and up to date
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/new-automation-skill

# Make changes and commit
git add .
git commit -m "feat(skills): add automation-setup skill"

# AI asks user before pushing
# User confirms: "yes"
git push -u origin feature/new-automation-skill

# Create PR with GitHub CLI
gh pr create --title "Add automation setup skill" --body "$(cat <<'EOF'
## Summary
Add comprehensive automation setup skill for Make.com and n8n.

## Changes
- Created .claude/skills/automation-setup.md
- Added tool comparison section
- Documented setup process
- Included troubleshooting guide

## Testing
- [x] Skill loads correctly
- [x] All links functional
- [x] Examples tested

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### 2. PR Template

```markdown
## Summary
Brief description of what this PR does.

## Changes
- Added/modified X
- Fixed Y
- Updated Z

## Type of Change
- [ ] New feature (skills, workflows, templates)
- [ ] Bug fix
- [ ] Documentation update
- [ ] Refactoring
- [ ] Chore (file reorganization, cleanup)

## Checklist
- [ ] Follows project file organization (ai-agent-organize.md)
- [ ] Follows documentation structure (ai-agent-docs-structure.md)
- [ ] Updated README.md if needed
- [ ] Added/updated relevant skills
- [ ] Tested changes (workflows, prompts, scripts)

## Testing Instructions (if applicable)
1. Step-by-step instructions
2. Expected results
3. Screenshots (optional)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### 3. Merge Strategy

**For AI Agent Project:**
- Use **Squash merge** for all PRs to keep history clean
- Merge to `main` directly (no develop branch for this project)
- Delete feature branch after merge

---

## ✅ Pre-Merge Checklist

Before merging any PR:

### File Organization
- [ ] Files are in correct locations (per ai-agent-organize.md)
- [ ] Follows naming conventions
- [ ] No files in root that should be in subdirectories

### Documentation
- [ ] README.md updated if needed
- [ ] Strategy documents updated if applicable
- [ ] Links are not broken
- [ ] Examples are accurate

### Quality
- [ ] No sensitive data (API keys, credentials)
- [ ] .gitignore patterns cover new file types
- [ ] Commit messages follow conventions
- [ ] PR description is clear and complete

### Skills & Templates
- [ ] Skills follow existing format
- [ ] Prompts are well-structured
- [ ] Workflows are exported correctly
- [ ] Scripts are executable (chmod +x)

---

## 🚀 Quick Reference Commands

### Common Git Operations

```bash
# Check status
git status

# View recent commits
git log --oneline -10

# Create and switch to new branch
git checkout -b feature/branch-name

# Stage all changes
git add -A

# Commit with message
git commit -m "type(scope): subject"

# Push to remote (after user confirms)
git push -u origin feature/branch-name

# Create PR with GitHub CLI
gh pr create --title "Title" --body "Description"

# View PR status
gh pr status

# Merge PR (from GitHub web UI or CLI)
gh pr merge --squash
```

### GitHub CLI PR Commands

```bash
# Create PR with title and body
gh pr create --title "Add new skill" --body "Description here"

# View PR details
gh pr view

# List all PRs
gh pr list

# Check PR checks/CI status
gh pr checks

# Merge PR (squash)
gh pr merge --squash --delete-branch
```

---

## 📖 Examples from AI Agent Project

### Example 1: Adding New Skill

```bash
git checkout -b feature/content-templates-skill
# Create .claude/skills/content-templates.md
git add .claude/skills/content-templates.md
git commit -m "$(cat <<'EOF'
feat(skills): add content-templates skill

Add comprehensive content templates library for all platforms.

Sections:
- LinkedIn templates (4 pillars)
- Facebook Tech templates (7 types)
- Facebook Chinese templates (8 types)
- Template usage guide

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push -u origin feature/content-templates-skill
gh pr create --title "Add content templates skill" --body "..."
```

### Example 2: Updating Documentation

```bash
git checkout -b docs/update-linkedin-strategy
# Edit documents/strategies/linkedin/strategy.md
git add documents/strategies/linkedin/strategy.md
git commit -m "docs(strategy): update LinkedIn posting frequency

Update posting frequency from 3x/week to 5x/week based on
engagement analysis.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push -u origin docs/update-linkedin-strategy
gh pr create --title "Update LinkedIn posting frequency" --body "..."
```

### Example 3: Adding Workflow

```bash
git checkout -b feature/facebook-automation-workflow
# Add workflows/make.com/facebook-auto-post.json
git add workflows/make.com/facebook-auto-post.json
git add documents/workflows/facebook-automation.md
git commit -m "$(cat <<'EOF'
feat(workflows): add Facebook automation workflow

Add Make.com workflow for Facebook Tech Page auto-posting.

Components:
- Notion content queue integration
- Claude API for content generation
- Meta Graph API for publishing
- Telegram notifications

Files:
- workflows/make.com/facebook-auto-post.json
- documents/workflows/facebook-automation.md

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push -u origin feature/facebook-automation-workflow
gh pr create --title "Add Facebook automation workflow" --body "..."
```

---

## 🔍 Troubleshooting

### Common Issues

**Issue: Branch already exists**
```bash
# Delete local branch
git branch -d feature/old-branch

# Delete remote branch
git push origin --delete feature/old-branch
```

**Issue: Merge conflicts**
```bash
# Update main branch
git checkout main
git pull origin main

# Rebase feature branch
git checkout feature/my-branch
git rebase main

# Resolve conflicts in files
# Then continue rebase
git add .
git rebase --continue
```

**Issue: Wrong commit message**
```bash
# Amend last commit (only if not pushed)
git commit --amend -m "new message"

# If already pushed, create new commit
git commit -m "fix: correct previous commit message"
```

---

## 📚 Integration with Other Skills

This skill works together with:
- **ai-agent-organize.md**: Determines where files should go
- **ai-agent-docs-structure.md**: Determines documentation organization
- **commit-workflow.md**: Detailed commit creation process
- **troubleshooting.md**: Debugging git issues

---

**Last Updated:** 2026-03-13
**Version:** 1.0.0 (Adapted for AI Agent Social Automation)
**Author:** VictorAurelius + Claude Sonnet 4.5
