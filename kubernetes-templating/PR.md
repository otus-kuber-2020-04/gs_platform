Выполнено ДЗ №

- [x] Основное ДЗ
- [ ] Задание со \*

## В процессе сделано:

- 7.1 Задиплоил K8s ч/з терраформ и настроил Helm
- 7.2 Создал Nginx-ingress
- 7.3 Задиплоил cert-manager + добавил ClusterIssuer
- 7.4 Установил Chartmuseum

## Как запустить проект:

- 7.1 Задиплоил K8s ч/з терраформ и настроил Helm

```
cd kubernetes-templating/terraform
terraform apply
gcloud container clusters get-credentials otus-k8s-cluster --region europe-west1
helm repo add stable https://kubernetes-charts.storage.googleapis.com
```

- 7.2 Создал Nginx-ingress

```
kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress stable/nginx-ingress --wait --namespace=nginx-ingress --version=1.11.1
```

- 7.3 Задиплоил cert-manager + добавил ClusterIssuer

```
helm repo add jetstack https://charts.jetstack.io
kubectl create ns cert-manager
#kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.0/cert-manager.yaml
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
helm upgrade --install cert-manager jetstack/cert-manager --wait --namespace=cert-manager --version=0.9.0
kubectl apply -f cert-manager/cluster-issuer-prod.yaml -n cert-manager
```

- 7.4 Установил Chartmuseum

```
kubectl create ns chartmuseum
helm upgrade --install chartmuseum stable/chartmuseum --wait --namespace=chartmuseum --version=2.3.2 -f chartmuseum/values.yaml
```

## Как проверить работоспособность:

- 7.4 Установил Chartmuseum

```
export INGRESS_EIP=$(kubectl get svc nginx-ingress-controller -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl https://chartmuseum.$INGRESS_EIP.nip.io
```

Должно вернуть Chartmuseum welcome page

## PR checklist:

- [ ] Выставлен label с темой домашнего задания
