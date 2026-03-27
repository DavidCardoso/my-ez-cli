# Git Workflow

## Commit strategy — amend vs new commit

Amend the existing commit when changes are corrections or adjustments to the same original intent (fixing wording, adding missed items, addressing review feedback on an unmerged commit).

Create a new commit only when the change introduces something genuinely new: a new feature, a bug fix for a previously merged PR, or a separate logical concern.

**Why:** User prefers clean commit history. Multiple small fixup commits for the same logical change create noise.

## Always use explicit branch in git push

Always run `git push` with an explicit remote and branch: `git push origin <branch-name>`.

For force pushes: `git push --force-with-lease origin <branch-name>`.

Never use bare `git push` or `git push --force-with-lease` without specifying the target.

**Why:** Prevents accidental pushes to the wrong branch, especially during force pushes on feature branches.
