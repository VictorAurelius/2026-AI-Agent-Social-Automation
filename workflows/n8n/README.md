# n8n Workflows

## Workflow List

| # | Name | File | Trigger | Purpose |
|---|------|------|---------|---------|
| WF1 | Content Generate | content-generate.json | Manual | Generate single content |
| WF2 | Batch Generate | batch-generate.json | Cron Mon/Wed/Fri 8AM | Generate weekly batch |
| WF3 | Daily Digest | daily-digest.json | Cron Daily 9AM | Send pending items summary |
| WF5 | Healthcheck | healthcheck.json | Cron Every 5min | Monitor services |

## Import Workflows

1. Open n8n: http://localhost:5678
2. Go to Workflows → Import from File
3. Select JSON file from this directory
4. Configure credentials (see below)
5. Activate workflow

## Credentials Required

Before importing, create these credentials in n8n:

### 1. PostgreSQL - Social Automation
- Host: `postgres` (Docker network name)
- Port: `5432`
- Database: `social_automation`
- User: `postgres`
- Password: (from docker/.env)

### 2. Telegram Bot
- Access Token: (from @BotFather - see docker/telegram-config.md)

## Workflow Flows

### WF1: content-generate
```
Manual Trigger → Set Input (topic/pillar) → Get Prompt (PostgreSQL)
  → Prepare Prompt (Code) → Call Ollama (HTTP) → Parse Response (Code)
  → Save to DB (PostgreSQL) → Notify (Telegram)
```

### WF2: batch-generate
```
Cron Trigger → Get Unused Topics (PostgreSQL) → Loop Each Topic
  → Get Prompt → Prepare → Generate (Ollama) → Save → Mark Used
  → Wait 30s → Next Topic → Send Summary (Telegram)
```

### WF3: daily-digest
```
Cron 9AM → Get Stats (PostgreSQL) + Get Pending (PostgreSQL)
  → Format Message (Code) → Send Digest (Telegram)
```

### WF5: healthcheck
```
Every 5min → Check Ollama + Check Postgres + Check Redis (parallel)
  → Evaluate Health (Code) → IF Healthy?
  → Yes: Log Success | No: Log Error + Telegram Alert
```

## Environment Variables

Workflows use these env vars (set in docker-compose.yml):
- `TELEGRAM_CHAT_ID` - Your Telegram chat ID

## Troubleshooting

### Workflow not triggering
- Check workflow is **active** (toggle in n8n UI)
- Check cron schedule timezone matches `GENERIC_TIMEZONE`

### Ollama timeout
- Increase timeout in HTTP Request node (default: 120s)
- Check Ollama container is running: `docker ps | grep ollama`

### PostgreSQL connection error
- Verify credential host is `postgres` (not `localhost`)
- Check container: `docker exec postgres pg_isready`
