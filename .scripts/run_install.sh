#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    run_script 'update_system'
}
