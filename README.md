# OpenFLIXR2.SetupScript
[![Discord chat](https://img.shields.io/discord/505749119802015756.svg?logo=discord)](https://discord.gg/PcCErTQ)
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

## Troubleshooting
If there are any issues with the script that cause it to error, it will let you know and attempt to submit the logs for you (if you want) or direct you to this section.

You can submit logs at any point by running
```bash
sudo setupopenflixr -l
```

If the automatic submission doesn't work, you will need to manually provide logs for troubleshooting.
To do this, run the following then send `/tmp/setup_logs.tar.gz` to MattyLightCU on Discord so that he can look into the issue.
```bash
tar -czvf /tmp/setup_logs.tar.gz /var/log/openflixr_setup.*
```

## Testing
Want to help with testing new development work and features of the setup? We'd really appreciate it!
Ask on [Discord](https://discord.gg/PcCErTQ) what the current development branch is, then do the following.
```bash
sudo setupopenflixr -u <branch>
sudo setupopenflixr -d
```
After running through the setup, let us know how it went and send us your logs.

## Special Thanks
Thanks to OpenFLIXR for being an awesome setup that motivated me to work on this as well as a bunch of other projects.

Thanks to Jeremy for making the guide for how to setup OpenFLIXR when the WebWizard went down that helped me build the original version of this script.

Thanks to [GhostWriters](https://github.com/GhostWriters), specifically their work on [DockSTARTer](https://github.com/GhostWriters/DockSTARTer) and the framework they built for scripts!
