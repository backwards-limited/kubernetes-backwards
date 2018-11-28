# Daemon Sets

Some use cases:

- Logging aggregators

- Monitoring

- Load Balancers / Reverse Proxies / API Gateways

- Running a daemon that only needs one instance per physical instance

And here is a DaemonSet example specification:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: monitoring-agent
  namespace: kube-system
  labels:
    app: monitoring-agent
spec:
  selector:
    matchLabels:
      name: monitoring-agent
  template:
    metadata:
      labels:
        name: monitoring-agent
    spec:
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
      containers:
        - name: hello-nodejs
          image: davidainslie/hello-nodejs
          ports:
            - name: nodejs-port
              containerPort: 3000
          resources:
            limits:
              memory: 200Mi
            requests:
              cpu: 100m
              memory: 200Mi
      terminationGracePeriodSeconds: 30
```