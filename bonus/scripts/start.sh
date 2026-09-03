#!/bin/bash
set -euo pipefail

HOST_ENTRY="127.0.0.1 gitlab.k3d.gitlab.com"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
GITLAB_NAMESPACE="${GITLAB_NAMESPACE:-gitlab}"
GITLAB_HOST="${GITLAB_HOST:-gitlab.k3d.gitlab.com}"
GITLAB_PROJECT="${GITLAB_PROJECT:-root/test}"
GITLAB_SERVICE_REPOSITORY="${GITLAB_SERVICE_REPOSITORY:-http://gitlab-webservice-default.gitlab.svc:8181/${GITLAB_PROJECT}.git}"
ARGOCD_NAMESPACE="argocd"
APP_NAMESPACE="dev"
APP_NAME="wil-playground"

for command_name in docker k3d kubectl helm argocd curl; do
  command -v "$command_name" >/dev/null || {
    echo "$command_name is required; run p3/scripts/install.sh and bonus/scripts/install.sh first" >&2
    exit 1
  }
done

if ! docker info >/dev/null 2>&1; then
  echo "Docker is unavailable for the current user; add it to the docker group and retry" >&2
  exit 1
fi

HOST_ENTRY="127.0.0.1 $GITLAB_HOST"
if ! grep -Eq "(^|[[:space:]])$GITLAB_HOST([[:space:]]|$)" /etc/hosts; then
  printf '%s\n' "$HOST_ENTRY" | sudo tee -a /etc/hosts >/dev/null
fi

if ! k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | grep -Fxq iot; then
  echo "Creating the K3d cluster"
  k3d cluster create iot --wait
fi

kubectl get namespace "$ARGOCD_NAMESPACE" >/dev/null 2>&1 || \
  kubectl create namespace "$ARGOCD_NAMESPACE"
kubectl get namespace "$APP_NAMESPACE" >/dev/null 2>&1 || \
  kubectl create namespace "$APP_NAMESPACE"
kubectl get namespace "$GITLAB_NAMESPACE" >/dev/null 2>&1 || \
  kubectl create namespace "$GITLAB_NAMESPACE"

echo "Installing GitLab"
helm repo add gitlab https://charts.gitlab.io/ >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install gitlab gitlab/gitlab \
  --namespace "$GITLAB_NAMESPACE" \
  --values "$SCRIPT_DIR/../values-minikube-minimum.yaml" \
  --set global.hosts.domain=k3d.gitlab.com \
  --set global.hosts.externalIP=0.0.0.0 \
  --set global.hosts.https=false \
  --set global.ingress.configureCertmanager=false \
  --set global.gatewayApi.enabled=false \
  --set global.gatewayApi.configureCertmanager=false \
  --timeout 600s

kubectl wait --for=condition=ready --timeout=1200s \
  pod -l app=webservice --namespace "$GITLAB_NAMESPACE"

echo "Installing Argo CD"
kubectl apply --namespace "$ARGOCD_NAMESPACE" \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server --namespace "$ARGOCD_NAMESPACE"

while ! kubectl get secret argocd-initial-admin-secret \
  --namespace "$ARGOCD_NAMESPACE" >/dev/null 2>&1; do
  echo "Waiting for the Argo CD admin secret"
  sleep 3
done

GITLAB_PASSWORD="$(sudo kubectl get secret gitlab-gitlab-initial-root-password \
  --namespace "$GITLAB_NAMESPACE" \
  --output=jsonpath="{.data.password}" | base64 -d)"
ARGOCD_PASSWORD="$(kubectl get secret argocd-initial-admin-secret \
  --namespace "$ARGOCD_NAMESPACE" \
  --output=jsonpath="{.data.password}" | base64 -d)"

kubectl port-forward --namespace "$GITLAB_NAMESPACE" \
  svc/gitlab-webservice-default 80:8888 \
  >"$HOME/.gitlab-port-forward.log" 2>&1 &
GITLAB_PORT_FORWARD_PID=$!
trap 'kill "$GITLAB_PORT_FORWARD_PID" 2>/dev/null || true' EXIT

echo "Waiting for GitLab HTTP access"
until curl -fsS "http://$GITLAB_HOST/users/sign_in" >/dev/null 2>&1; do
  sleep 3
done

GITLAB_NAMESPACE="$GITLAB_NAMESPACE" \
GITLAB_HOST="$GITLAB_HOST" \
GITLAB_PROJECT="$GITLAB_PROJECT" \
  "$SCRIPT_DIR/update.sh"

kubectl port-forward --namespace "$ARGOCD_NAMESPACE" \
  svc/argocd-server 8080:443 \
  >"$HOME/.argocd-port-forward.log" 2>&1 &
ARGOCD_PORT_FORWARD_PID=$!
trap 'kill "$GITLAB_PORT_FORWARD_PID" "$ARGOCD_PORT_FORWARD_PID" 2>/dev/null || true' EXIT

echo "Waiting for Argo CD API access"
until (echo >/dev/tcp/127.0.0.1/8080) >/dev/null 2>&1; do
  sleep 1
done

argocd login localhost:8080 \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --insecure
argocd repo add "$GITLAB_SERVICE_REPOSITORY" \
  --username root \
  --password "$GITLAB_PASSWORD" \
  --insecure-skip-server-verification \
  --upsert
argocd app create "$APP_NAME" \
  --repo "$GITLAB_SERVICE_REPOSITORY" \
  --path manifest/app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace "$APP_NAMESPACE" \
  --project default \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --upsert

kubectl wait --for=condition=available --timeout=300s \
  deployment/"$APP_NAME" --namespace "$APP_NAMESPACE"
kubectl port-forward --namespace "$APP_NAMESPACE" \
  svc/"$APP_NAME" 8888:8888 \
  >"$HOME/.wil-playground-port-forward.log" 2>&1 &

echo "Bonus environment is ready: http://localhost:8888"
