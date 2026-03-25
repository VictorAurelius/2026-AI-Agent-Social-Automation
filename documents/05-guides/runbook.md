# Operations Runbook

Hướng dẫn vận hành hệ thống AI Agent Personal.

---

## Daily Checklist

### Morning (9:00 AM)
- [ ] Check Telegram for daily digest message
- [ ] Review pending content (if any)
- [ ] Approve or reject with feedback

### Posting Day (Mon/Wed/Fri)
- [ ] Check approved content is ready
- [ ] Copy content from system
- [ ] Post to LinkedIn
- [ ] Update database with post URL
- [ ] Confirm in Telegram

### Evening
- [ ] Check for any error alerts
- [ ] Quick glance at container health

## Weekly Checklist

### Monday
- [ ] Review previous week's engagement metrics
- [ ] Add 3-5 new topic ideas to database
- [ ] Check workflow execution logs for errors

### Friday
- [ ] Verify backup ran successfully
- [ ] Review rejected content - improve prompts if needed
- [ ] Plan next week's content focus

## Common Operations

### Start All Services
```bash
cd docker
docker-compose up -d
```

### Stop All Services
```bash
cd docker
docker-compose down
```

### Restart Specific Service
```bash
docker-compose restart n8n
docker-compose restart ollama
docker-compose restart postgres
docker-compose restart redis
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service (last 100 lines)
docker-compose logs --tail 100 n8n
docker-compose logs --tail 100 ollama
```

### Check Health
```bash
./scripts/healthcheck.sh
```

### Run Backup
```bash
./scripts/backup.sh
```

### Access n8n UI
Open: http://localhost:5678
Login with credentials from `infrastructure/docker/.env`

## Content Operations

### Add New Topic Idea
```sql
docker exec -it postgres psql -U postgres -d agent_personal -c "
INSERT INTO topic_ideas (topic, pillar, notes, priority)
VALUES ('Your topic here', 'tech_insights', 'Additional context', 5);
"
```

### View Pending Content
```sql
docker exec -it postgres psql -U postgres -d agent_personal -c "
SELECT id, title, pillar, LEFT(generated_content, 100) as preview
FROM content_queue
WHERE status = 'pending_review'
ORDER BY created_at DESC;
"
```

### Read Full Content
```sql
docker exec -it postgres psql -U postgres -d agent_personal -c "
SELECT generated_content FROM content_queue WHERE id = <ID>;
"
```

### Approve Content
```sql
docker exec -it postgres psql -U postgres -d agent_personal -c "
UPDATE content_queue
SET status = 'approved',
    final_content = generated_content,
    scheduled_date = '2026-03-20 09:00:00'
WHERE id = <ID>;
"
```

### Reject Content
```sql
docker exec -it postgres psql -U postgres -d agent_personal -c "
UPDATE content_queue
SET status = 'rejected',
    rejection_reason = 'Needs more specific examples'
WHERE id = <ID>;
"
```

### Mark as Published
```sql
docker exec -it postgres psql -U postgres -d agent_personal -c "
UPDATE content_queue
SET status = 'published',
    published_date = NOW(),
    post_url = 'https://linkedin.com/posts/your-post-id'
WHERE id = <ID>;
"
```

### Add Engagement Metrics
```sql
docker exec -it postgres psql -U postgres -d agent_personal -c "
INSERT INTO metrics (content_id, platform, impressions, likes, comments, shares)
VALUES (<CONTENT_ID>, 'linkedin', 500, 25, 8, 3);
"
```

### View Content Stats
```sql
docker exec -it postgres psql -U postgres -d agent_personal -c "
SELECT * FROM v_content_stats;
"
```

### View Unused Topics
```sql
docker exec -it postgres psql -U postgres -d agent_personal -c "
SELECT * FROM v_unused_topics;
"
```

## Backup & Recovery

### Automated Backup
Backup script runs daily at 3AM (after setting up cron):
```bash
# Setup cron job
crontab -e
# Add this line:
0 3 * * * /path/to/scripts/backup.sh >> ~/backups/backup.log 2>&1
```

### Manual Backup
```bash
./scripts/backup.sh
```

