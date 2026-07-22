#!/bin/bash

apt update
apt install -y sudo openssh-server

usermod -aG sudo builder

systemctl enable ssh
systemctl start ssh
