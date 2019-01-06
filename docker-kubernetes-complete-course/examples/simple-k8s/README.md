# Simple k8s

We want to take our original [multi-client](../multi/README.md) image that we were working on using Docker and Docker Compose, and now use Kubernetes. For this example, we will feed into **kubectl** two config files that *create objects*.

> ![Docker Compose Kubernetes mapping 2](docs/images/docker-compose-kubernetes-mapping-2.png)

From our two config files [client-pod.yml](client-pod.yml) and [client-node-port.yml](client-node-port.yml) what is **kind** and **apiVersion**?

> ![Config](docs/images/config.png)
---
> ![Version](docs/images/version.png)

## Pod

So what is a **pod**?

> ![Pod](docs/images/pod.png)

When we start up Minikube for example, a Virtual Machine is instantiated, which in this case will be our Node. A Pod has one or more containers - so at a minimum we can deploy one container housed by one Pod. The containers in a Pod are somehow dependent one another i.e. they constitute a well define grouping e.g.

> ![Pod example](docs/images/pod-example.png)

## Service

> ![Service](docs/images/service.png)

In our [example](client-node-port.yml) the "sub type" of Service we declared is **NodePort**, i.e. a NodePort Service. All of the sub types of Service expose containers. However, a NodePort is only for **development** purposes, though it does expose its container to the outside world.

> ![Multi client example](docs/images/multi-client-example.png)
---
> ![Multi client example details](docs/images/multi-client-example-details.png)
---
> ![Ports](docs/images/ports.png)

# Deploy / Run

> ![Kubectl apply](docs/images/kubectl-apply.png)

```bash
$ minikube start
Starting local Kubernetes v1.12.4 cluster...
Starting VM...
Getting VM IP address...
Moving files into cluster...
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Stopping extra container runtimes...
Starting cluster components...
Verifying kubelet health ...
Verifying apiserver health ...Kubectl is now configured to use the cluster.
Loading cached images from config file.
```

```bash
$ ls
client-node-port.yml	client-pod.yml
```

```bash
$ kubectl apply -f client-pod.yml
pod "client-pod" created

$ kubectl apply -f client-node-port.yml
service "client-node-port" created
```

> ![Get pods](docs/images/get-pods.png)

```bash
$ kubectl get pods
NAME         READY     STATUS    RESTARTS   AGE
client-pod   1/1       Running   0          5m
```

```bash
$ kubectl get services
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
client-node-port   NodePort    10.107.56.225   <none>        3050:31515/TCP   5m
kubernetes         ClusterIP   10.96.0.1       <none>        443/TCP          2h
```

Now ask Minikube what IP address has been assigned to the instantiated VM:

```bash
$ minikube ip
192.168.99.101
```

and now we can navigate to the multi-client UI at http://192.168.99.101:31515