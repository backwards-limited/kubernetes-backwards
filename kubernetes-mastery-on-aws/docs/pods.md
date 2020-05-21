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
➜ bg
[1]  + continued  kubectl port-forward pods/nginx 8080:80
```

And we can access nginx with **httpie**, **curl** or **web browser**:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ http localhost:8080
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

## Volumes

A Docker container's file system is **ephemeral**. Without a **Volume**, after restart a container will start with a clean state.

A **Volume** provides persistent storage to the Pod.

## emptyDir Volume

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

## hostPath Volume

The **hostPath** Volume **mounts a file or directory** from the host node's filesystem into the Pod.

Any arbitrary location on the node can be mounted into the container e.g. running **cAdvisor** in a container needs access to **/sys** directory.

Take a look at [hostpath manifest](../k8s/pods/pod-ubuntu-hostpath.yaml).

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f pod-ubuntu-hostpath.yaml
pod/hostpath-test created

➜ kc exec -it pod/hostpath-test -- /bin/bash
root@hostpath-test:/# ls /var/run/docker.sock
/var/run/docker.sock
```

Now we'll use **curl** to talk to Docker to list containers:

```bash
root@hostpath-test:/# apt-get update && apt-get install -y curl
```

```bash
root@hostpath-test:/# curl --unix-socket /var/run/docker.sock -H 'Content-Type: application/json' http://localhost/containers/json

[{"Id":"4edef502a2cce579e500c1493bc810ed11dad7c3b4131d5074f13fb8d85d9d56","Names":["/k8s_ubuntu_hostpath-test_default_a43a19c2-6e1c-44e7-9324-a11efb54ae5f_0"],"Image":"ubuntu@sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209","ImageID":"sha256:005d2078bdfab5066ae941cea93f644f5fd25521849c870f4e1496f4526d1d5b","Command":"/bin/bash -c -- 'while true; do sleep 10; done;'","Created":1589122950,"Ports":[],"Labels":{"annotation.io.kubernetes.container.hash":"81bad010","annotation.io.kubernetes.container.restartCount":"0","annotation.io.kubernetes.container.terminationMessagePath":"/dev/termination-log","annotation.io.kubernetes.container.terminationMessagePolicy":"File","annotation.io.kubernetes.pod.terminationGracePeriod":"30","io.kubernetes.container.logpath":"/var/log/pods/default_hostpath-test_a43a19c2-6e1c-44e7-9324-a11efb54ae5f/ubuntu/0.log","io.kubernetes.container.name":"ubuntu","io.kubernetes.docker.type":"container","io.kubernetes.pod.name":"hostpath-test","io.kubernetes.pod.namespace":"default","io.kubernetes.pod.uid":"a43a19c2-6e1c-44e7-9324-a11efb54ae5f","io.kubernetes.sandbox.id":"b902509005a9d8ca83a23c26424baedda160ec211d61f90a692a626a61795ac9"},"State":"running","Status":"Up 6 minutes","HostConfig":{"NetworkMode":"container:b902509005a9d8ca83a23c26424baedda160ec211d61f90a692a626a61795ac9"}
...
```

## AWS Dynamic Persistent EBS Volume

- The **awsElasticBlockStore** volume type mounts an **AWS EBS** volume into the Pod
- The AWS EBS volume can persist data independent of a Pod's lifetime
- An EBS volume can be **pre-populated** with data
- The data can be **handed off** between Pods as they move from one k8s node (i.e. an EC2 instance) to another

To provision an EBS volume **dynamically** for your Pod, you'll need to first create an object of kind **StorageClass**.

Next, refer to the StorageClass inside an object of kind **PersistentVolumeClaim**. The PVC will use the StorageClass to dynamically provision the EBS volume.

![Dynamic AWS Volume Provisioning](images/dynamic-aws-volume.png)

So first create the StorageClass using [aws-ebs-storageclass.yaml](../k8s/pods/aws-ebs-storageclass.yaml):

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard-aws-ebs            # Users request a particular Storage class
provisioner: kubernetes.io/aws-ebs  # Determines the volume plugin used for provisioning PVs
parameters:
  type: gp2                         # General purpose SSD backed Volume Type in AWS EBS
reclaimPolicy: Delete               # Set to either Delete (default) or Retain
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f aws-ebs-storageclass.yaml
storageclass.storage.k8s.io/standard-aws-ebs created
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get sc
NAME               PROVISIONER             AGE
default            kubernetes.io/aws-ebs   48m
gp2 (default)      kubernetes.io/aws-ebs   48m
standard-aws-ebs   kubernetes.io/aws-ebs   34s
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc describe sc standard-aws-ebs
Name:            standard-aws-ebs
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"standard-aws-ebs"},"parameters":{"type":"gp2"},"provisioner":"kubernetes.io/aws-ebs","reclaimPolicy":"Delete"}

