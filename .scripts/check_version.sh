#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

check_version() {
    git fetch > /dev/null 2>&1
    if [[ ! -v DEVMODE ]]; then
        readonly GH_COMMIT=$(git rev-parse --short ${config[BRANCH]})
        if [[ "${LOCAL_COMMIT}" != "${GH_COMMIT}" ]]; then
            warning "OpenFLIXR Setup Script is not up-to-date."
            if run_script 'question_prompt' Y $"OpenFLIXR Setup Script is not up-to-date..\n\nDo you want to update now?" "Continue?" ${OF_BACKTITLE}; then
                info "Updating OpenFLIXR Setup Script..."
                (setupopenflixr -u)
                info "Running OpenFLIXR Setup Script after updating..."
                (setupopenflixr)
                exit 0
            else
                warning "Continuing with out-of-date OpenFLIXR Setup Script."
            fi
        fi
        if [[ "${config[SUBMITTED_LOGS]}" == "Y" && "${config[SUBMITTED_LOGS_VERSION]}" == "${LOCAL_COMMIT}" ]]; then
            if run_script 'question_prompt' Y "OpenFLIXR Setup Script hasn't been updated since you submitted logs. Do you want to continue?" "Continue?" ${OF_BACKTITLE}; then
                warning "Continuing with setup even though nothing has changed."
            else
                warning "Run again later once an update has been made."
                exit 0
            fi
        fi
    fi
    GIT_DIFF=$(git diff -G. ${config[BRANCH]} -- | cut -c1-5)
    if [[ "$GIT_DIFF" != "" ]]; then
        warning "OpenFLIXR Setup Script doesn't match with the repository's ${config[BRANCH]} branch."
        if run_script 'question_prompt' Y $"OpenFLIXR Setup Script doesn't match with the repository's ${config[BRANCH]} branch.\nThis usually means that the OpenFLIXR Setup Script has been modified locally.\n\nDo you want to continue?" "Continue?" ${OF_BACKTITLE}; then
            warning "Continuing with code differences."
        else
            warning "Update your local code by running run 'sudo setupopenflixr -u' and run again."
            exit 0
        fi
    fi
}
