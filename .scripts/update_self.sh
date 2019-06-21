#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

update_self() {
    local BRANCH
    BRANCH="${1:-${config[BRANCH]}}"
    if [[ ${BRANCH} != origin/* ]]; then
        if [[ $(git ls-remote --heads ${GIT_REPO} ${BRANCH} | wc -l) == 1 ]]; then
            config[BRANCH]="origin/${BRANCH}"
        else
            config[BRANCH]="origin/master"
        fi
        BRANCH="${config[BRANCH]}"
    fi

    cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
    git fetch > /dev/null 2>&1 || fatal "Failed to fetch recent changes from git."
    local GH_COMMIT=$(git rev-parse --short ${BRANCH})

    if run_script 'question_prompt' Y "Would you like to update OpenFLIXR2 Setup Script to '${GH_COMMIT}' on '${BRANCH}' now?"; then
        info "Updating OpenFLIXR2 Setup Script to '${GH_COMMIT}' on '${BRANCH}'."
        git reset --hard "${BRANCH}" > /dev/null 2>&1 || fatal "Failed to reset to '${BRANCH}'."
        git pull > /dev/null 2>&1 || fatal "Failed to pull recent changes from git."
        git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D > /dev/null 2>&1 || true
        chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "OpenFLIXR2 Setup Script must be executable."
        info "OpenFLIXR2 Setup Script has been updated to '${GH_COMMIT}' on '${BRANCH}'"
        run_script 'set_config' "BRANCH" "${BRANCH}"
    else
        info "OpenFLIXR2 Setup Script will not be updated to '${GH_COMMIT}' on '${BRANCH}'."
    fi
}
