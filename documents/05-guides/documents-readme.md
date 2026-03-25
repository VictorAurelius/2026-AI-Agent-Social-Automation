# 📚 Documents - AI Agent Personal

> Tài liệu chiến lược cho các AI Agent tự động hóa social media

---

## 📂 Cấu trúc thư mục

```
documents/
├── README.md (file này)
├── linkedin/               → Chiến lược LinkedIn AI Agent
├── facebook/
│   ├── tech-page/         → Facebook Page về Tech (Lập trình, AI, Cloud)
│   └── chinese-page/      → Facebook Page về Học tiếng Trung
├── tech-stack/            → Tech stack & tools overview
└── 99-archived/           → Các file cũ không còn sử dụng
```

---

## 🎯 Mục đích từng folder

### [`strategies/linkedin/`](./strategies/linkedin/)
Chiến lược xây dựng thương hiệu cá nhân trên LinkedIn với AI Agent
- **Audience**: Professionals, developers, IT professionals
- **Focus**: Personal branding, product promotion, networking
- **Status**: Đang phát triển

### [`strategies/facebook-tech/`](./strategies/facebook-tech/)
Chiến lược Facebook Page về Lập trình, AI, Cloud
- **Audience**: Developers Việt Nam (junior-mid level)
- **Focus**: Tech news, tutorials, tools
- **Monetization**: Affiliate, digital products, courses

### [`strategies/facebook-chinese/`](./strategies/facebook-chinese/)
Chiến lược Facebook Page dạy tiếng Trung
- **Audience**: Người Việt học tiếng Trung (HSK 1-4)
- **Focus**: Vocabulary, grammar, culture
- **Monetization**: Courses, coaching, digital products

### [`tech-stack/`](./tech-stack/)
Tổng quan tech stack, tools, và infrastructure cho các AI Agents
- **Automation tools**: n8n, Make.com
- **AI**: Claude API, GPT-4
- **Storage**: Notion, Airtable
- **Publishing**: Meta Graph API, LinkedIn API

### [`workflows/`](./workflows/)
Tài liệu về automation workflows
- Content generation workflows
- Publishing workflows
- Analytics workflows

### [`templates/`](./templates/)
Tài liệu về templates
- Content templates documentation
- Design template guidelines

### [`archived/`](./archived/)
Các file cũ, drafts không còn sử dụng
- Giữ lại để tham khảo nếu cần

### [`archived-reference/`](./archived-reference/)
Tài liệu reference từ dự án cũ (KiteClass)
- GitHub CI cleanup policy
- PR template patterns

---

## 🚀 Trạng thái dự án

| Platform | Page/Profile | Status | Priority | Feasibility Score |
|----------|-------------|--------|----------|-------------------|
| **LinkedIn** | Personal Profile | 📋 Planning | High | 7.2/10 |
| **Facebook** | Tech Page | 📋 Planning | High | 7.9/10 |
| **Facebook** | Chinese Page | 📋 Planning | Medium | 8.1/10 |

---

## 📖 Cách sử dụng

1. **Đọc chiến lược**: Chọn platform bạn muốn triển khai
2. **Review tech stack**: Xem [`tech-stack/overview.md`](./tech-stack/overview.md) để hiểu tools cần dùng
3. **Setup automation**: Follow [automation-setup skill](../.claude/skills/automation-setup.md)
4. **Use templates**: Apply [content templates](../.claude/skills/content-templates.md)
5. **Track performance**: Use [analytics tracking](../.claude/skills/analytics-tracking.md)

## 🛠️ Skills & Best Practices

Xem [SKILLS-README.md](../SKILLS-README.md) cho danh sách đầy đủ skills và best practices của dự án.

**Core Skills cho AI Agent:**
- **Automation Setup** - Make.com/n8n configuration
- **Content Templates** - Reusable templates for all platforms
- **Prompt Engineering** - AI prompt best practices
- **Notion Database** - Database schemas & setup
- **Analytics Tracking** - Metrics & optimization

---

## 🛠️ Tech Stack Chung

- **Orchestration**: n8n (self-hosted) hoặc Make.com
- **AI Engine**: Claude API (Anthropic)
- **Content Management**: Notion
- **Design**: Canva Pro
- **Publishing**: Meta Graph API, LinkedIn API
- **Analytics**: Platform-native insights + Notion dashboards
- **Notifications**: Telegram Bot

Chi tiết: [`tech-stack/overview.md`](./tech-stack/overview.md)

---

## 📞 Support

Nếu có thắc mắc về bất kỳ chiến lược nào, refer back to the specific strategy document.

**Last updated**: 2026-03-13
