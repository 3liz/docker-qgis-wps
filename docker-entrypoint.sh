#!/bin/bash
set -e

if [[ "$1" == "version" ]]; then
    version=`pip3 list | grep qgis-wps | tr -s [:blank:] | cut -d ' ' -f 2`
    qgis_version=`python3 -c "from qgis.core import Qgis; print(Qgis.QGIS_VERSION.split('-')[0])"`
    echo "$qgis_version-$version"
    exit 0
fi

QYWPS_USER=${QYWPS_USER:-"9001:9001"}

# Qgis need a HOME
export HOME=/home/qgis

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

