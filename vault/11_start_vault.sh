#!/bin/bash

# Last update : August, 2022
# Author: cetin@hashicorp.com
# Description: Start or Reset a Vault cluster in dev mode

script_name=$(basename "$0")
version="0.1.0"

echo "Running $script_name - version $version"
echo ""

HASHISTACK_DIR="$HOME/.hashistack/"
HASHISTACK_LOG_DIR="$HASHISTACK_DIR/log"

mkdir -p "$HASHISTACK_DIR/log"

# Check vault installation.
VAULT_VERSION=$(vault version)

if [ "$?" != 0 ]; then
  # exit if vault cli is not present
  echo "vault cli not found. Please see https://www.vaultproject.io/downloads to download Vault."
  exit 1
fi

RESET_VAULT="N"

if [ -f "$HASHISTACK_DIR/vault.pid" ]; then
    VAULT_PID=$(cat "$HASHISTACK_DIR/vault.pid")
    echo "Vault seems to be running under PID $VAULT_PID"
    echo "Running with this startup command:"
    echo ""
    ps |grep "$VAULT_PID" |grep -o -m1 -E 'vault.+'
  echo ""
    kill -9 "$VAULT_PID"
    rm "$HASHISTACK_DIR/vault.pid" "$HASHISTACK_LOG_DIR/vault.log"
  else # exit without action if answer is anything different that the accepted inputs
    echo "Already stopped"
  fi


export VAULT_LOG_LEVEL=debug

#vault server -dev -dev-root-token-id=root -dev-listen-address="0.0.0.0:8200" >"$HASHISTACK_LOG_DIR/vault.log" 2>&1 &
vault server -config=./configuration/vault.hcl > "$HASHISTACK_LOG_DIR/vault.log" 2>&1 &
echo $! >  "$HASHISTACK_DIR/vault.pid"

sleep 5

echo "Vault started with PID:$(cat "$HASHISTACK_DIR/vault.pid")"
echo "$VAULT_VERSION"
export VAULT_ADDR="http://127.0.0.1:8200"
# Print connection information
vault operator unseal QIqMZRkvdr0LS2nSeIm+bmIOvrJ5eXUwbFvodoAQyoE=
echo ""
echo "Visit http://127.0.0.1:8200/ui to access the GUI. You can authenticate with the following information:"
