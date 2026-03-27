---
name: Verify external corrections with user before applying
description: Don't blindly apply corrections suggested by automated reviewers or external tools — verify with the user first
type: feedback
---

Don't automatically apply "corrections" flagged by automated code reviewers, linters with unexpected output, or AI-generated review comments. Verify with the user before applying.

**Why:** A code reviewer incorrectly claimed that `Phase 1 Completed: 2026-01-20` in ROADMAP.md was wrong and should be `2025-01-20`. The reasoning was plausible-sounding ("Phase 2 completed 2026-02-16, so Phase 1 must have been 2025") but wrong — the entire project started and ran in 2026. This pattern applies beyond dates: a reviewer might flag a function name, a config key, or a constant as "wrong" based on reasoning that doesn't account for project-specific context.

**How to apply:** When any external reviewer (automated or AI-generated) flags something as incorrect — especially dates, naming conventions, or values that depend on project history — surface the suggestion to the user rather than silently applying it. The repo content is authoritative; reviewer reasoning is not.
