# Выполнено ДЗ №

- [x] Основное ДЗ
- [ ] Задание со \*

## В процессе сделано:

- Описал простой nginx app
- Описал Deployment,Service and ServiceMonitor для него
- Установил Prometheus and Grafana https://github.com/prometheus-operator/kube-prometheus
- Сделал дашборд на основе метрик Nginx app

## Как запустить проект:

```
minikube start --vm-driver=hyperkit --memory=4096  --disk-size=40g
minikube addons disable metrics-server
kubectl apply -f kubernetes-monitoring/nginx-deployment.yaml
kubectl apply -f kubernetes-monitoring/nginx-service.yaml
kubectl apply -f kubernetes-monitoring/manifests/setup/
kubectl apply -f kubernetes-monitoring/manifests/
kubectl apply -f kubernetes-monitoring/service-monitor.yaml
```

## Как проверить работоспособность:

```
# Check site is up and running
minikube service nginx-web --url
# Check ngnix.* related metrics are in Prometheus
kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
#Then access via http://localhost:9090/targets and check there are targets for default/nginx-mon
kubectl --namespace monitoring port-forward svc/grafana 3000
#Then access via http://localhost:3000 and use the default grafana user:password of admin:admin.
#And import the kubernetes-monitoring/dash nginx_app_dash.json
```

![](https://habrastorage.org/webt/z3/xu/ke/z3xukerthcnh7w2nrrfxwhexoco.png)

## PR checklist:

- [x] Выставлен label с темой домашнего задания
