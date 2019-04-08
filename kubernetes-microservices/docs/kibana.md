# Kibana

```bash
$ kubectl get all --namespace kube-system
NAME                   DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR
ds/fluentd-es-v2.2.0   3         3         3         3            3           <none>

NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/dns-controller        1         1         1            1           9m
deploy/kibana-logging        1         1         1            1           1m
deploy/kube-dns              2         2         2            2           9m
deploy/kube-dns-autoscaler   1         1         1            1           9m

NAME                                DESIRED   CURRENT   READY     AGE
rs/dns-controller-547884bc7f        1         1         1         8m
rs/kibana-logging-7444956bf8        1         1         1         1m
rs/kube-dns-6b4f4b544c              2         2         2         8m
rs/kube-dns-autoscaler-6b658bd4d5   1         1         1         8m

NAME                                 DESIRED   CURRENT   AGE
statefulsets/elasticsearch-logging   2         1         1m

NAME                                                                     READY     STATUS
po/dns-controller-547884bc7f-5bc2z                                       1/1       Running
po/elasticsearch-logging-0                                               1/1       Running 
po/etcd-server-events-ip-172-20-42-159.eu-west-2.compute.internal        1/1       Running
po/etcd-server-ip-172-20-42-159.eu-west-2.compute.internal               1/1       Running
po/fluentd-es-v2.2.0-l4x9k                                               1/1       Running
po/fluentd-es-v2.2.0-lqtkt                                               1/1       Running
po/fluentd-es-v2.2.0-trcgx                                               1/1       Running
po/kibana-logging-7444956bf8-ppjnc                                       1/1       Running
po/kube-apiserver-ip-172-20-42-159.eu-west-2.compute.internal            1/1       Running
po/kube-controller-manager-ip-172-20-42-159.eu-west-2.compute.internal   1/1       Running
po/kube-dns-6b4f4b544c-lx5pn                                             3/3       Running
po/kube-dns-6b4f4b544c-vvtb8                                             3/3       Running
po/kube-dns-autoscaler-6b658bd4d5-zld2n                                  1/1       Running
po/kube-proxy-ip-172-20-113-216.eu-west-2.compute.internal               1/1       Running
po/kube-proxy-ip-172-20-32-93.eu-west-2.compute.internal                 1/1       Running
po/kube-proxy-ip-172-20-42-159.eu-west-2.compute.internal                1/1       Running
po/kube-proxy-ip-172-20-92-230.eu-west-2.compute.internal                1/1       Running
po/kube-scheduler-ip-172-20-42-159.eu-west-2.compute.internal            1/1       Running

NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP        PORT(S)
svc/elasticsearch-logging   ClusterIP      100.68.164.13   <none>             9200/TCP
svc/kibana-logging          LoadBalancer   100.69.210.38   a2350b66459fb...   5601:30080/TCP
svc/kube-dns                ClusterIP      100.64.0.10     <none>             53/UDP,53/TCP
```

Navigate (depending on your auto generated load balancer's DNS) to:

```bash
$ kubectl describe svc/kibana-logging --namespace kube-system
Name:                     kibana-logging
Namespace:                kube-system
Labels:                   addonmanager.kubernetes.io/mode=Reconcile
                          k8s-app=kibana-logging
                          kubernetes.io/cluster-service=true
                          kubernetes.io/name=Kibana
Annotations:              kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"addonmanager.kubernetes.io/mode":"Reconcile","k8s-app":"kibana-logging","ku...
Selector:                 k8s-app=kibana-logging
Type:                     LoadBalancer
IP:                       100.69.210.38
LoadBalancer Ingress:     a2350b66459fb11e9855c067b740ebfc-236427576.eu-west-2.elb.amazonaws.com
```

```
a23cf48dd59fb11e9855c067b740ebfc-221616907.eu-west-2.elb.amazonaws.com:5601/app/kibana
```

![Kibana](images/kibana.png)

Even though we are using **fluentd** there is an index automatically generated that begins with **logstash** and today's date as a suffix (so we'd get a new index tomorrow with tomorrow's date).

![Index](images/index.png)

Fluentd with automatically add a timestamp for each log:

![With timestamp](images/index-with-timestamp.png)

---

![Gathering logs](images/gathering-logs.png)

Click on **Discover** to access the *Kibana search engine* and we'll initially see *all logs*:

![All logs](images/all-logs.png)