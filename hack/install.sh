#!/usr/bin/env bash

set -o errexit

brew update
brew upgrade mkcert || brew install mkcert
mkcert -install

kubefirst k3d create

$HOME/.k1/kubefirst/tools/mkcert -install

echo export KUBECONFIG
echo export KUBECONFIG=/Users/malston/.k1/kubefirst/kubeconfig

echo  --- Kubefirst Console ------------------------------------------------
echo  URL: https://kubefirst.kubefirst.dev
echo  --- ArgoCD -----------------------------------------------------------
echo  URL: https://argocd.kubefirst.dev
echo  --- Vault ------------------------------------------------------------
echo  URL: https://vault.kubefirst.dev
