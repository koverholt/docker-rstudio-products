#!/bin/bash

TCPDUMP_OUTPUT=${TCPDUMP_OUTPUT:-/tmp/tcpdump.pcap}
TCPDUMP_MAX_PACKETS=${TCPDUMP_MAX_PACKETS:-10000}

tcpdump -i any -w ${TCPDUMP_OUTPUT} -c ${TCPDUMP_MAX_PACKETS} &

# Launch the session based on RSTUDIO_TYPE
if [ -z "$RSTUDIO_TYPE" -o "$RSTUDIO_TYPE" == "session" ]; then
  echo "Starting RStudio session..."
  exec "/usr/lib/rstudio-server/bin/rserver-launcher" "$@"
elif [ "$RSTUDIO_TYPE" == "adhoc" ]; then
  echo "Starting RStudio adhoc job..."
  exec "/bin/bash" "$@"
else
  echo "ERROR: Unknown RSTUDIO_TYPE: ${RSTUDIO_TYPE}"
  exit 1
fi
