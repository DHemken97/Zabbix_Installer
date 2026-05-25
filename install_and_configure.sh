#!/bin/bash

START_DIR=$PWD

# 1. Prepare Workspace
mkdir -p /tmp/zabbix-install/old
cd /tmp/zabbix-install

# 2. Backup if old configurations exist
if [ -d /etc/zabbix ]; then
    cp -pr /etc/zabbix/* /tmp/zabbix-install/old/ 2>/dev/null
fi

ZABBIX_IP="10.0.42.2"

# 3. Download helpers
curl -s -o add_zabbix_host.sh "$ZABBIX_INSTALL_REPO/add_zabbix_host.sh"
curl -s -o get-distro.sh       "$ZABBIX_INSTALL_REPO/get-distro.sh"
curl -s -o zabbix_env.sh       "$ZABBIX_INSTALL_REPO/zabbix_env.sh"

chmod +x /tmp/zabbix-install/*.sh

# 4. Source environment variables (This dynamically triggers get-distro.sh)
. ./zabbix_env.sh

# 5. Run the Agent Installation FIRST
# (This ensures the /etc/zabbix directory is safely created by the OS package manager)
curl -s -o install_agent_2.sh "$ZABBIX_INSTALL_REPO/installers/${MY_OS}.sh"
chmod +x /tmp/zabbix-install/install_agent_2.sh
/tmp/zabbix-install/install_agent_2.sh

# 6. Configure PSK Security (Now completely safe because /etc/zabbix exists)
mkdir -p /etc/zabbix # Extra safety net in case installer changed paths
dd if=/dev/urandom bs=1 count=32 2>/dev/null | od -An -tx1 | tr -d ' \n' > /etc/zabbix/zabbix_agent2.psk
chmod 600 /etc/zabbix/zabbix_agent2.psk
ZABBIX_PSK=$(cat /etc/zabbix/zabbix_agent2.psk)

# 7. Register the host via API
./add_zabbix_host.sh -n "$HOSTNAME" -g "$ZABBIX_DEFAULT_GROUP" -i "$MY_IP" -p "$ZABBIX_PROXY_ID" -k "psk_$MY_HOSTNAME" -v "$ZABBIX_PSK"

# 8. Config File
# Define paths
TEMPLATE_CONF="/tmp/zabbix-install/zabbix_agent2.tmpl.conf" # The template you download
TARGET_CONF="/etc/zabbix/zabbix_agent2.conf"               # The live production config

# 8.1 Download your templated configuration file
curl -s -o "$TEMPLATE_CONF" "$ZABBIX_INSTALL_REPO/templates/zabbix_agent2.linux.conf"

# 8.2 Use sed to replace the placeholders with live environment variables
sed -e "s|<ZABBIX_SERVER_IP>|$ZABBIX_IP|g" \
    -e "s|<ZABBIX_PROXY_IP>|$ZABBIX_PROXY_IP|g" \
    -e "s|<HOSTNAME>|$MY_HOSTNAME|g" \
    "$TEMPLATE_CONF" > "$TARGET_CONF"

# 8.3 Ensure proper file ownership and restart the agent to apply changes
chown -R zabbix:zabbix "/etc/zabbix"
#chmod 600 "$TARGET_CONF"

# Check if systemd exists before attempting service restart (Universal safety check)
if command -v systemctl >/dev/null 2>&1; then
    systemctl restart zabbix-agent2
else
    service zabbix-agent2 restart 2>/dev/null || /etc/init.d/zabbix-agent2 restart
fi

# 9. Return home and cleanup
cd "$START_DIR"
rm -rf /tmp/zabbix-install