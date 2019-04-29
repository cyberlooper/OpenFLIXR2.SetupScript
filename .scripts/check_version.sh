#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

check_version() {
    git fetch > /dev/null 2>&1
    if [[ ! -v DEVMODE ]]; then
        readonly GH_COMMIT=$(git rev-parse --short ${config[BRANCH]})
        if [[ "${LOCAL_COMMIT}" != "${GH_COMMIT}" ]]; then
            warning "OpenFLIXR Setup Script is not up-to-date."
            warning "Please run 'sudo setupopenflixr -u' to get the latest."
            exit 0
        fi
    fi
    GIT_DIFF=$(git diff -G. ${config[BRANCH]} -- | cut -c1-5)
    if [[ "$GIT_DIFF" != "" ]]; then
        warning "OpenFLIXR Setup Script doesn't match with the repository's ${config[BRANCH]} branch."
        if run_script 'question_prompt' Y "OpenFLIXR Setup Script doesn't match with the repository's ${config[BRANCH]} branch. Do you want to continue?" "Continue?" ${OF_BACKTITLE}; then
            warning "Continuing with code differences."
        else
            warning "Update your local code and run again."
            exit 0
        fi
    fi
}
