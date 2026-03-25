# n8n Setup Guide

Hướng dẫn setup n8n sau khi chạy `scripts/setup.sh`

## Bước 1: Tạo PostgreSQL Credential

1. Mở n8n: http://localhost:5678
2. Click **Credentials** (icon chìa khóa bên trái)
3. Click **Add Credential**
4. Search và chọn **"Postgres"**
5. Điền thông tin:

```
Credential Name: Agent Personal DB
Host: postgres
Port: 5432
Database: agent_personal
User: postgres
Password: hWNxJiw0n+H7A1uRQnZ37dXa8zEjWdbLgt/whe5CZAY=
SSL: Disabled
```

6. Click **Test Connection** → phải thấy "Connection successful"
7. Click **Save**

## Bước 2: Import Workflows

### Content Generate Workflow
1. Click **Workflows** (icon list bên trái)
2. Click **Add Workflow** → **Import from File**
3. Chọn file: `F:\2026-AI-Agent-Social-Automation\workflows\n8n\content-generate.json`
4. Sau khi import, click **Save**
5. **KHÔNG activate** (để manual trigger)

### Batch Generate Workflow
1. Click **Add Workflow** → **Import from File**
2. Chọn file: `batch-generate.json`
3. Sau khi import, click **Save**
4. Click **Activate** (chạy tự động Mon/Wed/Fri 8AM)

### Daily Digest Workflow
1. Click **Add Workflow** → **Import from File**
2. Chọn file: `daily-digest.json`
3. Sau khi import, click **Save**
4. Click **Activate** (chạy tự động mỗi ngày 9AM)

### Healthcheck Workflow
1. Click **Add Workflow** → **Import from File**
2. Chọn file: `healthcheck.json`
3. Sau khi import, click **Save**
4. Click **Activate** (chạy mỗi 5 phút)

## Bước 3: Verify Credentials

Sau khi import, mở từng workflow và verify:
- PostgreSQL nodes → phải link tới "Agent Personal DB" credential
- Nếu có lỗi red, click vào node và chọn lại credential

## Bước 4: Test Content Generate

1. Mở workflow **content-generate**
2. Click **Execute Workflow** (góc trên phải)
3. Kiểm tra output - phải thấy content được tạo
4. Check database:
   ```bash
   bash scripts/healthcheck.sh
   ```

## Telegram Setup (Optional)

Nếu muốn nhận notifications qua Telegram:

1. Tạo bot với @BotFather trên Telegram
2. Get bot token và chat ID (xem `infrastructure/docker/telegram-config.md`)
3. Update `infrastructure/docker/.env`:
   ```
   TELEGRAM_BOT_TOKEN=your_token_here
   TELEGRAM_CHAT_ID=your_chat_id_here
   ```
4. Restart services:
   ```bash
   cd docker && docker-compose restart
   ```
5. Trong n8n, tạo Telegram credential:
   - Type: Telegram
   - Access Token: (paste bot token)

## Troubleshooting

### Workflow không chạy
- Check workflow status: phải có toggle màu xanh (Active)
- Check logs: `docker-compose logs -f n8n`

### PostgreSQL connection error
- Verify credential: Host phải là `postgres` (không phải `localhost`)
- Test connection trong credential settings

### Ollama timeout
- Tăng timeout trong HTTP Request node (Settings → Timeout)
- Default: 60s, recommend: 120s

## Next Steps

Sau khi setup xong:
1. Theo dõi healthcheck logs để verify hệ thống stable
2. Đợi batch-generate chạy vào Mon/Wed/Fri 8AM
3. Review generated content trong database
4. Approve content và publish lên LinkedIn

## Useful Commands

```bash
# Check system health
bash scripts/healthcheck.sh

# View n8n logs
cd docker && docker-compose logs -f n8n

# View all logs
docker-compose logs -f

# Restart n8n
docker-compose restart n8n

# Backup database
bash scripts/backup.sh
```
