# Выполнено ДЗ №3

- [x] Основное ДЗ
- [x] Задание со \*

## В процессе сделано:

- Задание 3.0 Настроил kind
- Задание 3.1 Описал и применил ReplicaSet. Ответил на вопрос в ниже в секции Questions from HM
- Задание 3.2 Описал Deployment. Произвел обновление и роллбек версии приложения, используя Deployment
- Задание со \* Протестировал возможность использования параметров maxSurge и maxUnavailable для Blue/Green & Reverse Rolling Update
- Задание 3.3 Проверил работу readinessProbe & livenessProbe
- Задание со \* #2 установил node-exporter на master & worker nodes используя DaemonSet

## Как запустить проект:

### Задание 3.0 Настроить kind

```
cd gs_platform/kubernetes-controllers/resources
kind create cluster --config kind_config.yaml
kubectl get nodes
```

### Задание 3.1 RelicaSet

В манифесте уже прописано три реплики

```
kubectl apply -f frontend-replicaset.yaml
```

### Заданиe 3.2

```
kubectl apply -f frontend-deployment.yaml
kubectl get deployments
kubectl get rs
```

### Задание со \*

```
kubectl apply -f paymentservice-deployment-bg.yaml
kubectl get pods --show-labels
kubectl apply -f paymentservice-deployment-reverse.yaml
kubectl get pods --show-labels
```

### Заданиe 3.3

```
kubectl rollout status deployment/paymentservice
kubectl describe deployment paymentservice
```

### Задание со \* #2

```
kubectl apply -f \*.yaml //sequentially
kubectl port-forward node-exporter-\$sha 9100:9100
```

## Как проверить работоспособность:

Расписано выше

## PR checklist:

- [*] Выставлен label с номером домашнего задания

## Questions from HM

### 3.1 Вопрос

_Руководствуясь материалами лекции опишите произошедшую ситуацию, почему обновление ReplicaSet не повлекло обновление запущенных pod?_

ReplicaSet controller не рестартует поды и только следит за тем, чтобы объявленное количество подов было запущено в каждый момент времени. [How a ReplicationController Works](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/#how-a-replicationcontroller-works)

