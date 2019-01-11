#!/bin/bash

TODAY=$(date)
echo "-----------------------------------------------------"
echo "Date:          ${TODAY}"
echo "-----------------------------------------------------"
THISUSER=$(whoami)
    if [ $THISUSER != 'root' ]
        then
            echo 'You must use sudo to run this script, sorry!'
            exit 1
    fi

echo "Initializing..."

#Variables
preinitialized="yes"
OPENFLIXIR_UID=$(id -u $OPENFLIXIR_USERNAME)
OPENFLIXIR_GID=$(id -u $OPENFLIXIR_USERNAME)
PUBLIC_IP=$(dig @ns1-1.akamaitech.net ANY whoami.akamai.net +short)
LOCAL_IP=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')

OPENFLIXR_LOGFILE="/var/log/updateof.log"
OPENFLIXR_SETUP_LOGFILE="/var/log/openflixr_setup.log"
OPENFLIXR_SETUP_PATH="/home/openflixr/openflixr_setup/"
OPENFLIXR_SETUP_CONFIG_FILE="openflixr_setup.config"
OPENFLIXR_SETUP_CONFIG="${OPENFLIXR_SETUP_PATH}${OPENFLIXR_SETUP_CONFIG_FILE}"
OPENFLIXR_SETUP_FUNCTIONS_FILE="functions.sh"
OPENFLIXR_SETUP_FUNCTIONS="${OPENFLIXR_SETUP_PATH}${OPENFLIXR_SETUP_FUNCTIONS_FILE}"
OPENFLIXR_FOLDERS=(downloads movies series music comics books)

FSTAB="/etc/fstab"
FSTAB_ORIGINAL="/etc/fstab.openflixrsetup.original"
FSTAB_BACKUP="/etc/fstab.openflixrsetup.bak"
OPENFLIXIR_CIFS_CREDENTIALS_FILE="/home/${OPENFLIXIR_USERNAME}/.credentials-openflixr"

typeset -A config # init array
config=( # set default values in config array
    [STEPS_CURRENT]=0
    [CHANGE_PASS]=""
    [NETWORK]=""
    [OPENFLIXR_IP]=""
    [OPENFLIXR_SUBNET]=""
    [OPENFLIXR_GATEWAY]=""
    [OPENFLIXR_DNS]=""
    [ACCESS]=""
    [LETSENCRYPT_DOMAIN]=""
    [LETSENCRYPT_EMAIL]=""
    [MOUNT_MANAGE]=""
    [HOST_NAME]=""
    [FSTAB_BACKUP]=0
    [FSTAB_MODIFIED]=0
)

for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
    config[MOUNT_TYPE_$FOLDER]=""
done

if [ ! -f $OPENFLIXR_SETUP_CONFIG ]; then
    mkdir -p $OPENFLIXR_SETUP_PATH
    touch $OPENFLIXR_SETUP_CONFIG
fi

#Always get the latest version of these files
typeset -A EXTERNAL_FILES # init array
EXTERNAL_FILES=(
    [setup.sh]="https://raw.githubusercontent.com/MagicalCodeMonkey/OpenFLIXR2.SetupScript/master/setup.sh"
    [functions.sh]="https://raw.githubusercontent.com/MagicalCodeMonkey/OpenFLIXR2.SetupScript/master/functions.sh"
    [welcome.txt]="https://raw.githubusercontent.com/MagicalCodeMonkey/OpenFLIXR2.SetupScript/master/welcome.txt"
)

for key in ${!EXTERNAL_FILES[@]}; do
    file=$key
    repo_path=${EXTERNAL_FILES[$key]}
    file_path="$OPENFLIXR_SETUP_PATH$file"

    if [[ $file = "setup.sh" ]]; then
        SETUP_SCRIPT=$file_path
    fi

    if [ -f "$file_path" ]; then
        rm $file_path
    fi

    wget -q -O $file_path $repo_path
    chown openflixr:openflixr $file_path

    shell=$(echo "$file" | grep -c ".sh")
    if [[ $shell > 0 ]]; then
        chmod +x $file_path
    fi
