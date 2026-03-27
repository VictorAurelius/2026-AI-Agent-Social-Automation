# modules/book-translation/scripts/tests/test_manage_cli.py
"""Tests for manage.py CLI commands."""
import pytest
from pathlib import Path
from click.testing import CliRunner

import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from manage import cli

FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture
def runner():
    return CliRunner()


@pytest.fixture
def sample_pdf():
    path = FIXTURES_DIR / "sample.pdf"
    if not path.exists():
        pytest.skip("sample.pdf fixture not created yet")
    return path


@pytest.fixture
def initialized_project(runner, sample_pdf, tmp_path, monkeypatch):
    """Create an initialized project for testing."""
    import manage
    monkeypatch.setattr(manage, "PROJECTS_DIR", tmp_path)
    result = runner.invoke(cli, ["init", "Test Book", "--author", "Author", "--source", str(sample_pdf)])
    assert result.exit_code == 0, f"Init failed: {result.output}"
    return tmp_path / "test-book"


class TestInitCommand:
    def test_creates_project(self, runner, sample_pdf, tmp_path, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", tmp_path)
        result = runner.invoke(cli, ["init", "My Book", "--author", "Author", "--source", str(sample_pdf)])
        assert result.exit_code == 0
        assert "created" in result.output.lower() or "my-book" in result.output.lower()
        assert (tmp_path / "my-book").exists()

    def test_duplicate_project_fails(self, runner, sample_pdf, tmp_path, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", tmp_path)
        runner.invoke(cli, ["init", "My Book", "--author", "A", "--source", str(sample_pdf)])
        result = runner.invoke(cli, ["init", "My Book", "--author", "A", "--source", str(sample_pdf)])
        assert "already exists" in result.output.lower()


class TestStatusCommand:
    def test_shows_status(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        runner.invoke(cli, ["extract", "test-book"])
        result = runner.invoke(cli, ["status", "test-book"])
        assert result.exit_code == 0

    def test_missing_project(self, runner, tmp_path, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", tmp_path)
        result = runner.invoke(cli, ["status", "nonexistent"])
        assert "not found" in result.output.lower()


class TestValidateCommand:
    def test_validate_missing_translations(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        runner.invoke(cli, ["extract", "test-book"])
        result = runner.invoke(cli, ["validate", "test-book"])
        assert "error" in result.output.lower() or "missing" in result.output.lower()


class TestConsistencyScanCommand:
    def test_runs_scan(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        runner.invoke(cli, ["extract", "test-book"])
        translated_dir = initialized_project / "translated"
        (translated_dir / "ch01.md").write_text(
            "---\nchapter: 1\nstatus: draft\n---\n\n# Ch 1\n\nContent.\n", encoding="utf-8")
        result = runner.invoke(cli, ["consistency-scan", "test-book"])
        assert result.exit_code == 0
        assert "Consistency Report" in result.output or "consistency" in result.output.lower()


class TestInterleaveBilingual:
    def test_interleaves_paragraphs(self):
        from manage import _interleave_bilingual
        source = "# Title\n\nParagraph one.\n\nParagraph two."
        translated = "# Tieu de\n\nDoan mot.\n\nDoan hai."
        result = _interleave_bilingual(source, translated)
        assert "[EN]" in result
        lines = result.split("\n\n")
        assert len(lines) >= 4

    def test_handles_unequal_lengths(self):
        from manage import _interleave_bilingual
        source = "One.\n\nTwo.\n\nThree."
        translated = "Mot.\n\nHai."
        result = _interleave_bilingual(source, translated)
        assert "Three" in result
        assert "Hai" in result


class TestBilingualRender:
    def test_bilingual_creates_docx(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        runner.invoke(cli, ["extract", "test-book"])
        translated_dir = initialized_project / "translated"
        (translated_dir / "ch01.md").write_text(
            "---\nchapter: 1\nstatus: approved\n---\n\n# Chuong 1\n\nNoi dung dich.\n", encoding="utf-8")
        result = runner.invoke(cli, ["render", "test-book", "--chapter", "1", "--bilingual", "--force"])
        assert result.exit_code == 0
        assert "Rendered" in result.output or "rendered" in result.output.lower()
