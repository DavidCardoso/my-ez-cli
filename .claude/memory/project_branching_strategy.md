---
name: project_branching_strategy
description: Branch and PR strategy for my-ez-cli — all new work targets rc-v1-alpha, not main
type: project
---

All new branches and PRs must target `rc-v1-alpha`, not `main`.

**Why:** `main` is reserved for the v1 stable release. `rc-v1-alpha` is the integration branch for the release candidate. Only when v1 is considered stable by the user will it be merged to `main`.

**How to apply:** When creating branches, always branch from `rc-v1-alpha`. When opening PRs, always set `--base rc-v1-alpha`. Never open PRs to `main` unless the user explicitly asks to cut a release.
