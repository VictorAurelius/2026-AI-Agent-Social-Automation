# Thiết kế: Migration sang Oracle Cloud Free Tier

**Created:** 2026-03-19
**Status:** Proposed
**Goal:** Chuyển hệ thống từ WSL2 local sang Oracle Cloud ARM VM (24GB RAM) để chạy model lớn hơn, always-on, $0/month

---

## 1. Tại sao Migration?

### Hạn chế hiện tại (WSL2 Local)
- RAM chỉ 7.6GB (WSL2 limit) → chỉ chạy được Llama 8B
- PC phải bật → system down khi tắt máy
- Chỉ access local → Telegram webhook không nhận được từ internet
- Không always-on → cron jobs miss khi PC sleep

### Oracle Cloud Free Tier
- **24GB RAM** → chạy Qwen2 14B hoặc 2 models cùng lúc
- **Always-on 24/7** → cron jobs chạy đúng giờ
- **Public IP** → Telegram webhook nhận trực tiếp
- **$0/month vĩnh viễn** → đúng philosophy dự án

## 2. So sánh Resources

| Resource | WSL2 Local | Oracle Cloud Free |
|----------|-----------|-------------------|
| RAM | 7.6 GB | **24 GB** |
| CPU | 8 cores x86 | 4 OCPU ARM (Ampere) |
| Storage | 942 GB | 200 GB |
| Uptime | Khi PC bật | **24/7/365** |
| Network | Local only | **Public IP + 10TB/mo** |
| Bandwidth | Unlimited local | 10 Mbps |
| Cost | $0 + điện | **$0** |

## 3. Model Upgrade với 24GB RAM

| Model | RAM | Chất lượng Vietnamese | Chinese | Use Case |
|-------|-----|----------------------|---------|----------|
| Llama 3.1 8B (hiện tại) | ~5GB | Tốt | Trung bình | General content |
| **Qwen2 14B** (upgrade) | ~10GB | Rất tốt | **Rất tốt** | Content + Translation |
| Llama 3.1 8B + Qwen2 7B | ~10GB | Tốt + Tốt | Tốt | Đa mục đích |
| Mixtral 8x7B | ~26GB | Xuất sắc | Tốt | Nếu tối ưu RAM |

**Recommendation:** Qwen2 14B cho tất cả tasks (content + translation + quiz)

## 4. Kiến trúc trên Oracle Cloud

```
Oracle Cloud ARM VM (4 OCPU, 24GB RAM, 200GB disk)
┌─────────────────────────────────────────────────────────────┐
│  Ubuntu 22.04 (ARM64/aarch64)                               │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Nginx Reverse Proxy (SSL via Let's Encrypt)             ││
│  │ :80 → n8n:5678 | Webhook endpoint for Telegram         ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Docker Compose                                          ││
│  │ ┌──────────┐ ┌──────────┐ ┌────────────┐ ┌──────────┐ ││
│  │ │   n8n    │ │ Postgres │ │  Ollama    │ │  Redis   │ ││
│  │ │  :5678   │ │  :5432   │ │  :11434   │ │  :6379   │ ││
│  │ │  ~2GB    │ │  ~1GB    │ │ Qwen2 14B │ │  ~256MB  │ ││
│  │ │          │ │          │ │  ~14GB    │ │          │ ││
│  │ └──────────┘ └──────────┘ └────────────┘ └──────────┘ ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
│  RAM: n8n 2GB + PG 1GB + Ollama 14GB + Redis 0.3GB = ~17GB │
│  Buffer: ~7GB cho OS + overhead                              │
│                                                              │
│  Firewall: chỉ mở port 80, 443, 22 (SSH)                   │
│  Ports 5678, 5432, 11434, 6379 → KHÔNG expose ra internet  │
└─────────────────────────────────────────────────────────────┘
```

## 5. Idle Reclamation Prevention

Oracle reclaim VM nếu CPU <20% liên tục 7 ngày.

### Hệ thống tự keep-alive:

| Workflow | Frequency | CPU Impact |
|----------|-----------|------------|
| WF5 Healthcheck | Every 5 min | Low (HTTP + SQL) |
| WF12 Auto-Comment | Every 30 min | Low (SQL queries) |
| WF13 Data Collector | Daily 6AM | **High** (RSS + Ollama) |
| WF14 Trending | Daily 7AM | Medium (3 HTTP + analysis) |
| WF2 Batch Generate | Mon/Wed/Fri 8AM | **Very High** (Ollama x5) |
| WF6 Telegram Bot | Always on | Low-Medium |

**Ollama inference 3x/week** alone đủ để giữ CPU >20%.

### Safety net: Thêm keepalive cron
```bash
# Chạy Ollama inference nhỏ mỗi 6 giờ
0 */6 * * * curl -s http://localhost:11434/api/generate -d '{"model":"qwen2:14b","prompt":"ping","stream":false}' > /dev/null 2>&1
```

## 6. Security Hardening

### 6.1 Firewall (iptables/nftables)
```bash
# Chỉ mở ports cần thiết
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT    # SSH
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT    # HTTP
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT   # HTTPS
sudo iptables -A INPUT -j DROP                         # Block all other
```

### 6.2 SSH Security
- Key-based auth only (disable password)
- fail2ban installed
- Non-default SSH port (optional)

