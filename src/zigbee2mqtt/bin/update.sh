#!/usr/bin/env bash

Z2M_ROOT_DIR="$PWD"
Z2M_OSNAME="$(uname -s)"
Z2M_RESTART_REQUIRED=0

# Loop until we find the Zigbee2MQTT root directory
echo "Locating Zigbee2MQTT root directory..."
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

if [ "$1" != "force" ]; then
    echo "Checking Zigbee2MQTT repository for updates..."
    git fetch -q
    Z2M_REPO_NEW_COMMITS="$(git rev-list HEAD...@{upstream} --count)"
    if [ "$Z2M_REPO_NEW_COMMITS" -gt 0 ]; then
        echo "Update available!"
    else
        echo "No updates available. Use '$0 force' to skip the check."
        exit 0
    fi
fi

if [ "$Z2M_OSNAME" == "FreeBSD" ]; then
    echo "Checking Zigbee2MQTT status..."
    if service zigbee2mqtt status >/dev/null; then
        echo "Stopping Zigbee2MQTT service..."
        service zigbee2mqtt stop
        Z2M_RESTART_REQUIRED=1
    fi
elif which systemctl 2> /dev/null > /dev/null; then
    echo "Checking Zigbee2MQTT status..."
    if systemctl is-active --quiet zigbee2mqtt; then
        echo "Stopping Zigbee2MQTT service..."
        sudo systemctl stop zigbee2mqtt
        Z2M_RESTART_REQUIRED=1
    fi
fi

echo "Resetting local changes to package.json and pnpm-lock.yaml..."
git checkout --quiet -- package.json pnpm-lock.yaml || true

echo "Updating repository..."
git pull --no-rebase

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Determine latest Node.js version required by Zigbee2MQTT
Z2M_NODE_VERSION=$(jq -r . package.json | jq -r '.engines.node' | grep -oE '[0-9]+' | sort -n | tail -1)

echo "Updating Node.js environment..."
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

if ! command -v pnpm >/dev/null 2>&1; then
    echo "pnpm not found, preparing with Corepack..."
    corepack prepare pnpm@latest --activate
fi

echo "Installing dependencies..."
pnpm i --frozen-lockfile

echo "Building..."
pnpm run build

if [ $Z2M_RESTART_REQUIRED -eq 1 ]; then
    echo "Starting Zigbee2MQTT service..."
    if [ "$Z2M_OSNAME" == "FreeBSD" ]; then
        service zigbee2mqtt start
    else
        sudo systemctl start zigbee2mqtt
    fi
fi

echo "Done!"