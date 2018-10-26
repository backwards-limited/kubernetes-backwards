# Minikube

```bash
minikube start

kubectl run hello-minikube --image=gcr.io/google_containers/echoserver:1.4 --port=8080

kubectl expose deployment hello-minikube --type=NodePort

minikube service hello-minikube --url
```

The final command will eventually provide the Url to access the application named (you could have provided any name) **hello-minikube** deployed into the minikube cluster (created by **minikube start**).

Upon first run, the image for said application will not be available and will be downloaded from the **gcr.io** repository.
Note that running an application on a Kubernetes cluster remains "private" to the cluster until it is exposed to the outside world - hence the extra command to expose to "some available port" via **NodePort**.
(Permanent ports are handled differently).