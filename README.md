# [kubefirst](https://docs.kubefirst.io/k3d/quick-start/install) on [k3d](https://k3d.io/)

## Install

Follow these [instructions](https://docs.kubefirst.io/k3d/quick-start/install) to install [kubefirst](https://docs.kubefirst.io/) or run [install.sh](hack/install.sh)

## Post-Install

### Get credentials

  ```sh
  kubefirst k3d root-credentials
  ```

### Create `.env` file with all the secrets

  ```sh
  kubefirst terraform set-env \
    --vault-token $(kubectl get secrets -n vault vault-unseal-secret -o jsonpath='{.data.root-token}' | base64 -d) \
    --vault-url https://vault.kubefirst.dev
  echo export GITHUB_TOKEN=\"$(read -rs TOKEN; echo $TOKEN)\" >> .env
  source .env
  vault kv list secret
  vault kv get -mount=secret atlantis
  vault kv get -mount=secret ci-secrets
  vault kv get -mount=secret -format=json ci-secrets | jq -r .data.data.accesskey
  vault kv get -mount=secret -format=json ci-secrets | jq -r .data.data.PERSONAL_ACCESS_TOKEN
  ```

### Download MinIO buckets

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

### Clone GitOps and Metaphor repositories

  ```sh
  git clone --recursive https://github.com/malston/gitops.git
  git clone --recursive https://github.com/malston/metaphor.git
  ```
  
### Unseal Vault (if this becomes sealed for any reason)

  ```sh
  kubefirst k3d unseal-vault
  ```
