#!/bin/bash

set -e

if ! command -v sshd >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y openssh-server sudo
fi

sudo systemctl enable ssh
sudo systemctl start ssh

if ! id vagrant >/dev/null 2>&1; then
    sudo useradd -m -s /bin/bash vagrant
fi

echo "vagrant ALL=(ALL) NOPASSWD:ALL" | \
sudo tee /etc/sudoers.d/vagrant

sudo mkdir -p /home/vagrant/.ssh

sudo curl \
-o /home/vagrant/.ssh/authorized_keys \
https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub

sudo chown -R vagrant:vagrant /home/vagrant/.ssh
sudo chmod 700 /home/vagrant/.ssh
sudo chmod 600 /home/vagrant/.ssh/authorized_keys

