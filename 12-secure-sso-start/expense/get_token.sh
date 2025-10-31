#!/usr/bin/env bash

if [ $# -lt 2 ]; then
  echo 1>&2 "Usage: $0 username password"
  echo 1>&2 "  or:   . $0 username password  (to export TOKEN to current shell)"
  echo 1>&2 "  available users (username/password):"
  echo 1>&2 "    user/redhat"
  echo 1>&2 "    superuser/redhat"
  exit 1
fi

SERVER="http://localhost:8888/realms/quarkus/protocol/openid-connect/token"
SECRET_ID="backend-service"
SECRET_PW="secret"
USERNAME="$1"
PASSWORD="$2"

TOKEN=$(curl --insecure -s -X POST "$SERVER" \
  --user ${SECRET_ID}:${SECRET_PW} \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${USERNAME}" \
  -d "password=${PASSWORD}" \
  -d 'grant_type=password' \
  | jq --raw-output '.access_token'
)

if [[ "$TOKEN" == "null" ]] || [[ "$TOKEN" == ""  ]]; then
    echo 1>&2 "Error: Token was not retrieved! Review input parameters." >&2
    exit 1
else
    echo 1>&2 "Token successfully retrieved." >&2
    export TOKEN
    echo "$TOKEN"
fi
