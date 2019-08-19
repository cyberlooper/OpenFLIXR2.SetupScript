#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

precheck_fixes()
{
    run_script 'load_config'
    if [[ ${config[PRECHECK_FIXES]:-} != "COMPLETED" ]]; then
        info "Putting some fixes in place..."
        info "These fixes can be run again later using 'setupopenflixr'"
        info "- Running 'setupopenflixr -f {fix name}' to do fixes"
        info "  - Updater"
        bash setupopenflixr -f updater || error "  - Unable to run command or an error occurred..."
        info "  - Mono"
        bash setupopenflixr -f mono || error "  - Unable to run command or an error occurred..."
        info "  - Redis"
        bash setupopenflixr -f redis || error "  - Unable to run command or an error occurred..."
        info "  - PHP"
        bash setupopenflixr -f php || error "  - Unable to run command or an error occurred..."
        info "- Fixes completed"
        run_script 'set_config' "PRECHECK_FIXES" "COMPLETED"
    else
        info "Fixes already completed!"
    fi
}