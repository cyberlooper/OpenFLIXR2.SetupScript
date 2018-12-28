# OpenFLIXR2.SetupScript
A script to help with OpenFLIXR2 setup without the web wizard

This script is largely based on the guide by jeremywho found here: http://www.openflixr.com/forum/discussion/559/setup-instructions-without-web-wizard

While this has been tested, it needs to be tested by more than just me and there may be bugs.
Please DO NOT run this against a working instance of OpenFLIXR. I have no idea what that might do. Fortunately, OpenFLIXR is container-based, so you can spin up a new one and test it out there.

Some areas in particular that need some additional love or more thorough testing:
+ Let's Encrypt/Certbot usage
+ NGINX fix
+ File mounting

Run this script by doing the following:
1. Uploading the script to your OpenFLIXIR box
2. Make it executable: `chmod +x openflixr_setup.sh`
3. Enter root: `sudo su -` or put `sudo` in front of the next line
4. Run the script: `./openflixr_setup.sh`
