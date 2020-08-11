# Выполнено ДЗ №

- [x] Основное ДЗ
- [ ] Задание со \*

## В процессе сделано:

- Подготовил скрипт mysql-operator.py и Docker образ
- Описал CRD с валидацией и описал Deployment для оператора

## Как запустить проект:

```
minikube start --vm-driver=hyperkit --memory=4096  --disk-size=40g
kubectl apply -f kubernetes-operators/deploy/crd.yml
kubectl apply -f kubernetes-operators/deploy/service-account.yml
kubectl apply -f kubernetes-operators/deploy/role.yml
kubectl apply -f kubernetes-operators/deploy/role-binding.yml
kubectl apply -f kubernetes-operators/deploy/deploy-operator.yml
kubectl apply -f kubernetes-operators/deploy/cr.yml
```

## Как проверить работоспособность:

```
# Create DB and fill it with test data
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test (id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id));" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name) VALUES ( null, 'some data' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name) VALUES ( null, 'some data-2' );" otus-database

#kubectl delete mysqls.otus.homework mysql-instance


```

## PR checklist:

- [x] Выставлен label с темой домашнего задания

# Issues

kubectl describe mysqls.otus.homework mysql-instance
usless_data: useless info - проходит проверку

https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#publish-validation-schema-in-openapi-v2

С новым apiextensions.k8s.io/v1 валидация данных обязательна (см schema)