Provisioner:           kubernetes.io/aws-ebs
Parameters:            type=gp2
AllowVolumeExpansion:  <unset>
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

Now we need to create a Persistent Volume Claim where our manifest is [aws-ebs-persistent-volume-claim.yaml](../k8s/pods/aws-ebs-persistent-volume-claim.yaml):

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
	# This claim results in an AWS SSD Persistent Disk being automatically provisioned
  name: aws-ebs-claim
spec:
	# Volume can be mounted as read-write by a single node (only option supported in AWS EBS)
  accessModes:
    - ReadWriteOnce
  # This links this PersistentVolumeClaim Object to the AWS Storage Class
	# This name must match the AWS Storage Class
	storageClassName: standard-aws-ebs
  resources:
    requests:
    	# 1GB volume is requested from AWS
      storage: 1Gi
```

Note when replicating a stateful Pod (such as MySql) they will require their own unique PersistentVolumeClaim object. So you will need a PersistentVolumeClaim template to be used by each **replica** - this is used in conjunction with a **StatefulSet**.

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f aws-ebs-persistent-volume-claim.yaml
persistentvolumeclaim/aws-ebs-claim created
```

```
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get pvc
NAME            STATUS   VOLUME                                     CAPACITY   STORAGECLASS
aws-ebs-claim   Bound    pvc-7cfac39a-e1a9-4a44-9c63-e2b920451cb8   1Gi        standard-aws-ebs
```

and we can also see said volume in AWS console:

![Dynamic volume](images/dynamic-volume.png)

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc describe pvc aws-ebs-claim
Name:          aws-ebs-claim
Namespace:     default
StorageClass:  standard-aws-ebs
Status:        Bound
Volume:        pvc-7cfac39a-e1a9-4a44-9c63-e2b920451cb8
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/aws-ebs
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Mounted By:    <none>
Events:
  Type    Reason                 Age    From                         Message
  ----    ------                 ----   ----                         -------
  Normal  ProvisioningSucceeded  6m29s  persistentvolume-controller  Successfully provisioned volume pvc-7cfac39a-e1a9-4a44-9c63-e2b920451cb8 using kubernetes.io/aws-ebs
```

So now we want to mount this (available) volume into our Pod, where the pod manifest using the pvc is [pod-nginx-volume-ebs-dynamic.yaml](../k8s/pods/pod-nginx-volume-ebs-dynamic.yaml):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    tier: frontend
    app:  nginx
  annotations:
    description: Nginx container with an AWS EBS Persistent Volume
spec:
  volumes:
    - name: aws-ebs              # Name of the AWS EBS Volume 
      persistentVolumeClaim:     # Pods access dynamic AWS storage by using claim as a volume
        claimName: aws-ebs-claim # Must match name of AWS Persistent Volume Claim we created
  containers:
    - name: nginx
      image: nginx:1.13.8
      volumeMounts:
        - mountPath: /usr/share/nginx/html # Mount path within the container
          name: aws-ebs                    # Name must match the AWS EBS volume name
      ports:
        - containerPort: 80
      resources:
        requests:
          cpu: "500m"
          memory: "64Mi"
        limits:
          cpu: "1"
          memory: "512Mi"
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f pod-nginx-volume-ebs-dynamic.yaml
pod/nginx created
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc describe pod/nginx
Name:         nginx
...
Volumes:
  aws-ebs:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim
...    
Events:
  Message
  -------
  AttachVolume.Attach succeeded for volume "pvc-7cfac39a-e1a9-4a44-9c63-e2b920451cb8"
```

and now we see the volume "in use":

![Dynamic volume in use](images/dynamic-volume-in-use.png)

To test the persistence we can copy a new index.html into the pod:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc cp index.html nginx:/usr/share/nginx/html/index.html

➜ kc port-forward nginx 8080:80 &
[1] 30712
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80

➜ http localhost:8080
HTTP/1.1 200 OK
...
nginx server running on an AWS Kubernetes cluster
```

We delete and then recreate the Pod:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc delete pod/nginx
pod "nginx" deleted

➜ kc apply -f pod-nginx-volume-ebs-dynamic.yaml
pod/nginx created

# Kill previous port fowarding
➜ pkill kc

➜ kc port-forward nginx 8080:80 &
[2] 31504

➜ http localhost:8080
HTTP/1.1 200 OK
...
nginx server running on an AWS Kubernetes cluster
```

Finally we can cleanup:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc delete pod/nginx
pod "nginx" deleted

➜ kc delete pvc/aws-ebs-claim
persistentvolumeclaim "aws-ebs-claim" deleted
```

and the claim will have gone in the AWS console.

And lastly:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc delete sc/standard-aws-ebs
storageclass.storage.k8s.io "standard-aws-ebs" deleted
```

