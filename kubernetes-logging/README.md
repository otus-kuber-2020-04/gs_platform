pwd

# Выполнено ДЗ №

- [ ] Основное ДЗ
- [ ] Задание со \*

## В процессе сделано:

- Добавил в терраформ пул под инфру + taint
- Установил Hipster shop
- Установил EFK
- Установил nginx ingress

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
ccd ../
helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability -f elasticsearch.values.yaml
helm upgrade --install kibana elastic/kibana --namespace observability
helm upgrade --install fluent-bit stable/fluent-bit --namespace observability -f fluent-bit.values.yaml
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress stable/nginx-ingress --namespace -f nginx-ingress.values.yaml
export INGRESS_EIP=$(kubectl get svc nginx-ingress-controller -n nginx-ingress -o=jsonpath='{.#
# Update addr in kibana.values.yaml with the value
helm upgrade --install kibana elastic/kibana --namespace observability -f kibana.values.yaml
helm upgrade --install elasticsearch-exporter stable/elasticsearch-exporter --set es.uri=http://elasticsearch-master:9200 --set serviceMonitor.enabled=true --namespace=observability

```

## Как проверить работоспособность:

- Например, перейти по ссылке http://localhost:8080

## PR checklist:

- [ ] Выставлен label с темой домашнего задания
