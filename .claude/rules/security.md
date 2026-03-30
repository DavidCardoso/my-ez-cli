# Security Standards

## Security-by-design is non-negotiable

Security must be considered at the design stage, not retrofitted. When evaluating an approach, if the cleanest technical solution requires a security compromise, choose a different architecture.

**Why:** This principle was established after a Docker socket mount was proposed as an architecture for the dashboard to trigger background AI analysis. The convenience was clear but the risk was unacceptable — it was rejected and a host-side CLI approach chosen instead.

## Never mount the Docker socket in a container

Mounting `/var/run/docker.sock` into any container grants that container root-equivalent access to the host. This is **never acceptable** in mec, regardless of convenience.

**Why:** A compromised or buggy container with socket access can escape isolation, inspect or control all other containers, read host secrets, and execute arbitrary commands as root on the host machine.

**How to apply:**
- If a design requires the dashboard or any service container to spawn Docker containers → redesign to keep Docker execution on the host side only
- If a feature cannot be implemented without socket mounting → defer it until a host-side mechanism (CLI, queue, or DB-backed job) exists
- This applies to all containers: dashboard, ai-service, config-service, tool wrappers

## Containers get minimum necessary permissions

- **Data volumes**: mount read-only (`:ro`) unless the container explicitly needs to write
- **No `--privileged`** unless absolutely required and documented with justification
- **No `--network host`** unless required and documented with justification
- **Non-root user** inside containers where possible — see `docker/ai-service/Dockerfile` for the established pattern

## Validate inputs at system boundaries

- Validate and sanitize all user-facing inputs (CLI args, API request bodies, env vars read from config)
- Never pass unsanitized user input directly to shell commands, Docker `--env`, or file paths
- Log injection attempts at `warning` level

## Secrets handling

- Never log credential values (API keys, tokens, passwords), even at debug level
- Never commit `.env` files or files containing credentials
- Use env var references, not embedded values, in Docker run commands
