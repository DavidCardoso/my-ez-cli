---
name: Commit strategy — amend vs new commit
description: When to amend vs create a new commit based on user's workflow preference
type: feedback
---

Amend the existing commit (rather than creating a new one) when changes are corrections or adjustments to the same original intent — e.g., fixing wording, adding missed items, addressing review feedback on a commit that hasn't been merged yet.

**Why:** User prefers clean commit history. Multiple small fixup commits for the same logical change create noise.

**How to apply:** Only create a new commit when the change introduces something genuinely new (new feature, fixing a bug introduced in a previously merged PR, or a separate logical concern). For iterative feedback on in-progress work, use `git commit --amend`.
