# Memory Index

> Source of truth for Claude Code memory in this project.
> New memories go here first; the home-folder MEMORY.md mirrors this index.

## Project
- [project_branching_strategy.md](./project_branching_strategy.md) — All new branches/PRs target `rc-v1-alpha`, not `main`; `main` only for v1 stable release
- [project_dockerhub_naming.md](./project_dockerhub_naming.md) — Open question: evaluate moving images from davidcardoso/ to a dedicated org (GH #92)

## Feedback
- [feedback_verify_external_corrections.md](./feedback_verify_external_corrections.md) — Don't blindly apply corrections from automated reviewers; verify with user first (dates, naming, config values, etc.)
- [feedback_skill_naming.md](./feedback_skill_naming.md) — Use specific, project-contextual skill names (e.g., `add-mec-tool` not `add-tool`)
- [feedback_gh_tracking.md](./feedback_gh_tracking.md) — Use GH issues/milestones/projects for tracking; avoid updating local ROADMAP.md inline
- [feedback_release_grouping.md](./feedback_release_grouping.md) — Group work by releases/milestones, not phases; include issue IDs in commits/PRs
- [feedback_custom_image_standards.md](./feedback_custom_image_standards.md) — Custom Docker images must include build script + localized README
- [feedback_language_standard.md](./feedback_language_standard.md) — en-US spelling throughout: `analyze` not `analyse`, `color` not `colour`, etc.
- [feedback_python3_dependency.md](./feedback_python3_dependency.md) — Use `mec-python` wrapper instead of bare `python3` in host-side shell scripts
- [feedback_validate_against_standards.md](./feedback_validate_against_standards.md) — Verify new patterns against industry standards (e.g. Conventional Commits) before recommending; don't reverse only when challenged
