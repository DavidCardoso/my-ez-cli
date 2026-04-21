---
name: feedback_custom_image_standards
description: Always include build script and localized README when adding a custom Docker image for a tool
type: feedback
---

Every custom Docker image added under `docker/<tool>/` must include a build script and a localized README.

**Why:** The Playwright image was added without a build script or localized README, deviating from project standards and requiring a follow-up fix.

**How to apply:**
- `docker/<tool>/Dockerfile` — required
- `docker/<tool>/build.sh` (or equivalent build script) — required
- `docker/<tool>/README.md` — required (localized docs for that tool's image)
- Docker Hub tag published under `davidcardoso/my-ez-cli:<tool>-latest`
- Update `CLAUDE.md` docker/ listing and root `README.md` tools section
- Update `bin/utils/common.sh` image constant (e.g., `MEC_IMAGE_PLAYWRIGHT`)
