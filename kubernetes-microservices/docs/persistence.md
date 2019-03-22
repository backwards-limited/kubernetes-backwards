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

