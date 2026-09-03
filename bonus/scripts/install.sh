#!/bin/bash
set -euo pipefail

HELM_INSTALLER="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4"
GITLAB_SCRIPT_FOR_DEPENDENCIES="https://gitlab.com/gitlab-org/charts/gitlab.git"

echo -e "\n\e[32;1m[Helm Installation]\e[0m\n"
sleep 1
curl -fsSL "$HELM_INSTALLER" | bash

git clone "$GITLAB_SCRIPT_FOR_DEPENDENCIES"
bash ./scripts/dev_dependencies.sh setup

