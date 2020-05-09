# Pods

Clone the course [yaml](https://github.com/naveenjoy/k8s-yaml):

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/course-yaml at ☸️ backwards.k8s.local
➜ git clone https://github.com/naveenjoy/k8s-yaml.git
```

The manifest we'll be following along with is:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ ls -las
...
16 -rw-r--r--   1 davidainslie  staff  4474  9 May 22:29 pod-nginx.yaml
```

## Kubectl

A sidebar...

**Imperative command** example:

```bash
kubectl run nginx --image nginx
```

**Imperative object configuration** examples:

```bash
kubectl create -f nginx.yaml

kubectl delete -f nginx.yaml

kubectl replace -f nginx.yaml
```

Replace (update) can be problematic - all updates must be reflected in the yaml file or they will be lost.

**Declarative object configurations** example:

```bash
kubectl apply -f nginx.yaml  # Apply a single configuration file

kubectl apply -f configs/    # Apply all configuration files inside the directory

kubectl apply -R -f configs/ # Recursively apply all configuration files inside the directory
```

Here, operations are **automatically detected** per object by kubectl.

Now, if you were to apply the following:

```bash
kubectl apply -f nginx-deploy.yaml # A kind of Deployment
```

we can then get the live object configuration with:

```bash
kubectl get -f nginx-deploy.yaml -o yaml
```

As well as **apply** the other command that you may use to change fields of a live object is **scale** e.g.

```bash
kubectl scale nginx --replicas=4 # Scale the number of Pod replicas in a ReplicaSet
```

But of course, this is an imperative command so be careful - after using it, you may want to update the **manifest** (which is another name for configuration file).

And how to delete on object?

```bash
kubectl delete -f nginx-deploy.yaml
```

## What is a Pod?

![Pod](images/pod.png)

Think of a Pod as an **environment** that **containers run in** and persists until it is deleted. Containers within a Pod **share** its **IP address** and **port space** - Containers inside a Pod communicate using the **localhost** IP address. Containers running in different Pods communicate using the Pod's unique IP address.

Pods can specify a set of **shared storage volumes** - all containers in the Pod can access these shared volumes. Kubernetes supports several types of volumes e.g.

- **emptyDir**: Data is **erased** when the Pod is removed
- **awsElasticBlockStore (AWS EBS)**: Data is **preserved** when the Pod is removed.
- **cephfs (CephFS volume)**: Data is **preserved** when the Pod is removed and also supports **multiple writers**

<u>Pods do not by themselves self-heal within Kubernetes.</u>

**Controllers** are responsible for pod replication, software roll-outs and self-healing i.e. they make Pods durable. Examples of controllers are:

- Deployment
- StatefulSet
- DaemonSet

## Create

Take a look at [pod-nginx.yaml](../k8s/pods/pod-nginx.yaml):

```yaml
apiVersion: v1                # The API version (v1 currently)
kind: Pod                     # The Kind of API resource
metadata:       
  name: nginx                 # Name of this Pod that must be unique within the namespace
spec:                         # Specification of Pod's contents - list of containers to run
  containers:                 # Start the container listing this way
    - name: nginx             # Nickname for the container in this Pod. Must be unique.
      image: nginx:1.7.9      # Name of the Docker image that Kubernetes will pull.
      ports:
        - containerPort: 80   # The port used by the container.
                              # This port is accessible from all cluster nodes. 
                              # In k8s you don't publish container ports like you do in Docker. 
      resources:
        limits:
          memory: 256Mi
          cpu: 250m
```

The following will launch one pod running nginx:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f pod-nginx.yaml
pod/nginx created
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          39s
```

To view the complete live pod configuration:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods -o yaml
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods/nginx -o wide
NAME   READY  STATUS   RESTARTS  AGE   IP           NODE
nginx  1/1    Running   0        2m26s 100.96.1.4   ip-172-20-33-58.eu-west-2.compute.internal
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc describe pods nginx
```

## Port forward

Currently the nginx pod is only accessible on the IP address 100.96.1.4 within the cluster. We can access this pod from outside the cluster via **port forwarding**.

kubectl can create a secure tunnel from some local environment it is running on (such as a VM) to the Kubernetes cluster and forward a local port on said local environment to a port on the pod. Let's forward the local port of 8080 to the port of 80 on the pod.

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc port-forward pods/nginx 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

Let's also send the above command to the background by first hitting **Ctl-Z** and the typing in **bg**:

```bash
^Z
zsh: suspended  kubectl port-forward pods/nginx 8080:80

kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local took 1m 28s
✦ ➜ bg
[1]  + continued  kubectl port-forward pods/nginx 8080:80
```

And we can access nginx with **httpie**, **curl** or **web browser**:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
✦ ➜ http localhost:8080
Handling connection for 8080
HTTP/1.1 200 OK
...
<body>
<h1>Welcome to nginx!</h1>
```

## Run command inside (nginx) Container

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local took 2s
➜ kc exec -it pod/nginx -- /bin/bash
root@nginx:/# ls
bin  boot  dev	etc  home  lib	lib64  media  mnt  opt	proc  root  run ...
```

When there are multiple containers within a pod e.g.

```bash
➜ kc exec -it pod/nginx --container nginx -- /bin/bash
```

## View Pods environment variables

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc exec pod/nginx -- env

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=nginx
KUBERNETES_PORT_443_TCP_ADDR=100.64.0.1
KUBERNETES_SERVICE_HOST=100.64.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT=tcp://100.64.0.1:443
KUBERNETES_PORT_443_TCP=tcp://100.64.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_PORT=443
NGINX_VERSION=1.7.9-1~wheezy
HOME=/root
```

And lots of other ways such as:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc exec pod/nginx -- hostname
nginx

➜ kc exec pod/nginx -- hostname -f
nginx
```

## Copy files from/to (nginx) Container

Copy the nginx index.html from the Pod into our local environment:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc cp nginx:usr/share/nginx/html/index.html index.html

➜ ls -las
...
8 -rw-r--r--   1 davidainslie  staff  612  2 May 23:06 index.html
```

Edit the file e.g. adding a **h2** with **Kubernetes**, and copy the file back to the pod:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc cp index.html nginx:usr/share/nginx/html/index.html
```

Let's check if the copy was successful:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc exec nginx -- cat /usr/share/nginx/html/index.html
...
<body>
<h1>Welcome to nginx!</h1>
<h2>Kubernetes</h2>
```

## Labels

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods --show-labels
NAME    READY   STATUS    RESTARTS   AGE   LABELS
nginx   1/1     Running   0          84s   <none>
```

Add a label:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc label pod/nginx "tier=frontend"
```

We can again "show labels", but we can get a slightly different view with:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods -L tier
NAME    READY   STATUS    RESTARTS   AGE     TIER
nginx   1/1     Running   0          5m10s   frontend
```

Let's filter by label:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods --selector="tier=frontend"
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          7m33s
```

or an equivalent command is:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods -l "tier=frontend"
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          8m47s
```

Another way for the above filter:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods --selector="tier!=backend"
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          10m
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods --selector="tier in (frontend, backend)"
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          16m
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods --selector="tier notin (tier1, tier2)"
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          17m
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods --selector="tier"
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          18m
```

Let's remove the above label:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local took 2s
➜ kc label pod/nginx "tier-"
pod/nginx labeled

➜ kc get pods --show-labels
NAME    READY   STATUS    RESTARTS   AGE   LABELS
nginx   1/1     Running   0          12m   <none>
```

We can still select (filter) for a non-existing key e.g.

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods --selector='!tier'
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          22m
```

**Noting we have to use single quotes - as yet, I do not know.**

Now follows an example of a Pod manifest with labels:

```yaml
apiVersion: v1               # The API version (v1 currently)
kind: Pod                    # The Kind of API resource
metadata:                    # Describes the Pod and its labels
  name: nginx            # Name of this Pod. A Pod's name must be unique within the namespace
  labels: # Optional. Labels are key:value pairs. Use is to group and target sets of pods.
    tier: frontend       # Tag your pods with identifying attributes that are meaningful
    app: nginx
spec:                   # Specification of Pod's contents e.g. A list of containers it will run
  containers:                # Start the container listing this way
    - name: nginx      # A nickname for the container in this Pod. Must be unique with this Pod
      image: nginx:1.7.9     # Name of the Docker image that Kubernetes will pull
      ports:
        - containerPort: 80  # The port used by the container. Accessible from all nodes.                               
      resources:
        limits:
          memory: 256Mi
          cpu: 250m
```

To **relabel** you have to include **--overwrite** e.g.

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc label pod/nginx "app=mynginx" --overwrite
```

## Update

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc describe pod/nginx
Name:         nginx
...
Containers:
  nginx:
    Container ID:   docker://21a2d45d1a3ffb5b43a7f0975f813ca073414769a535cf2054062f7935e44461
    Image:          nginx:1.7.9
```

By apply a manifest with a newer version of our (nginx) image, we update the software e.g.

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f pod-nginx-upgrade.yaml
pod/nginx configured
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local took 50s
➜ kc describe pod/nginx
Name:         nginx
...
Containers:
  nginx:
    Container ID:   docker://aceb0d80462f9cb6e889a4b6892eec8a6f149c88e0c3445e9296d0daf4ff173f
    Image:          nginx:latest
```

## Log

With nginx Pod running let's first generate some logging:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc port-forward pods/nginx 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
^Z
zsh: suspended  kubectl port-forward pods/nginx 8080:80

kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local took 7s
➜ bg
[1]  + continued  kubectl port-forward pods/nginx 8080:80

kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ http localhost:8080
Handling connection for 8080
HTTP/1.1 200 OK
...
```

and we'll have a log:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc logs pods/nginx
127.0.0.1 - - [05/May/2020:21:25:41 +0000] "GET / HTTP/1.1" 200 612 "-" "HTTPie/2.1.0" "-"
```

and to follow the logs:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc logs -f pods/nginx
127.0.0.1 - - [05/May/2020:21:25:41 +0000] "GET / HTTP/1.1" 200 612 "-" "HTTPie/2.1.0" "-"
```

To see logs from a **previous instantiation of a Pod**:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc logs --previous pods/nginx
```

## Annotate

**Labels** hold **identifying** information while **annotations** hold **non-identifying** information. The primary purpose of annotations is to assist **tools** and **libraries**. Let's add some annotations to our (nginx) pod:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc annotate pods/nginx build=two builder=joe
pod/nginx annotated
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods/nginx -o yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    build: two
    builder: joe
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"labels":{"app":"nginx","tier":"frontend"},"name":"nginx","namespace":"default"},"spec":{"containers":[{"image":"nginx:latest","name":"nginx","ports":[{"containerPort":80}],"resources":{"limits":{"cpu":"250m","memory":"256Mi"}}}]}}
...
```

We see the new annotations (and a useful one that shows how k8s performs an update via a diff).

To just see the annotations, use a **jsonpath**:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pods/nginx -o jsonpath='{.metadata.annotations}'
map[build:two builder:joe kubectl.kubernetes.io/last-applied-configuration:{"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"labels":{"app":"nginx","tier":"frontend"},"name":"nginx","namespace":"default"},"spec":{"containers":[{"image":"nginx:latest","name":"nginx","ports":[{"containerPort":80}],"resources":{"limits":{"cpu":"250m","memory":"256Mi"}}}]}}
]
```

