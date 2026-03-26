---
name: smoke test before commit
description: Always run smoke tests on new mec CLI behavior before committing
type: feedback
---

Always run a manual smoke test of any new `mec` subcommand or behavior before committing.

**Why:** Ensures the feature works end-to-end in the real environment, not just in unit tests. Unit tests may pass while the actual CLI invocation fails due to sourcing, dispatch, or integration issues.

**How to apply:** After implementing a new `mec` subcommand or behavior:
1. Run the command directly: `./bin/mec <subcommand>`
2. Test help: `./bin/mec <subcommand> help` and `--help`
3. Test edge cases: unknown subcommand, scriptability (`&& echo "ok" || echo "fail"`)
4. Only then commit.