## Volume Sharing with Multi-Container Pod

![Multi container pod](images/multi-pod.png)

We create the above with [pod-nginx-multi.yaml](../k8s/pods/pod-nginx-multi.yaml):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    tier: frontend
    app:  nginx
  annotations:
    description: Multiple containers in pod sharing a volume
spec:
  volumes:                                 # Define the volumes available to your containers
    - name: www-data-share                 # Name of the Volume 
      emptyDir: {}                         # EmptyDir type for sharing data between containers
  containers:
    # First container in the Pod
    - name: nginx
      image: nginx:1.13.8
      volumeMounts:
        - mountPath: /usr/share/nginx/html # Mount path inside the container
          name: www-data-share             # Name must match the volume name defined above
          readOnly: true                   # nginx can only read data from this volume
      ports:
        - containerPort: 80
    # Second Container - Syncs a Git Repo
    - name: git-sync
      image: openweb/git-sync:0.0.1
      volumeMounts:
        - mountPath: /usr/share/nginx/html  # Mount path within the second container
          name: www-data-share              # The same volume is mounted by both containers
      env:
        - name: GIT_SYNC_REPO               # GIT Repo to Sync 
          value: "https://github.com/naveenjoy/naveenjoy.github.io.git"
        - name: GIT_SYNC_DEST               # Destination is the shared volume
          value: "/usr/share/nginx/html" 
        - name: GIT_SYNC_BRANCH             # Sync the master branch
          value: "master"
        - name: GIT_SYNC_REV
          value: "FETCH_HEAD"
        - name: GIT_SYNC_WAIT               # Sync every 10 seconds
          value: "10"
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f pod-nginx-multi.yaml
```

To view the logs of just one container (such as git-sync):

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get all
NAME        READY   STATUS    RESTARTS   AGE
pod/nginx   2/2     Running   0          11s

➜ kc logs -f pod/nginx --container git-sync
2020/05/17 14:22:18 clone "https://github.com/naveenjoy/naveenjoy.github.io.git": Cloning into '/usr/share/nginx/html'...
2020/05/17 14:22:19 fetch "master": From https://github.com/naveenjoy/naveenjoy.github.io
 * branch            master     -> FETCH_HEAD
2020/05/17 14:22:19 reset "FETCH_HEAD": HEAD is now at 1bf64e0 Delete img.png
2020/05/17 14:22:19 wait 10 seconds
2020/05/17 14:22:29 done
2020/05/17 14:22:29 fetch "master": From https://github.com/naveenjoy/naveenjoy.github.io
...
```

And we can see if the web server does indeed pick up files pulled by the git image:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc port-forward pod/nginx 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
^Z
zsh: suspended  kubectl port-forward pod/nginx 8080:80

kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods on  master [!+] at ☸️ backwards.k8s.local took 2s
✦ ➜ bg
[1]  + continued  kubectl port-forward pod/nginx 8080:80

➜ http localhost:8080
HTTP/1.1 200 OK
...
Hello, Welcome to Kubernetes on AWS Git-Sync Demo
```

## Secrets

Some data to store inside a secret:

- TLS Data (key, certificate)
- Username / Password
- OAuth tokens
- Private keys

3 steps to creating and consuming secrets:

1. Assemble the raw data file(s) you want to store inside the secret object e.g. TLS key file, username file, password file, token file. You would e.g. put the TLS key in one file and the certificate in another file. Or one file to contain username and another file to contain password i.e. place one secret data item inside a file.
2. Create the secret object. Use **kubectl create secret <name of secret>** command with the data files provided as arguments. You can also create secret inside **yaml** (or **json**) file, and then use said file to create the secret - when doing this, the secret data must be base64 encoded. It is preferable to use the **create secret** command.
3. Consume the secret inside your application either:
   - Mount the secret as a data volume (**secrets volume**) OR
   - Expose it as environment variables inside the container.

## ConfigMap

```bash
➜ kc create configmap <map-name> <data-source>
```

The **data source** is specified as **key value pairs**.

ConfigMaps are consumed inside a container by mounting as a **configMap volume** OR exposing as **environment variables**.

When a ConfigMap already being consumed by a Pod is updated, the projected keys are eventually updated inside the Pod. Though you must first create a ConfigMap before a Pod can use it.

## Secret and ConfigMap Example - Setup Nginx to Serve HTTPS

- Enable TLS on nginx Pod to serve HTTPS connections
- Use a Secret to expose sensitive data (key & certificate) inside the container
- Use a ConfigMap to expose the nginx config file inside the container

First generate key and certificate:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -subj '/CN=localhost' -out cert.pem
Generating a 2048 bit RSA private key
..+++
.........+++
writing new private key to 'key.pem'
-----

➜ ls -las
...
 8 -rw-r--r--   1 davidainslie  staff   977 21 May 20:59 cert.pem
 8 -rw-r--r--   1 davidainslie  staff  1704 21 May 20:59 key.pem
```

