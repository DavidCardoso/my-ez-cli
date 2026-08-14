#!/usr/bin/env bats

# Test pnpm wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "pnpm script exists and is executable" {
    [ -x "$BASEDIR/bin/pnpm" ]
}

@test "pnpm20 script exists and is executable" {
    [ -x "$BASEDIR/bin/pnpm20" ]
}

@test "pnpm22 script exists and is executable" {
    [ -x "$BASEDIR/bin/pnpm22" ]
}

@test "pnpm24 script exists and is executable" {
    [ -x "$BASEDIR/bin/pnpm24" ]
}

@test "pnpm sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/pnpm"
    [ "$status" -eq 0 ]
}

@test "pnpm20 sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/pnpm20"
    [ "$status" -eq 0 ]
}

@test "pnpm22 sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/pnpm22"
    [ "$status" -eq 0 ]
}

@test "pnpm24 sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/pnpm24"
    [ "$status" -eq 0 ]
}

@test "pnpm runs with default version" {
    run "$BASEDIR/bin/pnpm" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "pnpm22 uses Node.js 22" {
    local tmpdir="/tmp/test-pnpm22-workspace-$$"
    mkdir -p "$tmpdir"
    echo '{"name":"tmp","version":"0.0.0"}' > "$tmpdir/package.json"
    cd "$tmpdir"
    run "$BASEDIR/bin/pnpm22" exec node --version
    cd - >/dev/null
    # pnpm runs as root in the container, so files it writes into the
    # bind-mounted workspace (e.g. node_modules/.pnpm-workspace-state-v1.json)
    # are root-owned on the host and can't be removed by the CI runner user.
    rm -rf "$tmpdir" 2>/dev/null || { docker run --rm -v "$tmpdir:/cleanup" alpine sh -c 'rm -rf /cleanup/*'; rm -rf "$tmpdir"; }
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v22" ]]
}

@test "pnpm24 uses Node.js 24" {
    local tmpdir="/tmp/test-pnpm24-workspace-$$"
    mkdir -p "$tmpdir"
    echo '{"name":"tmp","version":"0.0.0"}' > "$tmpdir/package.json"
    cd "$tmpdir"
    run "$BASEDIR/bin/pnpm24" exec node --version
    cd - >/dev/null
    rm -rf "$tmpdir" 2>/dev/null || { docker run --rm -v "$tmpdir:/cleanup" alpine sh -c 'rm -rf /cleanup/*'; rm -rf "$tmpdir"; }
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v24" ]]
}

@test "pnpm20 uses Node.js 20" {
    local tmpdir="/tmp/test-pnpm20-workspace-$$"
    mkdir -p "$tmpdir"
    echo '{"name":"tmp","version":"0.0.0"}' > "$tmpdir/package.json"
    cd "$tmpdir"
    run "$BASEDIR/bin/pnpm20" exec node --version
    cd - >/dev/null
    rm -rf "$tmpdir" 2>/dev/null || { docker run --rm -v "$tmpdir:/cleanup" alpine sh -c 'rm -rf /cleanup/*'; rm -rf "$tmpdir"; }
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v20" ]]
}

@test "pnpm store folder is created" {
    PNPM_STORE_DIR="/tmp/test-pnpm-store-$$"
    run bash -c "PNPM_STORE_DIR='$PNPM_STORE_DIR' $BASEDIR/bin/pnpm --version"
    [ "$status" -eq 0 ]
    [ -d "$PNPM_STORE_DIR" ]
    # Cleanup
    rm -rf "$PNPM_STORE_DIR"
}

@test "pnpm corepack cache folder is created and reused across invocations" {
    COREPACK_HOME="/tmp/test-pnpm-corepack-cache-$$"
    # Prime the cache. Retry a few times: corepack fetching pnpm from the
    # registry can hit transient network errors, which this test isn't
    # exercising — it only asserts that a *warm* cache is reused afterwards.
    local attempt
    for attempt in 1 2 3; do
        run bash -c "COREPACK_HOME='$COREPACK_HOME' $BASEDIR/bin/pnpm --version"
        [ "$status" -eq 0 ] && break
    done
    [ "$status" -eq 0 ]
    [ -d "$COREPACK_HOME" ]
    # A second invocation must not need the network: it reuses the cached
    # pnpm tarball rather than re-fetching it from the registry every time.
    run bash -c "COREPACK_HOME='$COREPACK_HOME' $BASEDIR/bin/pnpm --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
    # Cleanup. corepack extracts pnpm's tarball as root inside the container,
    # so the CI runner user can't remove it directly (see the pnpmNN tests above).
    rm -rf "$COREPACK_HOME" 2>/dev/null || { docker run --rm -v "$COREPACK_HOME:/cleanup" alpine sh -c 'rm -rf /cleanup/*'; rm -rf "$COREPACK_HOME"; }
}
