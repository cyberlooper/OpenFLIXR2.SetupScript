#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

### Setup permissions fixes
echo "Fixing 'setupopenflixr' permissions"
sudo chmod +x /usr/local/bin/setupopenflixr
sudo chmod +x /usr/bin/setupopenflixr
sudo setupopenflixr -s
### End Setup permissions fixes

### Ubooquity fixes
echo "Fixing ubooquity update"
sudo setupopenflixr -f ubooquity
### End Ubooquity fixes

### Permissions fixes
echo "Fixing various permissions on the system"
sudo setupopenflixr -f permissions
### End Permissions fixes