View the certificate:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ openssl x509 -text -noout -in cert.pem
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 13816641977533366620 (0xbfbe92acc3a0815c)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=localhost
...        
```

Now create the Secret:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc create secret generic ssl-secret --from-file=ssl-key=key.pem --from-file=ssl-cert=cert.pem
secret/ssl-secret created
```

Let's check the created Secret:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get secrets
NAME                  TYPE                                  DATA   AGE
default-token-jwtst   kubernetes.io/service-account-token   3      20m
ssl-secret            Opaque                                2      56s

kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods on  master [!] at ☸️ backwards.k8s.local
➜ kc describe secret/ssl-secret
Name:         ssl-secret
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
ssl-key:   1704 bytes
ssl-cert:  977 bytes
```

Note the number of bytes are the same as viewed on the file system.

And to view the Secret (in base64 encoding):

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc get secret/ssl-secret -o yaml
apiVersion: v1
data:
  ssl-cert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNwRENDQVl3Q0NRQy92cEtzdzZDQlhEQU5CZ2txaGtpRzl3MEJBUXNGQURBVU1SSXdFQVlEVlFRRERBbHMKYjJOaGJHaHZjM1F3SGhjTk1qQXdOVEl4TVRrMU9UTTBXaGNOTWpFd05USXhNVGsxT1RNMFdqQVVNUkl3RUFZRApWUVFEREFsc2IyTmhiR2h2YzNRd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUMxCjZzQTdXejY4Vlg4aDJaTFpnYVQ3YUpITTdDUWtNS05Bc0VVQTVDSFIzd05EQXI3bkxxL0VmVkY0d2NmK1hNUU0KVTVtTk1IVFdmTHN1bHA5NzZHbnpqSmMwMkVaMStwSTZGbEZjaEhaZlFGUHlVK0RPNU9Md3RnRE8wY3VwRmVQZAo3cWpWOVVwbWR5TEsrRG5PVE1ITFI1V1RScWtDSW1YSWozS2pVSjI2VUd6K1VMV0p2WHplM1VXNzJHTGYrSGVlCisydU13MnRQUXBqWWFEaHFZVS90eXZ6alFZTUVXOEM5Tmp0WDYyblZxVVppUFRBTmNEQS9XSmVVOVJ6NU03Q28KbzY1a1B3ZS9nanVZSzU2RUVDRGlPcTJVZGlHREhOOFhtWDZHdjdBd0V4R05wYVJOdE9YYVdMVGJsYlhKM0dtVwpzYmFGRlhGYnE3b2xPODNrRXlqVkFnTUJBQUV3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCQUlodHpUM2F3NEZICmFPR3A5SndvT1ppVEsyVWJrSSt1cllKWTkyV29TY3VSaDZTVUkvMmx1Y0I0TUJEL2hhQnppU2lwSnVBZEZsQzIKN2M2OWwvTnFxZkdiNGc1bHJxdkFqbE1FdytLZVVMNG1sc3pkeTNMMFNNKzJuTUovTUMyVnNVSWlyRGU1V3NocwpmbWpBME1uajBMcSs4QXEwNWlXWXJRLytHaUVLNEZmK2NtZmJTY1NBZ0lKREFwVHZFVFA4TndJeGkxb2IwRnFxCkt4cWU5ZndRdnBvQ1dxQWNxc01TRS9ydnhkUDlwTWNhV1hBZDNydENteWxNNVZZN2NJakZjN2ZBZFVQNHdIeUMKNHozc1FjUEhDODA1YUpVcHBia2pQL0lldUNaaWllNUtYKzlwQ05ibk5sYk15Y1FnNTdFQnViTnQreW01V2xhRQpwUlZUWW0waDJQQT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  ssl-key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2Z0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktnd2dnU2tBZ0VBQW9JQkFRQzE2c0E3V3o2OFZYOGgKMlpMWmdhVDdhSkhNN0NRa01LTkFzRVVBNUNIUjN3TkRBcjduTHEvRWZWRjR3Y2YrWE1RTVU1bU5NSFRXZkxzdQpscDk3NkduempKYzAyRVoxK3BJNkZsRmNoSFpmUUZQeVUrRE81T0x3dGdETzBjdXBGZVBkN3FqVjlVcG1keUxLCitEbk9UTUhMUjVXVFJxa0NJbVhJajNLalVKMjZVR3orVUxXSnZYemUzVVc3MkdMZitIZWUrMnVNdzJ0UFFwalkKYURocVlVL3R5dnpqUVlNRVc4QzlOanRYNjJuVnFVWmlQVEFOY0RBL1dKZVU5Uno1TTdDb282NWtQd2UvZ2p1WQpLNTZFRUNEaU9xMlVkaUdESE44WG1YNkd2N0F3RXhHTnBhUk50T1hhV0xUYmxiWEozR21Xc2JhRkZYRmJxN29sCk84M2tFeWpWQWdNQkFBRUNnZ0VCQUk2Vmc3eENSVWJLWUU0QXdhZjNoSCtGTTVvQmtFWkpWUHV6N1RISW5YVm8Kclo3TlBTSG9KdDRFTjJKRnlHSm5CVWFBRS85azluN1Mzc2VpU1RpT0x0VTA0YU1LelJkVm9WMGo5dnRqMjMvRwo1TVV2MXlseW55bDZEZUlNNytzRWZFaUw4Z3RaS2Nwc0lIb2oydk1HbUhLakZlcU1YSldPcm1abmdMdmV5UEdwCkc0TkRoMFVZbDM3OE5UVkdaNlEzTTYvMGlNd2YyTUc4U2pJSUVQQlhycEVUaFoyUzJHdE9TeHhXaHFZalRjeDYKZTQrUjRxSTZkdW5KbXBubmFmZ2E0RU9jNEk0dC9SOTNPYkZMZFBMYU9EbjNwRGxmY1hKTnpKdFFvUk8yTkkyawpMbkFhdFZUQ3A3Snp4ekJJaUlGb05va1pyYk9pb0c5eEFydGpSUDhCMGlFQ2dZRUEzbHpCNmJndndDR2E0SWk0CldubWlCNG9FMk80M0tDbElDSkJFKyt3dzFPTXU1bEtiQjNSNDkyZnowRTdGUlhzNVdKYzNGbndZdCtmajQ4UzYKeS9sZ2phWndpcllzVEEyRzlBb1plNlhRb3A2bHVuZ0VoSmdHcnNZVGpWQklCeFg2ZWhZcjVEQzZ4eVkwNCtvbgpSOXVvVDgzVkpvZ01Zd3VERW1kMFU0VnptNDBDZ1lFQTBXK3pRU3cwSkR2YzVvQWtEMkpGamFvajkwWFJyN3MwCjhFUmc2NVcwWHZNRUo3NVlEdm00M0hLU0ZwdVl0L2FBZEd4MXhRWGZBSmRJKzZsWU5GMTRWMCtBZmNHQnp6TUkKck02ZW0xZjVvcnZ1RVdtR0tDZkpsc3NybGNKbEJTQ21xR3VEalNIVGgwMU5qb3lockY5QzI1Mm14TmJuTWkwQgptTVh0ZU4rRXpHa0NnWUJJbHBzdXd0UERzclN1YTdOU3hiWWhJK3NsTGM2UHE3bzZJVzZEbHJ6eUloK2pUSUFUClZQQlFRMzBTR1VUSXc4c2FvbkozUXBlSElZb0JScTE3L0xLS1N6VWQ4dzVPM1hPYW90bGl4ZVJ2MGI1a090MnUKc3pvclA3b09QWkRsejBUdktlRzJJam8yM01BVFR0TDM0RHIzb2tmY3hqalU5R01iVk81aWZZUVoyUUtCZ0RGYwpXQzBtRSt2dVIvUHpnNHcwcHh2cVc2dXR3dXZkL1c0YlQ1UjJwaG95d0duMWpKK0s3NnpWTytVa0t1eEFwcW5KCjNqL2ZVRjI5U2pBMkMxbmNKYjYrT0JScmhRS21qb2JiODdtOUZGTHNaQUdxa3pubmxyVjVrUDRzNE01Q2tjVGsKQWc5RFI2MTk1S2VTTVpDRXF5ZERrc2lWdGN1M204YTc3Mm9ybEFyeEFvR0JBTVFIUnNPZWcxZ01LS2QzVERiSgphbExBWWllUk91cG1aa1NNR0RZQ3lGK1QyRE82VDQ0SVZOTVZ2UnZSSE1OQ0JWUUI0dzFTS2J5Q01HZ1hSWjZCCjZ2UFNYUkloQVVqcWVQd0h0U25pSEtNT3FLMm82Y2xDMHF0QWg3UXlGMHpoYUwrTlVEVlRCRlhNdnBNbll4Z0oKUTUyYXJiQ2ZraFg4YUdMUFZGQUFRZVZaCi0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K
kind: Secret
metadata:
  creationTimestamp: "2020-05-21T20:05:03Z"
  name: ssl-secret
  namespace: default
  resourceVersion: "2637"
  selfLink: /api/v1/namespaces/default/secrets/ssl-secret
  uid: 232f019f-5ce2-4b49-8b97-17b21474427c
type: Opaque
```

