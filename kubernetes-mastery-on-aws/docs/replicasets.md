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

