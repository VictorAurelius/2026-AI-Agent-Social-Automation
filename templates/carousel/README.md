# Carousel Slide Templates

HTML templates for generating LinkedIn/Facebook carousel PDFs.

## Templates

| File | Slide Type | Background |
|------|-----------|------------|
| `cover.html` | Cover slide (slide 1) | Dark gradient |
| `content.html` | Content slides (2-6) | White |
| `cta.html` | CTA slide (last) | Blue gradient |

## Placeholders

### cover.html
- `{{TITLE}}` - Main title
- `{{HOOK}}` - Subtitle/hook text

### content.html
- `{{NUMBER}}` - Slide number
- `{{HEADING}}` - Point heading
- `{{SUBHEADING}}` - Category/subtitle
- `{{BODY}}` - Main content
- `{{HIGHLIGHT}}` - Key takeaway
- `{{TOTAL}}` - Total slides

### cta.html
- `{{CTA}}` - Author/follow text
- `{{HASHTAGS}}` - Hashtag string
- `{{SUMMARY}}` - Brief summary

## Dimensions
- Default: 1080x1080 (square, works on all platforms)
- LinkedIn recommended: 1080x1350 (4:5)

## Brand Colors
- Primary: `#2563EB` (blue)
- Dark BG: `#1E293B`
- Text: `#1E293B` (dark) / `#FFFFFF` (light)
- Muted: `#94A3B8` / `#475569`
- Highlight BG: `#F0F9FF`

## Usage
Rendered by Browserless Chrome via n8n WF9 workflow.
See `docs/superpowers/specs/2026-03-19-pdf-carousel-design.md` for details.
