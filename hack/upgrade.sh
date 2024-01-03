#!/usr/bin/env bash

set -o errexit

brew update
brew upgrade k3d kubefirst mkcert nss
