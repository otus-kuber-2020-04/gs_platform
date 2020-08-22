pwd

# Выполнено ДЗ №

- [ ] Основное ДЗ
- [ ] Задание со \*

## В процессе сделано:

- Добавил в терраформ пул под инфру + taint
- Установил Hipster shop
- Установил EFK и Grafana
- Установил nginx ingress
- Настроил node exporters

## Как запустить проект:

```
cd kubernetes-logging/terraform
terraform apply
gcloud container clusters get-credentials otus-k8s-cluster --region europe-west1
kubectl get nodes
kubectl create ns microservices-demo
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo
kubectl get pods -n microservices-demo -o wide
helm repo add elastic https://helm.elastic.co
helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability -f kubernetes-logging/elasticsearch.values.yaml
helm upgrade --install fluent-bit stable/fluent-bit --namespace observability -f kubernetes-logging/fluent-bit.values.yaml
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx --namespace nginx-ingress -f kubernetes-logging/nginx-ingress.values.yaml
export INGRESS_EIP=$(kubectl get svc nginx-ingress-controller -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
# Update addr in kibana.values.yaml with the value and
helm upgrade --install kibana elastic/kibana --namespace observability -f kubernetes-logging/kibana.values.yaml
helm upgrade --install prometheus-operator stable/prometheus-operator --set prometheusOperator.createCustomResource=true --namespace=observability -f kubernetes-logging/prometheus-operator.values.yaml
helm upgrade --install elasticsearch-exporter stable/elasticsearch-exporter --set es.uri=http://elasticsearch-master:9200 --set serviceMonitor.enabled=true --namespace=observability

```

## Как проверить работоспособность:

```
#Goto and create kubernetes_cluster-* index pattern
open http://kibana.$INGRESS_EIP.xip.io/app/management/kibana/indexPatterns
# check logs
open http://kibana.$INGRESS_EIP.xip.io/app/discover
```

```
open http://grafana.34.76.141.66.xip.io/
#Import the following dash with prometheus as a datasource kubernetes-logging/elasticsearch_rev1.json
```

![](https://habrastorage.org/webt/1l/r-/cc/1lr-cczgkrdsbp4kopykjabuq2y.png)

## PR checklist:

- [ ] Выставлен label с темой домашнего задания
