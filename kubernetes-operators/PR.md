# Выполнено ДЗ №

- [ ] Основное ДЗ
- [ ] Задание со \*

## В процессе сделано:

- Пункт 1
- Пункт 2

## Как запустить проект:

```
minikube start
kubectl apply -f deploy/crd.yml
kubectl apply -f deploy/cr.yml
```

## Как проверить работоспособность:

- Например, перейти по ссылке http://localhost:8080

## PR checklist:

- [ ] Выставлен label с темой домашнего задания

# Issues

kubectl describe mysqls.otus.homework mysql-instance
usless_data: useless info - проходит проверку

https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#publish-validation-schema-in-openapi-v2

С новым apiextensions.k8s.io/v1 валидация данных обязательна (см schema)
