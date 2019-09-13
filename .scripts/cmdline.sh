#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

cmdline() {
    # http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/
    # http://kirk.webfinish.com/2009/10/bash-shell-script-to-use-getopts-with-gnu-style-long-positional-parameters/
    local ARG=
    local LOCAL_ARGS
    for ARG; do
        local DELIM=""
        case "${ARG}" in
            #translate --gnu-long-options to -g (short options)
            --devmode) LOCAL_ARGS="${LOCAL_ARGS:-}-d " ;;
            --help) LOCAL_ARGS="${LOCAL_ARGS:-}-h " ;;
            --install) LOCAL_ARGS="${LOCAL_ARGS:-}-i " ;;
            --no-log-submission)
                LOG_SUBMISSION="DISABLED"
                ;;
            --test) LOCAL_ARGS="${LOCAL_ARGS:-}-t " ;;
            --update) LOCAL_ARGS="${LOCAL_ARGS:-}-u " ;;
            --verbose) LOCAL_ARGS="${LOCAL_ARGS:-}-v " ;;
            --debug) LOCAL_ARGS="${LOCAL_ARGS:-}-x " ;;
            #pass through anything else
            *)
                [[ ${ARG:0:1} == "-" ]] || DELIM='"'
                LOCAL_ARGS="${LOCAL_ARGS:-}${DELIM}${ARG}${DELIM} "
                ;;
        esac
    done

    #Reset the positional parameters to the short options
    eval set -- "${LOCAL_ARGS:-}"

    while getopts ":d:f:hilp:st:u:vx" OPTION; do
        case ${OPTION} in
            d)
                readonly DEVMODE=${OPTARG}
                ;;
            f)
                case ${OPTARG} in
                    kernel | mono | mopidy | nginx | permissions | php | redis | sonarr | sources | pihole | ubooquity | updater)
                        run_script "fixes_${OPTARG}"
                        ;;
                    *)
                        error "${OPTARG} not supported"
                        ;;
                esac
                exit
                ;;
            h)
                usage
                exit
                ;;
            i)
                run_script 'run_install'
                exit
                ;;
            l)
                run_script 'load_config'
                SUBMIT_MESSAGE="Do you want to submit the logs now?"
                run_script 'submit_logs'
                exit
                ;;
            p)
                case ${OPTARG} in
                    dns_check | prepare_upgrade | process_check | ready_check | upgrade | uptime)
                        run_script "firstrun_${OPTARG}"
                        ;;
                    *)
                        error "${OPTARG} not supported"
                        ;;
                esac
                exit
                ;;
            s)
                run_script 'symlink_setupopenflixr'
                exit
                ;;
            t)
                run_test "${OPTARG}"
                exit
                ;;
            u)
                run_script 'load_config'
                run_script 'update_self' "${OPTARG}"
                run_script 'set_config' "BRANCH" "${OPTARG}"
                exit
                ;;
            v)
                readonly VERBOSE=1
                ;;
            x)
                readonly DEBUG=1
                set -x
                ;;
            :)
                case ${OPTARG} in
                    d)
                        readonly DEVMODE=1
                        ;;
                    f)
                        run_script 'setup_fixes'
                        ;;
                    u)
                        run_script 'update_self'
                        exit
                        ;;
                    *)
                        fatal "${OPTARG} requires an option."
                        exit
                        ;;
                esac
                ;;
            *)
                usage
                exit
                ;;
        esac
    done
    return 0
}
