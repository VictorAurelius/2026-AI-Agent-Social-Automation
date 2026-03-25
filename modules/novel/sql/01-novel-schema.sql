-- Novel Translation Schema
-- Version: 1.0
-- Created: 2026-03-19
-- Database: agent_personal (shared)

-- Novel Registry
CREATE TABLE IF NOT EXISTS novel_registry (
    id SERIAL PRIMARY KEY,
    title_cn VARCHAR(255) NOT NULL,
    title_vn VARCHAR(255),
    author VARCHAR(100),
    source_site VARCHAR(50) DEFAULT 'shuhaige',
    base_url VARCHAR(500) NOT NULL,
    chapter_list_url VARCHAR(500),
    total_chapters INTEGER,
    genre VARCHAR(50) DEFAULT 'xianxia',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(title_cn, source_site)
);

-- Translation History (cache)
CREATE TABLE IF NOT EXISTS translation_history (
    id SERIAL PRIMARY KEY,
    novel_id INTEGER REFERENCES novel_registry(id) ON DELETE CASCADE,
    chapter_number INTEGER NOT NULL,
    chapter_title VARCHAR(255),
    source_url VARCHAR(500),
    original_text TEXT,
    translated_text TEXT,
    model_used VARCHAR(50) DEFAULT 'qwen2:7b',
    translation_time_ms INTEGER,
    char_count INTEGER,
    status VARCHAR(20) DEFAULT 'completed'
        CHECK (status IN ('pending', 'translating', 'completed', 'failed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(novel_id, chapter_number)
);

-- Translation Glossary
CREATE TABLE IF NOT EXISTS translation_glossary (
    id SERIAL PRIMARY KEY,
    genre VARCHAR(50) DEFAULT 'xianxia',
    term_cn VARCHAR(100) NOT NULL,
    term_vn VARCHAR(100) NOT NULL,
    pinyin VARCHAR(100),
    category VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(genre, term_cn)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_novel_title ON novel_registry(title_cn);
CREATE INDEX IF NOT EXISTS idx_translation_novel ON translation_history(novel_id, chapter_number);
CREATE INDEX IF NOT EXISTS idx_translation_status ON translation_history(status);
CREATE INDEX IF NOT EXISTS idx_glossary_genre ON translation_glossary(genre);
CREATE INDEX IF NOT EXISTS idx_glossary_term ON translation_glossary(term_cn);

-- Seed: Register first novel
INSERT INTO novel_registry (title_cn, title_vn, author, source_site, base_url, genre)
VALUES ('阵问长生', 'Trận Vấn Trường Sinh', '观虚', 'shuhaige', 'https://m.shuhaige.net/230050/', 'xianxia')
ON CONFLICT (title_cn, source_site) DO NOTHING;

-- Seed: Xianxia glossary (core terms)
INSERT INTO translation_glossary (genre, term_cn, term_vn, pinyin, category) VALUES
('xianxia', '修炼', 'tu luyện', 'xiū liàn', 'cultivation'),
('xianxia', '修士', 'tu sĩ', 'xiū shì', 'cultivation'),
('xianxia', '真气', 'chân khí', 'zhēn qì', 'cultivation'),
('xianxia', '灵气', 'linh khí', 'líng qì', 'cultivation'),
('xianxia', '丹田', 'đan điền', 'dān tián', 'cultivation'),
('xianxia', '经脉', 'kinh mạch', 'jīng mài', 'cultivation'),
('xianxia', '灵根', 'linh căn', 'líng gēn', 'cultivation'),
('xianxia', '功法', 'công pháp', 'gōng fǎ', 'cultivation'),
('xianxia', '炼气', 'Luyện Khí', 'liàn qì', 'realm'),
('xianxia', '筑基', 'Trúc Cơ', 'zhù jī', 'realm'),
('xianxia', '金丹', 'Kim Đan', 'jīn dān', 'realm'),
('xianxia', '元婴', 'Nguyên Anh', 'yuán yīng', 'realm'),
('xianxia', '化神', 'Hóa Thần', 'huà shén', 'realm'),
('xianxia', '渡劫', 'Độ Kiếp', 'dù jié', 'realm'),
('xianxia', '灵石', 'linh thạch', 'líng shí', 'item'),
('xianxia', '丹药', 'đan dược', 'dān yào', 'item'),
('xianxia', '法器', 'pháp khí', 'fǎ qì', 'item'),
('xianxia', '法宝', 'pháp bảo', 'fǎ bǎo', 'item'),
('xianxia', '储物袋', 'túi trữ vật', 'chǔ wù dài', 'item'),
('xianxia', '阵法', 'trận pháp', 'zhèn fǎ', 'item'),
('xianxia', '宗门', 'tông môn', 'zōng mén', 'sect'),
('xianxia', '掌门', 'chưởng môn', 'zhǎng mén', 'sect'),
('xianxia', '长老', 'trưởng lão', 'zhǎng lǎo', 'sect'),
('xianxia', '弟子', 'đệ tử', 'dì zǐ', 'sect'),
('xianxia', '内门', 'nội môn', 'nèi mén', 'sect'),
('xianxia', '外门', 'ngoại môn', 'wài mén', 'sect'),
('xianxia', '神识', 'thần thức', 'shén shí', 'combat'),
('xianxia', '剑气', 'kiếm khí', 'jiàn qì', 'combat'),
('xianxia', '威压', 'uy áp', 'wēi yā', 'combat'),
('xianxia', '禁制', 'cấm chế', 'jìn zhì', 'combat')
ON CONFLICT (genre, term_cn) DO NOTHING;

-- Seed: Novel-specific terms for 阵问长生
INSERT INTO translation_glossary (genre, term_cn, term_vn, pinyin, category, notes) VALUES
('xianxia', '墨画', 'Mặc Họa', 'mò huà', 'character', 'Nam chính'),
('xianxia', '通仙门', 'Thông Tiên Môn', 'tōng xiān mén', 'sect', 'Tông môn chính'),
('xianxia', '通仙城', 'Thông Tiên Thành', 'tōng xiān chéng', 'location', 'Thành phố'),
('xianxia', '道廷', 'Đạo Đình', 'dào tíng', 'organization', 'Quản lý tu đạo giới'),
('xianxia', '道历', 'Đạo lịch', 'dào lì', 'term', 'Lịch pháp'),
('xianxia', '道律', 'Đạo luật', 'dào lǜ', 'term', 'Luật tu đạo')
ON CONFLICT (genre, term_cn) DO NOTHING;

-- Verify
DO $$
DECLARE
    novel_count INTEGER;
    glossary_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO novel_count FROM novel_registry;
    SELECT COUNT(*) INTO glossary_count FROM translation_glossary;
    RAISE NOTICE 'Novel translation setup: % novels, % glossary terms', novel_count, glossary_count;
END $$;
