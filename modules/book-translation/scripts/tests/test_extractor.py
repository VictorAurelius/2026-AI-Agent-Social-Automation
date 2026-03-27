"""Tests for PDF/text extractor module."""
import pytest
from pathlib import Path

from lib.extractor import (
    detect_format,
    extract_pdf,
    detect_chapters,
    is_scanned_pdf,
    extract_to_chapters,
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
