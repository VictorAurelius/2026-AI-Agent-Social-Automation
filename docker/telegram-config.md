# Telegram Bot Setup Guide

Hướng dẫn tạo và cấu hình Telegram Bot cho notifications.

---

## 1. Tạo Bot với BotFather

### Step 1.1: Mở BotFather

1. Mở Telegram app
2. Tìm kiếm `@BotFather`
3. Bắt đầu chat với BotFather

### Step 1.2: Tạo Bot mới

Gửi lệnh:
```
/newbot
```

BotFather sẽ hỏi:
1. **Bot name**: `AI Agent Notifier` (hoặc tên bạn muốn)
2. **Username**: `your_agent_bot` (phải kết thúc bằng `bot`)

### Step 1.3: Lưu API Token

BotFather sẽ trả về token dạng:
```
123456789:ABCdefGHIjklMNOpqrsTUVwxyz
```

**⚠️ QUAN TRỌNG: Lưu token này an toàn, không share public!**

---

## 2. Lấy Chat ID

### Step 2.1: Message bot của bạn

1. Tìm bot bạn vừa tạo trên Telegram
2. Gửi bất kỳ tin nhắn nào (ví dụ: "Hello")

### Step 2.2: Lấy Chat ID

Mở URL này trong browser (thay TOKEN bằng token của bạn):

```
https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
```

Ví dụ:
```
https://api.telegram.org/bot123456789:ABCdefGHIjklMNOpqrsTUVwxyz/getUpdates
```

### Step 2.3: Tìm Chat ID trong response

Tìm phần:
```json
{
  "message": {
    "chat": {
      "id": 123456789,  // <-- Đây là Chat ID của bạn
      "type": "private"
    }
  }
}
```

---

## 3. Test Bot

### Gửi test message

Thay `TOKEN` và `CHAT_ID` bằng giá trị của bạn:

```bash
curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d "chat_id=<CHAT_ID>" \
  -d "text=🎉 Hello from AI Agent Social Automation!" \
  -d "parse_mode=Markdown"
```

Nếu thành công, bạn sẽ nhận được message trên Telegram.

---

## 4. Cập nhật .env

Mở file `docker/.env` và cập nhật:

```env
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=123456789
```

---

## 5. Cấu hình trong n8n

### Step 5.1: Thêm Credentials

1. Mở n8n: http://localhost:5678
2. Vào **Settings** → **Credentials**
3. Click **Add Credential**
4. Tìm **Telegram**
5. Điền:
   - **Credential Name**: `Telegram Bot`
   - **Access Token**: Token từ BotFather
6. Click **Save**

### Step 5.2: Test trong workflow

1. Tạo workflow mới
2. Thêm node **Telegram** → **Send Message**
3. Chọn credential vừa tạo
4. Chat ID: Dùng expression `{{ $env.TELEGRAM_CHAT_ID }}`
5. Text: `Test message from n8n`
6. Execute để test

---

## 6. Message Templates

### Content Ready for Review

```markdown
📝 *New Content Ready for Review*

*Title:* {{title}}
*Platform:* {{platform}}
*Pillar:* {{pillar}}
*Status:* Pending Review

📅 Created: {{created_at}}

_Review at:_ http://localhost:5678
```

### Daily Digest

```markdown
📊 *Daily Digest - {{date}}*

📋 *Content Status:*
• Draft: {{draft_count}}
• Pending Review: {{pending_count}}
• Approved: {{approved_count}}
• Scheduled: {{scheduled_count}}
• Published: {{published_count}}

📝 *Pending Review:*
{{#each pending_items}}
{{@index}}. {{this.title}} ({{this.pillar}})
{{/each}}

_Review at:_ http://localhost:5678
```

### Workflow Error Alert

```markdown
🚨 *Workflow Error Alert*

*Workflow:* {{workflow_name}}
*Status:* Error
*Time:* {{timestamp}}

*Error Message:*
```
{{error_message}}
```

_Check n8n for details_
```

### Batch Generation Complete

```markdown
📦 *Batch Generation Complete*

✅ Generated: {{count}} posts
📋 Status: Pending Review

*Topics:*
{{#each topics}}
• {{this}}
{{/each}}

_Review at:_ http://localhost:5678
```

### Health Check Alert

```markdown
🚨 *Service Health Alert*

*Time:* {{timestamp}}

*Service Status:*
• n8n: {{n8n_status}}
• PostgreSQL: {{postgres_status}}
• Ollama: {{ollama_status}}
• Redis: {{redis_status}}

⚠️ _Please check immediately!_
```

### Post Published

```markdown
🚀 *Post Published Successfully*

*Title:* {{title}}
*Platform:* {{platform}}
*Time:* {{published_at}}

🔗 {{post_url}}
```

---

## 7. Telegram Formatting Guide

### Markdown Mode

n8n Telegram node hỗ trợ Markdown:

```markdown
*Bold text*
_Italic text_
`Inline code`
```Code block```
[Link text](https://example.com)
```

### Emojis phổ biến

| Purpose | Emoji |
|---------|-------|
| Success | ✅ 🎉 🚀 |
| Error | ❌ 🚨 ⚠️ |
| Info | 📝 📊 📋 |
| Time | 📅 ⏰ |
| Review | 👀 🔍 |
| Content | 📄 📑 |

---

## 8. Troubleshooting

### Bot không gửi được message

1. **Check token**: Đảm bảo token đúng, không có space
2. **Check chat ID**: Phải là số, không có dấu
3. **Check bot đã được message**: Bạn phải message bot trước

### getUpdates trả về rỗng

1. Gửi message mới cho bot
2. Refresh URL getUpdates
3. Chat ID nằm trong message mới nhất

### n8n không connect được

1. Restart n8n: `docker-compose restart n8n`
2. Check credential đã save
3. Test token với curl trước

---

## 9. Security Notes

- ⚠️ **Không commit** token vào git
- ⚠️ **Không share** token publicly
- ✅ Lưu trong `.env` (đã có trong .gitignore)
- ✅ Rotate token nếu bị lộ (dùng `/revoke` với BotFather)

---

## Quick Reference

| Item | Value |
|------|-------|
| BotFather | @BotFather |
| Token format | `123456789:ABCxyz...` |
| getUpdates URL | `https://api.telegram.org/bot<TOKEN>/getUpdates` |
| sendMessage URL | `https://api.telegram.org/bot<TOKEN>/sendMessage` |
| n8n env var | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` |
