#!/bin/bash

ISO_FILE=$(curl -s "$ISO_PATH" \
          | grep -oE 'debian-[0-9]+\.[0-9]+\.[0-9]+-amd64-netinst\.iso' \
          | head -1)
ISO_URL="${ISO_PATH}${ISO_FILE}"
ISO_FILENAME="debian_latest_stable.iso"

DEBIAN_PATH="${IMAGES_DIR}/${DEBIAN_FILE}"

PRESEED_PATH="${IMAGES_DIR}/${PRESEED_FILE}"

download_iso()
{
mkdir -p "$IMAGES_DIR"

if [ ! -f "$DEBIAN_PATH" ];
then
    log "Downloading "${ISO_FILE}"..."
    curl -L "$ISO_URL" -o "$DEBIAN_PATH"
else
    log "${ISO_FILE} exists"
fi
}

vm_creation()
{
log "VM creation and setup ..."

VBoxManage createvm \
    --name "$VM_NAME" \
    --ostype Debian_64 \
    --register
}

vm_setup()
{
log "VM creation and setup ..."

#MEMORY AND CPU
VBoxManage modifyvm "$VM_NAME" \
    --memory $RAM \
    --cpus $CPU

#NETWORK (NAT)
VBoxManage modifyvm "$VM_NAME" \
    --nic1 nat

#VDI
VBoxManage createmedium disk \
    --filename "$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi" \
    --size $DISK_SIZE \
    --format VDI
}
attach_storage()
{
#SATA CONTROLLER
VBoxManage storagectl "$VM_NAME" \
    --name "SATA Controller" \
    --add sata

#DISK CONNEXION
VBoxManage storageattach "$VM_NAME" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "${DISK_PATH}"

#ISO MOUNT
VBoxManage storageattach "$VM_NAME" \
    --storagectl "SATA Controller" \
    --port 1 \
    --device 0 \
    --type dvddrive \
    --medium "$DEBIAN_PATH"

#BOOT ORDER
VBoxManage modifyvm "$VM_NAME" \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none
}

install_debian()
{
VBoxManage unattended install "$VM_NAME" \
    --iso "$DEBIAN_PATH" \
    --user "builder" \
    --password "builder" \
    --hostname "debian13-template.local" \
    --start-vm=headless
}

log()
{
    echo "[$(date '+%H:%M:%S')] $*"
}