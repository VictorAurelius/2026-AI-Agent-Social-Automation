# Lessons Learned

Document các bài học quan trọng trong quá trình phát triển project.

---

## 2026-03-19: Importance of Branch-PR Workflow

**Context:**
Trong quá trình fix bug Ollama JSON expression (commits bf6b63c, 1b1d6f1), đã commit trực tiếp lên `main` branch thay vì follow branch → PR → merge workflow.

**Problem:**
- ❌ Không có code review process
- ❌ Không có opportunity để catch issues trước khi merge
- ❌ History không clean (multiple small commits)
- ❌ Không professional practice

**Root Cause:**
- AI agent không enforce check current branch trước khi commit
- Skill git-pr-workflow.md có nhưng không được áp dụng nghiêm ngặt
- Thiếu automation để prevent direct commits to main

**Lesson Learned:**
```
✅ MANDATORY: Check branch before every commit
✅ MANDATORY: Use feature/bugfix branches for ALL changes
✅ MANDATORY: Create PR for ALL changes (even documentation)
✅ Better: Squash merge for clean history
```

**Actions Taken:**
1. ✅ Updated `.claude/skills/git-pr-workflow.md` with stricter enforcement
2. ✅ Added mandatory branch check before commit
3. ✅ Created pre-commit check script (TODO)
4. ✅ Documented lesson in this file

**Going Forward:**
- Every single change (features, bugfixes, docs) MUST use branch → PR workflow
- AI agent MUST check `git branch --show-current` before committing
- User will enforce this rule by rejecting direct commits to main

**Related Skills:**
- `.claude/skills/git-pr-workflow.md`
- `.claude/skills/verification-before-completion.md`

---

## Template for Future Lessons

**Context:**
What happened?

**Problem:**
What went wrong?

**Root Cause:**
Why did it happen?

**Lesson Learned:**
What should we do differently?

**Actions Taken:**
What did we fix?

**Going Forward:**
How do we prevent this?

---

**Last Updated:** 2026-03-19
