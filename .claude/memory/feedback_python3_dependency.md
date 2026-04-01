---
name: python3 host dependency
description: Do not use bare python3 calls in shell scripts; use the mec-python wrapper instead
type: feedback
---

Never call `python3` directly in host-side shell scripts (`common.sh`, `setup.sh`, `bin/*`). Use the `mec-python` wrapper instead whenever inline Python execution is needed on the host.

**Why:** `python3` creates an external host dependency. My Ez CLI aims to be as self-contained as possible. The fact that `python3` was already used in several places is a pre-existing gap, not a justification to add more.

**How to apply:**
- New inline Python logic on the host → use `mec-python -c "..."` or `mec python -c "..."`
- When reviewing or touching existing `python3` calls in shell scripts → flag them for replacement
- Python inside Docker containers (e.g. `ai-service`) is fine — that's the container's own runtime
