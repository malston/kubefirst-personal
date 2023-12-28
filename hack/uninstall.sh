#!/usr/bin/env bash

set -o errexit

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

usage() { echo "Usage: $0 [-r]" 1>&2; exit 1; }

while getopts ":r" o; do
    case "${o}" in
        r)
            kubefirst reset
            exit 0
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

kubefirst k3d destroy
mkcert -uninstall
rm -rf ~/.k1
rm -rf "$__DIR/../gitops/"
rm -rf "$__DIR/../metaphor/"
rm -rf "$__DIR/../minio/"