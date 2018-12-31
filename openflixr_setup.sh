#!/bin/bash
#exec 1> >(tee -a /var/log/openflixrsetup.log) 2>&1
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

#Variables
STEPS_CURRENT=0
STEPS_CONTINUE=0
OPENFLIXIR_UID=$(id -u $OPENFLIXIR_USERNAME)
OPENFLIXIR_GID=$(id -u $OPENFLIXIR_USERNAME)
OPENFLIXR_LOGFILE="/var/log/updateof.log"
OPENFLIXR_SETUP_LOGFILE="/var/log/openflixr_setup.log"
OPENFLIXR_SETUP_CONFIG="/var/log/openflixr_setup.config"
OPENFLIXR_FOLDERS=(downloads movies series music comics books)
PUBLIC_IP=$(dig @ns1-1.akamaitech.net ANY whoami.akamai.net +short)
LOCAL_IP=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
FSTAB="/etc/fstab"
FSTAB_ORIGINAL="/etc/fstab.openflixrsetup.original"
FSTAB_BACKUP="/etc/fstab.openflixrsetup.bak"
OPENFLIXIR_CIFS_CREDENTIALS_FILE="/home/${OPENFLIXIR_USERNAME}/.credentials-openflixr"

#Helper methods
function check_cancel()
{
    local input=$1
    
    if [[ $input -eq 1 ]]; then
        echo "'Cancel' selected. Exiting script."
        exit
    fi
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

echo "Initializing: Checking to see if this has been run before."
if [ ! -f $OPENFLIXR_SETUP_CONFIG ]; then
    echo "First time running or the configuration file has been deleted."
    touch $OPENFLIXR_SETUP_CONFIG
    echo "STEPS_CURRENT=1" > $OPENFLIXR_SETUP_CONFIG
    echo "CHANGE_PASS=" >> $OPENFLIXR_SETUP_CONFIG
    echo "NETWORK=" >> $OPENFLIXR_SETUP_CONFIG
    echo "OPENFLIXR_IP=" >> $OPENFLIXR_SETUP_CONFIG
    echo "OPENFLIXR_SUBNET=" >> $OPENFLIXR_SETUP_CONFIG
    echo "OPENFLIXR_GATEWAY=" >> $OPENFLIXR_SETUP_CONFIG
    echo "OPENFLIXR_DNS=" >> $OPENFLIXR_SETUP_CONFIG
    echo "ACCESS=" >> $OPENFLIXR_SETUP_CONFIG
    echo "LETSENCRYPT_DOMAIN=" >> $OPENFLIXR_SETUP_CONFIG
    echo "LETSENCRYPT_EMAIL=" >> $OPENFLIXR_SETUP_CONFIG
    echo "MOUNT_MANAGE=" >> $OPENFLIXR_SETUP_CONFIG
    echo "MOUNT_TYPE=" >> $OPENFLIXR_SETUP_CONFIG
    echo "HOST_NAME=" >> $OPENFLIXR_SETUP_CONFIG
    echo "FSTAB_BACKUP=0" >> $OPENFLIXR_SETUP_CONFIG
    echo "FSTAB_MODIFIED=0" >> $OPENFLIXR_SETUP_CONFIG
else
    echo "Config file found! Resuming from where we last left off."
    echo ""
    echo ""
fi

#Get variables from config file
shopt -s extglob
tr -d '\r' < $OPENFLIXR_SETUP_CONFIG > $OPENFLIXR_SETUP_CONFIG.unix
while IFS='= ' read -r lhs rhs
do
    if [[ ! $lhs =~ ^\ *# && -n $lhs ]]; then
        rhs="${rhs%%\#*}"    # Del in line right comments
        rhs="${rhs%%*( )}"   # Del trailing spaces
        rhs="${rhs%\"*}"     # Del opening string quotes 
        rhs="${rhs#\"*}"     # Del closing string quotes 
        declare $lhs="$rhs"
    fi
done < $OPENFLIXR_SETUP_CONFIG.unix


#From wizard
networkconfig=$NETWORK
ip=$OPENFLIXR_IP
subnet=$OPENFLIXR_SUBNET
gateway=$OPENFLIXR_GATEWAY
dns='127.0.0.1'
password=''
if [[ $ACCESS = 'remote' ]]; then
    letsencrypt='on'
    domainname=$LETSENCRYPT_DOMAIN
    email=$LETSENCRYPT_EMAIL
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

case $STEPS_CURRENT in
    0)
        echo ""
        echo "OOPS! Moving on"
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    1)        
        echo ""
        echo "Step ${STEPS_CURRENT}: Checking to make sure OpenFLIXR is ready."
        echo "This may take about 15 minutes depending on when you ran this script..."

        LOG_LINE=""
        while [[ ! $LOG_LINE = "Set Version" ]]; do
            while IFS='' read -r line || [[ -n "$line" ]]; do
                LOG_LINE="$line"
                if [[ $DEBUG -eq 1 ]]; then
                    echo "DEBUG RUN: $LOG_LINE"
                fi
                if [[ $LOG_LINE = "Set Version" ]]; then
                  break
                fi
            done < "$OPENFLIXR_LOGFILE"
        done
        echo "OpenFLIXR is ready! Let's GO!"
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    2)
        echo ""
        echo "Step ${STEPS_CURRENT}: Timezone Settings"
        if [[ $DEBUG -ne 1 ]]; then
            dpkg-reconfigure tzdata
        else
            echo "DEBUG RUN: Would have updated timezone Settings"
        fi
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    3)
        echo ""
        echo "Step ${STEPS_CURRENT}: Set new password"
        
        done=0
        while [[ ! $done = 1 ]]; do
            CHANGE_PASS=$(whiptail --yesno --title "Change Password" "Do you want to change the default password for OpenFLIXR?" 10 40 3>&1 1>&2 2>&3)
            CHANGE_PASS=$?
            
            if [[ $CHANGE_PASS -eq 0 ]]; then
                CHANGE_PASS="Y"
                sed -i "s/CHANGE_PASS=.*/CHANGE_PASS=${CHANGE_PASS} /g" $OPENFLIXR_SETUP_CONFIG
                valid=0
                while [[ ! $valid = 1 ]]; do
                    pass=$(whiptail --passwordbox --title "Set new password" "Enter password" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    cpass=$(whiptail --passwordbox --title "Set new password" "Confirm password" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    
                    if [[ $pass == $cpass ]]; then
                        password=$pass
                        valid=1
                        done=1
                    else
                        whiptail --ok-button "Try Again" --msgbox "Passwords do not match =( Try again." 10 30
                    fi
                done
            else
                CHANGE_PASS="N"
                done=1
            fi
        done
        
        if [[ $STEPS_CONTINUE -gt 0 ]]; then
            STEPS_CURRENT=$STEPS_CONTINUE
        else
            STEPS_CURRENT=$((STEPS_CURRENT+1))
        fi
    ;;
    4)
        echo ""
        echo "Step ${STEPS_CURRENT}: Network Settings."
        
        done=0
        while [[ ! $done = 1 ]]; do
            networkconfig=$(whiptail --radiolist "Choose network configuration" 10 30 2\
                           dhcp "DHCP" on \
                           static "Static IP" off 3>&1 1>&2 2>&3)
            check_cancel $?;              
            sed -i "s/NETWORK=.*/NETWORK=${networkconfig} /g" $OPENFLIXR_SETUP_CONFIG
            
            if [[ $networkconfig = 'static' ]]; then
                echo "Configuring for Static IP"
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    ip=$(whiptail --inputbox --title "Network configuration" "IP Address" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    
                    if valid_ip $ip; then
                        sed -i "s/OPENFLIXR_IP=.*/OPENFLIXR_IP=${ip} /g" $OPENFLIXR_SETUP_CONFIG
                        valid=1
                    else
                        whiptail --ok-button "Try Again" --msgbox "Invalid IP Address" 10 30
                    fi
                done
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    subnet=$(whiptail --inputbox --title "Network configuration" "Subnet Mask" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    
                    if valid_ip $ip; then
                        sed -i "s/OPENFLIXR_SUBNET=.*/OPENFLIXR_SUBNET=${subnet} /g" $OPENFLIXR_SETUP_CONFIG
                        valid=1
                    else
                        whiptail --ok-button "Try Again" --msgbox "Invalid IP Address" 10 30
                    fi
                done
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    gateway=$(whiptail --inputbox --title "Network configuration" "Gateway" 10 30 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    
                    if valid_ip $ip; then
                        sed -i "s/OPENFLIXR_GATEWAY=.*/OPENFLIXR_GATEWAY=${gateway} /g" $OPENFLIXR_SETUP_CONFIG
                        valid=1
                    else
                        whiptail --ok-button "Try Again" --msgbox "Invalid IP Address" 10 30
                    fi
                done
                
                done=1
            fi
            
            if [[ $networkconfig = 'dhcp' ]]; then
                echo "Configuring for DHCP"
                done=1
            fi
            
            if [[ $networkconfig = '' ]]; then
                read -p "Something went wrong... Press enter to repeat this step or press ctrl+c to exit: " TEMP
            fi
        done
        
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    5)
        echo ""
        echo "Step ${STEPS_CURRENT}: Access settings"
        
        done=0
        while [[ ! $done = 1 ]]; do
            access=$(whiptail --radiolist "How do you want to access OpenFLIXR?" 10 30 2\
                           local "Local" on \
                           remote "Remote" off 3>&1 1>&2 2>&3)
            check_cancel $?;
            sed -i "s/ACCESS=.*/ACCESS=${access} /g" $OPENFLIXR_SETUP_CONFIG
            
            if [[ $access = 'local' ]]; then
                echo "Local access selected. Nothing else to do."
                done=1
            fi
            
            if [[ $access = 'remote' ]]; then
                echo "Configuring for Remote access."
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    domain=$(whiptail --inputbox --ok-button "Next" --title "STEP 1/ : Domain" "Enter your domain (required to obtain certificate). If you don't have one, register one and then enter it here." 10 50 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    sed -i "s/LETSENCRYPT_DOMAIN=.*/LETSENCRYPT_DOMAIN=${domain} /g" $OPENFLIXR_SETUP_CONFIG
                    
                    #TODO: Validate domain
                    valid=1
                done
                
                whiptail --ok-button "Next" --msgbox "Add/Edit the A records for ${domain} and www.${domain} to point to ${PUBLIC_IP}" 10 50
                whiptail --ok-button "Next" --msgbox "Forward port 443 (only!) on your router to your local IP (${LOCAL_IP})" 10 50
                
                valid=0
                while [[ ! $valid = 1 ]]; do
                    email=$(whiptail --inputbox --title "STEP 1/ : Domain" "Enter your e-mail address (required for lost key recovery)." 10 50 3>&1 1>&2 2>&3)
                    check_cancel $?;
                    
                    #TODO: Validate email
                    valid=1
                done
                
                
                done=1
            fi
            
            if [[ $access = '' ]]; then
                read -p "Something went wrong... Press enter to repeat this step or press ctrl+c to exit: " TEMP
            fi
        done
        
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    6)
        echo ""
        echo "Step ${STEPS_CURRENT}: Folders"
        echo "Creating mount folders"
        for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
            if [[ $DEBUG -ne 1 ]]; then
                echo "Creating mount point /mnt/${FOLDER}/"
                sudo mkdir -p /mnt/${FOLDER}/
            else
                echo "Would have created /mnt/${FOLDER}/"
            fi
        done
        
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    7)
        echo ""
        echo "Step ${STEPS_CURRENT}: Mount network shares"
        MOUNT_MANAGE="webmin"
        echo "Visit webmin to complete the setup of your folders. http://${LOCAL_IP}/webmin/"
        sed -i "s/MOUNT_MANAGE=.*/MOUNT_MANAGE=webmin /g" $OPENFLIXR_SETUP_CONFIG
        #done=0
        #while [[ ! $done = 1 ]]; do
        #    sharetype=$(whiptail --radiolist "Choose network share type" 10 30 2\
        #                   nfs "NFS" on \
        #                   cifs "CIFS/SMB" off 3>&1 1>&2 2>&3)
        #    check_cancel $?;
        #done

        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    8)
        echo ""
        echo "Step ${STEPS_CURRENT}: Nginx fix"
        if [[ $DEBUG -ne 1 ]]; then
            sed -i "s/listen 443 ssl http2;/#listen 443 ssl http2; /g" /etc/nginx/sites-enabled/reverse
            echo "Done! Let's test to make sure nginx likes it..."
            nginx -t
        else
            echo "This would have commented out a line in /etc/nginx/sites-enabled/reverse"
        fi
        echo "If the above doesn't say 'syntax ok' and 'test is successful' please edit '/etc/nginx/sites-enabled/reverse' directly to correct any problems."
        
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    *)
        echo ""
        echo ""
        echo "COMPLETED!!"
        echo "Checking data provided..."
        
        if [[ $CHANGE_PASS = "Y" && $password = "" ]]; then
            echo "You selected to have the password changed but no password is set. Either something went wrong or this script was resumed (passwords aren't saved)."
            echo "We will return you to the password step now."
            STEPS_CURRENT=3
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
sed -i "s/STEPS_CURRENT=.*/STEPS_CURRENT=${STEPS_CURRENT} /g" $OPENFLIXR_SETUP_CONFIG

