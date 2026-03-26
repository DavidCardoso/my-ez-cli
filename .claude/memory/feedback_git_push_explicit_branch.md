---
name: git push explicit branch
description: Always specify explicit remote and branch when running git push, especially force pushes
type: feedback
---

Always run `git push` with an explicit remote and branch target.

**Why:** Prevents accidental pushes to the wrong branch, especially during force pushes.

**How to apply:** Use `git push origin <branch-name>` (or `--force-with-lease origin <branch-name>`) instead of bare `git push` or `git push --force-with-lease`.
