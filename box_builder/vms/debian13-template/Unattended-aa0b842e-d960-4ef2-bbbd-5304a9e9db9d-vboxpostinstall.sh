#!/bin/bash

:<<COMMENT
apt update
apt install -y sudo openssh-server

usermod -aG sudo builder

systemctl enable ssh
systemctl start ssh
COMMENT

echo "HELLO POST INSTALL" > /tmp/postinstall-test