done

#Find setup.sh and run it. 
if [ -f "/usr/share/nginx/html/setup/scripts/setup.sh" ]; then
    echo "Found setup.sh in /usr/share/nginx/html/setup/scripts/"
    chmod +x /usr/share/nginx/html/setup/scripts/setup.sh
    source /usr/share/nginx/html/setup/scripts/setup.sh
elif [ -f "/usr/share/nginx/html/setup/setup.sh" ]; then
    echo "Found setup.sh in /usr/share/nginx/html/setup/"
    chmod +x /usr/share/nginx/html/setup/setup.sh
    source /usr/share/nginx/html/setup/setup.sh
elif [ -f "/home/openflixr/setup.sh" ]; then
    echo "Found setup.sh in /home/openflixr/"
    chmod +x /home/openflixr/setup.sh
    source /home/openflixr/setup.sh
elif [ ! -f "/home/openflixr/setup.sh" ]; then
    echo "Couldn't find setup.sh. Downloading from repo"
    wget -o /home/openflixr/setup.sh https://raw.githubusercontent.com/MagicalCodeMonkey/OpenFLIXR2.SetupScript/dev/setup.sh
    chmod +x /home/openflixr/setup.sh
    source /home/openflixr/setup.sh
else
    echo "Couldn't find setup.sh to complete the setup."
fi
