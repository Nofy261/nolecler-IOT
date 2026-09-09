#!/bin/bash

set -euo pipefail

chmod +x "$0"
#Relance le script en root si ce n'est pas deja le cas
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0"
fi

export DEBIAN_FRONTEND=noninteractive

# Outils de base parfois absents d'une installation Debian minimale (netinst)
apt-get update
apt-get install -y ca-certificates curl gnupg

# Depot HashiCorp : fournit Vagrant 2.4.x (necessaire pour VirtualBox 7.2)
install -d -m 0755 /usr/share/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
chmod a+r /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com trixie main" \
    > /etc/apt/sources.list.d/hashicorp.list

# Depot Debian Backports : fournit des dependances requises par VirtualBox
cat > /etc/apt/sources.list.d/trixie-backports.sources <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp
EOF

# Depot Debian Fast Track : fournit le paquet VirtualBox lui-meme
apt-get update
apt-get install -y fasttrack-archive-keyring

cat > /etc/apt/sources.list.d/trixie-fasttrack.sources <<EOF
Types: deb
URIs: https://fasttrack.debian.net/debian-fasttrack
Suites: trixie-fasttrack trixie-backports-staging
Components: main contrib
Signed-By: /usr/share/keyrings/fasttrack-archive-keyring.gpg
EOF

apt-get update

#En-tetes du noyau + outils de compilation (DKMS compile les modules VirtualBox)
apt-get install -y "linux-headers-$(uname -r)" || true
apt-get install -y linux-headers-amd64 build-essential dkms

#Installe Vagrant, puis VirtualBox
apt-get install -y vagrant
apt-get install -y virtualbox virtualbox-dkms

#Desactive KVM pour laisser VT-x a VirtualBox (maintenant ET apres un reboot)
cat > /etc/modprobe.d/blacklist-kvm.conf <<'EOF'
blacklist kvm
blacklist kvm_intel
blacklist kvm_amd
EOF
modprobe -r kvm_intel kvm_amd 2>/dev/null || true
modprobe -r kvm              2>/dev/null || true

#Charge les modules VirtualBox maintenant, et a chaque demarrage
cat > /etc/modules-load.d/virtualbox.conf <<'EOF'
vboxdrv
vboxnetadp
vboxnetflt
EOF
modprobe vboxdrv
modprobe vboxnetadp
modprobe vboxnetflt

echo
echo "Installation done"
