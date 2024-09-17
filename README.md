# [kubefirst](https://docs.kubefirst.io/k3d/quick-start/install) on [k3d](https://k3d.io/)

## Install

Follow these [instructions](https://docs.kubefirst.io/k3d/quick-start/install) to install [kubefirst](https://docs.kubefirst.io/) or run [install.sh](hack/install.sh)

## Post-Install

### Get credentials

  ```sh
  kubefirst k3d root-credentials
  ```

If you created your cluster using the UI, or reset your `kubefirst` environment, you can still retrieve the root credentials (except the `kbot` user password, which you will have to find manually in Vault) using `kubectl`:

  ```sh
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

  ```sh
  kubectl -n vault get secret vault-unseal-secret -o jsonpath="{.data.root-token}" | base64 -d
  ```

### Create `.env` file with all the secrets

  ```sh
  kubefirst terraform set-env \
    --vault-token $(kubectl get secrets -n vault vault-unseal-secret -o jsonpath='{.data.root-token}' | base64 -d) \
    --vault-url https://vault.kubefirst.dev
  source .env
  ```

### Peek at some Vault Secrets

  ```sh
  vault kv list secret
  vault kv get -mount=secret atlantis
  vault kv get -mount=secret atlantis-ngrok
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
  
### Unseal Vault

If vault becomes sealed for any reason, see [faq](https://docs.kubefirst.io/k3d/faq#how-can-i-unseal-hashicorp-vault).

  ```sh
  kubefirst k3d unseal-vault
  ```

### Login to [Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

  ```sh
  vault kv get -format=json -mount=secret dockerconfigjson | jq -r '.data.data.dockerconfig' | jq -r '.auths."ghcr.io".auth' | base64 --decode
  echo $GITHUB_TOKEN | docker login ghcr.io -u malston --password-stdin
  ```
