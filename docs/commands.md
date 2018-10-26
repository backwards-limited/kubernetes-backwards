# Useful Commands

## Cluster Commands

```bash
kops create cluster --name=kubernetes.newtech.academy --state=s3://kops-state-b429b  --zones=eu-west-1a --node-count=2 --node-size=t2.micro  --master-size=t2.micro --dns-zone=kubernetes.newtech.academy

kops update cluster kubernetes.newtech.academy --yes --state=s3://kops-state-b429b

kops delete cluster --name kubernetes.newtech.academy --state=s3://kops-state-b429b

kops delete cluster --name kubernetes.newtech.academy --state=s3://kops-state-b429b --yes
```

## Docker Commands 

```bash
Build image:
docker build .

Build & Tag:
docker build -t <user>/k8s-demo:latest .

Tag image:
docker tag imageid <user>/k8s-demo

Push image:
docker push <user>/k8s-demo

List images:
docker images

List all containers:
docker ps -a
```

## Kubernetes commands

```bash
Get information about all running pods:
kubectl get pod

Describe one pod:
kubectl describe pod <pod>

Expose the port of a pod (creates a new service):
kubectl expose pod <pod> --port=444 --name=frontend

Port forward the exposed pod port to your local machine:
kubectl port-forward <pod> 8080

Attach to the pod:
kubectl attach <podname> -i

Execute a command on the pod:
kubectl exec <pod> -- command

Add a new label to a pod:
kubectl label pods <pod> mylabel=awesome

Run a shell in a pod - very useful for debugging:
kubectl run -i --tty busybox --image=busybox --restart=Never -- sh

Get information on current deployments:
kubectl get deployments

Get information about the replica sets:
kubectl get rs

Get pods, and also show labels attached to those pods:
kubectl get pods --show-labels

Get deployment status:
kubectl rollout status deployment/helloworld-deployment

Run k8s-demo with the image label version 2:
kubectl set image deployment/helloworld-deployment k8s-demo=k8s-demo:2

Edit the deployment object:
kubectl edit deployment/helloworld-deployment

Get the status of the rollout:
kubectl rollout status deployment/helloworld-deployment

Get the rollout history:
kubectl rollout history deployment/helloworld-deployment

Rollback to previous version:
kubectl rollout undo deployment/helloworld-deployment

Rollback to any version version:
kubectl rollout undo deployment/helloworld-deployment --to-revision=n
```

## AWS Commands

```bash
aws ec2 create-volume --size 10 --region us-east-1 --availability-zone us-east-1a --volume-type gp2
```

## Certificate Commands

```bash
Creating a new key for a new user:
openssl genrsa -out myuser.pem 2048

Creating a certificate request:
openssl req -new -key myuser.pem -out myuser-csr.pem -subj "/CN=myuser/O=myteam/"

Creating  a certificate:
openssl x509 -req -in myuser-csr.pem -CA  /path/to/kubernetes/ca.crt -CAkey /path/to/kubernetes/ca.key  -CAcreateserial -out myuser.crt -days 10000
```