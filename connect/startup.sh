#!/bin/bash

set -e
set -x

# Deactivate license when it exists
deactivate() {
    echo "Deactivating license ..."
    /opt/rstudio-connect/bin/license-manager deactivate >/dev/null 2>&1
}
trap deactivate EXIT

# Start RStudio Connect
/opt/rstudio-connect/bin/connect --config /etc/rstudio-connect/rstudio-connect.gcfg
