RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ISO_PATH="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/"

IMAGES_DIR="./iso"
DEBIAN_FILE="debian_latest_stable.iso"
PRESEED_FILE="preseed.iso"

VM_NAME="debian13-template"
RAM=1024
CPU=1
DISK_SIZE=10240

OUTPUT_DIR="./output"
LOG_DIR="./logs"

DISK_PATH="$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi"