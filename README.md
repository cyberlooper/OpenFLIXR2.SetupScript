# OpenFLIXR2.SetupScript
## Information
A script to help with OpenFLIXR setup.

While this will help you get started, it doesn't get you to a fully functioning box, you will still need to do some configuring of the various applications once complete.
Also, Please DO NOT run this against a working instance of OpenFLIXR. I have no idea what that might do. Fortunately, OpenFLIXR is container-based, so you can spin up a new one and test it out there.

## Usage
NOTE: OpenFLIXR 2.9 hasn't been release yey but will be released soon.

As of OpenFLIXR 2.9, the setup script is included!
To run the setup, you now can simply go to `/setup` in your browser!

An alternative is to run the following after connecting to OpenFLIXR via SSH
```bash
sudo setupopenflixr
```

## Special Thanks
Thanks to OpenFLIXR for being an awesome setup that motivated me to work on this as well as a bunch of other projects.

Thanks to Jeremy for making the guide for how to setup OpenFLIXR when the WebWizard went down that helped me build the original version of this script.

Thanks to [GhostWriters](https://github.com/GhostWriters), specifically their work on [DockSTARTer](https://github.com/GhostWriters/DockSTARTer) and the framework they built for scripts!
