# modules/book-translation/scripts/manage.py
"""CLI for book translation project management."""
import sys
import shutil
from pathlib import Path

import click

sys.path.insert(0, str(Path(__file__).parent))

from lib.config_loader import (
    init_config,
    init_progress,
    load_config,
    load_progress,
    save_progress,
    get_next_chapter,
    slugify,
    VALID_STATUSES,
)
from lib.extractor import extract_to_chapters, detect_format
from lib.merger import merge_chapters
from lib.renderer import render_markdown_to_docx

PROJECTS_DIR = Path(__file__).parent.parent / "projects"


@click.group()
def cli():
    """Book Translation Manager — manage translation projects."""
    pass


@cli.command()
@click.argument("title")
@click.option("--author", required=True, help="Book author name")
@click.option("--source", required=True, type=click.Path(exists=True), help="Path to source PDF/EPUB/text")
def init(title, author, source):
    """Initialize a new book translation project."""
    source_path = Path(source)
    fmt = detect_format(source_path)
    slug = slugify(title)

    project_dir = PROJECTS_DIR / slug
    if project_dir.exists():
        click.secho(f"Project '{slug}' already exists!", fg="red")
        return

    project_dir.mkdir(parents=True)
    (project_dir / "source" / "chapters").mkdir(parents=True)
    (project_dir / "translated").mkdir()
    (project_dir / "output").mkdir()

    dest = project_dir / "source" / f"original{source_path.suffix}"
    shutil.copy2(source_path, dest)

    init_config(
        project_dir=project_dir,
        title=title,
        author=author,
        source_format=fmt,
        source_file=f"source/original{source_path.suffix}",
    )

    (project_dir / "glossary.md").write_text(
        f"# Glossary — {title}\n\n"
        "| English | Vietnamese | Context | Notes |\n"
        "|---------|-----------|---------|-------|\n",
        encoding="utf-8",
    )
    (project_dir / "style-guide.md").write_text(
        f"# Style Guide — {title}\n\n"
        "(To be defined with Claude using define-style skill)\n",
        encoding="utf-8",
    )

    click.secho(f"Project '{slug}' created at {project_dir}", fg="green")
    click.echo(f"  Source: {fmt} ({source_path.name})")
    click.echo(f"  Next: run 'python manage.py extract {slug}'")


@cli.command()
@click.argument("slug")
def extract(slug):
    """Extract source file into chapter markdown files."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return

    config = load_config(project_dir)
    source_file = project_dir / config["source"]["file"]
    chapters_dir = project_dir / "source" / "chapters"

    click.echo(f"Extracting {config['source']['format']}...")

    try:
        chapters = extract_to_chapters(source_file, chapters_dir)
    except ValueError as e:
        click.secho(f"Error: {e}", fg="red")
        return

    max_words = config.get("chunking", {}).get("max_section_words", 3000)
    init_progress(project_dir, chapters, max_section_words=max_words)

    click.secho(f"Extracted {len(chapters)} chapters:", fg="green")
    for ch in chapters:
        click.echo(f"  {ch['id']}: {ch['title']} ({ch['word_count']} words)")


@cli.command()
@click.argument("slug")
def status(slug):
    """Show translation progress for a project."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return

    config = load_config(project_dir)
    progress = load_progress(project_dir)

    title = config["book"]["title"]
    author = config["book"]["author"]

    click.echo(f"\n{title} — {author}")
    click.echo(f"   Status: {progress['status']}\n")

    status_icons = {
        "extracted": "[ ]", "translating": "[~]", "draft": "[D]",
        "reviewing": "[R]", "approved": "[x]",
    }

    total = len(progress["chapters"])
    approved = sum(1 for ch in progress["chapters"] if ch["status"] == "approved")

    click.echo(f"   {'Chapter':<35} {'Words':>6}  Status")
    click.echo(f"   {'─' * 55}")
    for ch in progress["chapters"]:
        icon = status_icons.get(ch["status"], "[?]")
        click.echo(
            f"   {ch['id']}  {ch.get('title', ''):<30} "
            f"{ch.get('word_count_source', 0):>6}  {icon} {ch['status']}"
        )
    click.echo(f"   {'─' * 55}")
    click.echo(f"   Progress: {approved}/{total} approved")


