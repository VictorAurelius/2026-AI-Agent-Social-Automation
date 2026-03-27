# modules/book-translation/scripts/lib/config_loader.py
"""Load and manage config.yaml and progress.yaml for book translation projects."""
import math
import re
from datetime import date
from pathlib import Path

import yaml

VALID_STATUSES = ("extracted", "translating", "draft", "reviewing", "approved")
VALID_BOOK_STATUSES = (
    "init", "extracting", "translating", "reviewing", "consistency_check", "done"
)

PROJECTS_DIR = Path(__file__).parent.parent.parent / "projects"


def slugify(title: str) -> str:
    """Convert book title to URL-friendly slug."""
    slug = title.lower().strip()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[\s_]+", "-", slug)
    slug = re.sub(r"-+", "-", slug)
    return slug.strip("-")


def get_project_path(slug: str) -> Path:
    """Get the project directory path for a given book slug."""
    return PROJECTS_DIR / slug


def init_config(
    project_dir: Path,
    title: str,
    author: str,
    source_format: str,
    source_file: str,
    source_lang: str = "en",
    target_lang: str = "vi",
) -> dict:
    """Create config.yaml for a new book project."""
    slug = slugify(title)
    config = {
        "book": {
            "title": title,
            "author": author,
            "slug": slug,
            "language": {"source": source_lang, "target": target_lang},
        },
        "source": {
            "format": source_format,
            "file": source_file,
        },
        "chunking": {
            "strategy": "flexible",
            "max_section_words": 3000,
        },
        "output": {
            "format": "docx",
            "mirror_source_format": True,
            "template": None,
        },
    }
    config_path = project_dir / "config.yaml"
    with open(config_path, "w", encoding="utf-8") as f:
        yaml.dump(config, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    return config


def init_progress(
    project_dir: Path,
    chapters: list[dict],
    max_section_words: int = 3000,
) -> dict:
    """Create progress.yaml for a new book project."""
    progress_chapters = []
    for ch in chapters:
        word_count = ch.get("word_count", 0)
        sections = math.ceil(word_count / max_section_words) if word_count > max_section_words * 2 else 1
        chapter_entry = {
            "id": ch["id"],
            "title": ch["title"],
            "sections": sections,
            "status": "extracted",
            "word_count_source": word_count,
            "last_updated": str(date.today()),
        }
        if sections > 1:
            chapter_entry["section_status"] = [
                {f"s{i+1}": "extracted"} for i in range(sections)
            ]
        progress_chapters.append(chapter_entry)

    progress = {
        "status": "extracting",
        "chapters": progress_chapters,
    }
    progress_path = project_dir / "progress.yaml"
    with open(progress_path, "w", encoding="utf-8") as f:
        yaml.dump(progress, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    return progress


def load_config(project_dir: Path) -> dict:
    """Load config.yaml from project directory."""
    config_path = project_dir / "config.yaml"
    if not config_path.exists():
        raise FileNotFoundError(f"Config not found: {config_path}")
    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_progress(project_dir: Path) -> dict:
    """Load progress.yaml from project directory."""
    progress_path = project_dir / "progress.yaml"
    if not progress_path.exists():
        raise FileNotFoundError(f"Progress not found: {progress_path}")
    with open(progress_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def save_progress(project_dir: Path, progress: dict) -> None:
    """Save progress.yaml to project directory."""
    progress_path = project_dir / "progress.yaml"
    with open(progress_path, "w", encoding="utf-8") as f:
        yaml.dump(progress, f, default_flow_style=False, allow_unicode=True, sort_keys=False)


def get_next_chapter(progress: dict) -> dict | None:
    """Find the next chapter to translate (first non-approved chapter)."""
    for ch in progress.get("chapters", []):
        if ch["status"] in ("extracted", "translating", "draft", "reviewing"):
            return ch
    return None
