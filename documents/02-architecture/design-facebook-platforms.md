# Thiết kế: Mở rộng sang Facebook Tech và Facebook Tiếng Trung

## Tổng quan

Dự án hiện chỉ có workflows cho LinkedIn. Document này thiết kế mở rộng sang 2 Facebook Pages:
1. **Facebook Tech Page** - Chia sẻ tech news, tutorials cho developers Việt Nam
2. **Facebook Chinese Page** - Dạy tiếng Trung cho người Việt (HSK 1-4)

## 1. Facebook Tech Page

### Content Pillars

| Pillar | % | Tần suất | Mô tả |
|--------|---|----------|--------|
| Tech News | 35% | 2-3/tuần | Tin công nghệ mới, AI updates |
| Tutorials | 30% | 2/tuần | Hướng dẫn step-by-step |
| Tools & Tips | 20% | 1-2/tuần | Công cụ hữu ích, productivity |
| Community | 15% | 1/tuần | Câu hỏi, thảo luận, poll |

### Tone & Style
- Casual, friendly (khác LinkedIn professional)
- Nhiều emoji hơn LinkedIn
- Ngôn ngữ: Vietnamese chủ yếu, English technical terms
- Độ dài: 100-200 từ (ngắn hơn LinkedIn)
- Hashtags: 3-5 tags

### Prompt Templates cần tạo

1. `fb_tech_news` - Tóm tắt tin công nghệ + ý kiến cá nhân
2. `fb_tech_tutorial` - Hướng dẫn ngắn với code examples
3. `fb_tech_tools` - Giới thiệu tools với pros/cons
4. `fb_tech_community` - Câu hỏi thảo luận

### Posting Schedule
```
Thứ 2: Tech News (8AM)
Thứ 3: Tutorial (12PM)
Thứ 4: Tech News (8AM)
Thứ 5: Tools & Tips (12PM)
Thứ 6: Community (6PM)
Thứ 7: Tutorial (10AM)
```

## 2. Facebook Chinese Page

### Content Pillars

| Pillar | % | Tần suất | Mô tả |
|--------|---|----------|--------|
| Vocabulary | 35% | Hàng ngày | Từ vựng HSK 1-4 + ví dụ |
| Grammar | 25% | 2-3/tuần | Ngữ pháp với examples |
| Culture | 20% | 1-2/tuần | Văn hóa Trung Quốc |
| Practice | 20% | 1-2/tuần | Bài tập, quiz, challenge |

### Tone & Style
- Supportive, encouraging (giáo viên thân thiện)
- Mix Vietnamese + Chinese (有标注拼音)
- Pinyin cho mọi từ mới
- Mức: HSK 1-4 (beginner → intermediate)
- Độ dài: 150-250 từ
- Emoji: Nhiều, thân thiện

### Prompt Templates cần tạo

1. `fb_chinese_vocab` - Từ vựng mới + pinyin + ví dụ + mẹo nhớ
2. `fb_chinese_grammar` - Giải thích ngữ pháp + so sánh Việt-Trung
3. `fb_chinese_culture` - Văn hóa + từ vựng liên quan
4. `fb_chinese_practice` - Bài tập, câu hỏi trắc nghiệm

### Posting Schedule
```
Hàng ngày 7AM: Vocabulary (1 từ/ngày)
Thứ 2, 4: Grammar (10AM)
Thứ 3, 6: Practice/Quiz (6PM)
Thứ 7: Culture (10AM)
```

## Database Changes

### Thêm prompt templates
Cần INSERT 8 prompts mới (4 per page) vào bảng `prompts`.

### Thêm topic ideas
Cần INSERT 20 topics (10 per page) vào bảng `topic_ideas`.

### Platform values
Mở rộng content_queue.platform:
- `linkedin` (hiện có)
- `facebook_tech` (mới)
- `facebook_chinese` (mới)

## Workflow Changes

### Batch Generate (WF2)
- Cần thêm schedule cho Facebook pages
- Có thể tạo WF riêng hoặc mở rộng WF2 hiện tại

### Đề xuất: Tạo WF riêng cho mỗi page
- WF2a: Batch Generate LinkedIn (hiện có)
- WF2b: Batch Generate FB Tech
- WF2c: Batch Generate FB Chinese

## Timeline

### Phase 1 (Week 1): Facebook Tech
- Tạo prompt templates
- Thêm topic ideas
- Setup Facebook Page
- Test content generation

### Phase 2 (Week 2): Facebook Chinese
- Tạo prompt templates (cần Chinese proficiency review)
- Thêm topic ideas
- Setup Facebook Page
- Test content quality

### Phase 3 (Week 3): Auto-posting
- Connect Facebook API
- Enable auto-posting for both pages
- Monitor quality

## Risks
- **FB Chinese quality:** Llama 3.1 8B có thể không đủ tốt cho Chinese content
  - Mitigation: Test kỹ, có thể cần model khác (Qwen2 7B tốt hơn cho Chinese)
- **Content volume:** 3 pages = nhiều content hơn
  - Mitigation: Batch generate cho tất cả pages cùng lúc
