#!/usr/bin/env bash

set -o errexit

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
