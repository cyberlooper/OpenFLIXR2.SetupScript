

# OpenFLIXR2.SetupScript
## Information
A script to help with OpenFLIXR2 setup without the web wizard.

While this will help you get started, it doesn't get you to a fully functioning box, you will still need to do some configuring of the various applications once complete.
Also, Please DO NOT run this against a working instance of OpenFLIXR. I have no idea what that might do. Fortunately, OpenFLIXR is container-based, so you can spin up a new one and test it out there.

## Usage
NOTE: This will only work with OpenFLIXR 2.9 running on Ubuntu 18.04. Since OpenFLIXR 2.9 hasn't been released yet, please wait to run this.
1. Install Virtualbox or your favorite hypervisor
2. Download OpenFLIXR - http://www.openflixr.com/#Download
3. Import in hypervisor and power on
4. Log in to your OpenFLIXR box
5. Run the following
```bash
bash -c "$(curl -fsSL https://openflixr.github.io/OpenFLIXR2.SetupScript/main.sh)"
```

## Special Thanks
Thanks to OpenFLIXR for being an awesome setup that motivated me to work on this as well as a bunch of other projects.

Thanks to Jeremy for making the guide for how to setup OpenFLIXR when the WebWizard went down that helped me build the original version of this script. The guide can be found here: http://www.openflixr.com/forum/discussion/559/setup-instructions-without-web-wizard but now is based on what WebWizard outputs - https://github.com/mfrelink/OpenFLIXR2.Wizard

Thanks to [GhostWriters](https://github.com/GhostWriters), specifically their work on [DockSTARTer](https://github.com/GhostWriters/DockSTARTer) and the framework they built for scripts!
