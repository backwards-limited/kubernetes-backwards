# ReplicaSets

- A production environment requires multiple reliable Pod replicas
- The benefits of using a ReplicaSet are:
  - Scale your application
  - Provide fault tolerance to your application
    - ReplicaSet will replace Pods that are deleted of terminated for any reason
    - ReplicaSet can ensure reliable singleton Pod instances
  - Can improve your application's performance by sharing or parallel processing

**ReplicaSets are used to create and manage a certain number of Pod replicas.**

Set the desired number of replicas using the **spec.replicas** key, where the default is **1**.

A ReplicaSet uses a **label selector** to identify the Pods it manages - **spec.selector**.

Regarding your application - Every Pod instance created by a ReplicaSet should be identical. ReplicaSets are designed to scale **stateless** (or **nearly stateless**) applications - good examples being **nginx** or **Apache Web Server**.

## Create ReplicaSet

Take a look at [pod-nginx-multi-rs.yaml](../k8s/replicasets/pod-nginx-multi-rs.yaml):

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx          # A unique name for the ReplicaSet in the current namespace
  labels:
    tier: frontend     # Labels assigned to the ReplicaSet object. Typically it is set to the same
    app:  nginx        # values as the Pod's label (i.e. the .spec.template.metadata.labels)
  annotations:
    description: This ReplicaSet scales a stateless Nginx Pod
spec:                  # Just like the Pod, the ReplicaSet has a spec section
  replicas: 3          # Set the desired number of replicas here
  selector:            # The label selector is used by this ReplicaSet to identify the Pods its managing
    matchLabels:       # The spec.selector.matchLabels must match the spec.template.metadata.labels
      tier: frontend
      app: nginx
            
  template:            # Pod template. The schema is the same as the Pod without apiVersion or kind keys
    metadata:          # Pod name is not required; ReplicaSet will assign unique names to each Pod replica
      labels:
        tier: frontend # Labels must be assigned to the Pod controlled by this replicaset.
        app:  nginx    # Make sure to not overlap these labels with any other Pods or controllers
    spec:              # Notice that the pod spec is now nested inside the template
      volumes:          
        - name: www-data-share     
          emptyDir: {}
      containers:
        - name: nginx                
          image: nginx:1.13.8
          volumeMounts:
            - mountPath: /usr/share/nginx/html      
              name: www-data-share                  
              readOnly: true                        
          ports:
            - containerPort: 80
        
        - name: git-sync
          image: openweb/git-sync:0.0.1
          volumeMounts:
            - mountPath: /usr/share/nginx/html    
              name: www-data-share                
          env:                       
            - name: GIT_SYNC_REPO    
              value: "https://github.com/naveenjoy/naveenjoy.github.io.git"     
            - name: GIT_SYNC_DEST    
              value: "/usr/share/nginx/html" 
            - name: GIT_SYNC_BRANCH  
              value: "master"
            - name: GIT_SYNC_REV
              value: "FETCH_HEAD"
            - name: GIT_SYNC_WAIT    
              value: "10"
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc apply -f pod-nginx-multi-rs.yaml
replicaset.apps/nginx created
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc get pods
NAME          READY   STATUS    RESTARTS   AGE
nginx-2jglv   2/2     Running   0          46s
nginx-sx548   2/2     Running   0          46s
nginx-zxr7k   2/2     Running   0          46s
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc get rs
NAME    DESIRED   CURRENT   READY   AGE
nginx   3         3         3       3m50s
```

Simulate a pod issue; bring one down; another should be started automatically:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc delete pod/nginx-2jglv
pod "nginx-2jglv" deleted

➜ kc get pods
NAME          READY   STATUS    RESTARTS   AGE
nginx-sx548   2/2     Running   0          8m22s
nginx-xjp9b   2/2     Running   0          17s
nginx-zxr7k   2/2     Running   0          8m22s
```

ReplicaSets are matched to Pods by labels. So it is possible to have zero to many ReplicaSets matching a Pod. To which which ReplicaSet matches a Pod(s):

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc get pod/nginx-sx548 -o yaml
apiVersion: v1
kind: Pod
metadata:
  ...
  generateName: nginx-
  labels:
    app: nginx
    tier: frontend
  name: nginx-sx548
  namespace: default
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: nginx
    uid: ec8ed926-804e-4a39-93a3-80362f91b68e
...    
```

Filter the Pods managed by a ReplicaSet:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc get pods -l app=nginx,tier=frontend
NAME          READY   STATUS    RESTARTS   AGE
nginx-sx548   2/2     Running   0          14m
nginx-xjp9b   2/2     Running   0          6m26s
nginx-zxr7k   2/2     Running   0          14m
```

Deleting the ReplicaSet will delete its managed Pods:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc delete rs/nginx
replicaset.apps "nginx" deleted

➜ kc get pods
NAME          READY   STATUS        RESTARTS   AGE
nginx-xjp9b   0/2     Terminating   0          8m23s
nginx-zxr7k   0/2     Terminating   0          16m
```

If for some reason you would like to delete the ReplicaSet without touching the Pods (say you accidentally have more that one ReplicaSet managing your Pods):

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc delete rs/nginx --cascade=false
```

## Scaling

The **desired state** is the **configured number of replicas** in the RS yaml file, using the **spec.replicas** field.

The **current state** is **how many Pod replicas are currently running** that **matches the label selector**.

There are **2 ways to scale** - imperatively or declaratively.

- To scale imperatively, use the **kubectl scale** command:
  - e.g. **kc scale rs/nginx --replicas=5**
- To scale declaratively, edit the ReplicaSet yaml file and change the **spec.replicas** field then **kc apply** it.
  - e.g. **kc apply -f replicaset-file.yaml**

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc scale rs/nginx --replicas=5
replicaset.apps/nginx scaled

➜ kc get rs
NAME    DESIRED   CURRENT   READY   AGE
nginx   5         5         5       80s

➜ kc get pods
NAME          READY   STATUS    RESTARTS   AGE
nginx-5cq62   2/2     Running   0          15s
nginx-7gdfm   2/2     Running   0          87s
nginx-8xmct   2/2     Running   0          15s
nginx-9w4ld   2/2     Running   0          87s
nginx-b95wh   2/2     Running   0          87s
```

## HPA - Horizontal Pod Autoscaler

Horizontal Pod Autoscaler can auto-scale a ReplicaSet, based on **observed CPU/memory utilisation**. HPA periodically (default of 30 seconds) fetches metrics for each of the Pods in the ReplicaSet using a control loop. Note that you will need **metrics-server** running in the cluster. To check for the metrics-server:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s/replicasets at ☸️ backwards.k8s.local
➜ kc get pods -n kube-system
```

If not there, take a look at the first part of [monitoring](monitoring.md).

HPA computes an **arithmetic mean** of the Pods's CPU or memory and will preserve the condition:

**MinReplicas <= Replicas <= MaxReplicas**