#!/bin/bash

set -e
set -x

# Deactivate license when it exists
deactivate() {
    echo "== Exiting =="
    rstudio-server stop

    echo " --> TAIL 100 rstudio-server.log"
    tail -n 100 /var/log/rstudio-server.log
    echo " --> TAIL 100 rstudio-kubernetes-launcher.log"
    tail -n 100 /var/lib/rstudio-launcher/Kubernetes/rstudio-kubernetes-launcher.log
    echo " --> TAIL 100 rstudio-local-launcher*.log"
    tail -n 100 /var/lib/rstudio-launcher/Local/rstudio-local-launcher*.log
    echo " --> TAIL 100 rstudio-launcher.log"
    tail -n 100 /var/lib/rstudio-launcher/rstudio-launcher.log
    echo " --> TAIL 100 monitor/log/rstudio-server.log"
    tail -n 100 /var/lib/rstudio-server/monitor/log/rstudio-server.log

    echo "Deactivating license ..."
    /usr/lib/rstudio-server/bin/license-manager deactivate >/dev/null 2>&1

    echo "== Done =="
}
trap deactivate EXIT

verify_installation(){
   echo "==VERIFY INSTALLATION==";
   mkdir -p $DIAGNOSTIC_DIR
   chmod 777 $DIAGNOSTIC_DIR
   rstudio-server verify-installation --verify-user=$RSP_TESTUSER | tee $DIAGNOSTIC_DIR/verify.log
}

# touch log files to initialize them
su rstudio-server -c 'touch /var/lib/rstudio-server/monitor/log/rstudio-server.log'
mkdir -p /var/lib/rstudio-launcher
chown rstudio-server:rstudio-server /var/lib/rstudio-launcher
su rstudio-server -c 'touch /var/lib/rstudio-launcher/rstudio-launcher.log'
touch /var/log/rstudio-server.log
mkdir -p /var/lib/rstudio-launcher/Local
chown rstudio-server:rstudio-server /var/lib/rstudio-launcher/Local
su rstudio-server -c 'touch /var/lib/rstudio-launcher/Local/rstudio-local-launcher-placeholder.log'
mkdir -p /var/lib/rstudio-launcher/Kubernetes
chown rstudio-server:rstudio-server /var/lib/rstudio-launcher/Kubernetes
su rstudio-server -c 'touch /var/lib/rstudio-launcher/Kubernetes/rstudio-kubernetes-launcher.log'

# Support RSP_ or RSW_ prefix
RSP_LICENSE=${RSP_LICENSE:-${RSW_LICENSE}}
RSP_LICENSE_SERVER=${RSP_LICENSE_SERVER:-${RSW_LICENSE_SERVER}}

# Activate License
RSW_LICENSE_FILE_PATH=${RSW_LICENSE_FILE_PATH:-/etc/rstudio-server/license.lic}
if ! [ -z "$RSP_LICENSE" ]; then
    /usr/lib/rstudio-server/bin/license-manager activate $RSP_LICENSE
elif ! [ -z "$RSP_LICENSE_SERVER" ]; then
    /usr/lib/rstudio-server/bin/license-manager license-server $RSP_LICENSE_SERVER
elif test -f "$RSW_LICENSE_FILE_PATH"; then
    /usr/lib/rstudio-server/bin/license-manager activate-file $RSW_LICENSE_FILE_PATH
fi

# ensure these cannot be inherited by child processes
unset RSP_LICENSE
unset RSP_LICENSE_SERVER
unset RSW_LICENSE
unset RSW_LICENSE_SERVER

# Create one user
if [ $(getent passwd $RSP_TESTUSER_UID) ] ; then
    echo "UID $RSP_TESTUSER_UID already exists, not creating $RSP_TESTUSER test user";
else
    if [ -z "$RSP_TESTUSER" ]; then
        echo "Empty 'RSP_TESTUSER' variables, not creating test user";
    else
        useradd -m -s /bin/bash -N -u $RSP_TESTUSER_UID $RSP_TESTUSER
        echo -n "$RSP_TESTUSER:$RSP_TESTUSER_PASSWD" | sudo chpasswd
    fi
fi

# Start Launcher
if [ "$RSP_LAUNCHER" == "true" ]; then
  /usr/lib/rstudio-server/bin/rstudio-launcher > /var/log/rstudio-launcher.log 2>&1 &
  wait-for-it.sh localhost:5559 -t $RSP_LAUNCHER_TIMEOUT
fi

# Check diagnostic configurations
if [ "$DIAGNOSTIC_ENABLE" == "true" ]; then
  verify_installation
  if [ "$DIAGNOSTIC_ONLY" == "true" ]; then
    echo $(<$DIAGNOSTIC_DIR/verify.log);
    echo "Exiting script because DIAGNOSTIC_ONLY=${DIAGNOSTIC_ONLY}";
    exit 0
  fi;
else
  echo "not running verify installation because DIAGNOSTIC_ENABLE=${DIAGNOSTIC_ENABLE}";
fi

tail -n 100 -f \
  /var/lib/rstudio-server/monitor/log/*.log \
  /var/lib/rstudio-launcher/*.log \
  /var/lib/rstudio-launcher/Local/*.log \
  /var/lib/rstudio-launcher/Kubernetes/*.log \
  /var/log/rstudio-launcher.log \
  /var/log/rstudio-server.log &

# the main container process
# cannot use "exec" or the "trap" will be lost
/usr/lib/rstudio-server/bin/rserver --server-daemonize 0 > /var/log/rstudio-server.log 2>&1
