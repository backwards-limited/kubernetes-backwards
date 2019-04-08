# Prometheus

```bash
$ helm install stable/prometheus-operator --name monitoring --namespace monitoring
```

```bash
$ kubectl get all --namespace monitoring
```

Prometheus gathers all data for monitoring (Grafana merely makes is all pretty).

Let's take a look at the Prometheus UI by first exposing it (initially it has a ClusterIP):

```bash
$ kubectl edit service/monitoring-prometheus-oper-prometheus --namespace monitoring
```

Change **type** to **LoadBalancer**.

```bash
$ kubectl get all --namespace monitoring
...
NAME                                       TYPE         CLUSTER-IP  EXTERNAL-IP  PORT(S)
...
svc/monitoring-prometheus-oper-prometheus  LoadBalancer  100.67.104.43  ad..  9090:31792/TCP
...
```

To get the **complete external IP**:

```bash
$ kubectl get all --namespace monitoring -o wide

NAME                                          TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)
svc/monitoring-prometheus-oper-prometheus     LoadBalancer   100.67.104.43    adc4168fc5a2411e986a1064cd962d7e-2074528455.eu-west-2.elb.amazonaws.com   9090:31792/TCP
```



