#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Usage Information
#/ Usage: sudo setupopenflixr [OPTION]
#/
#/ This is the main OpenFLIXR2 Setup Script script.
#/
#/ Usage: vms [OPTION]
#/ NOTE: vms shortcut is only available after the first run
#/
#/ For regular usage you can run without providing any options.
#/
#/  -t --test <test_name>
#/      run tests to check the program
#/  -u --update
#/      update OpenFLIXR2 Setup Script to the latest stable commits
#/  -u --update <branch>
#/      update OpenFLIXR2 Setup Script to the latest commits from the specified branch
##/ -v --verbose
##/     verbose
#/  -x --debug
#/      debug
#/
usage() {
    grep '^#/' "${SCRIPTNAME}" | cut -c4- || echo "Failed to display usage information."
    exit
}

# Command Line Arguments
readonly ARGS=("$@")

# Github Token for Travis CI
if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
fi

# Script Information
# https://stackoverflow.com/a/246128/1384186
get_scriptname() {
    local SOURCE
    local DIR
    SOURCE="${BASH_SOURCE[0]:-$0}" # https://stackoverflow.com/questions/35006457/choosing-between-0-and-bash-source
    while [[ -L ${SOURCE} ]]; do # resolve ${SOURCE} until the file is no longer a symlink
        DIR="$(cd -P "$(dirname "${SOURCE}")" > /dev/null && pwd)"
        SOURCE="$(readlink "${SOURCE}")"
        [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    echo "${SOURCE}"
}
readonly SCRIPTNAME="$(get_scriptname)"
readonly SCRIPTPATH="$(cd -P "$(dirname "${SCRIPTNAME}")" > /dev/null && pwd)"

# Other variables
readonly PREINIT="yes"
readonly PUBLIC_IP=$(dig @ns1-1.akamaitech.net ANY whoami.akamai.net +short)
if [ $? -eq 0 ]; then
    HAS_INTERNET=1
else
    HAS_INTERNET=0
fi
readonly NIC=$(ip -o -4 route show to default | awk '{print $5}')
readonly LOCAL_IP=$(ifconfig ${NIC} | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
readonly OPENFLIXR_FOLDERS=(downloads movies series music comics books)
# Init config array
typeset -A config
config=(
    [STEPS_CURRENT]=0
    [CHANGE_PASS]=""
    [NETWORK]=""
    [OPENFLIXR_IP]=${LOCAL_IP}
    [OPENFLIXR_SUBNET]=""
    [OPENFLIXR_GATEWAY]=""
    [OPENFLIXR_DNS]=""
    [ACCESS]=""
    [OPENFLIXR_DOMAIN]=""
    [OPENFLIXR_EMAIL]=""
    [MOUNT_MANAGE]=""
    [HOST_NAME]=""
    [FSTAB_BACKUP]=0
    [FSTAB_MODIFIED]=0
    [OPENFLIXR_PLEX_CLAIM]="claim-YYYYYYYYY"
    [OPENFLIXR_TIMEZONE]=""
    [OPENFLIXR_TIMEZONE_SHORT]=""
)
for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
    config[MOUNT_TYPE_$FOLDER]=""
done

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
readonly DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)

# Colors
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
readonly BLU='\e[34m'
readonly GRN='\e[32m'
readonly RED='\e[31m'
readonly YLW='\e[33m'
readonly NC='\e[0m'

# Log Functions
readonly LOG_FILE="/var/log/openflixr_setup.log"
sudo chown "${DETECTED_PUID:-$DETECTED_UNAME}":"${DETECTED_PGID:-$DETECTED_UGROUP}" "${LOG_FILE}" > /dev/null 2>&1 || true # This line should always use sudo
info() { echo -e "${NC}$(date +"%F %T") ${BLU}[INFO]${NC}       $*${NC}" | tee -a "${LOG_FILE}" >&2; }
warning() { echo -e "${NC}$(date +"%F %T") ${YLW}[WARNING]${NC}    $*${NC}" | tee -a "${LOG_FILE}" >&2; }
error() { echo -e "${NC}$(date +"%F %T") ${RED}[ERROR]${NC}      $*${NC}" | tee -a "${LOG_FILE}" >&2; }
fatal() {
    echo -e "${NC}$(date +"%F %T") ${RED}[FATAL]${NC}      $*${NC}" | tee -a "${LOG_FILE}" >&2
    exit 1
}
debug() {
    if [[ -v DEBUG && $DEBUG == '-x' ]] || [[ -v VERBOSE && $VERBOSE == 1 ]]; then
        echo -e "${NC}$(date +"%F %T") ${GRN}[DEBUG]${NC}      $*${NC}" | tee -a "${LOG_FILE}" >&2
    fi
}

# Script Runner Function
run_script() {
    local SCRIPTSNAME="${1:-}"
    shift
    if [[ -f "/opt/OpenFLIXR2.SetupScript/.scripts/${SCRIPTSNAME}.sh" ]]; then
        source "/opt/OpenFLIXR2.SetupScript/.scripts/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME} "$@"
    else
        fatal "/opt/OpenFLIXR2.SetupScript/.scripts/${SCRIPTSNAME}.sh not found."
    fi
}

# Test Runner Function
run_test() {
    local TESTSNAME="${1:-}"
    shift
    if [[ -f ${SCRIPTPATH}/.tests/${TESTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPTPATH}/.tests/${TESTSNAME}.sh"
        ${TESTSNAME} "$@"
    else
        fatal "${SCRIPTPATH}/.tests/${TESTSNAME}.sh not found."
    fi
}

# Root Check
root_check() {
    if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
        fatal "Running as root is not supported. Please run as openflixr user using sudo."
    fi
}

# Cleanup Function
cleanup() {
    if [[ $? = 1 ]]; then
        fatal "It appears and error occurred. Please post on Discord and DM MattyLightCU your setup log:'${LOG_FILE}'"
    fi
    #if [[ ${SCRIPTPATH} == "/opt/OpenFLIXR2.SetupScript" ]]; then
    #    chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "${SCRIPTNAME} must be executable."
    #fi
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS} == false ]]; then
        warning "TRAVIS_SECURE_ENV_VARS is false for Pull Requests from remote branches. Please retry failed builds!"
    fi
}
trap 'cleanup' 0 1 2 3 6 14 15

# Main Function
main() {
    # Arch Check
    readonly ARCH=$(uname -m)
    if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "armv7l" ]] && [[ ${ARCH} != "x86_64" ]]; then
        fatal "Unsupported architecture."
    fi
    # Ubuntu Version Check
    readonly UBU_VER=$(lsb_release -rs)
    if [[ ${UBU_VER} != "18.04" ]]; then
        fatal "Unsupported Ubuntu Version. This setup can only be run for OpenFLIXR running Ubuntu 18.04"
    fi
    # Terminal Check
    if [[ -n ${PS1:-} ]] || [[ ${-} == *"i"* ]]; then
        root_check
    fi
    # shellcheck source=/dev/null
    source "${SCRIPTPATH}/.scripts/cmdline.sh"
    cmdline "${ARGS[@]:-}"

    debug "DETECTED_HOME=$DETECTED_HOMEDIR"
    debug "SCRIPTPATH=$SCRIPTPATH"

    run_script 'load_config'
    run_script 'save_config'

    readonly PROMPT="GUI"
    run_script 'run_steps'

    warning "System reboot needed. Please reboot your system when you are ready."
}
main
