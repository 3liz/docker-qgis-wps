#!/bin/bash
set -e

QYWPS_USER=${QYWPS_USER:-"9001:9001"}

# Qgis need a HOME
export HOME=/home/wps

if [ "$(id -u)" = '0' ]; then
   mkdir -p $HOME
   chown -R $QYWPS_USER $HOME
   # Change ownership of $QYWPS_SERVER_WORKDIR
   # This is necessary if it is mounted from a named volume
   chown -R $QYWPS_USER $QYWPS_SERVER_WORKDIR

   # Run as QYWPS_USER
   exec gosu $QYWPS_USER  "$BASH_SOURCE"
fi

# Run as QYWPS_USER
exec wpsserver $@ -p 8080

