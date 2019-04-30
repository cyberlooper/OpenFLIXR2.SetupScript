#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes()
{
    info "Various fixes not handled anywhere else in setup"
    run_script 'setup_fixes_sonarr'
    run_script 'setup_fixes_permissions'
    run_script 'setup_fixes_nginx'
    run_script 'setup_fixes_updater'
}