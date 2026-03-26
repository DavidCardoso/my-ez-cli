---
name: Don't blindly apply reviewer date "corrections"
description: Code reviewers have hallucinated incorrect dates for this project — always verify date claims against the user before applying
type: feedback
---

A code reviewer incorrectly claimed that `Phase 1 Completed: 2026-01-20` in ROADMAP.md was wrong and should be `2025-01-20`. The reviewer's reasoning ("Phase 2 completed 2026-02-16, so Phase 1 must have been 2025") was plausible-sounding but wrong — the entire project started and ran in 2026.

**Why:** The project was started in 2026. Phase 1 completed 2026-01-20, Phase 2 completed 2026-02-16. All dates are 2026.

**How to apply:** When a reviewer flags a date as incorrect, verify with the user before applying the fix. Do not trust reviewer reasoning about "what year makes sense" — dates in the repo are authoritative.
