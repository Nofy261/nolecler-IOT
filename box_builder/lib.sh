#!/bin/bash

ISO_FILE=$(curl -s "$ISO_PATH" \
          | grep -oE 'debian-[0-9]+\.[0-9]+\.[0-9]+-amd64-netinst\.iso' \
          | head -1)
ISO_URL="${ISO_PATH}${ISO_FILE}"
ISO_FILENAME="debian_latest_stable.iso"

DEBIAN_PATH="${IMAGES_DIR}/${DEBIAN_FILE}"

DISK_PATH="${VM_BASE_DIR}/${VM_NAME}/${VM_NAME}.vdi"

PRESEED_PATH="${IMAGES_DIR}/${PRESEED_FILE}"

check_existing_vm()
{
    if VBoxManage list vms | grep -q "\"$VM_NAME\""; then

        echo "La VM $VM_NAME existe déjà."
        echo "Que voulez-vous faire ?"
        echo "1) Continuer avec cette VM"
        echo "2) Supprimer et reconstruire"

        read -r -p "Choix [1-2] : " choice

        case "$choice" in

            1)
                log "Reprise de la préparation Vagrant..."
                return 0
                ;;

            2)
                log "Suppression de la VM..."

                VBoxManage unregistervm \
                    "$VM_NAME" \
                    --delete

                return 1
                ;;

            *)
                log "Choix invalide"
                exit 1
                ;;
        esac

    else
        log "Aucune VM existante."
        return 1
    fi
}

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

cleanup_host()
{
if VBoxManage list vms | grep -q "\"$VM_NAME\"";
then
    VBoxManage unregistervm "$VM_NAME" --delete || true
fi

if VBoxManage list hdds | grep -q "$DISK_PATH";
then
    VBoxManage closemedium disk "$DISK_PATH" --delete || true
fi

    rm -f "$DISK_PATH"
}

vm_creation()
{
log "VM creation and setup ..."

VBoxManage createvm \
    --name "$VM_NAME" \
    --basefolder "$VM_BASE_DIR" \
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
    --nic1 nat \
    --natpf1 "ssh,tcp,,2222,,22"

#VDI
VBoxManage createmedium disk \
    --filename "$DISK_PATH" \
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
    --medium "$DISK_PATH"

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
    --post-install-template ./scripts/postinstall.sh \
    --start-vm=headless \
    --auxiliary-base-path ./aux \
    --dry-run
}

start_vm()
{
    VBoxManage startvm "$VM_NAME" --type headless
}

wait_for_ssh()
{
    log "Attente du démarrage SSH..."

    TIMEOUT=600
    ELAPSED=0
    
    ssh-keygen -R "[127.0.0.1]:2222" >/dev/null 2>&1 || true
    
    until ssh \
        -p 2222 \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        builder@127.0.0.1 "echo SSH OK" 2>/dev/null
    do
        if [ $ELAPSED -ge $TIMEOUT ]; then
            echo "Timeout SSH"
            exit 1
        fi
        
        sleep 5
        ELAPSED=$((ELAPSED+5))
    done

    log "SSH disponible"
}

vm_prepare()
{
scp -P 2222 \
    -o StrictHostKeyChecking=no \
    ./scripts/prepare_vagrant.sh \
    builder@127.0.0.1:/tmp/
ssh -p 2222 builder@127.0.0.1 \
    "chmod +x /tmp/prepare_vagrant.sh && sudo /tmp/prepare_vagrant.sh"
}

vm_clean()
{
scp -P 2222 \
    -o StrictHostKeyChecking=no \
    ./scripts/clean_vm.sh \
    builder@127.0.0.1:/tmp/
ssh -p 2222 builder@127.0.0.1 \
    "chmod +x /tmp/clean_vm.sh && sudo /tmp/clean_vm.sh" || true
}

log()
{
    echo "[$(date '+%H:%M:%S')] $*"
}