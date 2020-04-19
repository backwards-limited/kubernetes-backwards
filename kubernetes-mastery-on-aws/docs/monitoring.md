# Monitoring

```bash
~/workspace/kubernetes at ☸️ backwards.k8s.local
➜ git clone https://github.com/kubernetes-sigs/metrics-server.git
```

We have to edit **metrics-server-deployment.yaml** under **metrics-server/deploy/1.8+**:

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      name: metrics-server
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      volumes:
      # mount in tmp so we can safely use from-scratch images and/or read-only containers
      - name: tmp-dir
        emptyDir: {}
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP
        - --kubelet-insecure-tls=true
        name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.1
        imagePullPolicy: Always
        volumeMounts:
        - name: tmp-dir
          mountPath: /tmp


```

Then deploy:

```bash
metrics-server/deploy/1.8+ at ☸️ backwards.k8s.local
➜ kc apply -f .
```

Or:

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

Check it is running:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s at ☸️ backwards.k8s.local
➜ kubectl get deployment metrics-server -n kube-system
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   1/1     1            1           43s
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

```bash
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl create -f prometheus-service.yaml
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

We'll follow a [tutorial](https://devopscube.com/setup-kube-state-metrics/) - After cloning the [repo](https://github.com/devopscube/kube-state-metrics-configs.git):

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

We'll follow a [tutorial](https://devopscube.com/alert-manager-kubernetes-guide/)

AlertManager is an opensource alerting system which works with Prometheus Monitoring system. Alert Manager setup has the following key configurations:

- A config map for Alert Manager configuration
- A config map for Alert Manager alert templates
- Alert Manager Deployment
- Alert Manager service to access the web UI

Note that Prometheus should have the correct Alert Manager service endpoint in its **config.yaml** which is shown below (and which we already have in the above **kubernetes-prometheus** repository that was cloned):

```yaml
alerting:
   alertmanagers:
      - scheme: http
        static_configs:
        	- targets:
          	- "alertmanager.monitoring.svc:9093"
```

Also, all alerting rules need to be present in the Prometheus config. Again in the same file we already have the following:

```yaml
rule_files:
	- /etc/prometheus/prometheus.rules
```

Create a file **alert-manager-config-map.yaml** with the following content:

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  config.yml: |-
    global:
    templates:
    - '/etc/alertmanager/*.tmpl'
    route:
      receiver: alert-emailer
      group_by: ['alertname', 'priority']
      group_wait: 10s
      repeat_interval: 30m
      routes:
        - receiver: slack_demo
        # Send severity=slack alerts to slack.
          match:
            severity: slack
          group_wait: 10s
          repeat_interval: 1m
 
    receivers:
    - name: alert-emailer
      email_configs:
      - to: demo@devopscube.com
        send_resolved: false
        from: from-email@email.com
        smarthost: smtp.eample.com:25
        require_tls: false
    - name: slack_demo
      slack_configs:
      - api_url: https://hooks.slack.com/services/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sz4Qk
        channel: '#devopscube-demo'
