---
name: Test changes before committing
description: Always run local tests/validation before committing code changes
type: feedback
---

Always test code changes locally before committing.

**Why:** User caught multiple bugs that would have been committed untested (find ! -type d fix, ai-service sidecar empty file fix). Running the commands locally first catches regressions before they land in git history.

**How to apply:** Before any `git commit`, run the relevant test command or validate the behavior manually. For shell script changes to bin/mec, run the affected subcommand (e.g. `mec ai last`, `mec ai logs`) against real data. For Python service changes, run pytest inside the Docker container. For Docker pipeline changes, run the pipeline synchronously first.
