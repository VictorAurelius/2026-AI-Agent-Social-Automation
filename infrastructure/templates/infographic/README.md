# Infographic Templates

HTML templates for generating social media infographics (ByteByteGo style).

## Templates

| File | Type | Best For |
|------|------|----------|
| `grid-cards.html` | Grid layout | Top N lists, tool collections |
| `comparison.html` | Table format | A vs B, feature comparison |
| `process-flow.html` | Step-by-step | How-to, workflows, processes |
| `vocab-card.html` | Vocabulary | Chinese learning (HSK) |

## Style Guide

Inspired by ByteByteGo/Alex Xu infographic style:
- Clean, minimal design
- Light background (#F0FDF4 mint or #F8FAFC gray)
- White cards with subtle shadows
- Accent line before titles
- Brand mark in header
- Consistent typography hierarchy

## Placeholders

Each template uses `{{PLACEHOLDER}}` syntax.
Data is injected by n8n Code node before rendering.

## Rendering

Templates are rendered by Browserless Chrome:
```
POST http://browserless:3000/screenshot
Body: { "html": "<rendered template>", "options": { "width": 1080 } }
```

## Brand Colors
- Primary: `#2563EB` (blue)
- Secondary: `#10B981` (green/mint)
- Accent: `#F59E0B` (amber)
- Dark: `#1E293B`
- Light BG: `#F0FDF4` or `#F8FAFC`