```

Set up the necessary **Slack alert hook**. E.g. in [Backwards Incoming WebHooks](https://backwards-limited.slack.com/apps/A0F7XDUAZ-incoming-webhooks?next_id=0) I can acquire a token to place in the above config map. Then:

```yaml
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl create -f alert-manager-config-map.yaml
```

Next, we need alert templates for all the receivers we use (email, slack etc). Create the file **alert-template-config-map.yaml** with the following content:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: alertmanager-templates
  namespace: monitoring
data:
  default.tmpl: |
    {{ define "__alertmanager" }}AlertManager{{ end }}
    {{ define "__alertmanagerURL" }}{{ .ExternalURL }}/#/alerts?receiver={{ .Receiver }}{{ end }}
    {{ define "__subject" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .GroupLabels.SortedPairs.Values | join " " }} {{ if gt (len .CommonLabels) (len .GroupLabels) }}({{ with .CommonLabels.Remove .GroupLabels.Names }}{{ .Values | join " " }}{{ end }}){{ end }}{{ end }}
    {{ define "__description" }}{{ end }}
    {{ define "__text_alert_list" }}{{ range . }}Labels:
    {{ range .Labels.SortedPairs }} - {{ .Name }} = {{ .Value }}
    {{ end }}Annotations:
    {{ range .Annotations.SortedPairs }} - {{ .Name }} = {{ .Value }}
    {{ end }}Source: {{ .GeneratorURL }}
    {{ end }}{{ end }}
    {{ define "slack.default.title" }}{{ template "__subject" . }}{{ end }}
    {{ define "slack.default.username" }}{{ template "__alertmanager" . }}{{ end }}
    {{ define "slack.default.fallback" }}{{ template "slack.default.title" . }} | {{ template "slack.default.titlelink" . }}{{ end }}
    {{ define "slack.default.pretext" }}{{ end }}
    {{ define "slack.default.titlelink" }}{{ template "__alertmanagerURL" . }}{{ end }}
    {{ define "slack.default.iconemoji" }}{{ end }}
    {{ define "slack.default.iconurl" }}{{ end }}
    {{ define "slack.default.text" }}{{ end }}
    {{ define "hipchat.default.from" }}{{ template "__alertmanager" . }}{{ end }}
    {{ define "hipchat.default.message" }}{{ template "__subject" . }}{{ end }}
    {{ define "pagerduty.default.description" }}{{ template "__subject" . }}{{ end }}
    {{ define "pagerduty.default.client" }}{{ template "__alertmanager" . }}{{ end }}
    {{ define "pagerduty.default.clientURL" }}{{ template "__alertmanagerURL" . }}{{ end }}
    {{ define "pagerduty.default.instances" }}{{ template "__text_alert_list" . }}{{ end }}
    {{ define "opsgenie.default.message" }}{{ template "__subject" . }}{{ end }}
    {{ define "opsgenie.default.description" }}{{ .CommonAnnotations.SortedPairs.Values | join " " }}
    {{ if gt (len .Alerts.Firing) 0 -}}
    Alerts Firing:
    {{ template "__text_alert_list" .Alerts.Firing }}
    {{- end }}
    {{ if gt (len .Alerts.Resolved) 0 -}}
    Alerts Resolved:
    {{ template "__text_alert_list" .Alerts.Resolved }}
    {{- end }}
    {{- end }}
    {{ define "opsgenie.default.source" }}{{ template "__alertmanagerURL" . }}{{ end }}
    {{ define "victorops.default.message" }}{{ template "__subject" . }} | {{ template "__alertmanagerURL" . }}{{ end }}
    {{ define "victorops.default.from" }}{{ template "__alertmanager" . }}{{ end }}
    {{ define "email.default.subject" }}{{ template "__subject" . }}{{ end }}
    {{ define "email.default.html" }}
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <!--
    Style and HTML derived from https://github.com/mailgun/transactional-email-templates
    The MIT License (MIT)
    Copyright (c) 2014 Mailgun
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    -->
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns="http://www.w3.org/1999/xhtml" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
    <head style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
    <meta name="viewport" content="width=device-width" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
    <title style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">{{ template "__subject" . }}</title>
    </head>
    <body itemscope="" itemtype="http://schema.org/EmailMessage" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; -webkit-font-smoothing: antialiased; -webkit-text-size-adjust: none; height: 100%; line-height: 1.6em; width: 100% !important; background-color: #f6f6f6; margin: 0; padding: 0;" bgcolor="#f6f6f6">
    <table style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; background-color: #f6f6f6; margin: 0;" bgcolor="#f6f6f6">
      <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
        <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;" valign="top"></td>
        <td width="600" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; display: block !important; max-width: 600px !important; clear: both !important; width: 100% !important; margin: 0 auto; padding: 0;" valign="top">
          <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; max-width: 600px; display: block; margin: 0 auto; padding: 0;">
            <table width="100%" cellpadding="0" cellspacing="0" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; border-radius: 3px; background-color: #fff; margin: 0; border: 1px solid #e9e9e9;" bgcolor="#fff">
              <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 16px; vertical-align: top; color: #fff; font-weight: 500; text-align: center; border-radius: 3px 3px 0 0; background-color: #E6522C; margin: 0; padding: 20px;" align="center" bgcolor="#E6522C" valign="top">
                  {{ .Alerts | len }} alert{{ if gt (len .Alerts) 1 }}s{{ end }} for {{ range .GroupLabels.SortedPairs }}
                    {{ .Name }}={{ .Value }}
                  {{ end }}
                </td>
              </tr>
              <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 10px;" valign="top">
                  <table width="100%" cellpadding="0" cellspacing="0" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                    <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                      <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;" valign="top">
                        <a href="{{ template "__alertmanagerURL" . }}" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; color: #FFF; text-decoration: none; line-height: 2em; font-weight: bold; text-align: center; cursor: pointer; display: inline-block; border-radius: 5px; text-transform: capitalize; background-color: #348eda; margin: 0; border-color: #348eda; border-style: solid; border-width: 10px 20px;">View in {{ template "__alertmanager" . }}</a>
                      </td>
                    </tr>
                    {{ if gt (len .Alerts.Firing) 0 }}
                    <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                      <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;" valign="top">
                        <strong style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">[{{ .Alerts.Firing | len }}] Firing</strong>
                      </td>
                    </tr>
                    {{ end }}
                    {{ range .Alerts.Firing }}
                    <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                      <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;" valign="top">
                        <strong style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">Labels</strong><br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
                        {{ range .Labels.SortedPairs }}{{ .Name }} = {{ .Value }}<br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />{{ end }}
                        {{ if gt (len .Annotations) 0 }}<strong style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">Annotations</strong><br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />{{ end }}
                        {{ range .Annotations.SortedPairs }}{{ .Name }} = {{ .Value }}<br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />{{ end }}
                        <a href="{{ .GeneratorURL }}" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; color: #348eda; text-decoration: underline; margin: 0;">Source</a><br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
                      </td>
                    </tr>
                    {{ end }}
                    {{ if gt (len .Alerts.Resolved) 0 }}
                      {{ if gt (len .Alerts.Firing) 0 }}
                    <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                      <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;" valign="top">
                        <br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
                        <hr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
                        <br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
                      </td>
                    </tr>
                      {{ end }}
                    <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                      <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;" valign="top">
                        <strong style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">[{{ .Alerts.Resolved | len }}] Resolved</strong>
                      </td>
                    </tr>
                    {{ end }}
                    {{ range .Alerts.Resolved }}
                    <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                      <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;" valign="top">
                        <strong style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">Labels</strong><br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
                        {{ range .Labels.SortedPairs }}{{ .Name }} = {{ .Value }}<br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />{{ end }}
                        {{ if gt (len .Annotations) 0 }}<strong style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">Annotations</strong><br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />{{ end }}
                        {{ range .Annotations.SortedPairs }}{{ .Name }} = {{ .Value }}<br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />{{ end }}
                        <a href="{{ .GeneratorURL }}" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; color: #348eda; text-decoration: underline; margin: 0;">Source</a><br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
                      </td>
                    </tr>
                    {{ end }}
                  </table>
                </td>
              </tr>
            </table>
            <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; clear: both; color: #999; margin: 0; padding: 20px;">
              <table width="100%" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                  <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 12px; vertical-align: top; text-align: center; color: #999; margin: 0; padding: 0 0 20px;" align="center" valign="top"><a href="{{ .ExternalURL }}" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 12px; color: #999; text-decoration: underline; margin: 0;">Sent by {{ template "__alertmanager" . }}</a></td>
                </tr>
              </table>
            </div></div>
        </td>
        <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;" valign="top"></td>
      </tr>
    </table>
    </body>
    </html>
    {{ end }}
    {{ define "pushover.default.title" }}{{ template "__subject" . }}{{ end }}
    {{ define "pushover.default.message" }}{{ .CommonAnnotations.SortedPairs.Values | join " " }}
    {{ if gt (len .Alerts.Firing) 0 }}
    Alerts Firing:
    {{ template "__text_alert_list" .Alerts.Firing }}
    {{ end }}
    {{ if gt (len .Alerts.Resolved) 0 }}
    Alerts Resolved:
    {{ template "__text_alert_list" .Alerts.Resolved }}
    {{ end }}
    {{ end }}
    {{ define "pushover.default.url" }}{{ template "__alertmanagerURL" . }}{{ end }}
  slack.tmpl: |
    {{ define "slack.devops.text" }}
    {{range .Alerts}}{{.Annotations.DESCRIPTION}}
    {{end}}
    {{ end }}
```

