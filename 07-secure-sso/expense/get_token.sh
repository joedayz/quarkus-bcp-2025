#!/bin/bash

# get_token.sh - Script to retrieve bearer token from OIDC server
# Usage: source get_token.sh <username> <password>

if [ $# -ne 2 ]; then
    echo "Usage: source get_token.sh <username> <password>"
    echo "Example: source get_token.sh user redhat"
    return 1
fi

USERNAME=$1
PASSWORD=$2

# OIDC server configuration (matching your Keycloak setup)
OIDC_SERVER_URL="https://localhost:8888"
REALM="quarkus"
CLIENT_ID="backend-service"
CLIENT_SECRET="secret"

echo "Authenticating with OIDC server..."
echo "Server: $OIDC_SERVER_URL"
echo "Realm: $REALM"
echo "Client: $CLIENT_ID"
echo "Username: $USERNAME"

# Get the token endpoint URL
TOKEN_URL="$OIDC_SERVER_URL/realms/$REALM/protocol/openid-connect/token"

# Request the token using client credentials flow
RESPONSE=$(curl -s -X POST "$TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "username=$USERNAME" \
    -d "password=$PASSWORD" \
    --insecure)

# Check if the request was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to OIDC server"
    echo "Make sure the SSO server is running at $OIDC_SERVER_URL"
    return 1
fi

# Extract the access token from the response
TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "Error: Failed to retrieve token"
    echo "Response from server:"
    echo "$RESPONSE"
    return 1
fi

# Export the token as a shell variable
export TOKEN="$TOKEN"

echo "Token successfully retrieved."
