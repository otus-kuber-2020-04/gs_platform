- Добавление проверок Pod
  > Почему следующая конфигурация валидна, но не имеет смысла?

```
livenessProbe:
  exec:
command:
- 'sh'
- '-c'
- 'ps aux | grep my_web_server_process'
```

Если это проверка для главного процесса с PID 1, то проверка не имеет смысла. Потому что в случае его падения весь контейнер будет польность перезапущен.

> Бывают ли ситуации, когда она все-таки имеет смысл?

Возможо использование подобной проверки, если речь о дочернем процессе внутри контейнера

# MetalLB || Проверка конфигурации

Добавление маршрута на миникуб

```
sudo route -n add 172.17.0.0/16 $(minikube ip)
```

[Про ipvs](https://kubernetes.io/blog/2018/07/09/ipvs-based-in-cluster-load-balancing-deep-dive/)


# Про OpenResty
```
In a relatively big clusters with frequently deploying apps this feature saves significant number of Nginx reloads which can otherwise affect response latency, load balancing quality (after every reload Nginx resets the state of load balancing) and so on.
```


