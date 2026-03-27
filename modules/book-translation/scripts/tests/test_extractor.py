"""Tests for PDF/text extractor module."""
import pytest
from pathlib import Path

from lib.extractor import (
    detect_format,
    extract_pdf,
    detect_chapters,
    is_scanned_pdf,
    extract_to_chapters,
    extract_epub,
)

FIXTURES_DIR = Path(__file__).parent / "fixtures"


class TestDetectFormat:
    def test_pdf_extension(self):
        assert detect_format(Path("book.pdf")) == "pdf"

    def test_epub_extension(self):
        assert detect_format(Path("book.epub")) == "epub"

    def test_md_extension(self):
        assert detect_format(Path("book.md")) == "markdown"

    def test_txt_extension(self):
        assert detect_format(Path("book.txt")) == "markdown"

    def test_unknown_raises(self):
        with pytest.raises(ValueError, match="Unsupported"):
            detect_format(Path("book.docx"))


class TestIsScannedPdf:
    def test_text_pdf_is_not_scanned(self):
        pdf_path = FIXTURES_DIR / "sample.pdf"
        if not pdf_path.exists():
            pytest.skip("sample.pdf fixture not created yet")
        assert is_scanned_pdf(pdf_path) is False


class TestExtractPdf:
    @pytest.fixture
    def sample_pdf(self):
        path = FIXTURES_DIR / "sample.pdf"
        if not path.exists():
            pytest.skip("sample.pdf fixture not created yet")
        return path

    def test_extracts_text_blocks(self, sample_pdf):
        blocks = extract_pdf(sample_pdf)
        assert len(blocks) > 0
        assert "text" in blocks[0]
        assert "page" in blocks[0]
        assert "font_size" in blocks[0]

    def test_detects_headings_by_font_size(self, sample_pdf):
        blocks = extract_pdf(sample_pdf)
        headings = [b for b in blocks if b["is_heading"]]
        assert len(headings) >= 3


class TestDetectChapters:
    def test_splits_by_heading_pattern(self):
        blocks = [
            {"text": "Chapter 1: The Beginning", "is_heading": True, "page": 0, "font_size": 18},
            {"text": "Some content here.", "is_heading": False, "page": 0, "font_size": 12},
            {"text": "Chapter 2: The Middle", "is_heading": True, "page": 1, "font_size": 18},
            {"text": "More content.", "is_heading": False, "page": 1, "font_size": 12},
        ]
        chapters = detect_chapters(blocks)
        assert len(chapters) == 2
        assert chapters[0]["id"] == "ch01"
        assert chapters[0]["title"] == "Chapter 1: The Beginning"
        assert "Some content here." in chapters[0]["content"]

    def test_handles_no_chapter_pattern(self):
        blocks = [
            {"text": "Introduction", "is_heading": True, "page": 0, "font_size": 18},
            {"text": "Some text.", "is_heading": False, "page": 0, "font_size": 12},
        ]
        chapters = detect_chapters(blocks)
        assert len(chapters) == 1
        assert chapters[0]["id"] == "ch01"


class TestExtractToChapters:
    def test_writes_chapter_files(self, tmp_path):
        sample_pdf = FIXTURES_DIR / "sample.pdf"
        if not sample_pdf.exists():
            pytest.skip("sample.pdf fixture not created yet")
        output_dir = tmp_path / "chapters"
        output_dir.mkdir()
        chapters = extract_to_chapters(sample_pdf, output_dir)
        assert len(chapters) >= 1
        md_files = list(output_dir.glob("ch*.md"))
        assert len(md_files) >= 1
        content = md_files[0].read_text(encoding="utf-8")
        assert len(content) > 0


class TestExtractEpub:
    @pytest.fixture
    def sample_epub(self):
        path = FIXTURES_DIR / "sample.epub"
        if not path.exists():
            pytest.skip("sample.epub fixture not created yet")
        return path

    def test_extracts_chapters(self, sample_epub):
        """EPUB extraction returns list of chapter dicts with expected fields."""
        chapters = extract_epub(sample_epub)
        assert len(chapters) == 2
        assert chapters[0]["id"] == "ch01"
        assert chapters[1]["id"] == "ch02"
        assert "Chapter 1" in chapters[0]["title"]
        assert "Chapter 2" in chapters[1]["title"]

    def test_preserves_bold_markdown(self, sample_epub):
        """Bold <strong> tags should be converted to **text** markdown."""
        chapters = extract_epub(sample_epub)
        ch1_content = chapters[0]["content"]
        assert "**bold text**" in ch1_content

    def test_preserves_italic_markdown(self, sample_epub):
        """Italic <em> tags should be converted to *text* markdown."""
        chapters = extract_epub(sample_epub)
        ch1_content = chapters[0]["content"]
        assert "*italic text*" in ch1_content

    def test_preserves_blockquote(self, sample_epub):
        """Blockquote content should be rendered with > prefix."""
        chapters = extract_epub(sample_epub)
        ch2_content = chapters[1]["content"]
        assert "> " in ch2_content
        assert "wise man" in ch2_content


class TestExtractToChaptersEpub:
    def test_writes_chapter_files(self, tmp_path):
        """extract_to_chapters should handle EPUB and write chapter .md files."""
        sample_epub = FIXTURES_DIR / "sample.epub"
        if not sample_epub.exists():
            pytest.skip("sample.epub fixture not created yet")
        output_dir = tmp_path / "chapters"
        output_dir.mkdir()
        chapters = extract_to_chapters(sample_epub, output_dir)
        assert len(chapters) == 2
        md_files = sorted(output_dir.glob("ch*.md"))
        assert len(md_files) == 2
        content = md_files[0].read_text(encoding="utf-8")
        assert "Chapter 1" in content
