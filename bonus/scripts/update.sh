#!/bin/bash
set -euo pipefail

GITLAB_NAMESPACE="${GITLAB_NAMESPACE:-gitlab}"
GITLAB_HOST="${GITLAB_HOST:-gitlab.k3d.gitlab.com}"
GITLAB_PROJECT="${GITLAB_PROJECT:-root/test}"
GITLAB_REPO_DIR="${GITLAB_REPO_DIR:-$PWD/gitlab_repo}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-https://github.com/Nofy261/nolecler-IOT.git}"

command -v git >/dev/null || { echo "git is required" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required" >&2; exit 1; }

GITLAB_PASSWORD="$(sudo kubectl get secret gitlab-gitlab-initial-root-password \
  --namespace "$GITLAB_NAMESPACE" \
  --output=jsonpath="{.data.password}" | base64 -d)"

if [[ -z "$GITLAB_PASSWORD" ]]; then
  echo "Could not retrieve the GitLab root password" >&2
  exit 1
fi

NETRC_FILE="$HOME/.netrc"
umask 077
printf 'machine %s\nlogin root\npassword %s\n' \
  "$GITLAB_HOST" "$GITLAB_PASSWORD" > "$NETRC_FILE"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Cloning the source repository"
git clone --depth 1 "$GITHUB_REPOSITORY" "$WORK_DIR/github_repo"

SOURCE_MANIFESTS="$WORK_DIR/github_repo/p3/confs"
if [[ ! -d "$SOURCE_MANIFESTS" ]]; then
  echo "Manifest directory not found: $SOURCE_MANIFESTS" >&2
  exit 1
fi

if [[ -d "$GITLAB_REPO_DIR/.git" ]]; then
  git -C "$GITLAB_REPO_DIR" pull --ff-only
else
  GITLAB_REPOSITORY="http://$GITLAB_HOST/$GITLAB_PROJECT.git"
  git clone "$GITLAB_REPOSITORY" "$GITLAB_REPO_DIR"
fi

mkdir -p "$GITLAB_REPO_DIR/manifest/app"
rm -rf "$GITLAB_REPO_DIR/manifest/app"/*
cp -R "$SOURCE_MANIFESTS"/. "$GITLAB_REPO_DIR/manifest/app/"

git -C "$GITLAB_REPO_DIR" config user.email "root@root.com"
git -C "$GITLAB_REPO_DIR" config user.name "root"
git -C "$GITLAB_REPO_DIR" add manifest/app

if git -C "$GITLAB_REPO_DIR" diff --cached --quiet; then
  echo "GitLab repository is already up to date"
  exit 0
fi

git -C "$GITLAB_REPO_DIR" commit -m "Update application manifests"
git -C "$GITLAB_REPO_DIR" push origin HEAD
echo "GitLab repository updated successfully"