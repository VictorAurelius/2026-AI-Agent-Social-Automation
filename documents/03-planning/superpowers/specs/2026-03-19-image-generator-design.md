# Image Generator (Infographic Style) - Design Spec

**Created:** 2026-03-19
**Status:** Proposed
**Goal:** Tự động tạo infographic images (style ByteByteGo) từ AI content cho social media posts

---

## 1. Vấn đề

Bài viết có hình ảnh infographic engagement cao hơn 2-3x. Các influencers như ByteByteGo, Alex Xu tạo infographics chất lượng cao thu hút hàng nghìn engagement. Hệ thống cần tự động tạo được dạng hình này.

## 2. Phân tích phong cách mẫu

Từ phân tích 3 bài mẫu (bai-1.gif, bai-2.gif, bai-3.gif):

### Kiểu 1: Grid Cards (bai-1 - "Top 12 AI GitHub Repos")
- Grid layout 3x4 hoặc 3x3
- Mỗi card: số thứ tự + tên + icon/logo + mô tả ngắn
- Background xanh nhạt, cards trắng
- Brand header + logo góc phải

### Kiểu 2: Architecture Diagram (bai-2 - "AI Agent Protocols")
- Sơ đồ kiến trúc với boxes, arrows
- Comparison table ở dưới
- Multiple sections organized vertically
- Color-coded cho mỗi protocol

### Kiểu 3: Flow/Sequence Diagram (bai-3 - "How SSO Works")
- Sequence diagram với actors
- Arrows cho flow direction
- Step-by-step process
- Color blocks cho different phases

## 3. Giải pháp: HTML → Browserless → PNG

### Tại sao HTML?
1. **Linh hoạt nhất**: CSS Grid, Flexbox, fonts, colors
2. **Dễ template hóa**: Inject data vào HTML template
3. **Responsive**: Dễ điều chỉnh kích thước
4. **Không cần GPU**: Browserless Chrome render
5. **Consistent**: Pixel-perfect output mọi lần

### Supported Image Types

| Type | Template | Use Case | Platforms |
|------|----------|----------|-----------|
| **Grid Cards** | `grid-cards.html` | Top N lists, tool comparison | LinkedIn, FB |
| **Comparison Table** | `comparison.html` | A vs B, feature matrix | LinkedIn, FB |
| **Process Flow** | `process-flow.html` | Step-by-step, how-to | LinkedIn, FB |
| **Stats/Numbers** | `stats-highlight.html` | Key metrics, facts | LinkedIn, FB |
| **Chinese Vocab** | `vocab-card.html` | HSK vocabulary | FB Chinese |

## 4. Template Designs

### Template 1: Grid Cards (ByteByteGo style)

```
┌──────────────────────────────────────────┐
│ ▌Title                        @brand     │
├──────────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐              │
│ │  1   │ │  2   │ │  3   │              │
│ │ Name │ │ Name │ │ Name │              │
│ │ Icon │ │ Icon │ │ Icon │              │
│ │ Desc │ │ Desc │ │ Desc │              │
│ └──────┘ └──────┘ └──────┘              │
│ ┌──────┐ ┌──────┐ ┌──────┐              │
│ │  4   │ │  5   │ │  6   │              │
│ │ ...  │ │ ...  │ │ ...  │              │
│ └──────┘ └──────┘ └──────┘              │
└──────────────────────────────────────────┘
```

### Template 2: Comparison Table

```
┌──────────────────────────────────────────┐
│ ▌Title: A vs B                           │
├──────────────────────────────────────────┤
│         │    A    │    B    │             │
│─────────┼─────────┼─────────│             │
│ Feature │   ✅    │   ❌    │             │
│ Feature │   ❌    │   ✅    │             │
│ Feature │   ✅    │   ✅    │             │
│ Price   │  Free   │ $10/mo │             │
├──────────────────────────────────────────┤
│ Verdict: A for X, B for Y               │
└──────────────────────────────────────────┘
```

### Template 3: Process Flow

```
┌──────────────────────────────────────────┐
│ ▌How X Works                             │
├──────────────────────────────────────────┤
│                                          │
│  ┌─────┐    ┌─────┐    ┌─────┐          │
│  │  1  │ →  │  2  │ →  │  3  │          │
│  │Step │    │Step │    │Step │          │
│  └─────┘    └─────┘    └─────┘          │
│       ↓                                  │
│  ┌─────┐    ┌─────┐    ┌─────┐          │
│  │  4  │ →  │  5  │ →  │  6  │          │
│  │Step │    │Step │    │Step │          │
│  └─────┘    └─────┘    └─────┘          │
│                                          │
└──────────────────────────────────────────┘
```

## 5. Ollama Prompt cho Structured Output

System prompt yêu cầu output JSON:

```json
{
  "type": "grid_cards",
  "title": "Top 5 AI Tools",
  "items": [
    {
      "number": 1,
      "name": "GitHub Copilot",
      "description": "AI pair programmer",
      "category": "Coding"
    }
  ],
  "footer": "@VictorAurelius | #AI #DevTools"
}
```

## 6. WF10: Image Generator Workflow

```
[Manual Trigger / Telegram /image command]
       │
       ▼
[Select Template Type] ── grid_cards, comparison, process_flow
       │
       ▼
[Generate Structured Content] ── Ollama API (JSON output)
       │
       ▼
[Build HTML] ── Inject data into template
       │
       ▼
[Screenshot] ── POST browserless /screenshot
       │           width: 1080, height: auto
       ▼
[Save Image] ── Save PNG to filesystem
       │
       ▼
[Attach to Content] ── Link image to content_queue entry
       │
       ▼
[Telegram Notify] ── Send image preview + confirmation
```

## 7. Kích thước output

| Platform | Width | Height | Format |
|----------|-------|--------|--------|
| LinkedIn feed | 1200 | 628 | PNG |
| LinkedIn/FB square | 1080 | 1080 | PNG |
| FB Tech | 1080 | 1080 | PNG |
| FB Chinese vocab | 1080 | 1080 | PNG |
| Story | 1080 | 1920 | PNG |

## 8. Brand System

```css
:root {
  --primary: #2563EB;
  --secondary: #10B981;
  --accent: #F59E0B;
  --dark-bg: #1E293B;
  --light-bg: #F0FDF4;  /* mint green like ByteByteGo */
  --card-bg: #FFFFFF;
  --text-dark: #1E293B;
  --text-muted: #64748B;
  --border-radius: 12px;
  --font: 'Noto Sans', sans-serif;
}
```

## 9. Kế hoạch triển khai

### Phase 1 (Week 1): Templates
- Tạo 5 HTML templates
- Test rendering trong browser
- Verify responsive design

### Phase 2 (Week 2): Workflow
- Browserless integration
- WF10 workflow trong n8n
- Ollama structured prompts

### Phase 3 (Week 3): Integration
- Telegram Bot /image command
- Auto-attach to content_queue
- A/B test with/without images

## 10. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Ollama JSON unreliable | High | JSON validation + fallback template |
| Browserless OOM | Medium | Memory limits + session caps |
| Font rendering | Low | Use web-safe fonts + embed Noto Sans |
| Image too large | Low | Optimize PNG compression |
