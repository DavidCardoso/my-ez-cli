#!/usr/bin/env bats

# Test gcloud wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "gcloud script exists and is executable" {
    [ -x "$BASEDIR/bin/gcloud" ]
}

@test "gcloud script has valid syntax" {
    run bash -n "$BASEDIR/bin/gcloud"
    [ "$status" -eq 0 ]
}

@test "gcloud exits with error when gcloud-config container is missing" {
    # Stub docker to simulate missing gcloud-config container
    docker() {
        if [ "$1" = "inspect" ] && [ "$2" = "gcloud-config" ]; then
            return 1
        fi
        command docker "$@"
    }
    export -f docker

    run bash -c "
        docker() {
            if [ \"\$1\" = 'inspect' ] && [ \"\$2\" = 'gcloud-config' ]; then
                return 1
            fi
            command docker \"\$@\"
        }
        export -f docker
        source '$BASEDIR/bin/utils/common.sh' 2>/dev/null || true
        SKIP_DEPENDENCY_CHECK=1 bash '$BASEDIR/bin/gcloud' version 2>&1
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"gcloud-config"* ]] || [[ "$output" == *"gcloud-login"* ]]
}

@test "gcloud error message mentions mec gcloud-login" {
    run bash -c "
        docker() {
            if [ \"\$1\" = 'inspect' ] && [ \"\$2\" = 'gcloud-config' ]; then
                return 1
            fi
            command docker \"\$@\"
        }
        export -f docker
        SKIP_DEPENDENCY_CHECK=1 bash '$BASEDIR/bin/gcloud' 2>&1
    "
    [[ "$output" == *"mec gcloud-login"* ]]
}
