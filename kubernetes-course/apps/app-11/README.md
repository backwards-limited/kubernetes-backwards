# Stateful Sets

Stateful distributed applications on a Kubernetes cluster.

- Need a **stable pod host name** (instead of e.g. podname-randomstring).
- Podname will have a sticky identity, using an index e.t. podname-0, podname-1, and when a pod is rescheduled, it will keep that identity.
- A StatefulSet allows your stateful application to use **DNS** to find other **peers**. E.g. Cassandra clusters, Elasticsearch clusters use DNS to find other members of the cluster.

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

$ kops update cluster kubernetes.backwards.limited --yes

$ kops validate cluster
```

```bash
$ kubectl create -f cassandra.yml
statefulset "cassandra" created
storageclass "standard" created
service "cassandra" created

$ kubectl get pods
NAME          READY     STATUS    RESTARTS   AGE
cassandra-0   0/1       Pending   0          2m

$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                STORAGECLASS   REASON    AGE
pvc-622dcf09-f23e-11e8-af99-068919e6e332   2Gi        RWO            Delete           Bound     default/cassandra-data-cassandra-0   standard                 2m

$ kubectl get pvc
NAME                         STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
cassandra-data-cassandra-0   Bound     pvc-622dcf09-f23e-11e8-af99-068919e6e332   2Gi        RWO            standard       3m
```

We can **watch** until all pods are up and running:

```bash
$ kubectl get pods --watch
NAME          READY     STATUS    RESTARTS   AGE
cassandra-0   0/1       Pending   0          2m
```

which will eventually look like:

```bash
NAME          READY     STATUS    RESTARTS   AGE
cassandra-0   1/1       Running   0          6m
cassandra-1   1/1       Running   0          6m
cassandra-2   1/1       Running   0          6m
```

```bash
$ kubectl exec -it cassandra-0 -- nodetool status
...
Status=Up/Down

$ kubectl exec -it cassandra-0 -- bash
root@cassandra-0:/# ping cassandra-0.cassandra
```

Of course, don't forget to bring everything down:

```bash
$ kops delete cluster kubernetes.backwards.limited

$ kops delete cluster kubernetes.backwards.limited --yes
```