done

#Helper methods
source $OPENFLIXR_SETUP_FUNCTIONS

#Get variables from config file 
load_config $OPENFLIXR_SETUP_CONFIG
save_config


#From wizard
networkconfig=${config[NETWORK]}
ip=${config[OPENFLIXR_IP]}
subnet=${config[OPENFLIXR_SUBNET]}
gateway=${config[OPENFLIXR_GATEWAY]}
dns='127.0.0.1'
password=''
if [[ ${config[ACCESS]} = 'remote' ]]; then
    letsencrypt='on'
    domainname=${config[LETSENCRYPT_DOMAIN]}
    email=${config[LETSENCRYPT_EMAIL]}
else
    letsencrypt='off'
    domainname=''
    email=''
fi

oldpassword=$(crudini --get /usr/share/nginx/html/setup/config.ini password oldpassword)
if [ "$oldpassword" == '' ]
  then
    oldpassword='openflixr'
fi

#TODO Add these later
usenetdescription=''
usenetservername=''
usenetusername=''
usenetpassword=''
usenetport=''
usenetthreads=''
usenetssl=''
newznabprovider=''
newznaburl=''
newznabapi=''
tvshowdl='sickrage' #sickrage or sonarr
nzbdl='sabnzbd' #sabnzbd or nzbget
mopidy='enabled'
hass='enabled'
ntopng='enabled'
headphonesuser=''
headphonespass=''
anidbuser=''
anidbpass=''
spotuser=''
spotpass=''
imdb=''
comicvine=''


while [[ true ]]; do

