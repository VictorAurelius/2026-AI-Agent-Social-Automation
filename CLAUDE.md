# Claude Code Instructions

## Communication Language
**ALWAYS communicate in Vietnamese**
- All responses and explanations in Vietnamese
- Code comments in English (standard practice)
- Commit messages in English (git convention)

## Project Overview
**AI Agent Personal** — Nền tảng AI assistant cá nhân với các module domain (social, novel) chạy 100% local ($0/month) với Docker + Ollama + n8n

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

## Project Structure

```
ai-agent-personal/
├── documents/                       # ALL docs (merged, numbered)
│   ├── 01-business/social/         # strategies, content pillars
│   ├── 02-architecture/            # design-*.md (13 files)
│   ├── 03-planning/                # specs, plans, superpowers
│   ├── 04-quality/                 # bugfixes, lessons learned
│   ├── 05-guides/                  # runbook, setup, how-to
│   └── 07-archived/               # legacy docs
├── infrastructure/                  # DevOps
│   ├── docker/                     # compose, .env, init-db/
│   ├── templates/                  # carousel, infographic, social-media
│   └── dashboard/                  # web UI
├── modules/
│   ├── social/                     # Social automation (8 workflows + prompts)
│   └── novel/                      # Novel translation (1 workflow)
├── workflows/n8n/                  # Common workflows (healthcheck, bot, digest)
├── scripts/                        # Common scripts
└── .claude/                        # Claude Code config
```

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
├── n8n (:5678)        — 12 workflows (8 social + 1 novel + 3 common)
├── PostgreSQL (:5432) — 11 SQL init scripts
├── Ollama (:11434)    — Llama 3.1 8B / Qwen2 14B
└── Redis (:6379)      — Caching

Modules:
├── Social: LinkedIn, Facebook Tech, Facebook Chinese
└── Novel: Xianxia translation (CN → VI)

Bot: Telegram (15 commands)
Content: Posts, Quiz, Carousel*, Infographic*
```

## Key Documents

| Doc | Purpose |
|-----|---------|
| `documents/05-guides/tong-quan-du-an.md` | Vietnamese project overview |
| `documents/05-guides/huong-dan-workflows.md` | All workflows explained |
| `documents/03-planning/mo-ta-tat-ca-tinh-nang.md` | All 20 PRs documented |
| `documents/05-guides/runbook.md` | Operations guide |
| `NEXT-ACTIONS.md` | Current status + next steps |

## Quality Checks
- `scripts/test/run-all-tests.sh` — Validate workflows + SQL + security
- GitHub Actions CI — Auto-run on every PR
- `/quality-audit` — Technical quality score /100
