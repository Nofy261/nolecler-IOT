#!/bin/bash
set -euo pipefail

HOST_ENTRY="127.0.0.1 gitlab.k3d.gitlab.com"
HOSTS_FILE="/etc/hosts"
GITLAB_NAMESPACE="gitlab"

if grep -Fq -- "$HOST_ENTRY" "$HOSTS_FILE"; then
  echo "$HOSTS_FILE already contains the GitLab host"
else
  echo "Adding the GitLab host to $HOSTS_FILE"
  printf '%s\n' "$HOST_ENTRY" | sudo tee -a "$HOSTS_FILE"
fi

echo -e "\n\e[32;1mCreation du namespace $GITLAB_NAMESPACE\e[0m\n"
kubectl create namespace "$GITLAB_NAMESPACE"

echo -e "\n\e[32;1mInstallation de GitLab via Helm dans le namespace $GITLAB_NAMESPACE\e[0m\n"
helm repo add gitlab https://charts.gitlab.io/
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --namespace "$GITLAB_NAMESPACE" \
  --values https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
  --set global.hosts.domain=k3d.gitlab.com \
  --set global.hosts.externalIP=0.0.0.0 \
  --set global.hosts.https=false \
  --timeout 600s

echo -e "\n\e[33mAttente que les pods GitLab soient prêts\e[0m"
kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice --namespace "$GITLAB_NAMESPACE"

kubectl get secret gitlab-gitlab-initial-root-password \
  --namespace "$GITLAB_NAMESPACE" \
  --output=jsonpath="{.data.password}" | base64 -d > gitlab_password.txt
kubectl port-forward svc/gitlab-webservice-default 80:8888 \
  --namespace "$GITLAB_NAMESPACE" 2>&1 >/dev/null &
