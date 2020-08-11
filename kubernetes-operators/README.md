```
kubectl get jobs.batch
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           2s         5m37s
restore-mysql-instance-job   1/1           3m17s      6m49s

 export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}" | xargs)
 ~/Do/co/ot/gs_platform   kubernetes-operators                                                                                 ✔  11598  01:46:10
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database                
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

