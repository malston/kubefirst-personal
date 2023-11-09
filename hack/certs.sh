#!/usr/bin/env bash

set -o errexit

# certs created with mkcert: https://github.com/FiloSottile/mkcert
# mkcert automatically creates and installs a local CA in the system root store, and generates 
# locally-trusted certificates.

openssl x509 -in ~/.k1/kubefirst/ssl/kubefirst.dev/pem/kubefirst-cert.pem -noout -text