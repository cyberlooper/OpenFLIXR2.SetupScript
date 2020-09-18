#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ombi_check() {
    [[ -f /opt/Ombi/complete ]] && info "Ombi Installed." || run_script 'ombi'
}