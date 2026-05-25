curl -s -X POST -H "Content-Type: application/json-rpc" \
  -d '{
    "jsonrpc": "2.0",
    "method": "proxy.get",
    "params": {
        "output": ["proxyid", "name"]
    },
    "auth": "90f73691ffaf049dbade54197ead87cbf0bdd78f3102d1c2c26451bf9ee01b8f",
    "id": 1
  }' http://127.0.0.1/api_jsonrpc.php | jq '.result'