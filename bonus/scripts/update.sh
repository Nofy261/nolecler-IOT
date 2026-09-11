#!/bin/bash
set -euo pipefail

GITLAB_NAMESPACE="gitlab"
GITLAB_PASSWORD="$(sudo KUBECONFIG="$HOME/.kube/config" kubectl get secret gitlab-gitlab-initial-root-password \
  --namespace "$GITLAB_NAMESPACE" \
  --output=jsonpath="{.data.password}" | base64 -d)"
NETRC_FILE="$HOME/.netrc"

printf 'machine gitlab.k3d.gitlab.com\nlogin root\npassword %s\n' \
  "$GITLAB_PASSWORD" > "$NETRC_FILE"
sudo chmod 600 "$NETRC_FILE"

if [ -d gitlab_repo ]; then
  git -C gitlab_repo pull
else
  git clone http://gitlab.k3d.gitlab.com/root/test.git gitlab_repo
fi

git clone https://github.com/Nofy261/nolecler-IOT github_repo

rm -rf gitlab_repo/confs
mv github_repo/p3/confs gitlab_repo/confs
sed -i 's/wil-playground/wil-playground2/g' gitlab_repo/confs/*.yaml
rm -rf github_repo/

pushd gitlab_repo >/dev/null
git config user.email "root@root.com"
git config user.name "root"
git add .
git commit -m "update the repo" || echo "no changes to push"
git push
popd >/dev/null

argocd app create wil-playground2 \
  --repo http://gitlab-webservice-default.gitlab.svc:8181/root/test.git \
  --path confs \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --project default \
  --sync-policy automated

echo "Attente que le deployment wil-playground2 existe..."
while ! kubectl -n dev get deployment wil-playground2 &> /dev/null; do
  sleep 3
done

echo "Attente que le deployment wil-playground2 soit disponible..."
kubectl wait --for=condition=available --timeout=120s deployment/wil-playground2 -n dev

kubectl port-forward svc/wil-playground2 8889:8888 \
  --namespace dev 2>&1 >/dev/null &