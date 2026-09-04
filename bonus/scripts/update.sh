GITLAB_PASSWORD=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 -d)

echo "machine gitlab.k3d.gitlab.com
login root
password ${GITLAB_PASSWORD}"> ~/.netrc

sudo chmod 600 ~/.netrc

git clone http://gitlab-webservice-default.gitlab.svc:8181/root/test.git gitlab_repo
git clone https://github.com/Nofy261/nolecler-IOT github_repo

mv github_repo/manifest gitlab_repo/
rm -rf github_repo/

#!/bin/bash
set -euo pipefail

GITLAB_NAMESPACE="gitlab"
GITLAB_PASSWORD="$(sudo kubectl get secret gitlab-gitlab-initial-root-password \
  --namespace "$GITLAB_NAMESPACE" \
  --output=jsonpath="{.data.password}" | base64 -d)"
NETRC_FILE="$HOME/.netrc"

printf 'machine gitlab.k3d.gitlab.com\nlogin root\npassword %s\n' \
  "$GITLAB_PASSWORD" > "$NETRC_FILE"
sudo chmod 600 "$NETRC_FILE"

git clone http://gitlab-webservice-default.gitlab.svc:8181/root/test.git gitlab_repo
git clone https://github.com/Nofy261/nolecler-IOT github_repo

mv github_repo/manifest gitlab_repo/
rm -rf github_repo/

pushd gitlab_repo >/dev/null
git config --global user.email "root@root.com"
git config --global user.name "root"
git add .
git commit -m "update the repo"
git push
popd >/dev/null

argocd app create wil-playground2 \
  --repo http://gitlab-webservice-default.gitlab.svc:8181/root/test.git \
  --path manifest/app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --project default \
  --sync-policy automated

kubectl port-forward svc/wil-playground2 8888:8888 \
  --namespace dev 2>&1 >/dev/null &