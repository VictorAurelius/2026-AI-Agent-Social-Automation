# Claude Code Instructions

## Communication Language
**ALWAYS communicate in Vietnamese**
- All responses and explanations in Vietnamese
- Code comments in English (standard practice)
- Commit messages in English (git convention)

## Project Overview
**AI Agent Social Automation** — Hệ thống tự động hóa nội dung social media chạy 100% local ($0/month) với Docker + Ollama + n8n

**Architecture:** Docker Compose trên WSL2/Oracle Cloud ARM (n8n + PostgreSQL + Ollama + Redis)

## Development Workflow

### Superpowers Methodology (every PR)
1. **Quick Brainstorm** (5-10 min) — `.claude/skills/core/brainstorming-methodology.md`
   - Analyze scope, risks, edge cases
   - Identify dependencies and blockers
2. **Task Breakdown** (5-10 min) — `.claude/skills/core/task-breakdown-guide.md`
   - Split into specific tasks with effort estimates
3. **TDD - Test First** — `.claude/skills/core/tdd-enforcement.md`
   - Write tests BEFORE code: Red -> Green -> Refactor
4. **Implementation**
   - Follow task breakdown, commit frequently
5. **Code Review** (self-review) — `.claude/skills/core/two-stage-code-review.md`

### Do NOT skip:
- Do not jump straight into code without brainstorming
- Do not write code before tests
- Do not commit without accompanying tests

## Scripts (MUST use scripts, NOT ad-hoc commands)

| Script | Purpose |
|--------|---------|
| `scripts/test-local.sh` | Test locally before push |
| `scripts/test-local.sh --quick` | Quick lint/compile only |
| `scripts/check-ci.sh` | Wait for CI after push |
| `scripts/check-ci.sh --status` | Quick CI status check |
| `scripts/pre-commit-check.sh` | Pre-commit compliance |
| `scripts/setup.sh` | First-time Docker setup |
| `scripts/healthcheck.sh` | Check service health |
| `scripts/backup.sh` | Backup databases |
| `scripts/oracle-setup.sh` | Oracle Cloud VM setup |
| `scripts/migrate-data.sh` | Migrate data to cloud |
| `scripts/test/run-all-tests.sh` | Run all validation tests |
| `scripts/test/validate-workflows.sh` | Validate n8n JSON |
| `scripts/test/validate-sql.sh` | Validate SQL scripts |
| `scripts/test/test-security.sh` | Security scan |

## Git Workflow
- **ALWAYS** create feature branch before changes
- **NEVER** commit directly to main
- **Branch naming:** `feature/{description}`, `fix/{description}`, `docs/{description}`
- Self-test before push: `scripts/test/run-all-tests.sh`
- CI runs automatically on PR (GitHub Actions)

## System Architecture

```
Docker Compose (WSL2 or Oracle Cloud ARM)
├── n8n (:5678)        — 11 workflows
├── PostgreSQL (:5432) — 11 SQL init scripts
├── Ollama (:11434)    — Llama 3.1 8B / Qwen2 14B
└── Redis (:6379)      — Caching

Platforms: LinkedIn, Facebook Tech, Facebook Chinese
Bot: Telegram (15 commands)
Content: Posts, Quiz, Carousel*, Infographic*
```

## Key Documents

| Doc | Purpose |
|-----|---------|
| `docs/tong-quan-du-an.md` | Vietnamese project overview |
| `docs/huong-dan-workflows.md` | All 11 workflows explained |
| `docs/mo-ta-tat-ca-tinh-nang.md` | All 20 PRs documented |
| `docs/runbook.md` | Operations guide |
| `NEXT-ACTIONS.md` | Current status + next steps |

## Quality Checks
- `scripts/test/run-all-tests.sh` — Validate workflows + SQL + security
- GitHub Actions CI — Auto-run on every PR
- `/quality-audit` — Technical quality score /100
