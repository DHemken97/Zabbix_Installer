curl -s -X POST -H "Content-Type: application/json-rpc" \
  -d '{
    "jsonrpc": "2.0",
    "method": "proxy.get",
    "params": {
        "output": ["proxyid", "name"]
    },
    "auth": "$ZABBIX_API_TOKEN",
    "id": 1
  }' http://127.0.0.1/api_jsonrpc.php | jq '.result'