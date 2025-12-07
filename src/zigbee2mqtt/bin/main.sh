#!/usr/bin/env bash

# Change to Zigbee2MQTT directory first
while [ "$Z2M_ROOT_DIR" != "/" ]; do
    if [ -f "$Z2M_ROOT_DIR/package.json" ] && [ -f "$Z2M_ROOT_DIR/pnpm-lock.yaml" ]; then
        cd "$Z2M_ROOT_DIR" 
        break
    fi

    Z2M_ROOT_DIR=$(dirname "$Z2M_ROOT_DIR")
done

if [ -z "$Z2M_ROOT_DIR" ]; then 
    echo "Unable to locate Zigbee2MQTT root directory."
    exit 1;
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Determine latest Node.js Version for Zigbee2MQTT
Z2M_NODE_VERSION=$(jq -r . package.json | jq -r '.engines.node' | grep -oE '[0-9]+' | sort -n | tail -1)

if [ -z "$Z2M_NODE_VERSION" ]; then 
    nvm install --lts
    nvm use lts/*
else 
    # Check if a matching Node.js version is installed
    NVM_NODE_VERSION_INSTALLED=$(nvm ls --no-colors "${Z2M_NODE_VERSION}" | command tail -1 | command tr -d '\->*' | command tr -d '[:space:]')

    # Install Node.js version or switch to Node.js version 
    if [ "$NVM_NODE_VERSION_INSTALLED" = 'N/A' ]; then 
        nvm install "${Z2M_NODE_VERSION}"
    elif [ "$(nvm current)" != "${NVM_NODE_VERSION_INSTALLED}" ]; then
        nvm use "${NVM_NODE_VERSION_INSTALLED}";
    else 
        echo "Skipped Node.js enviroment update, already using the latest version requried by Zigbee2MQTT."
    fi
fi

# Run Zigbee2MQTT
node index.js
