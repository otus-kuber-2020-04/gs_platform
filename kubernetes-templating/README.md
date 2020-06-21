# Создал Ingress

kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress stable/nginx-ingress --wait --namespace=nginx-ingress --version=1.11.1

# Диплоймент cert-manager

helm repo add jetstack https://charts.jetstack.io
kubectl create ns cert-manager
#kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.0/cert-manager.yaml
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
helm upgrade --install cert-manager jetstack/cert-manager --wait --namespace=cert-manager --version=0.9.0

# Добавил ClusterIssuer

kubectl apply -f kubernetes-templating/cert-manager/cluster-issuer-prod.yaml -n cert-manager

# Задиплоил Chart museum

kubectl create ns chartmuseum
helm upgrade --install chartmuseum stable/chartmuseum --wait --namespace=chartmuseum --version=2.3.2 -f kubernetes-templating/chartmuseum/values.yaml

# Verification

export INGRESS_EIP=$(kubectl get svc nginx-ingress-controller -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl https://chartmuseum.$INGRESS_EIP.nip.io
Должно вернуть Chartmuseum welcome page

# Задание со \*

Опишите в PR последовательность действий, необходимых для добавления туда helm chart's и их установки с использованием chartmuseum как репозитория

# Диплоймент Harbor

kubectl create ns harbor
helm repo add harbor https://helm.goharbor.io
helm upgrade --install harbor harbor/harbor --wait --namespace=harbor --version=1.1.2 -f kubernetes-templating/harbor/values.yaml

# Свой helm chart

kubectl create ns hipster-shop
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop

# Uninstall

helm uninstall hipster-shop

# Диплоймент фронта отдельно

helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
helm upgrade --install hipster-shop-frontend kubernetes-templating/frontend/ --namespace hipster-shop
