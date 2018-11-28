# Pod Presets

Pod presets can **inject information into pods at runtime**, a bit like Secrets, ConfigMaps, Volumes and Environment variables. Note that there is also [Helm](https://helm.sh).

e.g. you have 20 applications to deploy which all need specific credentials. Either add to all 20 specifications, or create 1 Preset object to inject an environment variable or config file to all **matching pods**.

And here is an example:

```yaml
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: allow-database
spec:
  selector:
    matchLabels:
      role: frontend # every pod that has this label the following will apply to
  env:
    - name: DB_PORT
      value: "6379"
  volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
    - name: cache-volume
      emptyDir: {}
```

## Example with AWS

As per the [kops](../../../docs/kops.md) documentation:

```bash
$ export AWS_PROFILE=ireland

$ aws s3 mb s3://ireland-kubernetes --region eu-west-1

$ export KOPS_STATE_STORE=s3://ireland-kubernetes

$ kops create cluster \
--name kubernetes.backwards.limited \
--dns-zone kubernetes.backwards.limited \
--zones eu-west-1a \
--state s3://ireland-kubernetes \
--node-count 2 \
--node-size t2.micro \
--master-size t2.micro
```

At this time Pods Presets is in alpha and so we need to add extra information to the cluster's **spec** before launching. You will see the following command that can be run to edit the spec:

```bash
$ kops edit cluster kubernetes.backwards.limited
```

and add the following at the end of the spec:

```yaml
  kubeAPIServer:
    enableAdmissionPlugins:
    - Initializers
    - NamespaceLifecycle
    - LimitRanger
    - ServiceAccount
    - PersistentVolumeLabel
    - DefaultStorageClass
    - DefaultTolerationSeconds
    - MutatingAdmissionWebhook
    - ValidatingAdmissionWebhook
    - NodeRestriction
    - ResourceQuota
    - PodPreset
    runtimeConfig:
      settings.k8s.io/v1alpha1: "true"
```

Now we can actually launch the cluster:

```bash
$ kops update cluster kubernetes.backwards.limited --yes

$ kops validate cluster
```

And let's deploy:

```bash
$ kubectl create -f pod-presets.yml

$ kubectl get podpresets
NAME               AGE
share-credential   19s

$ kubectl create -f deployments.yml
deployment "deployment-1" created
deployment "deployment-2" created

$ kubectl get pods
NAME                            READY     STATUS    RESTARTS   AGE
deployment-1-6c8fd46975-kx72g   1/1       Running   0          36s
deployment-1-6c8fd46975-nj6ks   1/1       Running   0          36s
deployment-1-6c8fd46975-xx5sh   1/1       Running   0          36s
deployment-2-6c8fd46975-4zbb9   0/1       Pending   0          36s
deployment-2-6c8fd46975-6ql9r   1/1       Running   0          36s
deployment-2-6c8fd46975-pj2lw   0/1       Pending   0          36s

$ kubectl describe pod deployment-1-6c8fd46975-kx72g
...
    Environment:
      MY_SECRET:  123456
    Mounts:
      /share from share-volume (rw)
...
Volumes:
  share-volume:
    Type:    EmptyDir (a temporary directory that shares a pod's lifetime)
```

Of course, don't forget to bring everything down:

```bash
$ kops delete cluster kubernetes.backwards.limited

$ kops delete cluster kubernetes.backwards.limited --yes
```

