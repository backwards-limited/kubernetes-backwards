# Grafana

First change prometheus back to using a ClusterIP instead of LoadBalancer (to save money), which will include removing the nodePort:

```bash
$ kubectl edit service/monitoring-prometheus-oper-prometheus --namespace monitoring
```

Then switch the Grafana manifest to using a LoadBalancer instead of a ClusterIP:

```bash
$ kubectl edit service/monitoring-grafana --namespace monitoring
```

![Grafana login](images/grafana-login.png)

Use the default user / password of **admin / prom-operator** for the helm chart, which can be overridden.

![Grafana dashboard](images/grafana-dashboard.png)

View more dashboards from the **Home** dropdown:

![Grafana more dashboards](images/grafana-more-dashboards.png)

---

![View pod](images/grafana-view-pod.png)

Let's take a look at the whole cluster:

![Grafana cluster](images/grafana-cluster.png)

---

![Grafana cluster dashboard](images/grafana-cluster-dashboard.png)