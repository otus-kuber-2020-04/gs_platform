# Выполнено ДЗ №3

- [x] Основное ДЗ

## В процессе сделано:

- Задание 4.0 Создал аккаунт с ролью admin для всего кластера и создал второй аккаунт без доступа к кластеру
- Задание 4.1 Создал NS prometheus и service account. Всем Service account в NS Prometheus дал возможность делать get, list, watch в отношении Pod всего кластреа
- Задание 4.2 Создал service accounts в рамках одного NS с разными ролями - admin & ken

## Как запустить проект:

- kubectl apply -f 0\{d}.\*.yaml //sequentially

## Как проверить работоспособность:

```
kubectl apply -f test-pod.yaml
```

В каждой директории с заданием есть test-pod.yaml, который нужно диплоить в проверяемый namespace и тогда можно легко проверять права ч/з `<kubectl exec -it curl-ken -c main curl localhost:8001/api/v1/namespaces/dev/pods>`

## PR checklist:

- [*] Выставлен label с номером домашнего задания
