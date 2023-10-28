# [kubefirst](https://docs.kubefirst.io/k3d/quick-start/install) on [k3d](https://k3d.io/)

## Get credentials

  ```sh
  kubefirst k3d root-credentials
  ```

## Get the vault root token from cluster

  ```sh
  kubectl get secrets -n vault vault-unseal-secret -o jsonpath='{.data.root-token}' | base64 -d
  ```

## Create `.env` file with all the secrets

  ```sh
  kubefirst terraform set-env \
    --vault-token $(kubectl get secrets -n vault vault-unseal-secret -o jsonpath='{.data.root-token}' | base64 -d) \
    --vault-url https://vault.kubefirst.dev
  source .env
  vault kv list secret
  vault kv get -mount=secret atlantis
  vault kv get -mount=secret ci-secrets
  vault kv get -mount=secret -format=json ci-secrets | jq -r .data.data.accesskey
  vault kv get -mount=secret -format=json ci-secrets | jq -r .data.data.PERSONAL_ACCESS_TOKEN
  ```

## Download minio buckets

  ```sh
  mc alias set local https://minio.kubefirst.dev \
    $(vault kv get -mount=secret -format=json ci-secrets | jq -r .data.data.accesskey) \
    $(vault kv get -mount=secret -format=json ci-secrets | jq -r .data.data.secretkey)
  mc admin info local
  mc ls local --recursive
  rm -rf minio
  mkdir minio
  mc cp local --recursive minio
  ```

## Clone gitops and metaphor

  ```sh
  rm -rf gitops
  rm -rf metaphor
  git cr https://github.com/malston/gitops.git
  git cr https://github.com/malston/metaphor.git
  ```
  
## Unseal

  ```sh
  vault operator unseal $(kubectl get secrets -n vault vault-unseal-secret -o jsonpath='{.data.root-token}')
  ```