@cli.command()
@click.argument("slug")
@click.option("--chapter", type=int, default=None, help="Render single chapter")
@click.option("--full", is_flag=True, help="Render full book")
@click.option("--bilingual", is_flag=True, help="Render bilingual EN/VI")
@click.option("--force", is_flag=True, help="Render even if chapters not approved")
def render(slug, chapter, full, bilingual, force):
    """Render translated markdown to DOCX."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return

    config = load_config(project_dir)
    progress = load_progress(project_dir)
    translated_dir = project_dir / "translated"
    output_dir = project_dir / "output"
    output_dir.mkdir(exist_ok=True)

    if chapter:
        ch_id = f"ch{chapter:02d}"
        ch_data = next((c for c in progress["chapters"] if c["id"] == ch_id), None)
        if not ch_data:
            click.secho(f"Chapter {ch_id} not found!", fg="red")
            return
        if ch_data["status"] not in ("draft", "reviewing", "approved") and not force:
            click.secho(f"Chapter {ch_id} not translated yet (status: {ch_data['status']})", fg="yellow")
            return
        chapters_to_render = [ch_data]
        output_file = output_dir / f"{slug}-{ch_id}.docx"
    elif full:
        if not force:
            not_approved = [c for c in progress["chapters"] if c["status"] != "approved"]
            if not_approved:
                click.secho(
                    f"{len(not_approved)} chapters not yet approved. Use --force to render anyway.",
                    fg="yellow",
                )
                return
        chapters_to_render = progress["chapters"]
        suffix = "-bilingual" if bilingual else "-final"
        output_file = output_dir / f"{slug}{suffix}.docx"
    else:
        click.echo("Specify --chapter N or --full")
        return

    click.echo(f"Rendering {len(chapters_to_render)} chapter(s)...")

    try:
        merged = merge_chapters(translated_dir, chapters_to_render)
    except FileNotFoundError as e:
        click.secho(f"Error: {e}", fg="red")
        return

    if bilingual:
        source_dir = project_dir / "source" / "chapters"
        try:
            source_merged = merge_chapters(source_dir, chapters_to_render)
        except FileNotFoundError:
            click.secho("Source chapters not found for bilingual mode!", fg="red")
            return
        merged = _interleave_bilingual(source_merged, merged)

    render_markdown_to_docx(merged, output_file)
    click.secho(f"Rendered to {output_file}", fg="green")


def _interleave_bilingual(source_md: str, translated_md: str) -> str:
    source_paras = [p for p in source_md.split("\n\n") if p.strip()]
    trans_paras = [p for p in translated_md.split("\n\n") if p.strip()]
    result = []
    max_len = max(len(source_paras), len(trans_paras))
    for i in range(max_len):
        if i < len(source_paras):
            result.append(f"*[EN] {source_paras[i]}*")
        if i < len(trans_paras):
            result.append(trans_paras[i])
    return "\n\n".join(result)


@cli.command()
@click.argument("slug")
def validate(slug):
    """Validate project before rendering."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return

    progress = load_progress(project_dir)
    translated_dir = project_dir / "translated"
    errors = []
    warnings = []

    for ch in progress["chapters"]:
        ch_id = ch["id"]
        sections = ch.get("sections", 1)
        if sections <= 1:
            f = translated_dir / f"{ch_id}.md"
            if not f.exists():
                errors.append(f"Missing: {f.name}")
            elif f.stat().st_size < 10:
                warnings.append(f"Nearly empty: {f.name}")
        else:
            for s in range(1, sections + 1):
                f = translated_dir / f"{ch_id}-s{s}.md"
                if not f.exists():
                    errors.append(f"Missing: {f.name}")

    if errors:
        click.secho(f"\n{len(errors)} error(s):", fg="red")
        for e in errors:
            click.echo(f"  - {e}")
    if warnings:
        click.secho(f"\n{len(warnings)} warning(s):", fg="yellow")
        for w in warnings:
            click.echo(f"  - {w}")
    if not errors and not warnings:
        click.secho("All checks passed!", fg="green")


if __name__ == "__main__":
    cli()
