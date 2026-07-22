#!/bin/bash

set -euo pipefail

source config.sh
source lib.sh

download_iso
vm_creation
vm_setup
attach_storage
install_debian
prepare_vagrant
clean_vm
package_box