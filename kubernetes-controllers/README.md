# Задание 3

- настроил kind
- описал и применил ReplicaSet

```
kubectl apply -f frontend-replicaset.yaml
```

- Руководствуясь материалами лекции опишите произошедшую ситуацию, почему обновление ReplicaSet не повлекло обновление запущенных pod?

ReplicaSet controller не рестартует поды и только следит за тем, чтобы объявленное количество подов было запущено в каждый момент времени. [How a ReplicationController Works](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/#how-a-replicationcontroller-works)

- описал Deployment. Произвел обновление и роллбек версии приложения, используя Deployment

Deploy

```

echo "Deploy v0.0.1"
sed -i "s/v0.0.2/v0.0.1/g" paymentservice-deployment.yaml
kubectl apply -f paymentservice-deployment.yaml
kubectl get pods -l app=frontend -w
echo "Deploy v0.0.2"
sed -i "s/v0.0.1/v0.0.2/g" paymentservice-deployment.yaml
kubectl apply -f paymentservice-deployment.yaml
kubectl get pods -l app=frontend -w
```

Rollback to v0.0.1

```
kubectl rollout undo deployment paymentservice --to-revision=1 | kubectl get rs -l app=paymentservice -w
```

- протестировал возможность использования параметров maxSurge и maxUnavailable для Blue/Green & Reverse Rolling Update

```
echo "Blue/Green"
sed -i "s/v0.0.2/v0.0.1/g" paymentservice-deployment-bg.yaml
kubectl apply -f paymentservice-deployment-bg.yaml
kubectl get pods -l app=frontend -w
```

Reverse Rolling Update

```
echo "Blue/Green"
sed -i "s/v0.0.1/v0.0.2/g" paymentservice-deployment-bg.yaml
kubectl apply -f paymentservice-deployment-reverse.yaml
kubectl get pods -l app=frontend -w
```

- проверил работу readinessProbe & livenessProbe
- установил node-exporter на master & worker nodes используя DaemonSet

```
kubectl apply -f node-exporter-daemonset.yaml
kubectl port-forward node-exporter-$sha 9100:9100
curl localhost:9100/metrics
```