```bash
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl create -f alert-template-config-map.yaml
```

At last we can create a Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      name: alertmanager
      labels:
        app: alertmanager
    spec:
      containers:
      - name: alertmanager
        image: prom/alertmanager:v0.19.0
        args:
          - "--config.file=/etc/alertmanager/config.yml"
          - "--storage.path=/alertmanager"
        ports:
        - name: alertmanager
          containerPort: 9093
        volumeMounts:
        - name: config-volume
          mountPath: /etc/alertmanager
        - name: templates-volume
          mountPath: /etc/alertmanager-templates
        - name: alertmanager
          mountPath: /alertmanager
      volumes:
      - name: config-volume
        configMap:
          name: alertmanager-config
      - name: templates-volume
        configMap:
          name: alertmanager-templates
      - name: alertmanager
        emptyDir: {}
```

```bash
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl create -f alert-deployment.yaml
```

Finally, we need to expose the alert manager using NodePort or Load Balancer just to access the Web UI. Prometheus will talk to alert manager using the internal service endpoint:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
  namespace: monitoring
  annotations:
      prometheus.io/scrape: 'true'
      prometheus.io/path:   /
      prometheus.io/port:   '8080'
spec:
  selector: 
    app: alertmanager
  type: NodePort  
  ports:
    - port: 9093
      targetPort: 9093
      nodePort: 31000
```