Let's **overwrite** one of our new annotations:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc annotate pods/nginx build=3 --overwrite
```

and to remove said annotations:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc annotate pods/nginx "build-"
```

## Delete

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc delete pods/nginx
```

By default k8s initiates a graceful shutdown over 30 seconds. Upon receiving a **delete** k8s first sends a **TERM signal** to the Pod application. After 30 seconds a **kill signal** will be sent.

## Resources

- Resource **requests** are **guaranteed** by Kubernetes
- Resource **limits** are the maximum amount of CPU and Memory a container can use

![Resources](images/resources.png)

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f pod-nginx.yaml
pod/nginx created

➜ kc describe pods/nginx
Name:         nginx
...
Containers:
  nginx:
    ...
    Limits:
      cpu:     1
      memory:  512Mi
    Requests:
      cpu:        500m
      memory:     64Mi
...
QoS Class:       Burstable
```

## Liveness and Readiness probes

By using a **liveness probe** Kubelet can detect whether a process is healthy and functioning well. Most common way to check for liveness is with **HTTP GET**, though you could execute a command or open a TCP socket to the container on a specific port.

A **readiness probe** is used to detect whether a container is **ready** to receive traffic through Kubernetes **services**. A readiness probe tells Kubernetes **not to send traffic to containers until the probe is successful**.

