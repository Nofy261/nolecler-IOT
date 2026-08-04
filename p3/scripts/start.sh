#!/bin/bash

echo -e "\nCreating the cluster\n"
k3d cluster create iot

echo -e "\nAdding the namespaces\n"
kubectl create namespace argocd
kubectl create namespace dev

echo -e "\nInstalling Argo CD in its namespace\n"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "\nWaiting for argocd-server availability...\n"
kubectl wait --for=condition=available --timeout=180s deployment.apps/argocd-server -n argocd

while ! kubectl -n argocd get secret argocd-initial-admin-secret &> /dev/null; do
  echo -e "\nWaiting for argocd initial admin secret...\n"
  sleep 3
done

ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "\nPort-forwarding to ArgoCD's API...\n"
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

while ! nc -z localhost 8080; do
  sleep 1
done

echo -e "\nLogging into Argo CD\n"
argocd login localhost:8080 --username admin --password "$ARGOCD_PASS" --insecure

sleep 1
argocd repo add https://github.com/Nofy261/nolecler-IOT
sleep 1
argocd app create wil-playground \
  --repo https://github.com/Nofy261/nolecler-IOT \
  --path p3/confs \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --project default \
  --sync-policy automated

echo -e "\nWaiting for wil-playground deployment to exist...\n"
while ! kubectl -n dev get deployment wil-playground &> /dev/null; do
  sleep 3
done

echo -e "\nWaiting for wil-playground deployment...\n"
kubectl wait --for=condition=available --timeout=120s deployment/wil-playground -n dev

echo -e "\nPort-forwarding to the app\n"
kubectl port-forward svc/wil-playground -n dev 8888:8888 2>&1 >/dev/null &
