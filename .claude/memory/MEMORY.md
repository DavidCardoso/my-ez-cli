# Memory Index

> Source of truth for Claude Code memory in this project.
> New memories go here first; the home-folder MEMORY.md mirrors this index.

## Project
- [project_branching_strategy.md](./project_branching_strategy.md) — All new branches/PRs target `rc-v1-alpha`, not `main`; `main` only for v1 stable release
- [project_tools_multicategory.md](./project_tools_multicategory.md) — Tools should support multiple categories; deferred after Phase 3.3

## Feedback
- [feedback_always_write_tests.md](./feedback_always_write_tests.md) — Always ship automated tests (unit at minimum) with every new feature, behavior, edge case, or key fix — not as a follow-up
- [feedback_test_before_commit.md](./feedback_test_before_commit.md) — Always run local tests/validation before committing code changes
- [feedback_commit_strategy.md](./feedback_commit_strategy.md) — Amend existing commit for corrections/adjustments; new commit only for genuinely new changes
- [feedback_git_push_explicit_branch.md](./feedback_git_push_explicit_branch.md) — Always use explicit `git push origin <branch>`, especially for force pushes
- [feedback_smoke_test_before_commit.md](./feedback_smoke_test_before_commit.md) — Always smoke test new `mec` CLI behavior (run/help/edge cases) before committing
- [feedback_dont_trust_reviewer_date_corrections.md](./feedback_dont_trust_reviewer_date_corrections.md) — Reviewer hallucinated wrong dates; verify date corrections with user before applying (all project dates are 2026)
