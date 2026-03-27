---
name: feedback_gh_tracking
description: Use GH issues, milestones, and projects for work tracking instead of local ROADMAP.md updates
type: feedback
---

Track all project work via GitHub issues, milestones, and projects — not by updating local docs.

**Why:** Reviewing and updating local files like `docs/ROADMAP.md` wastes time and tokens each session, and doesn't integrate with PR/commit workflows.

**How to apply:**
- New work item → open a GH issue (smallest unit of trackable work)
- Group of related issues toward a big feature/epic → use a GH milestone
- Cross-milestone or multi-release tracking → use a GH project board
- Always reference issue IDs in commit messages, PR descriptions, and branch names where applicable (e.g., `feat/123/short-description`)
- Only update `docs/ROADMAP.md` for high-level structural changes; defer details to GH issues
