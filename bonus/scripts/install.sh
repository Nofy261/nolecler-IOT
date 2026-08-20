#!/bin/bash
set -euo pipefail

HELM_INSTALLER="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"

echo -e "\n\e[32;1m[Helm Installation]\e[0m\n"
sleep 1
curl -fsSL "$HELM_INSTALLER" | bash