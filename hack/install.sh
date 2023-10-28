#!/usr/bin/env bash

set -o errexit

brew update
brew upgrade mkcert || brew install mkcert
mkcert -install

kubefirst k3d create