Now we want to mount the Secret into the [nginx Pod](../k8s/pods/pod-nginx-secret.yaml) as a Volume:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    tier: frontend
    app:  nginx
  annotations:
    description: Nginx pod with a secret containing TLS data
spec:
  volumes:            
    - name: ssl-files          # Define the secret volume
      secret:                  # Create a secret-volume to store sensitive data
        secretName: ssl-secret # Name matching secret object created by kubectl secret command
                      
  containers:
    - name: nginx
      image: nginx:1.13.8
      volumeMounts:            # Mount the secret volume
        - name: ssl-files      # Name matching secret volume name defined above in spec.volumes
          mountPath: /ssl      # mountPath within container where the secret data will appear
          readOnly: true
      ports:
        - containerPort: 80
      resources:
        requests:
          cpu: "100m"
          memory: "64Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f pod-nginx-secret.yaml
pod/nginx created

➜ kc get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          37s
```

Let's get a shell in the container to **cat** the secret files:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc exec -it pod/nginx -- /bin/bash

root@nginx:/# ls -las /ssl
total 4
0 drwxrwxrwt 3 root root  120 May 21 20:21 .
4 drwxr-xr-x 1 root root 4096 May 21 20:21 ..
0 drwxr-xr-x 2 root root   80 May 21 20:21 ..2020_05_21_20_21_21.046499874
0 lrwxrwxrwx 1 root root   31 May 21 20:21 ..data -> ..2020_05_21_20_21_21.046499874
0 lrwxrwxrwx 1 root root   15 May 21 20:21 ssl-cert -> ..data/ssl-cert
0 lrwxrwxrwx 1 root root   14 May 21 20:21 ssl-key -> ..data/ssl-key

root@nginx:/# cat /ssl/ssl-key
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC16sA7Wz68VX8h
2ZLZgaT7aJHM7CQkMKNAsEUA5CHR3wNDAr7nLq/EfVF4wcf+XMQMU5mNMHTWfLsu
lp976GnzjJc02EZ1+pI6FlFchHZfQFPyU+DO5OLwtgDO0cupFePd7qjV9UpmdyLK
+DnOTMHLR5WTRqkCImXIj3KjUJ26UGz+ULWJvXze3UW72GLf+Hee+2uMw2tPQpjY
aDhqYU/tyvzjQYMEW8C9NjtX62nVqUZiPTANcDA/WJeU9Rz5M7Coo65kPwe/gjuY
K56EECDiOq2UdiGDHN8XmX6Gv7AwExGNpaRNtOXaWLTblbXJ3GmWsbaFFXFbq7ol
O83kEyjVAgMBAAECggEBAI6Vg7xCRUbKYE4Awaf3hH+FM5oBkEZJVPuz7THInXVo
rZ7NPSHoJt4EN2JFyGJnBUaAE/9k9n7S3seiSTiOLtU04aMKzRdVoV0j9vtj23/G
5MUv1ylynyl6DeIM7+sEfEiL8gtZKcpsIHoj2vMGmHKjFeqMXJWOrmZngLveyPGp
G4NDh0UYl378NTVGZ6Q3M6/0iMwf2MG8SjIIEPBXrpEThZ2S2GtOSxxWhqYjTcx6
e4+R4qI6dunJmpnnafga4EOc4I4t/R93ObFLdPLaODn3pDlfcXJNzJtQoRO2NI2k
LnAatVTCp7JzxzBIiIFoNokZrbOioG9xArtjRP8B0iECgYEA3lzB6bgvwCGa4Ii4
WnmiB4oE2O43KClICJBE++ww1OMu5lKbB3R492fz0E7FRXs5WJc3FnwYt+fj48S6
y/lgjaZwirYsTA2G9AoZe6XQop6lungEhJgGrsYTjVBIBxX6ehYr5DC6xyY04+on
R9uoT83VJogMYwuDEmd0U4Vzm40CgYEA0W+zQSw0JDvc5oAkD2JFjaoj90XRr7s0
8ERg65W0XvMEJ75YDvm43HKSFpuYt/aAdGx1xQXfAJdI+6lYNF14V0+AfcGBzzMI
rM6em1f5orvuEWmGKCfJlssrlcJlBSCmqGuDjSHTh01NjoyhrF9C252mxNbnMi0B
mMXteN+EzGkCgYBIlpsuwtPDsrSua7NSxbYhI+slLc6Pq7o6IW6DlrzyIh+jTIAT
VPBQQ30SGUTIw8saonJ3QpeHIYoBRq17/LKKSzUd8w5O3XOaotlixeRv0b5kOt2u
szorP7oOPZDlz0TvKeG2Ijo23MATTtL34Dr3okfcxjjU9GMbVO5ifYQZ2QKBgDFc
WC0mE+vuR/Pzg4w0pxvqW6utwuvd/W4bT5R2phoywGn1jJ+K76zVO+UkKuxApqnJ
3j/fUF29SjA2C1ncJb6+OBRrhQKmjobb87m9FFLsZAGqkznnlrV5kP4s4M5CkcTk
Ag9DR6195KeSMZCEqydDksiVtcu3m8a772orlArxAoGBAMQHRsOeg1gMKKd3TDbJ
alLAYieROupmZkSMGDYCyF+T2DO6T44IVNMVvRvRHMNCBVQB4w1SKbyCMGgXRZ6B
6vPSXRIhAUjqePwHtSniHKMOqK2o6clC0qtAh7QyF0zhaL+NUDVTBFXMvpMnYxgJ
Q52arbCfkhX8aGLPVFAAQeVZ
-----END PRIVATE KEY-----

root@nginx:/# cat /ssl/ssl-cert
-----BEGIN CERTIFICATE-----
MIICpDCCAYwCCQC/vpKsw6CBXDANBgkqhkiG9w0BAQsFADAUMRIwEAYDVQQDDAls
b2NhbGhvc3QwHhcNMjAwNTIxMTk1OTM0WhcNMjEwNTIxMTk1OTM0WjAUMRIwEAYD
VQQDDAlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC1
6sA7Wz68VX8h2ZLZgaT7aJHM7CQkMKNAsEUA5CHR3wNDAr7nLq/EfVF4wcf+XMQM
U5mNMHTWfLsulp976GnzjJc02EZ1+pI6FlFchHZfQFPyU+DO5OLwtgDO0cupFePd
7qjV9UpmdyLK+DnOTMHLR5WTRqkCImXIj3KjUJ26UGz+ULWJvXze3UW72GLf+Hee
+2uMw2tPQpjYaDhqYU/tyvzjQYMEW8C9NjtX62nVqUZiPTANcDA/WJeU9Rz5M7Co
o65kPwe/gjuYK56EECDiOq2UdiGDHN8XmX6Gv7AwExGNpaRNtOXaWLTblbXJ3GmW
sbaFFXFbq7olO83kEyjVAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAIhtzT3aw4FH
aOGp9JwoOZiTK2UbkI+urYJY92WoScuRh6SUI/2lucB4MBD/haBziSipJuAdFlC2
7c69l/NqqfGb4g5lrqvAjlMEw+KeUL4mlszdy3L0SM+2nMJ/MC2VsUIirDe5Wshs
fmjA0Mnj0Lq+8Aq05iWYrQ/+GiEK4Ff+cmfbScSAgIJDApTvETP8NwIxi1ob0Fqq
Kxqe9fwQvpoCWqAcqsMSE/rvxdP9pMcaWXAd3rtCmylM5VY7cIjFc7fAdUP4wHyC
4z3sQcPHC805aJUppbkjP/IeuCZiie5KX+9pCNbnNlbMycQg57EBubNt+ym5WlaE
pRVTYm0h2PA=
-----END CERTIFICATE-----
```

