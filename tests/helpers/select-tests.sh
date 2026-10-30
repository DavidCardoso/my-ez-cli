#!/usr/bin/env bash
# Maps staged changes to the bats unit test file(s) relevant to those changes.
# Used by the local `bats-unit-tests` pre-commit hook to avoid running the
# entire (Docker-backed, slow) unit suite on every commit.
#
# Convention over configuration: tool tests are flat and named
# tests/unit/test-<tool>.bats, 1:1 with bin/<tool> (see tests/README.md).
# A changed bin/<tool> is resolved to its test file by checking the
# filesystem directly, with no lookup table to keep in sync — new tools
# are covered automatically as soon as their test file exists.
#
# Everything that is NOT a 1:1 tool (shared libs, bin/mec subcommands,
# setup.sh, config files, this script itself) lives in tests/unit/shared/
# and is treated as one group: any change under bin/utils/, bin/mec,
# setup.sh, config/, or tests/helpers/ selects the whole shared/ directory.
# This means a newly added shared lib or mec subcommand is covered the day
# it's added, without editing this script.
#
# Falls back to the full `tests/unit/` suite whenever a changed file has no
# derivable mapping, so coverage safety is never traded away for speed.
#
# CI (.github/workflows/test.yml) does not use this script and always runs
# the full suite regardless of changed files.
#
# POSIX/bash-3.2 compatible (no mapfile, no associative arrays) to match
# macOS's default /bin/bash used elsewhere in this project.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)

if [ -z "$CHANGED_FILES" ]; then
    echo "tests/unit/"
    exit 0
fi

SELECTED=""
RUN_ALL=0
SHARED_SELECTED=0

add_test() {
    case " $SELECTED " in
        *" $1 "*) ;;
        *) SELECTED="$SELECTED $1" ;;
    esac
}

select_shared_group() {
    SHARED_SELECTED=1
}

# Resolve bin/<name> (stripping a trailing version suffix, e.g. pnpm24,
# node20) to tests/unit/test-<name>.bats if that file exists on disk.
resolve_tool_test() {
    local bin_name="$1"
    local base_name="${bin_name%%[0-9]*}"
    local candidate="tests/unit/test-${base_name}.bats"
    if [ -f "$candidate" ]; then
        add_test "$candidate"
        return 0
    fi
    return 1
}

OLD_IFS="$IFS"
IFS='
'
for file in $CHANGED_FILES; do
    IFS="$OLD_IFS"

    case "$file" in
        tests/unit/shared/test-*.bats)
            add_test "$file"
            ;;
        tests/unit/test-*.bats)
            add_test "$file"
            ;;
        bin/utils/*|bin/mec|setup.sh|config/*|tests/helpers/*)
            select_shared_group
            ;;
        libexec/saml-extract-roles.py)
            add_test "tests/unit/test-aws-saml-okta.bats"
            ;;
        bin/gcloud-login)
            add_test "tests/unit/test-gcloud.bats"
            ;;
        bin/yarn-berry|bin/yarn-plus)
            add_test "tests/unit/test-yarn.bats"
            ;;
        bin/*)
            bin_name="${file#bin/}"
            if ! resolve_tool_test "$bin_name"; then
                RUN_ALL=1
            fi
            ;;
        docker/*)
            tool_dir="${file#docker/}"
            tool_dir="${tool_dir%%/*}"
            if ! resolve_tool_test "$tool_dir"; then
                RUN_ALL=1
            fi
            ;;
        tests/integration/*)
            RUN_ALL=1
            ;;
        *)
            # Not a file this hook cares about (files: regex already scoped
            # the trigger); ignore it.
            ;;
    esac

    IFS='
'
done
IFS="$OLD_IFS"

if [ "$RUN_ALL" -eq 1 ]; then
    echo "tests/unit/"
    exit 0
fi

if [ "$SHARED_SELECTED" -eq 1 ]; then
    # The whole group supersedes any individual tests/unit/shared/*.bats
    # entries already collected, so drop those before adding the directory.
    FILTERED=""
    for t in $SELECTED; do
        case "$t" in
            tests/unit/shared/*) ;;
            *) FILTERED="$FILTERED $t" ;;
        esac
    done
    SELECTED="$FILTERED"
    add_test "tests/unit/shared/"
fi

if [ -z "$SELECTED" ]; then
    # Nothing matched (shouldn't normally happen given the hook's files:
    # filter, but stay safe rather than running `bats` with no args).
    echo "tests/unit/"
    exit 0
fi

# shellcheck disable=SC2086
printf '%s\n' $SELECTED | sort -u
