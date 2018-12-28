#!/bin/bash
DEBUG=0 #Change this to a 1 if you want to run in debug mode. Debug mode disables the script from actually doing anything in most cases.
OPENFLIXIR_USERNAME="openflixr" #Change this if you aren't using the default username

#DO NOT CHANGE ANY OF THESE
STEPS_CURRENT=0
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

if [[ "$EUID" -ne 0 ]]; then
      echo "Please run as root..."
      echo "You can do this by either putting 'sudo' before the script or typing 'sudo su -' into your prompt before running"
      exit
  else 
    echo "Running as root! Great you can follow directions and we may continue!"
fi

echo ""
echo ""
echo ""
echo "----------------------------------"
echo "First, some acknowledgments!"
echo "Thanks to those that have built and help build OpenFLIXR! It is awesome!"
echo "This script is largely based on the guide by jeremywho found here: http://www.openflixr.com/forum/discussion/559/setup-instructions-without-web-wizard"
echo "Thanks to jeremywho for putting that together! Any steps that I may have missed or additional information can be found by visiting that link"
echo "Thanks to those people, past, present, and future that have helped make, test, or improve this script!"
echo ""
read -p "Press enter to continue" TEMP
echo "----------------------------------"
echo ""
echo "Now we may begin!"
echo ""
echo ""

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
        echo "Step ${STEPS_CURRENT}: Change passwords"
        read -p "Do you want to change ${OPENFLIXIR_USERNAME}'s password? (y/n): " CHANGE_PASS
        sed -i "s/CHANGE_PASS=.*/CHANGE_PASS=${CHANGE_PASS} /g" $OPENFLIXR_SETUP_CONFIG
        if [[ $DEBUG -ne 1 ]]; then
            if [[ $CHANGE_PASS = "y" ]]; then
                echo "Updating linux password"
                echo "Fixing expiry settings"
                passwd -d $OPENFLIXIR_USERNAME
                passwd $OPENFLIXIR_USERNAME

                echo "Updating HTPC password"
                cp /etc/nginx/.htpasswd /etc/nginx/.htpasswd.bak
                htpasswd -c /etc/nginx/.htpasswd openflixr
            else
                echo "Keeping ${OPENFLIXIR_USERNAME}'s default password"
            fi
            else
                echo "DEBUG RUN: Change pass? $CHANGE_PASS"
        fi
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    4)
        echo ""
        echo "Step ${STEPS_CURRENT}: Network Settings."
        PS3='Please choose your network type: '
        options=("DHCP" "Static")
        select opt in "${options[@]}"
        do
            case $opt in
                "DHCP")
                    echo "Configuring for DHCP"
                    sed -i "s/NETWORK=.*/NETWORK=${opt} /g" $OPENFLIXR_SETUP_CONFIG
                    
                    break
                    ;;
                "Static")
                    echo "Configuring for Static"
                    sed -i "s/NETWORK=.*/NETWORK=${opt} /g" $OPENFLIXR_SETUP_CONFIG
                    read -p "IP Address: " OPENFLIXR_IP
                    sed -i "s/OPENFLIXR_IP=.*/OPENFLIXR_IP=${OPENFLIXR_IP} /g" $OPENFLIXR_SETUP_CONFIG
                    read -p "Subnet Mask: " OPENFLIXR_SUBNET
                    sed -i "s/OPENFLIXR_IP=.*/OPENFLIXR_IP=${OPENFLIXR_IP} /g" $OPENFLIXR_SETUP_CONFIG
                    read -p "GATEWAY: " OPENFLIXR_GATEWAY
                    sed -i "s/OPENFLIXR_IP=.*/OPENFLIXR_IP=${OPENFLIXR_IP} /g" $OPENFLIXR_SETUP_CONFIG
                    break
                    ;;
                *) echo "Invalid option";;
            esac
        done
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    5)
        echo ""
        echo "Step ${STEPS_CURRENT}: Access settings"
        PS3='Please choose your access type: '
        options=("Local" "Remote")
        select opt in "${options[@]}"
        do
            case $opt in
                "Local")
                    echo "Local access selected."
                    sed -i "s/ACCESS=.*/ACCESS=${opt} /g" $OPENFLIXR_SETUP_CONFIG
                    break
                    ;;
                "Remote")
                    echo "Configuring for Remote access."
                    sed -i "s/ACCESS=.*/ACCESS=${opt} /g" $OPENFLIXR_SETUP_CONFIG
                    
                    echo "To complete this, you must first do the following:"
                    echo "Register a domain name for your server."
                    
                    if [[ $DEBUG -eq 1 ]]; then
                        echo "LETSENCRYPT_DOMAIN from config: '$LETSENCRYPT_DOMAIN'"
                        echo "LETSENCRYPT_EMAIL from config: '$LETSENCRYPT_EMAIL'"
                    fi
                    
                    if [[ $LETSENCRYPT_DOMAIN = "" ]]; then
                        read -p "Once registered, provide your domain name (without www): " DOMAIN
                    else
                        read -p "Once registered, provide your domain name (without www) [${LETSENCRYPT_DOMAIN}]: " DOMAIN
                    fi                    
                    LETSENCRYPT_DOMAIN=${DOMAIN:-$LETSENCRYPT_DOMAIN}
                    sed -i "s/LETSENCRYPT_DOMAIN=.*/LETSENCRYPT_DOMAIN=${LETSENCRYPT_DOMAIN} /g" $OPENFLIXR_SETUP_CONFIG
                    
                    echo "Add/Edit the A records for ${LETSENCRYPT_DOMAIN} and www.${LETSENCRYPT_DOMAIN} to point to ${PUBLIC_IP}"
                    read -p "Press enter to continue" TEMP
                    
                    echo "Forward ONLY port 443 to OpenFLIXR's Local IP"
                    read -p "Press enter to continue" TEMP
                    
                    echo "Provide and e-mail address for lost key recovery"
                    if [[ $LETSENCRYPT_EMAIL = "" ]]; then
                        read -p "E-mail address: " EMAIL
                    else
                        read -p "E-mail address [${LETSENCRYPT_EMAIL}]: " EMAIL
                    fi                    
                    LETSENCRYPT_EMAIL=${EMAIL:-$LETSENCRYPT_EMAIL}
                    sed -i "s/LETSENCRYPT_EMAIL=.*/LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL} /g" $OPENFLIXR_SETUP_CONFIG
                    
                    echo "Time to configure Let's Encrypt! User input may be required."
                    if [[ $DEBUG -ne 1 ]]; then
                        read -p "Press enter to continue" TEMP
                        apt-get update
                        apt-get install software-properties-common
                        add-apt-repository universe
                        add-apt-repository ppa:certbot/certbot
                        apt-get update
                        apt-get install python-certbot-nginx
                    
                        certbot --nginx -d "${LETSENCRYPT_DOMAIN},www.${LETSENCRYPT_DOMAIN}" -m "${LETSENCRYPT_EMAIL}"
                    else
                        echo "DEBUG RUN: Would have installed certbot and ran it"
                    fi
                    break
                    ;;
                *) echo "Invalid option";;
            esac
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
        echo "Step ${STEPS_CURRENT}: Mount folders"
        
        echo "How do you want to manage the folder mounting?"
        echo "Currently only NFS and CIFS are supported in this script. You may also use Webmin to mange this step instead."
        PS3='Choose your quest:'
        options=("Mount a Network Share via this script" "Mount a Network Share via Webmin" "Quit")
        select opt in "${options[@]}"
        do
            case $opt in
                "Mount a Network Share via this script")
                    MOUNT_MANAGE="script"
                    sed -i "s/MOUNT_MANAGE=.*/MOUNT_MANAGE=script /g" $OPENFLIXR_SETUP_CONFIG
                    
                    break
                ;;
                "Mount a Network Share via Webmin")
                    MOUNT_MANAGE="webmin"
                    echo "Visit webmin to complete the setup of your folders. http://${LOCAL_IP}/webmin/"
                    sed -i "s/MOUNT_MANAGE=.*/MOUNT_MANAGE=webmin /g" $OPENFLIXR_SETUP_CONFIG
                    break
                ;;
                "Quit")
                    exit
                ;;
                *) echo "Invalid option";;
            esac
        done
        
        if [[ $MOUNT_MANAGE = "script" ]]; then
            if [[ $FSTAB_BACKUP -eq 0 ]]; then
                echo "Backing up $FSTAB"
                cp $FSTAB $FSTAB_ORIGINAL
                sed -i "s/FSTAB_BACKUP=.*/FSTAB_BACKUP=1 /g" $OPENFLIXR_SETUP_CONFIG
            fi
            
            if [[ $FSTAB_MODIFIED -eq 1 ]]; then
                PS3='Restore $FSTAB from $FSTAB_ORIGINAL?:'
                options=("Yes" "No" "See $FSTAB" "See $FSTAB_ORIGINAL" "Quit")
                select opt in "${options[@]}"
                do
                    case $opt in
                        "Yes")
                            echo "Restoring $FSTAB from $FSTAB_ORIGINAL"
                            break
                        ;;
                        "No")
                            break
                        ;;
                        "See $FSTAB")
                            echo ""
                            echo "------------------------"
                            cat $FSTAB
                            echo "------------------------"
                            echo ""
                        ;;
                        "See $FSTAB_ORIGINAL")
                            echo ""
                            echo "------------------------"
                            cat $FSTAB_ORIGINAL
                            echo "------------------------"
                            echo ""
                        ;;
                        "Quit")
                            exit
                        ;;
                        *) echo "Invalid option";;
                    esac
                done
                
                if [[ $RESTORE -eq y ]]; then
                    cp $FSTAB_ORIGINAL $FSTAB
                else
                    echo "Making backups, just in case."
                    cp $FSTAB $FSTAB_BACKUP
                fi
            else            
                echo "" >> $FSTAB
                echo "#OPENFLIXR SETUP" >> $FSTAB
                sed -i "s/FSTAB_MODIFIED=.*/FSTAB_MODIFIED=1 /g" $OPENFLIXR_SETUP_CONFIG
            fi
            
            # Ask NFS or CIFS?
            MOUNT_TYPE=""
            while [[ $MOUNT_TYPE = "" && (! $MOUNT_TYPE = "nfs" || ! $MOUNT_TYPE = "cifs") ]]; do
                read -p "Please enter you filestorage mount type. (nfs|cifs|webmin): " MOUNT_TYPE
                MOUNT_TYPE=$(echo "$MOUNT_TYPE" | tr '[:upper:]' '[:lower:]')
                sed -i "s/MOUNT_TYPE=.*/MOUNT_TYPE=${MOUNT_TYPE} /g" $OPENFLIXR_SETUP_CONFIG
            done

            #If CIFS, get credentials and create credentials file
            if [[ $MOUNT_TYPE = "cifs" ]]; then
                echo "CIFS network shares requires credentials to access them. 
                It is more secure to save these to a file so we will save them to '/home/$OPENFLIXIR_USERNAME/.credentials-openflixr'"
                echo "You can change these at any time by editing that file or re-running this step."
                
                read -p "Please enter you network share username: " CIFS_USERNAME
                
                while [[ ! $CIFS_PASS = $CIFS_PASS_CONFIRM ]]; do
                    read -sp "Please enter you network share password: " CIFS_PASS
                    read -sp "Please enter you network share password again: " CIFS_PASS_CONFIRM
                    
                    if [[ ! $CIFS_PASS = $CIFS_PASS_CONFIRM ]]; then
                        echo "Passwords entered do not match :( Try again!"
                    fi
                done
                
                if [ ! -f "/home/$OPENFLIXIR_USERNAME/.credentials-openflixr" ]; then
                    touch "/home/$OPENFLIXIR_USERNAME/.credentials-openflixr"
                    echo "USERNAME=${CIFS_USERNAME}" >> $OPENFLIXIR_CIFS_CREDENTIALS_FILE
                    echo "PASSWORD=${CIFS_PASS}" >> $OPENFLIXIR_CIFS_CREDENTIALS_FILE
                else
                    sed -i "s/USERNAME=.*/USERNAME=${CIFS_USERNAME} /g" $OPENFLIXIR_CIFS_CREDENTIALS_FILE
                    sed -i "s/PASSWORD=.*/PASSWORD=${CIFS_PASS} /g" $OPENFLIXIR_CIFS_CREDENTIALS_FILE
                fi
                
                echo "Clearing temporaty credential variables, for security reasons"
                CIFS_USERNAME=""
                CIFS_PASS=""
                CIFS_PASS_CONFIRM=""
            fi
            
            # Ask for server name or IP
            HOST_NAME=""
            while [[ $HOST_NAME = "" ]]; do
                echo ""
                read -p "Please enter you server name or IP address: " HOST_NAME
                sed -i "s/HOST_NAME=.*/HOST_NAME=${HOST_NAME} /g" $OPENFLIXR_SETUP_CONFIG
            done
            
            for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
                echo ""
                echo "Setting up for '${FOLDER}'"
              
                # Ask for server folder
                HOST_FOLDER=""
                while [[ $HOST_FOLDER = "" ]]; do
                    echo ""
                    read -p "Please enter the folder name on your network share for ${FOLDER} (press 'Enter' to leave blank and mount directly): " HOST_FOLDER
                done
                
                if [[ $DEBUG -ne 1 ]]; then                    
                    if [[ $MOUNT_TYPE = "nfs" ]]; then
                        #TODO: Check if this mount already exists in FSTAB
                        #TODO: Check that the mount works before adding to FSTAB
                        echo "Adding '$HOST_NAME:/$HOST_FOLDER  /mnt/${FOLDER}/  $MOUNT_TYPE defaults    0 0' to $FSTAB"
                        echo "$HOST_NAME:/$HOST_FOLDER  /mnt/${FOLDER}/  $MOUNT_TYPE defaults    0 0" >> $FSTAB
                    fi
                    
                    if [[ $MOUNT_TYPE = "cifs" ]]; then
                        #TODO: Check if this mount already exists in FSTAB
                        #TODO: Check that the mount works before adding to FSTAB
                        echo "Adding '//$HOST_NAME/$HOST_FOLDER /mnt/${FOLDER}/ $MOUNT_TYPE credentials=${OPENFLIXR_SETUP_CONFIG},iocharset=utf8,gid=$OPENFLIXIR_GID,uid=$OPENFLIXIR_UID,file_mode=0777,dir_mode=0777 0 0' to $FSTAB"
                        echo "//$HOST_NAME/$HOST_FOLDER /mnt/${FOLDER}/ $MOUNT_TYPE credentials=${OPENFLIXR_SETUP_CONFIG},iocharset=utf8,gid=$OPENFLIXIR_GID,uid=$OPENFLIXIR_UID,file_mode=0777,dir_mode=0777 0 0" >> $FSTAB
                    fi
                else
                    echo "Would have added //$HOST_NAME/$HOST_FOLDER to $FSTAB using $MOUNT_TYPE"
                fi
            done
            
            if [[ $DEBUG -ne 1 ]]; then
                echo "Everything added to $FSTAB. Let's mount them!"
                mount -a
            fi
        fi
        
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
    9)
        echo ""
        echo "Step ${STEPS_CURRENT}: Update openflixr"
        echo "This may take a LONG time and requires some user input."
        PS3='Do you want to have the script start this or do in manually?:'
        options=("Script!" "Manually" "Quit")
        select opt in "${options[@]}"
        do
            case $opt in
                "Script!")
                    sed -i "s/STEPS_CURRENT=.*/STEPS_CURRENT=${STEPS_CURRENT} /g" $OPENFLIXR_SETUP_CONFIG
                    echo ""
                    echo "The system will reboot after the update script completes. No need to worry, just run this after reboot and we will pick up where we left off."
                    echo "Now, pay attention for prompts!"
                    read -p "Press enter to continue" TEMP
                    if [[ $DEBUG -ne 1 ]]; then
                        updateopenflixr
                    else
                        echo "This would have run updateopenflixr"
                    fi
                    break
                ;;
                "Manually")
                    echo "Update openflixr by typing 'sudo updateopenflixr' in your prompt."
                    break
                ;;
                "Quit")
                    exit
                ;;
                *) echo "Invalid option";;
            esac
        done
        
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    10)
        echo ""
        echo "Step ${STEPS_CURRENT}: Update openflixr again, but differently"
        PS3='Do you want to have the script start this or do in manually?:'
        options=("Script!" "Manually" "Quit")
        select opt in "${options[@]}"
        do
            case $opt in
                "Script!")
                    sed -i "s/STEPS_CURRENT=.*/STEPS_CURRENT=${STEPS_CURRENT} /g" $OPENFLIXR_SETUP_CONFIG
                    echo ""
                    read -p "Press enter to continue" TEMP
                    if [[ $DEBUG -ne 1 ]]; then
                        /opt/openflixr/updatewkly.sh
                    else
                        echo "This would have run /opt/openflixr/updatewkly.sh"
                    fi
                    break
                ;;
                "Manually")
                    echo "Update openflixr again by entering 'sudo /opt/openflixr/updatewkly.sh' into your prompt"
                    break
                ;;
                "Quit")
                    exit
                ;;
                *) echo "Invalid option";;
            esac
        done
        
        STEPS_CURRENT=$((STEPS_CURRENT+1))
    ;;
    *)
        echo ""
        echo ""
        echo "COMPLETED!!"
        echo "Nothing else left for this script to do!"
        echo "Be sure you exit sudo mode by either typing 'exit' or pressing 'ctrl-d'"
        echo ""
        echo ""
        break
    ;;
esac

#UPDATE CONFIG FOR SCRIPT RESUME
sed -i "s/STEPS_CURRENT=.*/STEPS_CURRENT=${STEPS_CURRENT} /g" $OPENFLIXR_SETUP_CONFIG

done
