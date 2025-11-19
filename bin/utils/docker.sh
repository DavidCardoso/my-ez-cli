#!/bin/sh

set -e

# Detect if we're running in a TTY and set appropriate flags
get_tty_flag() {
    if [ -t 0 ]; then
        echo "-t"
    else
        echo ""
    fi
}
