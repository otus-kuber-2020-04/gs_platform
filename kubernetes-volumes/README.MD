# Выполнено ДЗ №6

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:
 - 6.1 Поставил MinIO 
 - 6.2 Сконфигурировал секреты и запустил statefulset

## Как запустить проект:

- 6.1 Установка Kind, MiniO
```
kind create cluster
kubectl cluster-info --context kind-kind
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Kuberenetes-volumes/minio-statefulset.yaml
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Kuberenetes-volumes/minio-headless-service.yaml
kubectl get statefulsets
kubectl get pods
kubectl get pvc
kubectl get pv
```

- 6.2 Диплоймент секретов и statefulset'a 
```
kubectl apply -f kubernetes-volumes/minio-secrets.yaml
kubectl apply -f kubernetes-volumes/minio-statefulset.yaml
```

## Как проверить работоспособность:
- 6.1 Проверка с помощью [mc](https://github.com/minio/mc)
```
kubectl port-forward svc/minio 9000:9000
mc config host add minio http://127.0.0.1:9000 minio minio123
mc mb minio/bucket01
mc ls minio
```
- 6.2 Проверить наличие секрета 

```
kubectl describe secret minio
kubectl describe pod minio-0
```

## PR checklist:
 - [x] Выставлен label с номером домашнего задания

