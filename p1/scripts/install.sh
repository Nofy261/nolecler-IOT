#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

if [ ! command -v curl >/dev/null 2>&1 ]; then
    echo "curl absent : installation..."
    sudo apt-get update
    sudo apt-get install -y curl
else
    echo "✓ curl already installed"
fi

if [ ! command -v ca-certificates >/dev/null 2>&1 ]; then
    echo "Installation of ca-certificates..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates
else
    echo "✓ ca-certificates already installed"
fi

if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
    wget -O - https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
fi

if [ ! -f /etc/apt/sources.list.d/hashicorp.list ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/hashicorp.list
fi

apt update

apt install -y vagrant

apt install -y virtualbox
