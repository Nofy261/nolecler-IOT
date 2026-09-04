#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

apt update

wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt install -y vagrant

cat << EOF > /etc/apt/sources.list.d/trixie-backports.sources
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp
EOF

apt update

# Debian Fast Track repository for VirtualBox
apt install -y fasttrack-archive-keyring

cat << EOF > /etc/apt/sources.list.d/trixie-fasttrack.sources
Types: deb deb-src
URIs: https://fasttrack.debian.net/debian-fasttrack
Suites: trixie-fasttrack trixie-backports-staging
Components: main contrib
Signed-By: /usr/share/keyrings/fasttrack-archive-keyring.gpg
EOF

apt update

apt install -y linux-headers-$(uname -r)
apt install -y virtualbox

# Load VirtualBox kernel modules
modprobe vboxdrv
modprobe vboxnetadp
modprobe vboxnetflt

# Disable KVM modules to let VirtualBox use VT-x
modprobe -r kvm_intel 2>/dev/null || true
modprobe -r kvm 2>/dev/null || true


#-----------------

# A TESTER SUR UNE VM NEUVE -> 

#!/bin/bash

#if [ "$EUID" -ne 0 ]; then
#  exec sudo "$0" "$@"
#fi

#apt update

# Vagrant
#wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

#echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

#apt update
#apt install -y vagrant


# Debian Backports
#cat << EOF > /etc/apt/sources.list.d/trixie-backports.sources
#Types: deb
#URIs: http://deb.debian.org/debian
#Suites: trixie-backports
#Components: main contrib
#Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp
#EOF

#apt update


# Debian Fast Track repository for VirtualBox
#apt install -y fasttrack-archive-keyring

#cat << EOF > /etc/apt/sources.list.d/trixie-fasttrack.sources
#Types: deb
#URIs: https://fasttrack.debian.net/debian-fasttrack
#Suites: trixie-fasttrack trixie-backports-staging
#Components: main contrib
#Signed-By: /usr/share/keyrings/fasttrack-archive-keyring.gpg
#EOF

#apt update


# VirtualBox
#apt install -y linux-headers-$(uname -r)
#apt install -y virtualbox


# Disable KVM so VirtualBox can use VT-x
#cat << EOF > /etc/modprobe.d/blacklist-kvm.conf
#blacklist kvm_intel
#blacklist kvm
#EOF

#modprobe -r kvm_intel 2>/dev/null || true
#modprobe -r kvm 2>/dev/null || true


# Load VirtualBox kernel modules
#modprobe vboxdrv
#modprobe vboxnetadp
#modprobe vboxnetflt


# Load VirtualBox modules automatically after reboot
#cat << EOF > /etc/modules-load.d/virtualbox.conf
#vboxdrv
#vboxnetadp
#vboxnetflt
#EOF