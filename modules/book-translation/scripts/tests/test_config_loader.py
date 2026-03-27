# modules/book-translation/scripts/tests/test_config_loader.py
"""Tests for config_loader module."""
import os
import pytest
import yaml
from pathlib import Path

from lib.config_loader import (
    load_config,
    load_progress,
    save_progress,
    init_config,
    init_progress,
    get_project_path,
    get_next_chapter,
    slugify,
    VALID_STATUSES,
)


@pytest.fixture
def tmp_project(tmp_path):
    """Create a temporary project directory with basic structure."""
    project_dir = tmp_path / "test-book"
    project_dir.mkdir()
    (project_dir / "source" / "chapters").mkdir(parents=True)
    (project_dir / "translated").mkdir()
    (project_dir / "output").mkdir()
    return project_dir


class TestSlugify:
    def test_simple_title(self):
        assert slugify("Test Book") == "test-book"

    def test_long_title(self):
        assert slugify("What Life Should Mean to You") == "what-life-should-mean-to-you"

    def test_special_characters(self):
        assert slugify("Hello: World! (2024)") == "hello-world-2024"


class TestInitConfig:
    def test_creates_config_yaml(self, tmp_project):
        config = init_config(
            project_dir=tmp_project,
            title="Test Book",
            author="Test Author",
            source_format="pdf",
            source_file="source/original.pdf",
        )
        config_path = tmp_project / "config.yaml"
        assert config_path.exists()
        assert config["book"]["title"] == "Test Book"
        assert config["book"]["author"] == "Test Author"
        assert config["book"]["slug"] == "test-book"
        assert config["source"]["format"] == "pdf"
        assert config["chunking"]["max_section_words"] == 3000

    def test_generates_slug_from_title(self, tmp_project):
        config = init_config(
            project_dir=tmp_project,
            title="What Life Should Mean to You",
            author="Alfred Adler",
            source_format="pdf",
            source_file="source/original.pdf",
        )
        assert config["book"]["slug"] == "what-life-should-mean-to-you"


class TestInitProgress:
    def test_creates_progress_yaml(self, tmp_project):
        chapters = [
            {"id": "ch01", "title": "Chapter One", "word_count": 2000},
            {"id": "ch02", "title": "Chapter Two", "word_count": 5000},
        ]
        progress = init_progress(tmp_project, chapters)
        progress_path = tmp_project / "progress.yaml"
        assert progress_path.exists()
        assert progress["status"] == "extracting"
        assert len(progress["chapters"]) == 2
        assert progress["chapters"][0]["status"] == "extracted"
        assert progress["chapters"][1]["sections"] == 1

    def test_auto_sections_for_long_chapters(self, tmp_project):
        chapters = [
            {"id": "ch01", "title": "Long Chapter", "word_count": 9200},
        ]
        progress = init_progress(tmp_project, chapters, max_section_words=3000)
        ch = progress["chapters"][0]
        assert ch["sections"] == 4  # ceil(9200/3000) = 4


class TestLoadConfig:
    def test_loads_existing_config(self, tmp_project):
        config_data = {
            "book": {"title": "Test", "author": "Author", "slug": "test"},
            "source": {"format": "pdf", "file": "source/original.pdf"},
            "chunking": {"strategy": "flexible", "max_section_words": 3000},
            "output": {"format": "docx", "mirror_source_format": True},
        }
        with open(tmp_project / "config.yaml", "w", encoding="utf-8") as f:
            yaml.dump(config_data, f, allow_unicode=True)
        loaded = load_config(tmp_project)
        assert loaded["book"]["title"] == "Test"

    def test_raises_on_missing_config(self, tmp_project):
        with pytest.raises(FileNotFoundError):
            load_config(tmp_project)


class TestLoadProgress:
    def test_loads_existing_progress(self, tmp_project):
        progress_data = {
            "status": "translating",
            "chapters": [
                {"id": "ch01", "title": "Ch 1", "status": "approved", "sections": 1}
            ],
        }
        with open(tmp_project / "progress.yaml", "w", encoding="utf-8") as f:
            yaml.dump(progress_data, f, allow_unicode=True)
        loaded = load_progress(tmp_project)
        assert loaded["status"] == "translating"

    def test_raises_on_missing_progress(self, tmp_project):
        with pytest.raises(FileNotFoundError):
            load_progress(tmp_project)


class TestSaveProgress:
    def test_saves_and_reloads(self, tmp_project):
        progress = {
            "status": "translating",
            "chapters": [
                {"id": "ch01", "status": "draft", "sections": 1}
            ],
        }
        save_progress(tmp_project, progress)
        loaded = load_progress(tmp_project)
        assert loaded["status"] == "translating"


class TestGetNextChapter:
    def test_returns_first_extracted_chapter(self):
        progress = {
            "status": "translating",
            "chapters": [
                {"id": "ch01", "status": "approved", "sections": 1},
                {"id": "ch02", "status": "extracted", "sections": 1},
                {"id": "ch03", "status": "extracted", "sections": 1},
            ],
        }
        next_ch = get_next_chapter(progress)
        assert next_ch["id"] == "ch02"

    def test_returns_none_when_all_approved(self):
        progress = {
            "status": "translating",
            "chapters": [
                {"id": "ch01", "status": "approved", "sections": 1},
            ],
        }
        assert get_next_chapter(progress) is None
