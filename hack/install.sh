#!/usr/bin/env bash

set -o errexit

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

function usage() {
  echo "Usage:"
  echo "  $0 [flags]"
  printf "\n"
  echo "Flags:"
  printf "  %s, --provider\tGit provider\n" "-p"
  printf "  %s, --skip-tools\tDo not install (kubefirst, mkcert, nss)\n" "-s"
  printf "\n"
}

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

INSTALL_TOOLS=true

# parse argv variables
while [ "$#" -gt 0 ]; do
  case "$1" in
    -g | -p | --provider | --git-provider)
      GIT_PROVIDER="$2"
      shift 2
      ;;
    -g=* | --git-provider=* | -p=* | --provider=*)
      GIT_PROVIDER="${1#*=}"
      shift 1
      ;;
    -s | --skip | --skip-tools)
      INSTALL_TOOLS=false
      shift 1
      ;;
    -h | --help)
      usage
      exit
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z $GIT_PROVIDER ]]; then
  read -rp "Enter your git provider (github, gitlab) [github]: " GIT_PROVIDER
  GIT_PROVIDER=${GIT_PROVIDER:-github}
fi

if [[ $INSTALL_TOOLS == true ]]; then
  brew update
  brew upgrade kubefirst || brew install kubefirst/tools/kubefirst
  brew upgrade mkcert || brew install mkcert
  brew upgrade nss || brew install nss
  brew upgrade hashicorp/tap/vault || brew tap hashicorp/tap && brew install hashicorp/tap/vault
fi

# Create a new local CA
mkcert -install

case $GIT_PROVIDER in
  github)
    if [[ -z $GITHUB_TOKEN ]]; then
      GITHUB_TOKEN=$(read_password "Enter a Github Personal Access Token: ")
    fi
    if ! ssh-keyscan -t rsa github.com &> /dev/null; then
      ssh-keyscan github.com >> ~/.ssh/known_hosts
    fi
    export GITHUB_TOKEN
    kubefirst k3d create \
      --cluster-name kubefirst \
      --cluster-type mgmt \
      --github-org malston \
      --git-provider github
    ;;
  gitlab)
    if [[ -z $GITLAB_TOKEN ]]; then
      GITLAB_TOKEN=$(read_password "Enter a Gitlab Personal Access Token: ")
    fi
    if ! ssh-keyscan -t rsa gitlab.com &> /dev/null; then
      ssh-keyscan gitlab.com >> ~/.ssh/known_hosts
    fi
    export GITLAB_TOKEN
    kubefirst k3d create \
      --cluster-name kubefirst \
      --cluster-type mgmt \
      --github-org marktalston \
      --gitlab-group marsguitars \
      --git-provider gitlab
    ;;
  *)
    echo "Unknown value for '--git-provider'"
    usage
    exit 1
    ;;
esac

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
    -o jsonpath='{.data.root-token}' |
    base64 -d)" \
  --vault-url https://vault.kubefirst.dev

echo "export KUBECONFIG=$HOME/.k1/kubefirst/kubeconfig" >> "$__DIR/../.env"
if [[ -n $GITHUB_TOKEN ]]; then
  echo "export GITHUB_TOKEN=$GITHUB_TOKEN" >> "$__DIR/../.env"
fi
if [[ -n $GITLAB_TOKEN ]]; then
  echo "export GITLAB_TOKEN=$GITLAB_TOKEN" >> "$__DIR/../.env"
fi
if [[ -n $NGROK_AUTHTOKEN ]]; then
  echo "export NGROK_AUTHTOKEN=$NGROK_AUTHTOKEN" >> "$__DIR/../.env"
fi

echo --- Kubefirst Console ------------------------------------------------
echo URL: https://kubefirst.kubefirst.dev
echo --- ArgoCD -----------------------------------------------------------
echo URL: https://argocd.kubefirst.dev
echo --- Vault ------------------------------------------------------------
echo URL: https://vault.kubefirst.dev

# git clone --recursive https://github.com/malston/gitops.git "$__DIR/../gitops"
# git clone --recursive https://github.com/malston/metaphor.git "$__DIR/../metaphor"
open https://kubefirst.kubefirst.dev
