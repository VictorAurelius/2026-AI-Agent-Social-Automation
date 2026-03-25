# AI Agent Personal

> Nen tang AI assistant ca nhan voi cac module domain (social, novel) chay 100% local ($0/month) voi Docker + Ollama + n8n

---

## Tong quan

Du an nay cung cap nen tang tu dong hoa ca nhan voi cac module:

- **Social Automation** - Tu dong tao noi dung cho LinkedIn & Facebook
- **Novel Translation** - Dich truyen tieng Trung sang tieng Viet
- **Common Services** - Healthcheck, Telegram bot, daily digest

---

## Cau truc Du an

```
ai-agent-personal/
├── documents/                       # Tai lieu (merged, numbered)
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
│   ├── social/                     # Social automation
│   │   └── workflows/             # 8 n8n workflows
│   └── novel/                      # Novel translation
│       ├── workflows/             # 1 n8n workflow
│       ├── sql/                   # Novel DB schema
│       └── glossary/              # Xianxia terms
├── workflows/n8n/                  # Common workflows (3)
│   ├── healthcheck.json
│   ├── telegram-bot.json
│   └── daily-digest.json
├── scripts/                        # Utility scripts
│   └── test/                      # Validation tests
├── .claude/                        # Claude Code configuration
├── CLAUDE.md                       # Claude Code instructions
├── NEXT-ACTIONS.md                 # Current status + next steps
└── SKILLS-README.md                # Skills quick reference
```

---

## Tech Stack

### Core Components (100% Local - $0/month)

| Category | Tool | Purpose | Cost |
|----------|------|---------|------|
| **Orchestration** | n8n (self-hosted WSL) | Workflow automation | $0 |
| **AI Engine** | Ollama + Llama 3.1 8B | Content generation | $0 |
| **Database** | PostgreSQL (local) | Content queue & metrics | $0 |
| **Design** | HTML templates | Carousel, infographic | $0 |
| **Publishing** | Meta Graph API, LinkedIn API | Auto-posting | Free |
| **Notifications** | Telegram Bot | Alerts & control | Free |

**Total**: **$0/month**

### Architecture

```
Docker Compose (WSL2 or Oracle Cloud ARM)
├── n8n (:5678)        — 12 workflows (8 social + 1 novel + 3 common)
├── PostgreSQL (:5432) — 11 SQL init scripts
├── Ollama (:11434)    — Llama 3.1 8B / Qwen2 14B
└── Redis (:6379)      — Caching

Modules:
├── Social: LinkedIn, Facebook Tech, Facebook Chinese
└── Novel: Xianxia translation (CN -> VI)

Bot: Telegram (15 commands)
Content: Posts, Quiz, Carousel, Infographic
```

Chi tiet: [`documents/01-business/social/tech-stack/overview.md`](./documents/01-business/social/tech-stack/overview.md)

---

## Quick Start

### 1. Setup Infrastructure

```bash
# Clone and setup
git clone <repo-url>
cd ai-agent-personal
bash scripts/setup.sh
```

### 2. Doc Tai lieu

- [Tong quan du an](./documents/05-guides/tong-quan-du-an.md)
- [Huong dan workflows](./documents/05-guides/huong-dan-workflows.md)
- [Runbook](./documents/05-guides/runbook.md)
- [n8n Setup Guide](./documents/05-guides/n8n-setup-guide.md)

### 3. Chon Module

**Social Automation:**
- [LinkedIn Strategy](./documents/01-business/social/strategies/linkedin/strategy.md)
- [Facebook Tech Page](./documents/01-business/social/strategies/facebook-tech/strategy.md)
- [Facebook Chinese Page](./documents/01-business/social/strategies/facebook-chinese/strategy.md)

**Novel Translation:**
- [Novel Module](./modules/novel/README.md)
- [Glossary Xianxia](./modules/novel/glossary/glossary-xianxia.md)

---

## Modules

### Social Automation (`modules/social/`)

8 workflows tu dong hoa noi dung cho 3 platforms:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| content-generate | Manual | Tao 1 bai |
| batch-generate | Cron Mon/Wed/Fri 8AM | Batch 5 bai |
| facebook-post | Manual | Dang FB |
| linkedin-post-helper | Manual | Gui LI content qua Telegram |
| quiz-generator | Manual | Tao quiz |
| auto-comment | Cron 30min | Auto-comment dap an |
| data-collector | Cron 6AM | Thu thap RSS |
| trending-detector | Cron 7AM | Phat hien trending |

### Novel Translation (`modules/novel/`)

Dich truyen tieng Trung sang tieng Viet voi Qwen2 7B/14B:
- Auto-fetch chapter tu web sources
- Xianxia glossary (36+ terms)
- Caching (khong dich lai)
- Telegram bot integration

### Common Workflows (`workflows/n8n/`)

| Workflow | Purpose |
|----------|---------|
| healthcheck | Monitor services |
| telegram-bot | Telegram commands |
| daily-digest | Daily summary |

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup.sh` | First-time Docker setup |
| `scripts/healthcheck.sh` | Check service health |
| `scripts/backup.sh` | Backup databases |
| `scripts/import-workflows.sh` | Import n8n workflows |
| `scripts/test/run-all-tests.sh` | Run all validation tests |
| `scripts/test/validate-workflows.sh` | Validate n8n JSON |
| `scripts/test/validate-sql.sh` | Validate SQL scripts |
| `scripts/test/test-security.sh` | Security scan |

---

## Security & Best Practices

- NEVER commit API keys to git
- Use `.env` files (listed in `.gitignore`)
- Always review AI-generated content
- Follow platform policies

---

## Contributing

1. Fork repo
2. Create feature branch (`git checkout -b feature/description`)
3. Submit PR with clear description

---

## License

MIT License

---

**Last updated**: 2026-03-25
**Version**: 2.0
**Status**: Production Ready
