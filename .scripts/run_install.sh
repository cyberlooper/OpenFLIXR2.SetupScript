#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    # TODO: fix this - run_script 'update_system'
    run_script 'install_tzupdate'
}
