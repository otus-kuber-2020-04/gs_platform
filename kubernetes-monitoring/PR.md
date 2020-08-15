# Выполнено ДЗ №

- [ ] Основное ДЗ
- [ ] Задание со \*

## В процессе сделано:

- Пункт 1
- Установил Prometheus and Grafana https://github.com/prometheus-operator/kube-prometheus

## Как запустить проект:

```
minikube start --vm-driver=hyperkit --memory=4096  --disk-size=40g
minikube addons disable metrics-server
kubectl apply -f ../kubernetes-monitoring/nginx-deployment.yaml
kubectl apply -f ../kubernetes-monitoring/service.yaml

#install prometheus and grafana
#minikube addons enable ingress - удалить
kubectl get pods -n kube-system
kubectl apply -f manifests/setup/
kubectl apply -f manifests/
kubectl apply -f service-monitor.yaml
```

## Как проверить работоспособность:

```
minikube service web --url
# Prometheus
kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
#Then access via http://localhost:9090
#Grafana
kubectl --namespace monitoring port-forward svc/grafana 3000
#Then access via http://localhost:3000 and use the default grafana user:password of admin:admin.
# Alert Manager
kubectl --namespace monitoring port-forward svc/alertmanager-main 9093
#Then access via http://localhost:9093

```

## PR checklist:

- [ ] Выставлен label с темой домашнего задания
