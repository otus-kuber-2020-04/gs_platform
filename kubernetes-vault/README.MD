# Выполнено ДЗ №

- [ ] Основное ДЗ
- [ ] Задание со \*

## В процессе сделано:

- Установил consul && vault
- Пункт 2

## Как запустить проект:

```
# Infrastructure part
cd kubernetes-vault/terraform
terraform apply

# Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install consul hashicorp/consul
helm install vault hashicorp/vault -f kubernetes-vault/vault-helm-values.yaml
helm status vault
# Провести инициализацию ч/з любой под
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
#Включим авторизацию ч/з k8s
kubectl exec -it vault-0 -- vault auth enable kubernetes
kubectl create serviceaccount vault-auth
kubectl apply --filename vault-auth-service-account.yml
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | gsed 's/\x1b\[[0-9;]*m//g')
# Запишем конфиг в Vault
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
token_reviewer_jwt="$SA_JWT_TOKEN" \
kubernetes_host="$K8S_HOST" \
kubernetes_ca_cert="$SA_CA_CRT"

#Создание политики и роли в vault
kubectl cp otus-policy.hcl vault-0:./tmp
kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy ttl=24h

#Vault-guides: Non SSL nginx
k create -f nginx-config.yaml
k apply -f nginx-spec.yaml --record

#Create CA https://learn.hashicorp.com/tutorials/vault/pki-engine
kubectl exec -it vault-0  -- vault secrets enable pki
k exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
k exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="example.com" ttl=87600h > CA_cert.crt

#URL для CA и отозванных certs
kubectl exec -it vault-0 -- vault write pki/config/urls \ issuing_certificates="http://vault:8200/v1/pki/ca" \ crl_distribution_points="http://vault:8200/v1/pki/crl"

#Промежуточный сертификат
kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr

#Пропишем промужеточный сертификат
kubectl cp pki_intermediate.csr vault-0:./tmp
kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@./tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem
k cp intermediate.cert.pem vault-0:./tmp
kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@./tmp/intermediate.cert.pem

#Создадим роль для выдачи
kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"
#Создадим и отзовем серт
kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="57:d1:6f:a2:46:e9:47:b6:db:fa:cc:62:31:8f:01:28:ea:ae:c4:b0"

#Включить TLS для Vault
kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="vault.example.ru" ttl="240h"





#Включить TLS
export LB_IP="$(gcloud compute addresses describe gke-ext --region europe-west1 --format 'value(address)')"
cd kubernetes-vault/tls/
openssl genrsa -out vault.key 4096
openssl req -config vault_csr.cnf -new -key vault.key -nodes -out vault.csr
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: vaultcsr
spec:
  request: $(cat vault.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF
kubectl get csr
kubectl certificate approve vaultcsr
kubectl get csr vaultcsr -o jsonpath='{.status.certificate}' | base64 --decode > vault.crt
kubectl create secret tls vault-certs --cert=vault.crt --key=vault.key
helm upgrade --install vault hashicorp/vault -f tls-vault-values.yaml

kubectl delete pod -l app.kubernetes.io/instance=vault
kubectl exec -it vault-0 -- vault operator unseal
kubectl exec -it vault-1 -- vault operator unseal
kubectl exec -it vault-2 -- vault operator unseal
kubectl exec -it vault-0 -- vault login

# Проверка
kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7
apk add curl jq
curl -k --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config
# {"request_id":"0be08d47-e88a-db52-1e1a-d39c3fdf7aa7","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}

# Настроить автообновление сертификатов
kubectl cp pki-policy.hcl vault-0:/tmp
kubectl exec -it vault-0 -- vault policy write nginx-policy /tmp/pki-policy.hcl
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/pki bound_service_account_names=vault-auth bound_service_account_namespaces=default policies=pki-policy ttl=24h



```

## Как проверить работоспособность:

```
kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7
apk add curl jq
curl --request POST --data '{"jwt": "'$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)'", "role": "otus"}' http://vault:8200/v1/auth/kubernetes/login
TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)'", "role": "otus"}' http://vault:8200/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')



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

Обратите внимание на конструкцию sed 's/\x1b\[[0-9;]\*m//g, что по вашему она делает?
Убирает цвета stdout. На маке сработает только gsed. [source](https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream)

# Stdouts

```
 $ kubectl exec -it vault-0 -- vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.55wilszJaUShp59ODpfQvkkm
token_accessor       dU2YoYHUuO6xoIxGFdnAp8uv
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]

 $ kubectl exec -it vault-0 -- vault auth list
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_5e56f385    n/a
token/         token         auth_token_020c1297         token based credentials


 $ k exec -it nginx -- cat /usr/share/nginx/html/index.html
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>

kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDMzCCAhugAwIBAgIUbx+5g2y7d2qI11ysZ15iq5pQK7owDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjAxMDEwMjIwNzE5WhcNMjUx
MDA5MjIwNzQ5WjAsMSowKAYDVQQDEyFleGFtcGxlLnJ1IEludGVybWVkaWF0ZSBB
dXRob3JpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDVtPhQz3Eu
A5anLfn678wzcszFmJANZ4kGrLOifqEdS6mTleCao/bN38Cd8mI0mDOrPAUqBvmN
pzWOsEwabUA9qbTd1RCXSa1e9kF5GmZpSPJeD+YsUOe3VGAAV4rVA9fhVrdWphpp
RTrCcDR/N/5BgoPCf6xxQRYUiTpufCmj0DD0Rdnit8HtFLemHF31+yFwO0UjHPav
5LmCGnA3MZenlA9kYOCRh67KckInZaK/rUJgq6iczEVgzvGMvyNfBhndum4VSKSY
MXyrWuat0nUpLD8G73X9MtCadsdIvWxWT/qp10io+37QIUowFLedeoRaeAin76Hy
DzADbnUdZuaJAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTAD
AQH/MB0GA1UdDgQWBBQ6zEilDS8VQDy9So5fcqPFdIJ6ajAfBgNVHSMEGDAWgBQV
R4oT7b4Iso1E26W3GcmzXfdo5TANBgkqhkiG9w0BAQsFAAOCAQEAdKqsND7zqQc+
J5lQaT+3+KbTfbg+ghsUku7yiMr368/+0u612JZ2z6E8CHlJNtzrJybelsrwhXIM
P3klt8aGy0C2cC7wJ8P/ZRLvKBh6OPTgNwAOcB9nt7bs0ofiTK1uvO8c77ain0AL
c+dxa7/7QCirTnINrLGYWrO6VtTS7qqyB8wea50gKv3mhcLVUFTyTf/pnOIzmbMS
u8gWZg97Q1qAb6buDiExUJ1GkfcUoXZbVOkCJdH2CdWaaGCExFEzQVajmjIJa5qY
WFopH7W5c+9pBe9OhWl9JZeBMWmvx0fzzhoI0JCksRXKX4SvciDoEvDAGMvjaBSi
dQUtVBawbQ==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUV9FvokbpR7bb+sxiMY8BKOquxLAwDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIwMTAxMDIyMTExMVoXDTIwMTAxMTIyMTE0MVowHDEaMBgGA1UEAxMRZ2l0
bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC4
OuYdIG8DloSWrwM8lvLnEmnRkYfLC8bCXq0191bQG7mZ6CXBhfWWvxNJNr9uEZ2J
nZz1PzU4w+HKU5Bg/tGrn1jXCflCUx/O/rsY5IgZk+q4eCXTrU44zwkePW9xmDIV
C7fYh7w7kXLcoWdYLL+OSfYHzj54RHPGlli+Bty2qwW6yr4Hob0/HUwGxuPYRBhf
2TcGWTLAK3Dt2rMyu44xxxfqQU90nBOhoRZIWdtqCrChsqyJPWZHdOZhZpRDoEZ6
DkQX4b12kdAiwN+ufOkYAWWLg1OY3kChOqeDDkZEyigf8PxrWHn1dBRNpCv9F4Lk
iMFOyLRAMWCIA1d0dJYlAgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUyJ8KuD5RJ1KF/I3p
cDHLhqvv/EAwHwYDVR0jBBgwFoAUOsxIpQ0vFUA8vUqOX3KjxXSCemowHAYDVR0R
BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBAFATpUVl
TiD6ykd81ew7nXpWYI6N64AWrFPeiWOPdGp59Xj5ZwTk3yvt2oalT5xWAzBZ2uzj
P0zN3eaK852Tt6DoeDapHpKN7EXu6hekLi4eFrosj7TOrQ+rBnJQoahRT7k/aZsc
slPHumcj4iYSb9oEqSTONwZVaZ3Rq5tUAZ6gemaciCIrNpwj7J50QIbFIrswWYj0
nY5HWbL/Gqi/HuUpDD64jg1OinfENH7MhxWdjqLXqKLph4rATnDtxRg5881JaT8u
jIqwOqxNdH7iUMpGFfkio35vp8lKNahfJE5pwQRxIarp5TnyZNFEhaPNJPMPJWJG
uSxFljcpxhtxZ6s=
-----END CERTIFICATE-----
expiration          1602454301
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDMzCCAhugAwIBAgIUbx+5g2y7d2qI11ysZ15iq5pQK7owDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjAxMDEwMjIwNzE5WhcNMjUx
MDA5MjIwNzQ5WjAsMSowKAYDVQQDEyFleGFtcGxlLnJ1IEludGVybWVkaWF0ZSBB
dXRob3JpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDVtPhQz3Eu
A5anLfn678wzcszFmJANZ4kGrLOifqEdS6mTleCao/bN38Cd8mI0mDOrPAUqBvmN
pzWOsEwabUA9qbTd1RCXSa1e9kF5GmZpSPJeD+YsUOe3VGAAV4rVA9fhVrdWphpp
RTrCcDR/N/5BgoPCf6xxQRYUiTpufCmj0DD0Rdnit8HtFLemHF31+yFwO0UjHPav
5LmCGnA3MZenlA9kYOCRh67KckInZaK/rUJgq6iczEVgzvGMvyNfBhndum4VSKSY
MXyrWuat0nUpLD8G73X9MtCadsdIvWxWT/qp10io+37QIUowFLedeoRaeAin76Hy
DzADbnUdZuaJAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTAD
AQH/MB0GA1UdDgQWBBQ6zEilDS8VQDy9So5fcqPFdIJ6ajAfBgNVHSMEGDAWgBQV
R4oT7b4Iso1E26W3GcmzXfdo5TANBgkqhkiG9w0BAQsFAAOCAQEAdKqsND7zqQc+
J5lQaT+3+KbTfbg+ghsUku7yiMr368/+0u612JZ2z6E8CHlJNtzrJybelsrwhXIM
P3klt8aGy0C2cC7wJ8P/ZRLvKBh6OPTgNwAOcB9nt7bs0ofiTK1uvO8c77ain0AL
c+dxa7/7QCirTnINrLGYWrO6VtTS7qqyB8wea50gKv3mhcLVUFTyTf/pnOIzmbMS
u8gWZg97Q1qAb6buDiExUJ1GkfcUoXZbVOkCJdH2CdWaaGCExFEzQVajmjIJa5qY
WFopH7W5c+9pBe9OhWl9JZeBMWmvx0fzzhoI0JCksRXKX4SvciDoEvDAGMvjaBSi
dQUtVBawbQ==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAuDrmHSBvA5aElq8DPJby5xJp0ZGHywvGwl6tNfdW0Bu5megl
wYX1lr8TSTa/bhGdiZ2c9T81OMPhylOQYP7Rq59Y1wn5QlMfzv67GOSIGZPquHgl
061OOM8JHj1vcZgyFQu32Ie8O5Fy3KFnWCy/jkn2B84+eERzxpZYvgbctqsFusq+
B6G9Px1MBsbj2EQYX9k3BlkywCtw7dqzMruOMccX6kFPdJwToaEWSFnbagqwobKs
iT1mR3TmYWaUQ6BGeg5EF+G9dpHQIsDfrnzpGAFli4NTmN5AoTqngw5GRMooH/D8
a1h59XQUTaQr/ReC5IjBTsi0QDFgiANXdHSWJQIDAQABAoIBACLtf70b7hAnFEIh
MiLll225rvg9eBpFxEwLeRlXKE1SRFDqk2XqSNJorXZe+9IZYt25VQ2mCygU8xTR
3PiWtxeroUM7r9ckPU6YOs6QXUFEKucIWFuWatMYZWknSp6ltTEKRLO3oDdG7xjn
PNmZukN2wD9gmbVhfPW0gWSdlnDHDzFeMlp3UEZO5eITxflP2ehCdVcaRkNloL77
xn3YqE4+XCByBe9QDEpmzYz3T4tlKNUZS0RkV4HcfmmSw8t4F8EbjbFHFruMOk7c
k2BbHhyVh7AtGdAFVOXCskxthxCBqcB535xTTW9t9ZdN/PZf2jFdASGA6xgWp0f6
CPnpSOECgYEA69w7Vxgu7Vl2tIOlI5TwzqvBtRMF/FczJ1vo7oNhWArNVN9R8sNm
wQ3zWiNuHvVgn9yxSzFkWDj5tTwyrgbRSskociyd5eH0bbM9E2Wo1UvgqO0qzLqq
ctDgWOzbAZavskvUBm16WrTaHS7T+vTJFTmnS4y6zju8w6kXg1xWuj0CgYEAx/YP
lT0W/LJ3wYC/t8sLhV6Jvgopa70t2pYdv0tr9/4/yTULtG+l3iL0TabZorpUzZNo
7S+4VqORqjX4bgK1aNMC0Duk7RkjWiv1PJNctf7HahtqBQA3SaPGXyuJ9UsrniWg
924JGy2ol+0a+ihUBVjP+lo7S+w7Gbc7a9dK0gkCgYBdB/83+Uf5QsJ5rTtj74mU
W1cKjzhbMiHxMmWMPrIUwh3/jh6KvNw45cHJGhSDjZHRPIGKAS9tRPvpqpbq4bGH
6BRWBJc7Z4a8Bmjez8hqaYVx3Cp3mmFE7HKxYKt50u/2ScaVynTqdk9aF3Bxmj/+
aUE9oYLFefaYzoeBvthOmQKBgCxIsDbK6rZYB/GQw+S+UPTedP7jXT0BDpCkQj5F
Q8oOQq4a01bIiyFg+F3iH7zMK0/D3673rIlzfCUIAtbKPsbSRIM9Uk84C/5CUfNy
Z0ve+ubi313wKE5kuOAG0mzCkwxZJQbnFZkxSW8sEZdpKwJsItM8/HjZ/lS5oa1G
ZsmRAoGBAKdMGno39nShPnhXdRooLsLOAV2rFP8RSRxJrcxOp1Lcs3ipZfKEVT5M
lNcy0miKvqDrgEdSKGx2WVo2wtRbcvp8jR7VMkj6L/Ms7O9MiRkv1KVqvfQ3PgBK
hA0sdgCP0qo8LL4WsBphlgHhyvw1tiSyedUu4am/HYCUjd+1nx8F
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       57:d1:6f:a2:46:e9:47:b6:db:fa:cc:62:31:8f:01:28:ea:ae:c4:b0
 ~/Do/co/ot/gs/kubernetes-vault   kubernetes-vault ✚ ● ?                         ✔  11515  01:11:41
 $ kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="57:d1:6f:a2:46:e9:47:b6:db:fa:cc:62:31:8f:01:28:ea:ae:c4:b0"
Key                        Value
---                        -----
revocation_time            1602367921
revocation_time_rfc3339    2020-10-10T22:12:01.281267384Z
```