## Volume

A Docker container's file system is **ephemeral**. Without a **Volume**, after restart a container will start with a clean state.

A **Volume** provides persistent storage to the Pod.

Take a look at [emptydir manifest](../k8s/pods/pod-nginx-emptydir.yaml).

**emptyDir** Volume type: Data stored in an emptyDir Volume only lasts for the **life of the Pod**. Data **will not** persist when the Pod is terminated and recreated. Primary use-cases of an emptyDir Volume:

- As a data cache
- As a shared storage space that syncs remotely with a Git repository
- As a temporary file sharing space between a Pod's containers

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc describe pod/nginx
Name:         nginx
...
Containers:
  nginx:
    ...
    Mounts:
      /usr/share/nginx/html from www-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-6z97t (ro)
...
Volumes:
  www-data:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
...    
```

Let's check/test the Volume:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc port-forward nginx 8080:80 &

➜ echo "nginx server running on an AWS Kubernetes cluster" > index.html

➜ kc cp index.html pod/nginx:/usr/share/nginx/html/index.html

➜ curl http://localhost:8080
```

We can **exec** onto the pod to take a look at the mount:

```bash
➜ kc exec -it pod/nginx -- /bin/bash

root@nginx:/# cat /proc/mounts
...
/dev/nvme0n1p1 /user/share/nginx/html
```

