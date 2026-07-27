#!/bin/bash

IFACE=$(ip -o addr show | awk '$4 ~ /^192.168.56./ {print $2}' | head -1)

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --flannel-iface=$IFACE --tls-san=192.168.56.110 --write-kubeconfig-mode 644" sh -s -

while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
sleep 2
done

cp /var/lib/rancher/k3s/server/node-token /vagrant/token
chmod 644 /vagrant/token
