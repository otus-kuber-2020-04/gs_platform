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
helm upgrade --install nginx-ingress stable/nginx-ingress --wait --namespace=nginx-ingress --version=1.40.3
```

- 7.3 Задиплоил cert-manager + добавил ClusterIssuer

```
helm repo add jetstack https://charts.jetstack.io
kubectl create ns cert-manager
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.1/cert-manager.crds.yaml
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v0.15.1 \
#  --set installCRDs=true
# To automatically install and manage the CRDs as part of your Helm release, you must add the --set installCRDs=true flag to your Helm installation command.
kubectl apply -f cert-manager/cluster-issuer-prod.yaml -n cert-manager
```

- 7.4 Установил Chartmuseum

```
kubectl create ns chartmuseum
helm install chartmuseum stable/chartmuseum --wait --namespace=chartmuseum --version=2.13.0 -f chartmuseum/values.yaml
```

## Как проверить работоспособность:

- 7.4 Установил Chartmuseum

```
kubectl get svc nginx-ingress-controller -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
#Update chartmuseum/values.yaml
# - name: chartmuseum.$INGRESS_EIP.nip.io
export INGRESS_EIP=$(kubectl get svc nginx-ingress-controller -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl https://chartmuseum.$INGRESS_EIP.nip.io
```

Должно вернуть Chartmuseum welcome page

## PR checklist:

- [ ] Выставлен label с темой домашнего задания

Notes

Get the ChartMuseum URL by running:

export POD_NAME=$(kubectl get pods --namespace chartmuseum -l "app=chartmuseum" -l "release=chartmuseum" -o jsonpath="{.items[0].metadata.name}")
  echo http://127.0.0.1:8080/
  kubectl port-forward $POD_NAME 8080:8080 --namespace chartmuseum
