#!/bin/bash

echo -e "\nCleaning IOT environment ...\n"

# Stop Argo CD port-forward
pkill -f "kubectl port-forward svc/argocd-server.*8080:443" 2>/dev/null || true

# Stop application port-forward
pkill -f "kubectl port-forward svc/wil-playground.*8888:8888" 2>/dev/null || true

# Delete Argo CD application
argocd app delete wil-playground --yes 2>/dev/null || true

echo -e "\nCleaning completed.\n"