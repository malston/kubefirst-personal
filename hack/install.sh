#!/usr/bin/env bash

set -o errexit

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

brew update
brew upgrade kubefirst || brew install kubefirst/tools/kubefirst
brew upgrade mkcert || brew install mkcert
brew upgrade nss || brew install nss
mkcert -install

function read_password() {
  local prompt="$1"
  unset password
  while IFS= read -p "$prompt" -r -s -n 1 char; do
    if [[ $char == $'\0' ]]; then
      break
    fi
    prompt='*'
    password+="$char"
  done
  echo "$password"
}

GITHUB_TOKEN=$1

if [[ -z $GITHUB_TOKEN ]]; then
  GITHUB_TOKEN=$(read_password "Enter a Github Personal Access Token: ")
fi

# k3d cluster create gimlet-cluster --k3s-arg "--disable=traefik@server:0"

kubefirst k3d create \
  --cluster-name kubefirst \
  --cluster-type mgmt \
  --github-user malston \
  --git-provider github

kubefirst k3d root-credentials

export KUBECONFIG=$HOME/.k1/kubefirst/kubeconfig

if [[ -f "$__DIR/../.env" ]]; then
  cp "$__DIR/../.env" "$__DIR/../.env.bak"
fi

kubefirst terraform set-env \
  --vault-token "$(kubectl \
    --kubeconfig="$HOME/.k1/kubefirst/kubeconfig" \
    get secrets \
    -n vault vault-unseal-secret \
    -o jsonpath='{.data.root-token}' \
    | base64 -d)" \
  --vault-url https://vault.kubefirst.dev

echo "export KUBECONFIG=$HOME/.k1/kubefirst/kubeconfig" >> .env

echo  --- Kubefirst Console ------------------------------------------------
echo  URL: https://kubefirst.kubefirst.dev
echo  --- ArgoCD -----------------------------------------------------------
echo  URL: https://argocd.kubefirst.dev
echo  --- Vault ------------------------------------------------------------
echo  URL: https://vault.kubefirst.dev

git clone --recursive https://github.com/malston/gitops.git "$__DIR/../gitops"
git clone --recursive https://github.com/malston/metaphor.git "$__DIR/../metaphor"
