# modules/book-translation/scripts/tests/test_merger.py
"""Tests for chapter merger module."""
import pytest
from pathlib import Path
from lib.merger import merge_chapters, resolve_sections


class TestResolveSections:
    def test_single_section_returns_file(self, tmp_path):
        ch1 = tmp_path / "ch01.md"
        ch1.write_text("# Chapter 1\n\nContent here.\n", encoding="utf-8")
        result = resolve_sections(tmp_path, "ch01", sections=1)
        assert len(result) == 1
        assert result[0] == ch1

    def test_multiple_sections_returns_ordered(self, tmp_path):
        for i in range(1, 4):
            f = tmp_path / f"ch02-s{i}.md"
            f.write_text(f"Section {i} content.\n", encoding="utf-8")
        result = resolve_sections(tmp_path, "ch02", sections=3)
        assert len(result) == 3
        assert result[0].name == "ch02-s1.md"
        assert result[2].name == "ch02-s3.md"

    def test_missing_section_raises(self, tmp_path):
        (tmp_path / "ch03-s1.md").write_text("s1", encoding="utf-8")
        (tmp_path / "ch03-s3.md").write_text("s3", encoding="utf-8")
        with pytest.raises(FileNotFoundError, match="ch03-s2"):
            resolve_sections(tmp_path, "ch03", sections=3)


class TestMergeChapters:
    def test_merges_single_file_chapters(self, tmp_path):
        (tmp_path / "ch01.md").write_text("# Ch 1\n\nContent 1.\n", encoding="utf-8")
        (tmp_path / "ch02.md").write_text("# Ch 2\n\nContent 2.\n", encoding="utf-8")
        progress_chapters = [
            {"id": "ch01", "sections": 1},
            {"id": "ch02", "sections": 1},
        ]
        result = merge_chapters(tmp_path, progress_chapters)
        assert "Content 1." in result
        assert "Content 2." in result
        assert result.index("Content 1.") < result.index("Content 2.")

    def test_merges_multi_section_chapters(self, tmp_path):
        (tmp_path / "ch01.md").write_text("# Ch 1\n\nSingle.\n", encoding="utf-8")
        (tmp_path / "ch02-s1.md").write_text("Section 1.\n", encoding="utf-8")
        (tmp_path / "ch02-s2.md").write_text("Section 2.\n", encoding="utf-8")
        progress_chapters = [
            {"id": "ch01", "sections": 1},
            {"id": "ch02", "sections": 2},
        ]
        result = merge_chapters(tmp_path, progress_chapters)
        assert "Single." in result
        assert "Section 1." in result
        assert "Section 2." in result

    def test_strips_frontmatter(self, tmp_path):
        (tmp_path / "ch01.md").write_text("---\nchapter: 1\nstatus: draft\n---\n\n# Ch 1\n\nContent.\n", encoding="utf-8")
        progress_chapters = [{"id": "ch01", "sections": 1}]
        result = merge_chapters(tmp_path, progress_chapters)
        assert "Content." in result
        assert "status: draft" not in result
