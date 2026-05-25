#!/bin/bash

# --- Usage Function ---
usage() {
    echo "Usage: $0 -n <hostname> -g <groups> -i <ip> -p <proxy_id> -k <psk_id> -v <psk_value>"
    echo "  -n : Hostname"
    echo "  -g : Groups (comma-separated list of Group IDs, e.g., '2,4')"
    echo "  -i : IP Address"
    echo "  -p : Proxy ID (Use '0' if no proxy)"
    echo "  -k : PSK Identity"
    echo "  -v : PSK Value (Pre-shared key hex string)"
    exit 1
}

# --- Parse Arguments ---
while getopts "n:g:i:p:k:v:" opt; do
    case ${opt} in
        n ) HOSTNAME=$OPTARG ;;
        g ) GROUPS_INPUT=$OPTARG ;;
        i ) IP=$OPTARG ;;
        p ) PROXY_ID=$OPTARG ;;
        k ) PSK_ID=$OPTARG ;;
        v ) PSK_VALUE=$OPTARG ;;
        * ) usage ;;
    esac
done

if [ -z "$HOSTNAME" ] || [ -z "$GROUPS_INPUT" ] || [ -z "$IP" ] || [ -z "$PROXY_ID" ] || [ -z "$PSK_ID" ] || [ -z "$PSK_VALUE" ]; then
    echo "Error: Missing required arguments."
    usage
fi

# --- Format Groups Safely for JSON ---
# Force group IDs to be strings inside the JSON array (Zabbix API standard)
GROUPS_JSON=$(echo "$GROUPS_INPUT" | jq -R 'split(",") | map({groupid: .})')

# --- Construct JSON Payload (Zabbix 7.0+ Compliant) ---
# We build the base structure first, dynamically injecting proxy parameters if needed.
if [ "$PROXY_ID" = "0" ] || [ -z "$PROXY_ID" ]; then
    # Monitored by Server
    MONITORED_BY=0
    PROXY_FIELDS='{}'
else
    # Monitored by Proxy
    MONITORED_BY=1
    PROXY_FIELDS=$(jq -n --arg pid "$PROXY_ID" '{proxyid: $pid}')
fi

payload=$(jq -n \
  --arg token "$ZABBIX_API_TOKEN" \
  --arg host "$HOSTNAME" \
  --arg ip "$IP" \
  --arg pskid "$PSK_ID" \
  --arg pskval "$PSK_VALUE" \
  --argjson groups "$GROUPS_JSON" \
  --argjson mby "$MONITORED_BY" \
  --argjson pfields "$PROXY_FIELDS" \
  '{
    jsonrpc: "2.0",
    method: "host.create",
    params: ({
      host: $host,
      interfaces: [
        {
          type: 1,
          main: 1,
          useip: 1,
          ip: $ip,
          dns: "",
          port: "10050"
        }
      ],
      groups: $groups,
      monitored_by: $mby,
      tls_connect: 2,
      tls_accept: 2,
      tls_psk_identity: $pskid,
      tls_psk: $pskval
    } + $pfields),
    auth: $token,
    id: 1
  }')

# --- Execute API Call ---
echo "Sending request to Zabbix API..."
response=$(curl -s -X POST -H "Content-Type: application/json-rpc" -d "$payload" "$ZABBIX_URL")

# --- Error Handling ---
if ! echo "$response" | jq -e . >/dev/null 2>&1; then
    echo "? Critical Error: Server did not return a valid JSON response!"
    echo "------------------ RAW RESPONSE ------------------"
    echo "$response"
    echo "--------------------------------------------------"
    exit 1
fi

error=$(echo "$response" | jq '.error')

if [ "$error" != "null" ]; then
    echo "? Error creating host:"
    echo "$response" | jq '.error'
    exit 1
else
    hostid=$(echo "$response" | jq -r '.result.hostids[0]')
    echo "? Host created successfully! Host ID: $hostid"
fi