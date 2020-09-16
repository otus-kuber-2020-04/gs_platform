# Выполнено ДЗ №

- [ ] Основное ДЗ
- [ ] Задание со \*

## В процессе сделано:

- Пункт 1
- Пункт 2

## Как запустить проект:

```
cd kubernetes-vault/terraform
terraform apply
helm install consul consul-helm
cd kubernetes-vault/vault-helm
helm install vault .
helm status vault
kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
kubectl exec -it vault-0 -- vault operator unseal
kubectl exec -it vault-1 -- vault operator unseal
kubectl exec -it vault-2 -- vault operator unseal
kubectl exec -it vault-0 -- vault login
kubectl exec -it vault-0 -- vault auth list
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
kubectl exec -it vault-0 -- vault secrets list --detailed
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault read otus/otus-ro/config
kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
kubectl exec -it vault-0 -- vault auth enable kubernetes
kubectl create serviceaccount vault-auth
kubectl apply --filename vault-auth-service-account.yml
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \ token_reviewer_jwt="$SA_JWT_TOKEN" \
kubernetes_host="$K8S_HOST" \
kubernetes_ca_cert="$SA_CA_CRT"
kubectl cp otus-policy.hcl vault-0:./tmp
kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy ttl=24h
```

## Как проверить работоспособность:

```
kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7
apk add curl jq
VAULT_ADDR=http://vault:8200
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "test"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{p
rint $2}')
```

## PR checklist:

- [ ] Выставлен label с темой домашнего задания

# Outputs

```
helm status vault
NAME: vault
LAST DEPLOYED: Sat Sep 12 19:27:42 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault

kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: MmYIzbbiRDcT/xeIo+cCaKrEf293Tw1e+gCBZ+/1v6g=

Initial Root Token: s.7tUOJxhDEHRZI94X6TXtwG6l

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 1 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.

$ kubectl exec -it vault-0 -- vault status
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.5.2
Cluster Name    vault-cluster-90e698e8
Cluster ID      832d9140-af92-95dd-3d42-00713dedc674
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active

k exec -it vault-0 -- vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.7tUOJxhDEHRZI94X6TXtwG6l
token_accessor       YegWMDnVkp7IPemYEDaEsQFf
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
 ~/Do/co/ot/gs/kubernetes-vault   kubernetes-vault ?                       ✔  10994  19:37:36
 $ k exec -it vault-0 -- vault auth list
Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_9f42d1ff    token based credentials

 $ kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus


kubectl exec -it vault-0 -- vault auth list
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_1a44c063    n/a
token/         token         auth_token_8bf6bfe2         token based credentials

```

# Questions

Обратите внимание на конструкцию sed ’s/\x1b\[[0-9;]\*m//g, что по вашему она делает?
Убирает цвета stdout. На маке сработает только gsed. [source](https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream)
