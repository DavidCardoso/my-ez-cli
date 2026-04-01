# Git Workflow

## Commit strategy — amend vs new commit

Before committing anything, run `git log --oneline -5` and ask: does this change correct, adjust, or complete something already in the most recent commit on this branch? If yes → amend. Only create a new commit if the change is genuinely new and independent.

Amend the existing commit when changes are corrections or adjustments to the same original intent (fixing wording, adding missed items, addressing review feedback on an unmerged commit).

Create a new commit only when the change introduces something genuinely new: a new feature, a bug fix for a previously merged PR, or a separate logical concern.

**Why:** User prefers clean commit history. Multiple small fixup commits for the same logical change create noise.

**Common mistake:** Defaulting to a new commit without checking the log first. Always check before committing.

## Verify naming conventions against Conventional Commits before recommending

Before recommending any branch prefix, commit type, or workflow pattern for this project, verify it against [Conventional Commits](https://www.conventionalcommits.org/) first.

**Why:** `improve` was recommended as a branch/commit prefix and justified as appropriate — without checking it against Conventional Commits. When challenged, the recommendation was reversed immediately. The verification should happen before the recommendation, not after being challenged.

**How to apply:**
- Valid Conventional Commits types: `feat`, `fix`, `chore`, `docs`, `ci`, `test`, `refactor`, `perf`, `style`, `build`, `revert` — use these, nothing else
- If a type feels like it doesn't fit, pick the closest standard type (e.g. `improve` → `feat` if user-visible, `refactor` if internal)
- Branch naming: `<type>/<issue-id>/<short-description>` using the same type list
- Never introduce a non-standard type without explicitly flagging it as a deviation

## Link every PR to milestone, label, and project

Every PR must have all three set before requesting review:
- **Milestone**: `v1.0.0` (or the relevant release milestone)
- **Label**: matching the commit type (`enhancement` for `feat`, `bug` for `fix`, `documentation` for `docs`, etc.)
- **Project**: "My EZ CLI • Roadmap" (`PVT_kwHOANNfSs4BTAfg`)

**Why:** PRs without milestone/label/project were being merged without appearing correctly in the roadmap or release tracking. This was caught on PR #112.

**How to apply:**
```bash
gh pr edit <number> --milestone "v1.0.0" --add-label "<label>"
gh api graphql -f query='mutation { addProjectV2ItemById(input: { projectId: "PVT_kwHOANNfSs4BTAfg", contentId: "<PR node ID>" }) { item { id } } }'
# PR node ID: gh pr view <number> --json id
```

Label mapping: `feat` → `enhancement`, `fix` → `bug`, `docs` → `documentation`, `chore`/`ci`/`refactor`/`build` → no standard label (skip or use closest match)

## Always use explicit branch in git push

Always run `git push` with an explicit remote and branch: `git push origin <branch-name>`.

For force pushes: `git push --force-with-lease origin <branch-name>`.

Never use bare `git push` or `git push --force-with-lease` without specifying the target.

**Why:** Prevents accidental pushes to the wrong branch, especially during force pushes on feature branches.
