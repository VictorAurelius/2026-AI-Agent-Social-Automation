# Thiết kế: Tạo Hình ảnh cho Social Media Posts

## Vấn đề
Hiện tại hệ thống chỉ tạo content chữ. Social media posts có hình ảnh engagement cao hơn 2-3x.

## Phân tích các giải pháp

### Option A: Template-based (ImageMagick/Sharp) - RECOMMENDED
- Chi phí: $0
- RAM: Minimal
- Cách hoạt động: Tạo sẵn template PNG/SVG, overlay text lên bằng ImageMagick
- Ưu: Nhanh, consistent brand, không cần GPU
- Nhược: Design cố định, ít creative

Workflow:
```
Content text → Extract key points → Select template → Overlay text → Output PNG
```

Docker addition:
```yaml
imagemagick:
  image: dpokidov/imagemagick
  # hoặc cài trực tiếp vào n8n container
```

### Option B: Stable Diffusion (Local)
- Chi phí: $0
- RAM: +8-12GB VRAM (cần GPU NVIDIA)
- Cách hoạt động: Generate ảnh từ text prompt
- Ưu: Creative, unique images
- Nhược: Cần GPU, chậm trên CPU (5-10 phút/ảnh)

Không recommended cho setup hiện tại (không có GPU rời).

### Option C: Canva API
- Chi phí: $13/mo (Canva Pro)
- Cách hoạt động: Dùng Canva API tạo design từ template
- Ưu: Professional quality
- Nhược: Cần Pro subscription, API limited

### Option D: External API (DALL-E, etc.)
- Chi phí: ~$0.04/ảnh (DALL-E 3)
- Ưu: High quality, fast
- Nhược: Tốn tiền, không local

## Recommendation: Option A (Template-based)

### Lý do:
1. $0 chi phí - phù hợp mục tiêu dự án
2. Không cần GPU
3. Consistent branding
4. Nhanh (~1 giây/ảnh)
5. Dễ maintain

### Template Types

| Type | Platform | Kích thước | Dùng cho |
|------|----------|-----------|----------|
| Quote Card | LinkedIn, FB | 1200x628 | Thought leadership, tips |
| Tech Tip | FB Tech | 1080x1080 | Tutorial, code snippets |
| List Post | LinkedIn | 1200x1500 | Numbered lists, tips |
| Story Card | FB, IG | 1080x1920 | Quick tips, vocab |
| Chinese Vocab | FB Chinese | 1080x1080 | HSK vocabulary |

### Template Design

Mỗi template cần:
1. Background (solid color hoặc gradient)
2. Brand elements (logo, colors)
3. Text area (title, body, hashtags)
4. Visual accents (icons, lines)

Brand Colors:
```
Primary: #2563EB (blue)
Secondary: #10B981 (green)
Accent: #F59E0B (amber)
Background: #1E293B (dark) hoặc #F8FAFC (light)
Text: #FFFFFF (on dark) hoặc #1E293B (on light)
```

### Implementation Plan

Phase 1: Template Creation
- Tạo 5 SVG templates (1 per type)
- Test với ImageMagick
- Store templates trong repo

Phase 2: n8n Integration
- Tạo WF9: Image Generator
- Input: title, body text, template type
- Output: PNG file
- Save to filesystem hoặc upload

Phase 3: Integration với existing workflows
- WF1/WF2 tạo text → trigger WF9 → attach image

### Ví dụ ImageMagick Command

```bash
# Quote Card
convert template-quote.png \
  -font "Noto-Sans-Bold" \
  -pointsize 48 \
  -fill white \
  -gravity center \
  -annotate +0-50 "AI Tools Every Developer\nShould Know in 2026" \
  -pointsize 24 \
  -annotate +0+80 "@VictorAurelius | #TechInsights" \
  output.png
```

### WF9: Image Generator (Workflow)

```
[Trigger] → [Select Template] → [Prepare Text] → [Generate Image] → [Save/Upload]
```

Sẽ implement chi tiết trong PR riêng sau khi approve design.

## Kế hoạch triển khai

### Phase 1 (Week 1): Template prep
- Thiết kế 5 SVG/PNG templates
- Test ImageMagick commands
- Add imagemagick to Docker Compose

### Phase 2 (Week 2): Workflow
- Create WF9 in n8n
- Test end-to-end
- Integrate with WF1/WF2

### Phase 3 (Week 3): Polish
- A/B test designs
- Optimize for each platform
- Add more template variants
