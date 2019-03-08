

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

## To-do:
+ Configure folder/network share mounting
+ Addition of other sections for configuration

## Usage
1. Install Virtualbox or your favorite hypervisor
2. Download OpenFLIXR - http://www.openflixr.com/#Download
3. Import in hypervisor and power on
4. Log in to your OpenFLIXR box
5. Run the following
```bash
sudo apt-get install curl git
bash -c "$(curl -fsSL https://openflixr.github.io/OpenFLIXR2.SetupScript/main.sh)"
```

## Special Thanks
Thanks to OpenFLIXR for being an awesome setup that motivated me to work on this as well as a bunch of other projects.

Thanks to Jeremy for making the guide for how to setup OpenFLIXR when the WebWizard went down that helped me build the original version of this script. The guide can be found here: http://www.openflixr.com/forum/discussion/559/setup-instructions-without-web-wizard but now is based on what WebWizard outputs - https://github.com/mfrelink/OpenFLIXR2.Wizard

Thanks to [GhostWriters](https://github.com/GhostWriters), specifically their work on [DockSTARTer](https://github.com/GhostWriters/DockSTARTer) and the framework they built for scripts!
