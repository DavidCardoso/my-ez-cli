---
name: feedback_release_grouping
description: Use releases/milestones to group work, not phases; include issue IDs in all commit/PR descriptions
type: feedback
---

Group implementation work by releases and milestones, not by phases. Include GH issue IDs in all commit and PR descriptions.

**Why:** Phase labels (Phase 3.5, Phase 4) are too vague and detached from the actual tracking system. Releases (v1.0.0-rc, v1.1.0) and milestones map directly to GH capabilities.

**How to apply:**
- Use "release" terminology when discussing scope groups (e.g., "this is v1.0.0-rc work")
- Within a specific implementation, "phase/step/task" is still fine for internal structure
- Always add `#<issue-id>` to commit messages and PR descriptions (e.g., `feat: add MEC_HOME env var (#42)`)
- Use GH milestones for epics/big features; GH projects for multi-milestone tracking
