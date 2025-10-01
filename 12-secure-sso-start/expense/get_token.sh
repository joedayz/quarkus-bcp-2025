#!/bin/bash

# Function to get token
get_token() {
  local username="$1"
  local password="$2"
  
  if [ -z "$username" ] || [ -z "$password" ]; then
    echo 1>&2 "Usage: get_token username password"
    echo 1>&2 "  available users (username/password):"
    echo 1>&2 "    user/redhat"
    echo 1>&2 "    superuser/redhat"
    return 1
  fi

  local server="http://localhost:8888/realms/quarkus/protocol/openid-connect/token"
  local secret_id="backend-service"
  local secret_pw="secret"

  echo "Getting token for user: $username" 1>&2
  
  export TOKEN=$(curl --insecure -s -X POST "$server" \
    --user ${secret_id}:${secret_pw} \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${username}" \
    -d "password=${password}" \
    -d 'grant_type=password' \
    | jq --raw-output '.access_token'
  )

  if [[ "$TOKEN" == "null" ]] || [[ -z "$TOKEN" ]]; then
      echo 1>&2 "Token was not retrieved! Review input parameters."
      return 1
  else
      echo 1>&2 "Token successfully retrieved."
      return 0
  fi
}

# If script is called directly (not sourced), call the function
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  get_token "$@"
fi
