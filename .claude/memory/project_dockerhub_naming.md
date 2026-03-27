---
name: project_dockerhub_naming
description: Open question - evaluate Docker Hub org naming (davidcardoso/ vs mec/ or my-ez-cli/)
type: project
---

Open question: evaluate whether to move custom Docker images from `davidcardoso/my-ez-cli-*` to a dedicated org like `my-ez-cli/<tool>` or `mec/<tool>`.

**Why:** Using a personal account (`davidcardoso/`) makes the images feel personal rather than project-owned, which may reduce adoption and discoverability.

**How to apply:** This is a research + decision item. No code change until a decision is made. Track as GH issue #92 or ADR in `docs/`. Current images are `davidcardoso/my-ez-cli:<tag>`.