Now we want to configure nginx to serve HTTPS:

```bash
root@nginx:/# ls /etc/nginx/conf.d
default.conf
```

We will copy the file **default.conf**; edit it's configuration so nginx can serve HTTPS; and package in a ConfgiMap Volume, and mount it inside the container at **/etc/nginx/conf.d**, thus replacing the default:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc cp nginx:etc/nginx/conf.d/default.conf default.conf
```

and edit the file:

```yaml
server {
    listen       80;
    listen       443 ssl; # ADDED
    server_name  localhost;
    ssl_certificate     /ssl/ssl-cert; # ADDED
    ssl_certificate_key /ssl/ssl-key; # ADDED
...    
```

Create the ConfigMap:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc create configmap nginx-conf --from-file=default.conf
configmap/nginx-conf created
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc describe configmap/nginx-conf
Name:         nginx-conf
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
default.conf:
----
server {
    listen       80;
    listen       443 ssl; # ADDED
    server_name  localhost;
    ssl_certificate     /ssl/ssl-cert; # ADDED
    ssl_certificate_key /ssl/ssl-key; # ADDED

```

Essentially our edited default.conf.

Now expose this [ConfigMap Volume](../k8s/pods/pod-nginx-secret-configmap.yaml), mounting it into the container:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    tier: frontend
    app:  nginx
  annotations:
    description: Nginx pod serving both HTTP and HTTPS (uses a secret and configmap)
spec:
  volumes:            
    - name: ssl-files              
      secret:                      
        secretName: ssl-secret     
    
    - name: nginx-conf-file # Define the configmap volume
      configMap:                   
        name: nginx-conf    # Name matching name of ConfigMap containing the nginx config file
                      
  containers:
    - name: nginx
      image: nginx:1.13.8
      volumeMounts:                 
        - name: ssl-files           
          mountPath: /ssl
          readOnly: true
        - name: nginx-conf-file          # Mount the config map volume,  
          mountPath: /etc/nginx/conf.d   # at the path where nginx looks for its config file
      ports:
        - containerPort: 80
        - containerPort: 443
      resources:
        requests:
          cpu: "100m"
          memory: "64Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"
```

First delete the original version of the Pod before applying this enhancement:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc delete pod/nginx
pod "nginx" deleted
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc apply -f pod-nginx-secret-configmap.yaml
pod/nginx created
```

Double check viewing the updated **default.conf** in the Pod:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods on  master [!?] at ☸️ backwards.k8s.local took 5s
➜ kc exec pod/nginx -- cat /etc/nginx/conf.d/default.conf
server {
    listen       80;
    listen       443 ssl; # ADDED
    server_name  localhost;
    ssl_certificate     /ssl/ssl-cert; # ADDED
    ssl_certificate_key /ssl/ssl-key; # ADDED
...    
```

Let's test HTTPS:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ kc port-forward pod/nginx 8443:443
Forwarding from 127.0.0.1:8443 -> 443
Forwarding from [::1]:8443 -> 443
^Z
zsh: suspended  kubectl port-forward pod/nginx 8443:443


kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ bg
[1]  + continued  kubectl port-forward pod/nginx 8443:443


➜ curl https://localhost:8443 --insecure
Handling connection for 8443
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

Or with [httpie](https://httpie.org/):

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ http --verify=no https://localhost:8443
Handling connection for 8443
HTTP/1.1 200 OK
...
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

Sidenote - If you wish to base64 a file just do e.g.

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/pods at ☸️ backwards.k8s.local
➜ base64 cert.pem
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNwRENDQVl3Q0NRQy92cEtzdzZDQlhE
QU5CZ2txaGtpRzl3MEJBUXNGQURBVU1SSXdFQVlEVlFRRERBbHMKYjJOaGJHaHZjM1F3SGhj
Tk1qQXdOVEl4TVRrMU9UTTBXaGNOTWpFd05USXhNVGsxT1RNMFdqQVVNUkl3RUFZRApWUVFE
REFsc2IyTmhiR2h2YzNRd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0Fv
SUJBUUMxCjZzQTdXejY4Vlg4aDJaTFpnYVQ3YUpITTdDUWtNS05Bc0VVQTVDSFIzd05EQXI3
bkxxL0VmVkY0d2NmK1hNUU0KVTVtTk1IVFdmTHN1bHA5NzZHbnpqSmMwMkVaMStwSTZGbEZj
aEhaZlFGUHlVK0RPNU9Md3RnRE8wY3VwRmVQZAo3cWpWOVVwbWR5TEsrRG5PVE1ITFI1V1RS
cWtDSW1YSWozS2pVSjI2VUd6K1VMV0p2WHplM1VXNzJHTGYrSGVlCisydU13MnRQUXBqWWFE
aHFZVS90eXZ6alFZTUVXOEM5Tmp0WDYyblZxVVppUFRBTmNEQS9XSmVVOVJ6NU03Q28KbzY1
a1B3ZS9nanVZSzU2RUVDRGlPcTJVZGlHREhOOFhtWDZHdjdBd0V4R05wYVJOdE9YYVdMVGJs
YlhKM0dtVwpzYmFGRlhGYnE3b2xPODNrRXlqVkFnTUJBQUV3RFFZSktvWklodmNOQVFFTEJR
QURnZ0VCQUlodHpUM2F3NEZICmFPR3A5SndvT1ppVEsyVWJrSSt1cllKWTkyV29TY3VSaDZT
VUkvMmx1Y0I0TUJEL2hhQnppU2lwSnVBZEZsQzIKN2M2OWwvTnFxZkdiNGc1bHJxdkFqbE1F
dytLZVVMNG1sc3pkeTNMMFNNKzJuTUovTUMyVnNVSWlyRGU1V3NocwpmbWpBME1uajBMcSs4
QXEwNWlXWXJRLytHaUVLNEZmK2NtZmJTY1NBZ0lKREFwVHZFVFA4TndJeGkxb2IwRnFxCkt4
cWU5ZndRdnBvQ1dxQWNxc01TRS9ydnhkUDlwTWNhV1hBZDNydENteWxNNVZZN2NJakZjN2ZB
ZFVQNHdIeUMKNHozc1FjUEhDODA1YUpVcHBia2pQL0lldUNaaWllNUtYKzlwQ05ibk5sYk15
Y1FnNTdFQnViTnQreW01V2xhRQpwUlZUWW0waDJQQT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUt
LS0tLQo=
```

