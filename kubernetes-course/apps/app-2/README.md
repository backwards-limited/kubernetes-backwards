# App 2 - Pod Lifecycle

We have a deployment that shows some lifecycle events of a pod:

```bash
$ minikube start

(The following in a separate terminal)
$ kubectl get pods --watch
NAME                         READY     STATUS           RESTARTS   AGE
lifecycle-684c66d8f7-srzkx   0/1       Pending          0          0s
lifecycle-684c66d8f7-srzkx   0/1       Pending          0          0s
lifecycle-684c66d8f7-srzkx   0/1       Init:0/1         0          0s
lifecycle-684c66d8f7-srzkx   0/1       Init:0/1         0          7s
lifecycle-684c66d8f7-srzkx   0/1       PodInitializing  0          17s
lifecycle-684c66d8f7-srzkx   0/1       Running          0          31s

$ kubectl create -f app-2-deployment.yaml
deployment "lifecycle" created

$ kubectl exec -it lifecycle-684c66d8f7-srzkx -- cat /timing
1541430584: Running
1541430584: postStart
1541430594: end postStart
1541430620: readinessProbe

or
$ kubectl exec -it lifecycle-684c66d8f7-srzkx -- tail -f /timing
1541430650: readinessProbe
1541430657: livenessProbe
1541430660: readinessProbe
...
```