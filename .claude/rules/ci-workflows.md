# CI Workflow Standards

## Always use current GitHub Actions versions

When writing or editing any `.github/workflows/` file, always use the latest major version of each action. Node.js 20-based action versions are deprecated (forced to Node.js 24 June 2026, removed September 2026).

**Current latest versions (as of 2026-05):**
- `actions/checkout@v6`
- `actions/upload-artifact@v7`
- `actions/download-artifact@v8`
- `actions/setup-node@v6`
- `actions/setup-python@v6`
- `actions/cache@v5`
- `docker/setup-qemu-action@v4`
- `docker/setup-buildx-action@v4`
- `docker/login-action@v4`
- `docker/metadata-action@v6`
- `docker/build-push-action@v7`
- `aquasecurity/trivy-action@v0.36.0`
- `github/codeql-action/*@v4`
- `ossf/scorecard-action@v2.4.3`
- `hadolint/hadolint-action@v3.3.0`

**How to apply:**
- Before adding any `uses:` line, verify the action's latest release: `gh api repos/<owner>/<repo>/releases/latest --jq '.tag_name'`
- `v4` for `actions/checkout`, `upload-artifact`, or `download-artifact` is outdated — use the versions above
- When GitHub warns "Node.js 20 actions are deprecated", bump the action version — never use `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` or `ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION` as workarounds
- Upload and download artifact versions must be kept in sync (both must be ≥ v4 to share artifacts across jobs)
