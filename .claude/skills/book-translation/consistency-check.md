---
name: consistency-check
description: Check translation consistency across all chapters — use when user says "kiem tra nhat quan", "consistency check", after all chapters approved, or after every 3-5 chapters
---

# Consistency Check

## Trigger
User says "kiem tra nhat quan", "consistency check", "check consistency", or all chapters are approved.

## When to Run
- After all chapters reach `approved` status
- After every 3-5 chapters as a mid-project check
- When user explicitly requests it

## Step 1: Run Script-Assisted Scan

Run the consistency scanner to get automated checks:

```bash
cd modules/book-translation
python scripts/manage.py consistency-scan {slug}
```

This produces a report covering:
- **Glossary consistency** — terms used in some chapters but not others
- **Heading count comparison** — source vs translated heading counts
- **Word count ratios** — flag chapters with unusual ratios (< 0.5 or > 2.0)

## Step 2: Name Audit (Manual)

Scan translated files for proper name spelling consistency:
- Read through chapter files looking for character names, place names, book titles
- Check that each name is spelled identically across all chapters
- Common issues: accent variations, capitalization, transliteration differences
- If inconsistencies found, add to report

This step is manual because proper names vary too much for automated regex detection.

## Step 3: Review Report

Read the scanner report + name audit findings. For each issue:

### Glossary Issues
- Check if the term SHOULD appear in the flagged chapter (some terms are chapter-specific)
- If it should: note for correction
- If it shouldn't: skip (not a real issue)

### Heading Mismatches
- Check if headings were intentionally merged/split during translation
- If unintentional: note for correction

### Word Count Outliers
- Read the flagged chapter to check if content was omitted or over-expanded
- Minor variations (0.8-1.3 ratio) are normal for EN→VI translation

## Step 4: Style Drift Check (Manual Sampling)

Claude reads first and last paragraph of each chapter to detect style drift:
- Compare tone/formality between early and late chapters
- Check pronoun usage consistency
- Check Han-Viet vocabulary density consistency

**Context budget:** Only load first paragraph + last paragraph per chapter (not full text).

## Step 5: Present Findings

Present a summary to user:

```
Consistency Report for "{book title}":

Glossary:     X issue(s)
Names:        X issue(s)
Headings:     X mismatch(es)
Word Counts:  X outlier(s)
Style Drift:  [none detected / mild / significant]

Details:
[list each issue with chapter reference]

Options:
1. Fix all issues automatically
2. Review each issue one by one
3. Skip — proceed to render
```

## Step 6: Fix Issues

Based on user choice:
- **Fix all:** Claude corrects glossary terms, adjusts headings, flags content gaps
- **Review each:** Go through issues one by one, user decides per issue
- **Skip:** Move on

After fixes, re-run `consistency-scan` to verify.

## Step 7: Merge to Global Memory

After consistency check passes (all chapters approved + consistent):

1. Ask user: "Translation complete! Which terms/rules should be saved for future books?"
2. Present glossary terms for selection → merge chosen terms into `modules/book-translation/memory/glossary-global.md`
3. Present style rules discovered → merge into `modules/book-translation/memory/style-feedback.md`
4. Present notable translation patterns → merge into `modules/book-translation/memory/translation-patterns.md`
5. Update `projects/{slug}/progress.yaml`: book status → `done`

## Glossary Conflict Resolution (for future books)
When starting a new book, `init-project` skill should:
1. Read `memory/glossary-global.md`
2. Pre-populate new book's `glossary.md` with relevant terms
3. Flag any terms that might need different translation in new context
