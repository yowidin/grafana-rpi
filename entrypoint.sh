
#!/bin/bash

GRAFANA_BIN=/bin/grafana-server
GRAFANA_CLI=/bin/grafana-cli
CONFIG_FILE="/usr/share/grafana/conf/defaults.ini"


HOSTIPNAME=$(ip a show dev eth0 | grep inet | grep eth0 | tail -1 | sed -e 's/^.*inet.//g' -e 's/\/.*$//g')
HOSTNAME="$HOSTIPNAME"
export HOSTNAME

: "${GF_PATHS_DATA:=/var/lib/grafana}"

CMD="$GRAFANA_BIN"
CMDARGS="--homepath=/usr/share/grafana        \
  cfg:default.paths.data=$GF_PATHS_DATA       \
  web"

"$CMD" $CMDARGS
