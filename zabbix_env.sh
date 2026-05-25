#!/bin/bash
export ZABBIX_IP="10.0.42.2"
export ZABBIX_URL="http://$ZABBIX_IP/api_jsonrpc.php"
export ZABBIX_INSTALL_REPO="https://raw.githubusercontent.com/dhemken97/Zabbix_Installer/main"
#For Local Install
#export ZABBIX_INSTALL_REPO="http://$ZABBIX_IP/scripts"
export ZABBIX_API_TOKEN=""
export ZABBIX_DEFAULT_GROUP=6
export ZABBIX_PROXY_ID=1
export ZABBIX_PROXY_IP=10.0.42.2

export MY_OS=$(./get-distro.sh)
MY_IP_TMP=$(ip route get $ZABBIX_PROXY_IP 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
if [ -z "$MY_IP_TMP" ]; then
    MY_IP_TMP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
if [ -z "$MY_IP_TMP" ]; then
    MY_IP_TMP=$(ifconfig 2>/dev/null | awk '/inet / {print $2}' | sed 's/addr://' | grep -v '127.0.0.1' | head -n 1)
fi
export MY_IP=${MY_IP_TMP:-"127.0.0.1"}

export MY_HOSTNAME="${HOSTNAME_PREFIX}${HOSTNAME}${HOSTNAME_SUFFIX}"