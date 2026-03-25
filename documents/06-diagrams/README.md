# Project Diagrams

Diagrams cho AI Agent Personal project, rendered bằng PlantUML.

## Danh sách

| # | Diagram | File | Mô tả |
|---|---------|------|-------|
| 1 | System Architecture | `01-system-architecture` | Docker services + modules + APIs |
| 2 | Database ERD | `02-database-erd` | 8 tables + relationships |
| 3 | Content Lifecycle | `03-content-lifecycle` | Status flow: draft → published |
| 4 | Telegram Bot Flow | `04-telegram-bot-flow` | Sequence: user ↔ bot ↔ n8n |
| 5 | Data Pipeline | `05-data-pipeline` | RSS → Trending → Generate → Post |
| 6 | Deployment | `06-deployment` | WSL2 dev vs Oracle Cloud prod |
| 7 | Novel Translation | `07-novel-translation-flow` | /translate → fetch → translate → reply |

## Render

```bash
scripts/render-diagrams.sh
```

## View

Rendered PNGs trong `rendered/` directory.
Source files trong `source/` directory (`.puml`).
