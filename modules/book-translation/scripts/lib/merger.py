# modules/book-translation/scripts/lib/merger.py
"""Merge translated chapter/section files into a single document."""
from pathlib import Path


def resolve_sections(translated_dir: Path, chapter_id: str, sections: int) -> list[Path]:
    if sections <= 1:
        file_path = translated_dir / f"{chapter_id}.md"
        if not file_path.exists():
            raise FileNotFoundError(f"Missing translated file: {file_path}")
        return [file_path]
    files = []
    for i in range(1, sections + 1):
        file_path = translated_dir / f"{chapter_id}-s{i}.md"
        if not file_path.exists():
            raise FileNotFoundError(f"Missing section file: {file_path.name}")
        files.append(file_path)
    return files


def merge_chapters(translated_dir: Path, progress_chapters: list[dict]) -> str:
    parts = []
    for ch in progress_chapters:
        chapter_id = ch["id"]
        sections = ch.get("sections", 1)
        files = resolve_sections(translated_dir, chapter_id, sections)
        chapter_content = "\n\n".join(
            _strip_frontmatter(f.read_text(encoding="utf-8")) for f in files
        )
        parts.append(chapter_content)
    return "\n\n---\n\n".join(parts)


def _strip_frontmatter(text: str) -> str:
    if text.startswith("---"):
        end = text.find("---", 3)
        if end != -1:
            return text[end + 3:].strip()
    return text.strip()
