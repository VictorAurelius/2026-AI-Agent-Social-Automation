---
name: init-project
description: Initialize a new book translation project — use when user says "dich sach moi" or provides a PDF/EPUB file for translation
---

# Init Book Translation Project

## Trigger
User says "dich sach moi", "translate a new book", or provides a PDF/EPUB file.

## Steps

### 1. Gather info
Ask user (if not already provided):
- Book title
- Author name
- Source file path (PDF, EPUB, or text)

### 2. Create project
Run the CLI to scaffold the project:
```bash
cd modules/book-translation
python scripts/manage.py init "{title}" --author "{author}" --source "{path}"
```

### 3. Extract chapters
```bash
python scripts/manage.py extract {slug}
```

### 4. User reviews extraction
Show the user:
- Number of chapters detected
- Word count per chapter
- Ask them to review `projects/{slug}/source/chapters/` for accuracy

If chapter detection is wrong, user can:
- Edit the markdown files manually
- Re-run with a custom chapter pattern in config.yaml

### 5. Show status
```bash
python scripts/manage.py status {slug}
```

### 6. Transition
Once user confirms extraction looks good, invoke **define-style** skill to brainstorm the style guide for this book.
