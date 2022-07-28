#!/bin/bash

set -e
set -x

# Activate License
RSC_LICENSE_FILE_PATH=${RSC_LICENSE_FILE_PATH:-/etc/rstudio-connect/license.lic}
if ! [ -z "$RSC_LICENSE" ]; then
    /opt/rstudio-connect/bin/license-manager activate $RSC_LICENSE
elif ! [ -z "$RSC_LICENSE_SERVER" ]; then
    /opt/rstudio-connect/bin/license-manager license-server $RSC_LICENSE_SERVER
elif test -f "$RSC_LICENSE_FILE_PATH"; then
    /opt/rstudio-connect/bin/license-manager activate-file $RSC_LICENSE_FILE_PATH
fi

# ensure these cannot be inherited by child processes
unset RSC_LICENSE
unset RSC_LICENSE_SERVER
