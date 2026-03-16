# Docker Setup - AI Agent Social Automation

## Quick Start

### 1. Copy environment file

```bash
cp .env.example .env
```

### 2. Edit `.env` with your values

```bash
nano .env
# or
code .env
```

**Required changes:**
- `POSTGRES_PASSWORD`: Strong password for database
- `N8N_BASIC_AUTH_PASSWORD`: Password for n8n UI
- `N8N_ENCRYPTION_KEY`: Random 32+ character string
- `TELEGRAM_BOT_TOKEN`: Get from @BotFather
- `TELEGRAM_CHAT_ID`: Your Telegram chat ID

### 3. Start services

```bash
docker-compose up -d
```

### 4. Pull Llama model

```bash
docker exec -it ollama ollama pull llama3.1:8b
```

This downloads ~4.7GB. Wait for completion.

### 5. Access n8n

Open browser: http://localhost:5678

Login with credentials from `.env`

---

## Services

| Service | Port | Purpose | URL |
|---------|------|---------|-----|
| **n8n** | 5678 | Workflow automation | http://localhost:5678 |
| **PostgreSQL** | 5432 | Data storage | localhost:5432 |
| **Ollama** | 11434 | Local LLM | http://localhost:11434 |
| **Redis** | 6379 | Caching | localhost:6379 |

---

## Commands

### Start all services
```bash
docker-compose up -d
```

### Stop all services
```bash
docker-compose down
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f n8n
docker-compose logs -f ollama
```

### Restart specific service
```bash
docker-compose restart n8n
docker-compose restart ollama
```

### Check status
```bash
docker-compose ps
```

### Check health
```bash
# All containers should show "healthy"
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## Testing

### Test Ollama
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Hello, write a short greeting.",
  "stream": false
}'
```

### Test PostgreSQL
```bash
docker exec -it postgres psql -U postgres -d social_automation -c "SELECT 1;"
```

### Test Redis
```bash
docker exec -it redis redis-cli ping
# Expected: PONG
```

---

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs <service_name>

# Check disk space
df -h

# Check memory
free -h
```

### Ollama out of memory
- Reduce `memory: 12G` in docker-compose.yml
- Or close other applications

### Port already in use
```bash
# Find what's using the port
sudo lsof -i :5678

# Kill the process or change port in docker-compose.yml
```

### Reset everything
```bash
# Stop and remove containers + volumes
docker-compose down -v

# Start fresh
docker-compose up -d
```

---

## Resource Requirements

| Service | RAM | Disk |
|---------|-----|------|
| n8n | 512MB - 2GB | 1GB |
| PostgreSQL | 256MB - 1GB | 5GB |
| Ollama + Llama 3.1 8B | 8-10GB | 5GB |
| Redis | 64MB - 256MB | 100MB |
| **Total** | **~12GB** | **~12GB** |

Your system: 32GB RAM - more than enough!

---

## Backup

See `../scripts/backup.sh` for automated backups.

Manual PostgreSQL backup:
```bash
docker exec postgres pg_dump -U postgres social_automation > backup.sql
```

---

## Security Notes

- Never commit `.env` file to git
- Use strong passwords
- Keep Docker and images updated
- Ports are only exposed locally (localhost)
