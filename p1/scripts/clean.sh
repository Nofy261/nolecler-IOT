#!/bin/bash

set -euo pipefail

source config.sh

if [ "$EUID" -eq 0 ]; then
    echo "Error : do not execute this script with sudo."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR" || exit 1

echo "=== P1 cleaning ==="

vagrant destroy -f

echo
echo "=== Check of existing VM ==="

if vagrant status | grep -q "not created"; then
    echo $GREEN"No VM exist."$NC
else
	echo $RED"At least one VM exists"$NC
