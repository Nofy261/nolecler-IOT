#!/bin/bash

set -euo pipefail

source config.sh
source lib.sh

main()
{
    if ! check_existing_vm;
    then
        download_iso
        cleanup_host
        vm_creation
        vm_setup
        attach_storage
        install_debian
    else
        start_vm
    fi
    wait_for_ssh
    vm_prepare
    vm_clean
    ./scripts/package_box
}
main "$@"