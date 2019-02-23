# Pods

For the [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/pods/pod/):

*A pod is a group of one or more containers (such as Docker containers), with shared storage/network, and a specification for how to run the containers. A pod’s contents are always co-located and co-scheduled, and run in a shared context.*

## Deploy Pod

Let's try to create a [pod](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/#pod-v1-core) for the first docker image we encountered in the [introduction](introduction.md).

Check minikube is running:

```bash
$ minikube status
host: Running
kubelet: Running
apiserver: Running
kubectl: Correctly Configured: pointing to minikube-vm at 192.168.99.116
```

```bash
$ kubectl get all
NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
svc/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   35d
```

In directory [k8s](k8s):

```bash
$ kubectl apply -f first-pod.yml
pod "webapp" created
```

```bash
$ kubectl get all
NAME        READY     STATUS    RESTARTS   AGE
po/webapp   1/1       Running   0          29s

NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
svc/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   35d
```

## Describe Pod

```bash
$ kubectl describe pod webapp
Name:               webapp
Namespace:          default
Priority:           0
PriorityClassName:  <none>
Node:               minikube/10.0.2.15
...
```

## Exec on Pod

```bash
$ kubectl exec webapp -- ls -la
total 64
drwxr-xr-x    1 root     root          4096 Feb 23 19:39 .
drwxr-xr-x    1 root     root          4096 Feb 23 19:39 ..
-rwxr-xr-x    1 root     root             0 Feb 23 19:39 .dockerenv
drwxr-xr-x    2 root     root          4096 Jan  9  2018 bin
...
```

## Exec onto Pod

```bash
$ kubectl -it exec webapp sh
/ # wget http://localhost:80
Connecting to localhost:80 (127.0.0.1:80)
index.html           100% |********...
```

As the container we have is a basic **alpine**, curl is not available, but we can do a **wget** to download the **index.html** file from the running web server. And we can check said downloaded file:

```bash
$ / # cat index.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Fleet Management</title>
  <base href="/">

  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.png">
</head>
<body>
  <app-root></app-root>
<script type="text/javascript" src="runtime.js"></script><script type="text/javascript" src="polyfills.js"></script><script type="text/javascript" src="styles.js"></script><script type="text/javascript" src="vendor.js"></script><script type="text/javascript" src="main.js"></script></body>
</html>
```

