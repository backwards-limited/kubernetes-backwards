# Monitoring

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s at ☸️ backwards.k8s.local took 4s
➜ kc top node
Error from server (NotFound): the server could not find the requested resource (get services http:heapster:)
```

Ok, so we need to deploy [metrics server](https://github.com/kubernetes-sigs/metrics-server):

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s at ☸️ backwards.k8s.local
➜ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
```

Try again:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s at ☸️ backwards.k8s.local
➜ kc top node
error: metrics not available yet
```

## Prometheus

![Prometheus architecture](images/prometheus-architecture.png)

- The Prometheus **server** scrapes and stores metrics. Note that it uses a **persistence** layer.
- The web **UI** allows you to access, visualize, and chart the stored data. Prometheus provides its own UI, but you can also configure other visualization tools, like [Grafana](https://grafana.com/), to access the Prometheus server using PromQL (the Prometheus Query Language).
- **Alertmanager** sends alerts from client applications, especially the Prometheus server.

Kinds of **metrics** Prometheus supports:

- **Counter**: A cumulative metric that represents a single monotonically increasing counter whose value can only **increase** or be **reset** to zero on restart. For example, you can use a counter to represent the number of requests served, tasks completed, or errors.
- **Gauge**: A metric that represents a single numerical value that can arbitrarily go up and down. Gauges are typically used for measured values like [CPU] or current memory usage, but also 'counts' that can go up and down, like the number of concurrent requests.
- **Histogram**: Samples observations (usually things like request durations or response sizes) and counts them in configurable buckets. It also provides a sum of all observed values. This makes it an excellent candidate to track things like latency that might have a service level objective (SLO) defined against it - See the example below.
- **Summary**: samples observations (usually things like request durations and response sizes). While it also provides a total count of observations and a sum of all observed values, it calculates configurable quantiles over a sliding time window.

**Histogram Example**:

You might have an SLO to serve 95% of requests within 300ms. In that case, configure a histogram to have a bucket with an upper limit of 0.3 seconds. You can then directly express the relative amount of requests served within 300ms and easily alert if the value drops below 0.95. The following expression calculates it by job for the requests served in the last 5 minutes. The request durations were collected with a histogram called **http_request_duration_seconds**:

```mathematica
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m])) by (job) /
                         sum(rate(http_request_duration_seconds_count[5m])) by (job)
```

We'll follow a [tutorial](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/) - After cloning the [repo](https://github.com/bibinwilson/kubernetes-prometheus):

```bash
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl create namespace monitoring
namespace/monitoring created

➜ kubectl create -f clusterRole.yaml
clusterrole.rbac.authorization.k8s.io/prometheus created
clusterrolebinding.rbac.authorization.k8s.io/prometheus created

➜ kubectl create -f config-map.yaml
configmap/prometheus-server-conf created

➜ kubectl create  -f prometheus-deployment.yaml
deployment.apps/prometheus-deployment created

➜ kubectl get deployments --namespace=monitoring
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
prometheus-deployment   1/1     1            1           15s

➜ kubectl get pods --namespace=monitoring
NAME                                     READY   STATUS    RESTARTS   AGE
prometheus-deployment-77cb49fb5d-4sgtf   1/1     Running   0          40s

➜ kubectl port-forward prometheus-deployment-77cb49fb5d-4sgtf 8080:9090 -n monitoring
```

and goto [http://localhost:8080](http://localhost:8080):

![Prometheus UI](images/prometheus-ui.png)

E.g. **machine_memory_bytes**:

![Machine memory bytes](images/machine-memory-bytes.png)

To access the Prometheus dashboard over a IP or a DNS name, you need to expose it as Kubernetes service. The following uses a NodePort, but we could change to LoadBalancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
  annotations:
      prometheus.io/scrape: 'true'
      prometheus.io/port:   '9090'
spec:
  selector: 
    app: prometheus-server
  type: NodePort  
  ports:
    - port: 8080
      targetPort: 9090 
      nodePort: 30000
```

Once created, you can access the Prometheus dashboard using any Kubernetes node IP on port 30000. If you are on the cloud, make sure you have the right firewall rules for accessing the apps.

![Manage IP addresses](images/manage-ip-addresses.png)

![Port 30000](images/port-30000.png)

You can always delete the monitoring namespace and thus Prometheus objects with:

```bash
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl delete namespace monitoring
```

## Kube State Metrics

We'll follow a [tutorial](https://devopscube.com/setup-kube-state-metrics/) - - After cloning the [repo](https://github.com/devopscube/kube-state-metrics-configs.git):

[Kube State metrics](https://github.com/kubernetes/kube-state-metrics) is s service which talks to Kubernetes API server to get all the details about all the API objcts like [deployments](https://devopscube.com/kubernetes-deployment-tutorial/), pods, daemonsets etc. Basically it provides kubernetes API object metrics which you cannot get directly from native Kubernetes monitoring components.

Kube state metrics service exposes all the metrics on `/metrics` URI. [Prometheus](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/) can scrape all the metrics exposed by kube state metrics. Here are the few key objects you can monitor with kube state metrics:

- Monitor node status, node capacity (CPU and memory)
- Monitor replica-set compliance (desired/available/unavailable/updated status of replicas per deployment)
- Monitor pod status (waiting, running, ready, etc)
- Monitor the resource requests and limits
- Monitor Job & Cronjob Status

Kube state metrics is available as a [public docker image](https://quay.io/repository/coreos/kube-state-metrics?tag=v1.8.0&tab=tags). You will have to deploy the following Kubernetes objects for kube state metrics to work:

- A Service Account
- Cluster Role – For kube state metrics to access all the Kubernetes API objects
- Cluster Role Binding – Binds the service account with the cluster role
- Kube State Metrics Deployment
- Service – To expose the metrics

```bash
kube-state-metrics-configs at ☸️ backwards.k8s.local
➜ kubectl apply -f .
clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics created
clusterrole.rbac.authorization.k8s.io/kube-state-metrics created
deployment.apps/kube-state-metrics created
serviceaccount/kube-state-metrics created
service/kube-state-metrics created
```

```bash
kube-state-metrics-configs at ☸️ backwards.k8s.local took 2s
➜ kubectl get deployments kube-state-metrics -n kube-system
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
kube-state-metrics   1/1     1            1           44s
```

All the kube static metrics can be obtained from the kube state service endpoint on `/metrics` URI.

This configuration can be added as part of prometheus job configuration. You need to add the following job configuration to your prometheus config for prometheus to scrape all the kube state metrics - which we already have in our Prometheus setup (above).

## Alert Manager

TODO

## Grafana

TODO