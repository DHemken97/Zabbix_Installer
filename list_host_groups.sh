#!/bin/bash

# --- Usage Function ---
usage() {
    echo "Usage: $0 [-f <filter_name>]"
    echo "  -f : (Optional) Filter host groups by name (case-insensitive partial match)"
    exit 1
}

# --- Parse Arguments ---
FILTER_NAME=""
while getopts "f:h" opt; do
    case ${opt} in
        f ) FILTER_NAME=$OPTARG ;;
        h ) usage ;;
        * ) usage ;;
    esac
done

# --- Construct JSON Payload ---
# We build the base search structure using jq.
# Zabbix 7.0+ uses 'hostgroup.get' for host groups.
if [ -z "$FILTER_NAME" ]; then
    # No filter provided: fetch everything
    payload=$(jq -n \
      --arg token "$ZABBIX_API_TOKEN" \
      '{
        jsonrpc: "2.0",
        method: "hostgroup.get",
        params: {
          output: ["groupid", "name"],
          sortfield: "name"
        },
        auth: $token,
        id: 1
      }')
else
    # Filter provided: use the 'search' parameter with 'searchWildcardsEnabled'
    payload=$(jq -n \
      --arg token "$ZABBIX_API_TOKEN" \
      --arg filter "$FILTER_NAME" \
      '{
        jsonrpc: "2.0",
        method: "hostgroup.get",
        params: {
          output: ["groupid", "name"],
          sortfield: "name",
          search: {
            name: $filter
          },
          searchWildcardsEnabled: true
        },
        auth: $token,
        id: 1
      }')
fi

# --- Execute API Call ---
response=$(curl -s -X POST -H "Content-Type: application/json-rpc" -d "$payload" "$ZABBIX_URL")

# --- Error Handling ---
if ! echo "$response" | jq -e . >/dev/null 2>&1; then
    echo "? Critical Error: Server did not return a valid JSON response!"
    exit 1
fi

error=$(echo "$response" | jq '.error')

if [ "$error" != "null" ]; then
    echo "? Error fetching host groups:"
    echo "$response" | jq '.error'
    exit 1
fi

# --- Output Formatting ---
# Format the JSON array into a clean, human-readable terminal table
echo "----------------------------------------"
printf "%-10s | %s\n" "GROUP ID" "GROUP NAME"
echo "----------------------------------------"

echo "$response" | jq -r '.result[] | "\(.groupid)\t\(.name)"' | while IFS=$'\t' read -r id name; do
    printf "%-10s | %s\n" "$id" "$name"
done
echo "----------------------------------------"