```bash
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl create -f alert-service.yaml
```

Again we will have to add this port to our in-bounds rules on AWS. Then access the UI e.g.:

![Alert manager](images/alert-manager.png)

## Grafana

With Prometheus deployed we'll follow a [tutorial](https://devopscube.com/setup-grafana-kubernetes/).

First, a config map:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring
data:
  prometheus.yaml: |-
    {
        "apiVersion": 1,
        "datasources": [
            {
               "access":"proxy",
                "editable": true,
                "name": "prometheus",
                "orgId": 1,
                "type": "prometheus",
                "url": "http://prometheus-service.monitoring.svc:8080",
                "version": 1
            }
        ]
    }
```

```bash
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl create -f grafana-config-map.yaml
```

Next a deployment:

```bash
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl create -f grafana-deployment.yaml
```

Than a service:

```bash
kubernetes-prometheus at ☸️ backwards.k8s.local
➜ kubectl create -f grafana-service.yaml
```

Again add our node port (32000) to our IP rules in AWS and then access one of the cluster nodes with said port.

The Grafana default login credentials are:

User: admin

Pass: admin

You will be asked to change the password e.g "scooby".

We now need to setup a **dashboard** which can be done using a [template](https://grafana.com/grafana/dashboards?search=kubernetes) e.g. from [this template](https://grafana.com/grafana/dashboards/8588) choose the **template ID** of **8588** and import into Grafana:

![Grafana import](images/import-grafana-template.png)

After selecting (default) options:

![Grafana](images/grafana.png)