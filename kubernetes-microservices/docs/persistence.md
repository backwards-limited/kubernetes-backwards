# Persistence

We'll use Mongo:

![Mongo](images/mongo.png)

```bash
$ kubectl apply -f mongo-deployment.yml
```

When not completely configured, the **position tracker** microservice log shows:

```
com.mongodb.MongoSocketException: fleetman-mongodb.default.svc.cluster.local: Name or service not known
```

We need a service of mongo db named **fleetman-mongodb**:

```bash
$ kubectl apply -f mongo-service.yml
```

## Persistent Volume - Local

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template: # Template for the pods
    metadata:
      labels:
        app: mongo
    spec:
      containers:
        - name: mongo
          image: mongo:3.6.5-jessie
          # Think of the following as only related to the container
          volumeMounts:
            - name: mongo-persistent-storage # Name of the Volume
              # Path to mount i.e. directory within the container to be mapped externally
              # (which folder, by default, does Mongo store its data)
              mountPath: /data/db
          # With the above, where do we actually store the data
          # (external to the container (and pod))?
          # We accomplish this with a "volume" (see below)
      volumes:
        - name: mongo-persistent-storage
          hostPath:
            path: /mnt/mongo/data
            type: DirectoryOrCreate
```

