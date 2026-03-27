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
from lib.validator import validate_project

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
        word_count = ch.get("word_count", len(ch.get("content", "").split()))
        click.echo(f"  {ch['id']}: {ch['title']} ({word_count} words)")


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

    click.echo(f"\n{title} - {author}")
    click.echo(f"   Status: {progress['status']}\n")

    status_icons = {
        "extracted": "[ ]", "translating": "[~]", "draft": "[D]",
        "reviewing": "[R]", "approved": "[x]",
    }

    total = len(progress["chapters"])
    approved = sum(1 for ch in progress["chapters"] if ch["status"] == "approved")

    click.echo(f"   {'Chapter':<35} {'Words':>6}  Status")
    click.echo(f"   {'-' * 55}")
    for ch in progress["chapters"]:
        icon = status_icons.get(ch["status"], "[?]")
        click.echo(
            f"   {ch['id']}  {ch.get('title', ''):<30} "
            f"{ch.get('word_count_source', 0):>6}  {icon} {ch['status']}"
        )
    click.echo(f"   {'-' * 55}")
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
    """Validate project before rendering using comprehensive validator."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return

    # Use source/chapters as the source directory for validation
    source_dir = project_dir / "source" / "chapters"
    translated_dir = project_dir / "translated"

    # Build a temporary project-like dir structure for the validator
    # pointing at source chapters (not the original file)
    result = validate_project(project_dir)

    if result.errors:
        click.secho(f"\n{len(result.errors)} error(s):", fg="red")
        for e in result.errors:
            click.echo(f"  - {e}")
    if result.warnings:
        click.secho(f"\n{len(result.warnings)} warning(s):", fg="yellow")
        for w in result.warnings:
            click.echo(f"  - {w}")
    if result.is_valid and not result.warnings:
        click.secho("All checks passed!", fg="green")


@cli.command()
@click.argument("slug")
def repair(slug):
    """Repair progress.yaml by rebuilding from source chapters and translated frontmatter."""
    import re as _re
    import yaml

    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return

    source_dir = project_dir / "source" / "chapters"
    translated_dir = project_dir / "translated"

    if not source_dir.exists():
        click.secho("No source chapters found. Run 'extract' first.", fg="red")
        return

    source_files = sorted(source_dir.glob("ch*.md"))
    if not source_files:
        click.secho("No chapter files found in source/chapters/.", fg="yellow")
        return

    # Parse frontmatter helper
    _fm_re = _re.compile(r"^---\n(.*?)\n---\n", _re.DOTALL)

    chapters = []
    for src_file in source_files:
        ch_id = src_file.stem  # "ch01"
        src_content = src_file.read_text(encoding="utf-8")
        # Extract title from first heading
        title_match = _re.search(r"^#\s+(.+)", src_content, _re.MULTILINE)
        title = title_match.group(1).strip() if title_match else ch_id
        word_count = len(src_content.split())

        # Determine status from translated frontmatter if present
        status = "extracted"
        tr_file = translated_dir / f"{ch_id}.md"
        if tr_file.exists():
            tr_content = tr_file.read_text(encoding="utf-8")
            fm_match = _fm_re.match(tr_content)
            if fm_match:
                try:
                    fm = yaml.safe_load(fm_match.group(1))
                    if isinstance(fm, dict) and fm.get("status"):
                        status = fm["status"]
                except Exception:
                    pass

        chapters.append({
            "id": ch_id,
            "title": title,
            "sections": 1,
            "status": status,
            "word_count_source": word_count,
        })

    progress = {
        "status": "translating",
        "chapters": chapters,
    }

    progress_file = project_dir / "progress.yaml"
    with open(progress_file, "w", encoding="utf-8") as f:
        yaml.dump(progress, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

    click.secho(f"Repaired progress.yaml with {len(chapters)} chapters:", fg="green")
    for ch in chapters:
        click.echo(f"  {ch['id']}: {ch['title']} — {ch['status']}")


@cli.command("consistency-scan")
@click.argument("slug")
def consistency_scan(slug):
    """Run consistency checks on translated chapters."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return
    from lib.consistency_scanner import generate_report
    report = generate_report(project_dir)
    click.echo(report)


if __name__ == "__main__":
    cli()
