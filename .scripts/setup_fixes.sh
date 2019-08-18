#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes()
{
    info "Various fixes not handled anywhere else in setup"
    run_script 'setup_fixes_permissions'
    run_script 'setup_fixes_updater'
    run_script 'setup_fixes_mono'
    run_script 'setup_fixes_nginx'
    run_script 'setup_fixes_php'
    run_script 'setup_fixes_redis'
    run_script 'setup_fixes_sonarr'
    run_script 'setup_fixes_pihole'
    run_script 'setup_fixes_kernel'
}