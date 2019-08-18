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

    while getopts ":d:f:hilt:u:vx" OPTION; do
        case ${OPTION} in
            d)
                readonly DEVMODE=${OPTARG}
                ;;
            f)
                case ${OPTARG} in
                    permissions)
                        run_script 'setup_fixes_permissions'
                        ;;
                    updater)
                        run_script 'setup_fixes_updater'
                        ;;
                    mono)
                        run_script 'setup_fixes_mono'
                        ;;
                    nginx)
                        run_script 'setup_fixes_nginx'
                        ;;
                    php)
                        run_script 'setup_fixes_php'
                        ;;
                    redis)
                        run_script 'setup_fixes_redis'
                        ;;
                    sonarr)
                        run_script 'setup_fixes_sonarr'
                        ;;
                    pihole)
                        run_script 'setup_fixes_pihole'
                        ;;
                    kernel)
                        run_script 'setup_fixes_kernel'
                        ;;
                    *)
                        error "${OPTARG} not supported"
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
            s)
                run_script 'symlink_setupopenflixr'
                exit
            t)
                run_test "${OPTARG}"
                exit
                ;;
            u)
                run_script 'update_self' "${OPTARG}"
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