### 6.3 Nginx Reverse Proxy
```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # n8n webhook endpoint (for Telegram)
    location /webhook/ {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # n8n UI (password protected)
    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 6.4 Docker internal only
- PostgreSQL, Redis, Ollama: chỉ bind localhost hoặc Docker network
- KHÔNG expose ports ra internet

## 7. Backup Strategy (Cloud)

| Type | Destination | Schedule |
|------|------------|----------|
| PostgreSQL dump | Oracle Object Storage (10GB free) | Daily 3AM |
| n8n workflows | Git repo (auto-push) | On change |
| Full VM snapshot | Oracle Block Volume backup | Weekly |

### Object Storage backup script
```bash
#!/bin/bash
# Backup to Oracle Object Storage
oci os object put \
  --bucket-name social-automation-backups \
  --file ~/backups/postgres_$(date +%Y%m%d).sql.gz \
  --name postgres/$(date +%Y%m%d).sql.gz
```

## 8. Migration Steps

### Phase 1: Oracle Account Setup (30 min)
1. Tạo Oracle Cloud account (cần credit card, không charge)
2. Chọn Home Region (Singapore hoặc Tokyo cho latency thấp)
3. Tạo Compartment

### Phase 2: VM Provisioning (15 min)
1. Compute → Create Instance
2. Shape: VM.Standard.A1.Flex (ARM)
3. OCPU: 4, Memory: 24GB
4. OS: Ubuntu 22.04 (aarch64)
5. Boot volume: 100GB
6. Add block volume: 100GB
7. Download SSH key

### Phase 3: Server Setup (1 hour)
```bash
# SSH vào VM
ssh -i ssh-key.pem ubuntu@<public-ip>

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker ubuntu

# Install Nginx + Certbot
sudo apt install nginx certbot python3-certbot-nginx -y

# Clone repo
git clone https://github.com/VictorAurelius/2026-AI-Agent-Social-Automation.git
cd 2026-AI-Agent-Social-Automation

# Setup environment
cd docker
cp .env.example .env
nano .env  # Edit passwords

# Start services
docker-compose up -d

# Pull model (Qwen2 14B thay vì Llama 8B)
docker exec ollama ollama pull qwen2:14b
```

### Phase 4: SSL & Domain (30 min)
```bash
# Setup Nginx reverse proxy
sudo nano /etc/nginx/sites-available/social-automation
# (paste config from section 6.3)

sudo ln -s /etc/nginx/sites-available/social-automation /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com
```

### Phase 5: Telegram Webhook (10 min)
```bash
# Set webhook URL to cloud server
curl -X POST "https://api.telegram.org/bot<TOKEN>/setWebhook" \
  -d "url=https://your-domain.com/webhook/telegram-bot-webhook"
```

### Phase 6: Data Migration (30 min)
```bash
# On WSL2 (source):
docker exec postgres pg_dump -U postgres agent_personal > backup.sql
scp backup.sql ubuntu@<oracle-ip>:~/

# On Oracle (destination):
docker exec -i postgres psql -U postgres -d agent_personal < ~/backup.sql
```

### Phase 7: Verify (30 min)
```bash
# Test health
./scripts/healthcheck.sh

# Test Telegram bot
# Send /help to bot

# Test content generation
# Send /generate AI tools

# Test all workflows
./scripts/test/run-all-tests.sh
```

### Phase 8: Monitoring Setup (15 min)
```bash
# Setup keepalive cron
crontab -e
# Add:
0 */6 * * * curl -s http://localhost:11434/api/generate -d '{"model":"qwen2:14b","prompt":"ping","stream":false}' > /dev/null 2>&1
0 3 * * * /home/ubuntu/2026-AI-Agent-Social-Automation/scripts/backup.sh >> /home/ubuntu/logs/backup.log 2>&1
```

## 9. Rollback Plan

Nếu Oracle Cloud có vấn đề:
1. WSL2 local vẫn hoạt động (giữ làm backup)
2. Telegram webhook đổi về localhost (ngrok tunnel)
3. Data restore từ backup
4. Thời gian rollback: ~15 phút

## 10. Timeline

| Day | Task | Duration |
|-----|------|----------|
| Day 1 | Oracle account + VM provision | 1 hour |
| Day 1 | Server setup + Docker | 1 hour |
| Day 2 | SSL + Domain + Nginx | 1 hour |
| Day 2 | Data migration + workflows | 1 hour |
| Day 3 | Testing + verification | 2 hours |
| Day 3 | Monitoring + backup cron | 30 min |
| **Total** | | **~6 hours** |

## 11. Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Oracle reclaim VM | High | Low | Keepalive cron + natural workload |
| ARM compatibility | Medium | Low | Docker + Ollama support ARM64 |
| 10Mbps bottleneck | Low | Low | API calls nhỏ, không stream media |
| Oracle policy change | Medium | Very Low | WSL2 backup, data portable |
| SSH brute force | High | Medium | Key-only auth + fail2ban |

## 12. Cost Analysis

```
Oracle Cloud Free Tier:
  Compute: $0 (4 OCPU, 24GB RAM - Always Free)
  Storage: $0 (200GB Block Volume - Always Free)
  Network: $0 (10TB outbound - Always Free)
  Object Storage: $0 (10GB - Always Free)
  Load Balancer: $0 (10Mbps - Always Free)

Domain (optional):
  Free: use Oracle-provided IP
  Or: ~$10/year for custom domain

Total: $0/month (hoặc ~$0.83/month với custom domain)
```