### Restore PostgreSQL from Backup
```bash
# Stop services
cd docker && docker-compose stop n8n

# Restore
gunzip -c ~/backups/social-automation/postgres_YYYYMMDD_HHMMSS.sql.gz | \
  docker exec -i postgres psql -U postgres -d agent_personal

# Restart
docker-compose start n8n
```

### Restore n8n Data
```bash
# Stop n8n
docker-compose stop n8n

# Restore
docker cp ~/backups/social-automation/n8n_YYYYMMDD/ n8n:/home/node/.n8n

# Restart
docker-compose start n8n
```

## Troubleshooting

### Ollama Not Responding
```bash
# Check container status
docker ps | grep ollama
docker logs ollama --tail 50

# Restart
docker-compose restart ollama

# Verify model loaded
docker exec ollama ollama list

# Test API
curl http://localhost:11434/api/tags
```

### n8n Workflow Failing
1. Open n8n UI → Executions
2. Find failed execution
3. Click to see error details
4. Common fixes:
   - **PostgreSQL connection**: Verify host is `postgres` not `localhost`
   - **Ollama timeout**: Increase timeout in HTTP node
   - **Telegram error**: Verify bot token and chat ID

### PostgreSQL Connection Refused
```bash
# Check container
docker logs postgres --tail 20

# Test connection
docker exec postgres pg_isready -U postgres

# Restart
docker-compose restart postgres

# If data corrupted, restore from backup
```

### High Memory Usage
```bash
# Check container resources
docker stats --no-stream

# If Ollama using too much RAM
docker-compose restart ollama

# Reduce Ollama memory limit in docker-compose.yml
# deploy.resources.limits.memory: 8G (instead of 12G)
```

### Disk Space Low
```bash
# Check disk usage
df -h /

# Clean up old backups
find ~/backups -mtime +14 -delete

# Clean Docker unused images
docker image prune -f

# Clean Docker unused volumes
docker volume prune -f
```

### Container Won't Start
```bash
# Check what's wrong
docker-compose logs <service>

# Check port conflicts
sudo lsof -i :5678  # n8n
sudo lsof -i :5432  # postgres
sudo lsof -i :11434 # ollama

# Nuclear option: rebuild
docker-compose down
docker-compose up -d --force-recreate
```

## Performance Monitoring

### Weekly Performance Check
```bash
# Container resource usage
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Database size
docker exec postgres psql -U postgres -d agent_personal -c "
SELECT pg_size_pretty(pg_database_size('agent_personal'));
"

# Content queue stats
docker exec postgres psql -U postgres -d agent_personal -c "
SELECT status, COUNT(*),
       MIN(created_at)::date as oldest,
       MAX(created_at)::date as newest
FROM content_queue
GROUP BY status
ORDER BY status;
"

# Workflow error rate (last 7 days)
docker exec postgres psql -U postgres -d agent_personal -c "
SELECT status, COUNT(*)
FROM workflow_logs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY status;
"
```

## Emergency Procedures

### System Down - Full Recovery
1. Check Docker: `docker ps`
2. If no containers: `cd docker && docker-compose up -d`
3. Wait 60s for health checks
4. Run: `./scripts/healthcheck.sh`
5. If DB empty: Restore from backup
6. Check n8n workflows are active

### Data Loss Recovery
1. Stop all services: `docker-compose down`
2. Find latest backup: `ls -lt ~/backups/social-automation/`
3. Restore PostgreSQL (see Backup & Recovery section)
4. Restart services: `docker-compose up -d`
5. Verify data: Check content_queue and prompts tables

## Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:
```bash
# AI Agent shortcuts
alias sa-start="cd ~/social-automation/docker && docker-compose up -d"
alias sa-stop="cd ~/social-automation/docker && docker-compose down"
alias sa-logs="cd ~/social-automation/docker && docker-compose logs -f"
alias sa-health="~/social-automation/scripts/healthcheck.sh"
alias sa-backup="~/social-automation/scripts/backup.sh"
alias sa-db="docker exec -it postgres psql -U postgres -d agent_personal"
alias sa-pending="docker exec postgres psql -U postgres -d agent_personal -c \"SELECT id, title, pillar FROM content_queue WHERE status = 'pending_review' ORDER BY created_at DESC;\""
```
