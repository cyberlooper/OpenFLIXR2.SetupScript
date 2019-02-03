

# OpenFLIXR2.SetupScript
## Information
A script to help with OpenFLIXR2 setup without the web wizard.

While this will help you get started, it doesn't get you to a fully functioning box, you will still need to do some configuring of the various applications once complete.
Also, Please DO NOT run this against a working instance of OpenFLIXR. I have no idea what that might do. Fortunately, OpenFLIXR is container-based, so you can spin up a new one and test it out there.

## Features:
+ Automatically gets the latest extra scripts/files from the repository
+ Resume where you left off
+ Check to make sure OpenFLIXR is ready for setup
+ Configure timezone
+ Change password 
+ Configure Network settings
+ Configure Access settings (remote option still needs some work)
+ Create mount folders
+ nginx fix
+ Add custom scripts. Supported scripts:
	+ [Jeremy's Custom Scripts](https://github.com/jeremysherriff/OpenFLIXR2.CustomScripts)

## To-do:

+ Let's Encrypt/Certbot usage
+ Configure folder/network share mounting
+ Addition of other sections for configuration

## Usage
1. Install Virtualbox or your favorite hypervisor
2. Download OpenFLIXR - http://www.openflixr.com/#Download
3. Import in hypervisor and power on
3. Follow one of the options below to run the this script...

Run this script by doing the following:
### Option 1 (Preferred)
1. Log in to your OpenFLIXR box
2. Copy and paste the following into your command line (prompt) making sure it is all one line: `wget -O openflixr_setup.sh  https://raw.githubusercontent.com/MagicalCodeMonkey/OpenFLIXR2.SetupScript/master/openflixr_setup.sh && sudo bash openflixr_setup.sh`
### Option 2
 1. Upload `openflixr_setup.sh` to your OpenFLIXIR box, in the home directory
 2. Run the script: `sudo bash openflixr_setup.sh`
### Option 3
If for some reason Option 2 won't work for you
 1. Upload `openflixr_setup.sh` to your OpenFLIXIR box, in the home directory
 2. Make it executable: `chmod +x openflixr_setup.sh` 
 3. Run the script: `sudo ./openflixr_setup.sh`

### Notes
This script was originally largely based on the guide by Jeremy found here: http://www.openflixr.com/forum/discussion/559/setup-instructions-without-web-wizard but now is based on what WebWizard outputs - https://github.com/mfrelink/OpenFLIXR2.Wizard
