# Kubectl

## Config

Using **kubectl** to interact with a Kubernetes cluster, kubectl uses a file called **kubeconfig** to find and access a cluster.

- kubeconfig is located in your home directory inside directory **.kube** e.g. **/Users/davidainslie/.kube**
- By default the file is named **config** e.g. **/Users/davidainslie/.kube/config**

kubectl works at two different levels: **context** and **namespace**. First set the context to the newly create AWS cluster. Easiest way to do this is to use [kubectx + kubens](https://github.com/ahmetb/kubectx/), so make sure it is installed e.g.

```bash
➜ brew install kubectx
```

Now, set the context:

```bash
➜ kubectx
* backwards.k8s.local
backwards.tech
docker-desktop
minikube
```

Ok, so mine is already set, but if not:

```bash
➜ kubectx backwards.k8s.local
```

The **config** can get pretty big with contexts for every cluster you have. Here is a cut-down version regarding the current context I am using:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: *****
    server: https://api-backwards-k8s-local-*****.eu-west-2.elb.amazonaws.com
  name: backwards.k8s.local
...
contexts:
- context:
    cluster: backwards.k8s.local
    user: backwards.k8s.local
  name: backwards.k8s.local
...
current-context: backwards.k8s.local
kind: Config
preferences: {}
users:
- name: backwards.k8s.local
  user:
    client-certificate-data: *****
    client-key-data: *****
    password: *****
    username: *****
...
```

**Note** going forward you may see me use **kc** instead of **kubectl** when using the Kubernetes client to interact with the cluster - kc is nothing but an **alias** set in my local command line profile.

```bash
~/.kube at ☸️ backwards.k8s.local
➜ kc cluster-info
Kubernetes master is running at https://api-backwards-k8s-local-***.eu-west-2.elb.amazonaws.com
KubeDNS is running at https://api-backwards-k8s-local-***.eu-west-***
```

```bash
~/.kube at ☸️ backwards.k8s.local
➜ kc get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
ip-172-20-45-216.eu-west-2.compute.internal   Ready    node     47m   v1.16.7
ip-172-20-53-18.eu-west-2.compute.internal    Ready    master   48m   v1.16.7
ip-172-20-55-154.eu-west-2.compute.internal   Ready    node     47m   v1.16.7
```

## Namespace

- Namespaces support the concept of virtual clusters
- Namespaces divide cluster resources between users e.g. projects, teams etc.
- Kubernetes resources only need to be unique with a namespace - avoids name collisions
- Namespaces allow for isolation and access control

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kc get namespaces
NAME              STATUS   AGE
default           Active   4m14s
kube-node-lease   Active   4m15s
kube-public       Active   4m15s
kube-system       Active   4m15s
```

Create a namespace named **myns**:

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kc create namespace myns
namespace/myns created

kubernetes-backwards at ☸️ backwards.k8s.local
➜ kc get namespaces
NAME              STATUS   AGE
default           Active   6m58s
kube-node-lease   Active   6m59s
kube-public       Active   6m59s
kube-system       Active   6m59s
myns              Active   3s

kubernetes-backwards at ☸️ backwards.k8s.local
➜ kc get all --namespace=myns
No resources found in myns namespace.
```

It would be nicer to avoid having to always include **--namespace**.

First, what is the current **context** again?

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kc config current-context
backwards.k8s.local
```

or even easier:

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kubectx --current
backwards.k8s.local

kubernetes-backwards at ☸️ backwards.k8s.local
➜ kubectx -c
backwards.k8s.local
```

Now **set** the namespace on the current **context** where the easy way is:

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kubens myns
Context "backwards.k8s.local" modified.
Active namespace is "myns".
```

and the verbose (hard way) is:

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kc config set-context $(kc config current-context) --namespace=myns
Context "backwards.k8s.local" modified.
```





Eventually would like these services on our cluster:

heapster

kubernetes-dashboard

metrics-server

grafana (prometheus)

influxdb