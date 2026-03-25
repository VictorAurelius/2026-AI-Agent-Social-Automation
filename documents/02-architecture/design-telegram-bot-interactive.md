# Thiết kế: Telegram Bot Tương tác

## Tổng quan

Nâng cấp Telegram Bot từ **chỉ thông báo** thành **tương tác 2 chiều**, cho phép user điều khiển hệ thống qua lệnh Telegram.

## Kiến trúc hiện tại vs Đề xuất

```
HIỆN TẠI (1 chiều):
  n8n Workflow → Telegram Bot → User (chỉ nhận thông báo)

ĐỀ XUẤT (2 chiều):
  User ←→ Telegram Bot ←→ n8n ←→ Ollama/PostgreSQL

  User gửi lệnh → Bot nhận → n8n xử lý → Bot trả kết quả
```

## Danh sách lệnh

### Lệnh tạo nội dung
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/generate <topic>` | Tạo 1 bài viết LinkedIn (Ollama -> DB -> Reply) | `/generate AI tools cho developers` |
| `/suggest` | AI gợi ý 5 topic ideas | `/suggest` |
| `/addtopic <topic>\|<pillar>\|<priority>` | Thêm topic mới vào DB | `/addtopic AI trends\|tech_insights\|3` |

### Lệnh quản lý nội dung
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/status` | Xem thống kê content queue | `/status` |
| `/pending` | Liệt kê bài chờ review | `/pending` |
| `/view <id>` | Xem nội dung đầy đủ | `/view 15` |
| `/approve <id>` | Duyệt bài viết | `/approve 15` |
| `/reject <id> <lý do>` | Từ chối bài viết | `/reject 15 cần thêm ví dụ` |

### Lệnh quản lý topics
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/topics` | Xem topics chưa dùng | `/topics` |

### Lệnh đăng bài
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/post_linkedin` | Lấy bài LinkedIn approved để copy-paste đăng | `/post_linkedin` |
| `/post_fb` | Lấy bài Facebook approved | `/post_fb` |
| `/published <id> <url>` | Cập nhật trạng thái đã đăng + URL | `/published 15 https://linkedin.com/post/123` |

### Lệnh hệ thống
| Lệnh | Mô tả |
|-------|--------|
| `/health` | Kiểm tra Ollama + PostgreSQL status |
| `/help` | Hiển thị danh sách lệnh (15 commands) |

## Workflow mới: WF6 Telegram Bot

### Sơ đồ

```
[Telegram Trigger] ── Nhận message từ user
       │
       ▼
[Extract Command] ── Parse lệnh và tham số
       │
       ▼
[Switch/Router] ── Phân loại lệnh
       │
       ├── /help → [Reply Help Text]
       ├── /status → [Query Stats] → [Format] → [Reply]
       ├── /pending → [Query Pending] → [Format] → [Reply]
       ├── /view → [Query Content] → [Format] → [Reply]
       ├── /approve → [Update Status] → [Reply]
       ├── /reject → [Prepare Reject] → [Do Reject] → [Reply]
       ├── /generate → [Get Prompt] → [Prepare Prompt] → [Ollama] → [Parse+Save] → [Save DB] → [Reply]
       ├── /topics → [Query Topics] → [Format] → [Reply]
       ├── /health → [Check Ollama] → [Check Postgres] → [Evaluate] → [Reply]
       ├── /addtopic → [Parse Args] → [INSERT topic_ideas] → [Reply]
       ├── /published → [Parse Args] → [UPDATE content_queue] → [Reply]
       ├── /suggest → [Call Ollama] → [Format] → [Reply]
       ├── /post_fb → [Get FB Content] → [Format] → [Reply]
       ├── /post_linkedin → [Get LI Content] → [Format] → [Reply]
       └── fallback → [Reply Help Text]
```

### Chi tiết kỹ thuật

#### Telegram Trigger Node
- Type: `n8n-nodes-base.telegramTrigger`
- Updates: `message`
- Nhận mọi tin nhắn gửi đến bot

#### Extract Command (Code Node)
```javascript
const message = $json.message.text || '';
const parts = message.split(' ');
const command = parts[0].toLowerCase();
const args = parts.slice(1).join(' ');
const chatId = $json.message.chat.id;

return { command, args, chatId, rawMessage: message };
```

#### Switch Node
- Route theo giá trị `command`
- Mỗi route xử lý 1 lệnh cụ thể

#### Response Format
Tất cả response dùng Markdown, gửi về cùng chat_id

### Ví dụ Response

#### `/generate AI tools`
```
🤖 Đang tạo nội dung...

📝 *Kết quả:*

[Nội dung bài viết đầy đủ ở đây]

---
📋 ID: #23
📌 Platform: LinkedIn
🏷️ Pillar: tech_insights
⏳ Status: pending_review

Dùng `/approve 23` để duyệt hoặc `/reject 23 <lý do>` để từ chối.
```

#### `/status`
```
📊 *Content Queue Status*

• Draft: 2
• ⏳ Pending Review: 5
• ✅ Approved: 3
• 📅 Scheduled: 1
• 🚀 Published: 12
• ❌ Rejected: 2

📝 Unused Topics: 7

Dùng `/pending` để xem chi tiết bài chờ review.
```

#### `/view 15`
```
📄 *Content #15*

*Title:* AI đang thay đổi cách developers làm việc
*Platform:* LinkedIn
*Pillar:* tech_insights
*Status:* pending_review
*Created:* 2026-03-19 08:30

---

[Nội dung đầy đủ bài viết]

---

✅ `/approve 15` | ❌ `/reject 15 <lý do>`
```

## Yêu cầu kỹ thuật

### n8n Configuration
- Cần Telegram Trigger node (khác với Telegram Send node)
- Bot phải được set commands qua BotFather: `/setcommands`
- Workflow phải luôn ACTIVE để nhận messages

### BotFather Commands Setup
```
generate - Tạo bài viết LinkedIn từ chủ đề
suggest - AI gợi ý 5 topic ideas
addtopic - Thêm topic mới (topic|pillar|priority)
status - Xem thống kê content queue
pending - Liệt kê bài chờ review
view - Xem nội dung đầy đủ (dùng: /view ID)
approve - Duyệt bài viết (dùng: /approve ID)
reject - Từ chối bài (dùng: /reject ID lý do)
topics - Xem danh sách topics chưa dùng
post_linkedin - Lấy bài LinkedIn approved để đăng
post_fb - Lấy bài Facebook approved
published - Cập nhật đã đăng (dùng: /published ID URL)
health - Kiểm tra Ollama + PostgreSQL
help - Hiển thị trợ giúp
```

### Security
- Chỉ cho phép chat_id của owner tương tác
- Reject mọi message từ chat_id khác
- Log tất cả commands vào workflow_logs

## Trạng thái triển khai

Tất cả 15 commands đã được implement trong `workflows/n8n/telegram-bot.json`:

- `/help`, `/status`, `/pending`, `/view`, `/approve`, `/reject` - Core commands
- `/generate` - Full Ollama integration (prompt -> generate -> save -> reply)
- `/topics` - Query unused topics
- `/health` - Check Ollama + PostgreSQL status
- `/addtopic` - Parse topic|pillar|priority and INSERT
- `/published` - Mark content as published with URL
- `/suggest` - AI-powered topic idea generation
- `/post_linkedin` - Get approved LinkedIn content for copy-paste
- `/post_fb` - Get approved Facebook content
