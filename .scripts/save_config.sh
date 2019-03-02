#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

save_config() {
    for KEY in "${!config[@]}"; do 
        run_script 'set_config' "${KEY}" ${config[$KEY]}
    done
}