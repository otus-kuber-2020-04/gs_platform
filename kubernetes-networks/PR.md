# Выполнено ДЗ №5

 - [x] Основное ДЗ
 - [x] Задание со * DNS через MetalLB
 - [x] Задание со * Ingress для Dashboard
 - [x] Задание со * Canary для Ingress

## В процессе сделано:
 - 5.1 Описал Deployment
 - 5.2 Описал Service
 - 5.3 Переключил k8s в ipvs режим
 - 5.4 Установил MetalLB 
 - 5.5 Сделал CoreDNS доступным вне minikube по tcp & udp
 - 5.6 Изучил Ingress & Headless services 
 - 5.7 Ingress для Dashboard
 - 5.8 Canary для Ingress

## Как запустить проект:
- Добавление маршрута на миникуб
```
sudo route -n add 172.17.0.0/16 $(minikube ip)
```


## Как проверить работоспособность:
- Запустить minikube c hyperkit
```
minikube start --driver=hyperkit
```
- 5.2 Создание Deployment
```
kubectl apply -f web-deploy.yaml
kubectl describe deployment web
```
За выкаткой можно наблюдать через 'kubespy trace deploy' OR 'kubectl get events --watch'

- 5.2 Создание Service
```
kubectl apply -f web-svc-cip.yaml
kubectl get services
```

- 5.3 Переключил K8s в IPVS режим

```
minikube ssh
sudo su
# no iptables rules
iptables --list -nv -t nat
#Check if mode:"ipvs" and strictARP: true
kubectl --namespace kube-system edit configmap/kube-prox
#Install and check ipvsadm
toolbox
dnf install -y ipvsadm && dnf clean all
ipvsadm --list -n
```
- 5.4 Установил MetalLB
```
#Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
#Verify
kubectl --namespace metallb-system get all
#Configure announces and create addr pool
kubectl apply -f metallb-config.yaml
#Create & verify svc with type: LoadBalancer
kubectl apply -f web-svc-lb.yaml
kubectl -n metallb-system logs pod/controller-$$$ | grep ipAllocated
kubectl describe svc web-svc-lb
#Final verification
sudo route -n add 172.17.0.0/16 $(minikube ip)
#Open
http://$(LB Ingress for web-svc-lb)/index.html
```	
- 5.5 Сделал CoreDNS доступным вне minikube по tcp & udp
```
kubectl apply -f coredns/coredns-svc-lb.yaml
kubectl get services -A
dig web-svc-cip.default.svc.cluster.local @172.17.255.2 +short
``` 

- 5.6 Изучил Ingress & Headless services 
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml
curl $(kubectl get services -A | egrep "ingress-nginx.*LoadBalancer" | awk '{ print $5 }')
#Headless service
kubectl apply -f web-svc-headless.yaml
kubectl apply -f web-ingress.yaml
kubectl describe ingress/web
# Default backend shows: default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
# Which is Ok, see https://kubernetes.github.io/ingress-nginx/user-guide/default-backend/
curl http://$(kubectl get services -A | egrep "ingress-nginx.*LoadBalancer" | awk '{ print $5 }')/web/index.html
```
-  5.7 Ingress для Dashboard
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.1/aio/deploy/recommended.yaml
kubectl apply -f dashboard/dash-ingress.yaml
# Get secret for test login 
kubectl -n kube-system get secret | grep "deployment-controller-token"
kubectl -n kube-system describe secret deployment-controller-token-$$$
# Use this secret to login 

```
- 5.8 Canary для Ingress
```
kubectl apply -f canary/web-deploy.yaml
kubectl apply -f canary/web-svc-headless.yaml
kubectl apply -f canary/canary-web-ingress.yaml
# Verification step. 
# 1st curl returns HOSTNAME='web-prod-$$$'
curl -H "Host: canary-sandbox.com" http://172.17.255.3/canary-test --silent | grep HOSTNAME 
# 2nd curl with additional canary: always header returns HOSTNAME='web-canary-$$$'
curl -H "Host: canary-sandbox.com" -H "canary: always" http://172.17.255.3/canary-test --silent | grep HOSTNAME
```

## PR checklist:
 - [ ] Выставлен label с номером домашнего задания

## Вопросы

- Почему следующая конфигурация валидна, но не имеет смысла?

```
livenessProbe:
  exec:
command:
- 'sh'
- '-c'
- 'ps aux | grep my_web_server_process'
```

Если это проверка для главного процесса с PID 1, то проверка не имеет смысла. Потому что в случае его падения весь контейнер будет польность перезапущен.

- Бывают ли ситуации, когда она все-таки имеет смысл?

Возможо использование подобной проверки, если речь о дочернем процессе внутри контейнера
