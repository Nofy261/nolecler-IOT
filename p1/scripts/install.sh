#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
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
