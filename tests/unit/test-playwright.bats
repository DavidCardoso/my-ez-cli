#!/usr/bin/env bats

# Test playwright wrapper script and custom Docker image

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "bin/playwright exists and is executable" {
    [ -x "$BASEDIR/bin/playwright" ]
}

@test "bin/playwright uses MEC_IMAGE_PLAYWRIGHT constant" {
    grep -q 'MEC_IMAGE_PLAYWRIGHT' "$BASEDIR/bin/playwright"
}

@test "bin/playwright allows IMAGE override via environment" {
    grep -q 'IMAGE=${IMAGE:-' "$BASEDIR/bin/playwright"
}

@test "bin/playwright script is valid bash" {
    run bash -n "$BASEDIR/bin/playwright"
    [ "$status" -eq 0 ]
}

@test "docker/playwright/Dockerfile exists" {
    [ -f "$BASEDIR/docker/playwright/Dockerfile" ]
}

@test "docker/playwright/Dockerfile extends official Playwright image" {
    grep -q 'FROM mcr.microsoft.com/playwright' "$BASEDIR/docker/playwright/Dockerfile"
}

@test "docker/playwright/Dockerfile pre-installs Chromium" {
    grep -q 'playwright install chromium' "$BASEDIR/docker/playwright/Dockerfile"
}

@test "docker/playwright/Dockerfile has mec project label" {
    grep -q 'com.my-ez-cli.project' "$BASEDIR/docker/playwright/Dockerfile"
}

@test "docker/playwright/Dockerfile has ENTRYPOINT for transparent invocation" {
    grep -q 'ENTRYPOINT' "$BASEDIR/docker/playwright/Dockerfile"
}

@test "docker/playwright/build script exists and is executable" {
    [ -x "$BASEDIR/docker/playwright/build" ]
}

@test "docker/playwright/README.md exists" {
    [ -f "$BASEDIR/docker/playwright/README.md" ]
}
