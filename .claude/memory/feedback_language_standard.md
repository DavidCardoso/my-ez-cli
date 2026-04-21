---
name: language standard en-US
description: Use en-US spelling throughout — analyze not analyse, etc.
type: feedback
---

All code, comments, docs, and CLI output must use **en-US** spelling.

**Why:** The codebase was mixing en-US and en-GB (e.g. `analyze` vs `analyse`). en-US is the standard.

**How to apply:**
- Function names, variable names, subcommand names: `analyze`, not `analyse`
- Comments and docs: `analyze`, `color`, `behavior`, etc.
- When renaming existing en-GB identifiers, update all call sites
