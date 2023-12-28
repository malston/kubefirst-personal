#!/usr/bin/env bash

set -o errexit

brew update
brew upgrade mkcert || brew install mkcert
mkcert -install
brew upgrade nss || brew install nss

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

kubefirst k3d create

# "$HOME/.k1/kubefirst/tools/mkcert" -install

export KUBECONFIG=$HOME/.k1/kubefirst/kubeconfig

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
