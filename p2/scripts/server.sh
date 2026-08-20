#!/bin/bash
set -euo pipefail

IFACE=$(ip -o addr show | awk '$4 ~ /^192.168.56./ {print $2}' | head -1)

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --flannel-iface=$IFACE --write-kubeconfig-mode=644" sh -s -

kubectl apply -f /vagrant/confs/

echo "Done"