case ${config[STEPS_CURRENT]} in
    0)
        whiptail --title "Welcome!" --msgbox "$(cat $OPENFLIXR_SETUP_PATH"welcome.txt")" 10 75

        set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
    ;;
    1)
        {
            LOG_LINE=""
            start=$(date +%s)
            while [[ ! $LOG_LINE = "Set Version" ]]; do
                tail -5 $OPENFLIXR_LOGFILE > $OPENFLIXR_SETUP_PATH"/tmp.log"
                while IFS='' read -r line || [[ -n "$line" ]]; do
                    LOG_LINE="$line"
                    
                    if [[ $LOG_LINE = "Set Version" ]]; then
                    break
                    fi
                done < $OPENFLIXR_SETUP_PATH"/tmp.log"
                sleep 5s

                elapsed=$(($(date +%s)-$start))
                duration=$(date -ud @$elapsed +'%M minutes %S seconds')
                percent=$(($elapsed/10))
                echo -e "XXX\n$percent\nDuration: $duration\nXXX"
            done
            rm $OPENFLIXR_SETUP_PATH"/tmp.log"
            echo -e "XXX\n100\nDone!\nXXX"
        } | whiptail --title "Step ${config[STEPS_CURRENT]}: Checking to make sure OpenFLIXR is ready." --gauge "This may take about 15 minutes depending on when you ran this script..." 10 75 0

        set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
    ;;
    2)
        dpkg-reconfigure tzdata
        
        set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
    ;;
    3)
        done=0
        while [[ ! $done = 1 ]]; do
            pass_change=$(whiptail --yesno --title "Step ${config[STEPS_CURRENT]}: Change Password" "Do you want to change the default password for OpenFLIXR?" 10 40 3>&1 1>&2 2>&3)
            pass_change=$?
            
            if [[ $pass_change -eq 0 ]]; then
                config[CHANGE_PASS]="Y"
                valid=0
                while [[ ! $valid = 1 ]]; do
                    pass=$(whiptail --passwordbox --title "Step ${config[STEPS_CURRENT]}: Change Password" "Enter password" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    cpass=$(whiptail --passwordbox --title "Step ${config[STEPS_CURRENT]}: Change Password" "Confirm password" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    
                    if [[ $pass == $cpass ]]; then
                        password=$pass
                        valid=1
                        done=1
                    else
                        whiptail --title "Step ${config[STEPS_CURRENT]}: Change Password" --ok-button "Try Again" --msgbox "Passwords do not match =( Try again." 10 30
                    fi
                done
            else
                config[CHANGE_PASS]="N"
                done=1
            fi
            set_config "CHANGE_PASS" $CHANGE_PASS
        done
        
        if [[ $STEPS_CONTINUE -gt 0 ]]; then
            set_config "STEPS_CURRENT" $STEPS_CONTINUE
        else
            set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
        fi
    ;;
    4)
        done=0
        while [[ ! $done = 1 ]]; do
            networkconfig=$(whiptail --radiolist "Step ${config[STEPS_CURRENT]}: Choose network configuration" 10 30 2\
                           dhcp "DHCP" on \
                           static "Static IP" off 3>&1 1>&2 2>&3)
            check_cancel $?;              
            set_config "NETWORK" $networkconfig
            
            if [[ $networkconfig = 'static' ]]; then
                echo "Configuring for Static IP"
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    ip=$(whiptail --inputbox --title "Step ${config[STEPS_CURRENT]}: Network configuration" "IP Address" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    
                    if valid_ip $ip; then
                        set_config "OPENFLIXR_IP" $ip
                        valid=1
                    else
                        whiptail --title "Step ${config[STEPS_CURRENT]}: Network configuration" --ok-button "Try Again" --msgbox "Invalid IP Address" 10 30
                    fi
                done
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    subnet=$(whiptail --inputbox --title "Step ${config[STEPS_CURRENT]}: Network configuration" "Subnet Mask" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    
                    if valid_ip $ip; then
                        set_config "OPENFLIXR_SUBNET" $subnet
                        valid=1
                    else
                        whiptail --title "Step ${config[STEPS_CURRENT]}: Network configuration" --ok-button "Try Again" --msgbox "Invalid IP Address" 10 30
                    fi
                done
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    gateway=$(whiptail --inputbox --title "Step ${config[STEPS_CURRENT]}: Network configuration" "Gateway" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    
                    if valid_ip $ip; then
                        set_config "OPENFLIXR_GATEWAY" $gateway
                        valid=1
                    else
                        whiptail --title "Step ${config[STEPS_CURRENT]}: Network configuration" --ok-button "Try Again" --msgbox "Invalid IP Address" 10 30
                    fi
                done
                
                done=1
            fi
            
            if [[ $networkconfig = 'dhcp' ]]; then
                echo "Configuring for DHCP"
                done=1
            fi
            
            if [[ $networkconfig = '' ]]; then
                whiptail --title "Step ${config[STEPS_CURRENT]}: Network configuration" --yes-button "Try Again" --no-button "Cancel" --yesno "Something went wrong getting Network Configuration settings... Try again or select cancel to quit" 10 30
                check_cancel $?;
            fi
        done
        
        set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
    ;;
    5)
        done=0
        while [[ ! $done = 1 ]]; do
            access=$(whiptail --title "Step ${config[STEPS_CURRENT]}: Access settings" --radiolist "How do you want to access OpenFLIXR?" 10 30 2\
                           local "Local" on \
                           remote "Remote" off 3>&1 1>&2 2>&3)
            check_cancel $?;
            set_config "ACCESS" ${access}
            
            if [[ $access = 'local' ]]; then
                # Local access selected. Nothing else to do.
                done=1
            fi
            
            if [[ $access = 'remote' ]]; then
                # Configuring for Remote access.
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    domain=$(whiptail --inputbox --ok-button "Next" --title "Step ${config[STEPS_CURRENT]}: Access settings - Remote" "Enter your domain (required to obtain certificate). If you don't have one, register one and then enter it here." 10 50 ${config[LETSENCRYPT_DOMAIN]} 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    set_config "LETSENCRYPT_DOMAIN" $domain
                    
                    #TODO: Validate domain
                    valid=1
                done
                
                whiptail --title "Step ${config[STEPS_CURRENT]}: Access settings - Remote" --ok-button "Next" --msgbox "Add/Edit the A records for ${domain} and www.${domain} to point to ${PUBLIC_IP}" 10 50
                whiptail --title "Step ${config[STEPS_CURRENT]}: Access settings - Remote" --ok-button "Next" --msgbox "Forward port 443 (only!) on your router to your local IP (${LOCAL_IP})" 10 50
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    email=$(whiptail --inputbox --title "Step ${config[STEPS_CURRENT]}: Access settings - Remote" "Enter your e-mail address (required for lost key recovery)." 10 50 ${config[LETSENCRYPT_EMAIL]} 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    set_config "LETSENCRYPT_EMAIL" $email
                    
                    #TODO: Validate email
                    valid=1
                done
                
                
                done=1
            fi
            
            if [[ $access = '' ]]; then
                whiptail --title "Step ${config[STEPS_CURRENT]}: Access settings" --yes-button "Try Again" --no-button "Cancel" --yesno "Something went wrong... Try again or select cancel to quit" 10 30
                check_cancel $?;
            fi
        done
        
        set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
    ;;
    6)        
        {
            for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
                mkdir -p /mnt/${FOLDER}/
                #TODO: chown openflixr
            done            
            echo -e "XXX\n100\nFolders created!\nXXX"
            sleep 2s
        } | whiptail --title "Step ${config[STEPS_CURRENT]}: Folders" --gauge "Creating folders" 10 75 0

        set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
    ;;
    7)
        MOUNT_MANAGE="webmin"
        whiptail --title "Step ${config[STEPS_CURRENT]}: Mount folders" --msgbox "Visit webmin to complete the setup of your folders. http://${LOCAL_IP}/webmin/" 10 75
        check_cancel $?;
        
        set_config "MOUNT_MANAGE" $MOUNT_MANAGE
        set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
    ;;
    8)
        {
            sleep 2s
            sed -i "s/listen 443 ssl http2;/#listen 443 ssl http2; /g" /etc/nginx/sites-enabled/reverse
            echo -e "XXX\n100\nFixed!\nXXX"
            sleep 2s
        } | whiptail --title "Step ${config[STEPS_CURRENT]}: Nginx fix" --gauge "Fixing nginx" 10 75 0

        #nginx -t
        #TODO: Perfom a check to make sure this was successful
        
        set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
    ;;
    9)
        # Custom Scripts
        whiptail --title "Custom Scripts" --checklist --separate-output "If you want to install any custom scripts, choose them below." 10 75 1 \
        "jcs" "Jeremy's Custom Scripts" off \
        2>results

        while read choice
        do
            case $choice in
                jcs)
                    git clone https://github.com/jeremysherriff/OpenFLIXR2.CustomScripts.git /opt/custom
                    echo "" >> /opt/openflixr/userscript.sh
                    echo "/opt/custom/userscript_wrapper.sh # Added by OpenFLIXR Setup Script" >> /opt/openflixr/userscript.sh
                ;;
                *)
                ;;
            esac
        done < results
        
        set_config "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
    ;;
    *)
        echo ""
        echo ""
        echo "COMPLETED!!"
        echo "Checking data provided..."

        
        if [[ ${config[CHANGE_PASS]} = "Y" && $password = "" ]]; then
            echo "You selected to have the password changed but no password is set. Either something went wrong or this script was resumed (passwords aren't saved)."
            echo "We will return you to the password step now."
            sleep 2s
            ${config[STEPS_CURRENT]}=3
            STEPS_CONTINUE=9
        else
            echo "Nothing else left for us to do! Let's run the rest!"
            echo ""
            echo ""
            break
        fi
    ;;
esac

#UPDATE CONFIG FOR SCRIPT RESUME
set_config "STEPS_CURRENT" ${config[STEPS_CURRENT]}

done

#Run setup.sh now that we have everything ready
source $SETUP_SCRIPT
