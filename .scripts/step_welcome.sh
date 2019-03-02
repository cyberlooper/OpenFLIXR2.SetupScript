#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_wait () {
    # Variables
    HEIGHT_ORIGINAL=$HEIGHT
    WIDTH_ORIGINAL=$WIDTH
    HEIGHT=30
    WIDTH=75

read -r -d '' message << EOM
Welcome to OpenFLIXR setup!
This will guide you through getting your OpenFLIXR box setup (mostly).
Once completed, you will need to configure the applications appropriately.

As you go through this, use the following to navaigate:
[up]/[down] to move between options
[space] to select an option
[tab] to move to buttons or back to the options
[page up]/[page down] to scroll

Good luck!
EOM

    # Dialog to display
    dialog \
        --backtitle "OpenFLIXR Setup" \
        --title "Step ${step_number}: ${step_name}" \
        --clear \
        --msgbox "${message}" \
        $HEIGHT $WIDTH
}
