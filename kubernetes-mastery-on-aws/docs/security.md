# Security

## Authentication

- All **authentication** in Kubernetes is done at the **API server**
- Kubernetes clusters have 2 categories of user accounts:
  - Normal User Accounts
    - Normal users are managed by an independent service **outside** k8s
  - Service Accounts
    - Service accounts are synthetic users managed by the k8s API of **kind: ServiceAccount**

How are **normal users** managed outside of k8s?

- For small clusters:
  - Distribute private keys
  - Distribute bearer tokens
  - Use a static username/password in a CSV file
- For large clusters:
  - Integrate with an external store e.g. LDAP
  - Manage users centrally and provide single sign-on (SSO) capability
  - Subdivide users into groups and control resource access

And what is the purpose of **service accounts**?

- Service accounts create identities for **processes running in pods**
- Service accounts are bound to specific namespaces
- Service account credentials are stored as **secrets**
  - Secrets are objects in k8s for storing sensitive data e.g. passwords, OAuth tokens, access keys
- The API server automatically creates service accounts for pods
  - If a pod does not have a service account, its value is set to **default**
- You can also manually create service accounts

## Service Accounts

```bash
➜ kubectl get pods --all-namespaces
NAMESPACE              NAME                                                                  READY   STATUS    RESTARTS   AGE
kube-system            dns-controller-5769c5f8b6-x6gzp                                      
kube-system            etcd-manager-events-ip-172-20-35-223.eu-west-2.compute.internal       
kube-system            etcd-manager-main-ip-172-20-35-223.eu-west-2.compute.internal         
kube-system            kops-controller-682c9                                                 
kube-system            kube-apiserver-ip-172-20-35-223.eu-west-2.compute.internal            
kube-system            kube-controller-manager-ip-172-20-35-223.eu-west-2.compute.internal   
kube-system            kube-dns-autoscaler-594dcb44b5-vrvx4                                  
kube-system            kube-dns-b84c667f4-68gn8                                              
kube-system            kube-dns-b84c667f4-f6td9                                              
kube-system            kube-proxy-ip-172-20-35-223.eu-west-2.compute.internal                
kube-system            kube-proxy-ip-172-20-49-22.eu-west-2.compute.internal                 
kube-system            kube-proxy-ip-172-20-51-151.eu-west-2.compute.internal                
kube-system            kube-scheduler-ip-172-20-35-223.eu-west-2.compute.internal            
kubernetes-dashboard   dashboard-metrics-scraper-7b8b58dc8b-k9khs                            
kubernetes-dashboard   kubernetes-dashboard-5f5f847d57-ndcqg                                 
```

Lets look up the service account for **kubernetes dashboard**:

```yaml
➜ kc get pod/kubernetes-dashboard-5f5f847d57-ndcqg --namespace=kubernetes-dashboard -o yaml

apiVersion: v1
kind: Pod
metadata:
  ...
spec:
  ...
  serviceAccount: kubernetes-dashboard
  serviceAccountName: kubernetes-dashboard
  ...  
```

Now view the details of this service account, which includes the associated **secrets** name:

```yaml
➜ kc get serviceaccounts kubernetes-dashboard --namespace=kubernetes-dashboard -o yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  ...
secrets:
  - name: kubernetes-dashboard-token-l9c7c
```

By viewing the details of the associated **secret** we'll see **base64** encoded certificate and token (**JWT**):

```yaml
➜ kc get secret kubernetes-dashboard-token-l9c7c --namespace=kubernetes-dashboard -o yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    kubernetes.io/service-account.name: kubernetes-dashboard
    kubernetes.io/service-account.uid: ec11511c-c086-4ee6-b207-26b5b70d5cd8
  creationTimestamp: "2020-03-24T22:06:02Z"
  name: kubernetes-dashboard-token-l9c7c
  namespace: kubernetes-dashboard
  resourceVersion: "2616"
  selfLink: /api/v1/namespaces/kubernetes-dashboard/secrets/kubernetes-dashboard-token-l9c7c
  uid: ff1afb3d-7805-4606-a262-65263048d04a
type: kubernetes.io/service-account-token
data:
  ca.crt:
  ...
  namespace: a3ViZXJuZXRlcy1kYXNoYm9hcmQ=
  token:
  ...
```

We can **base64 decode** the token and use it to access the Kubernetes UI:

```bash
➜ kc proxy
Starting to serve on 127.0.0.1:8001
```

where the Dashboard can be accessed at:

[http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)

There will already be a lot of service accounts:

```bash
➜ kc get serviceaccounts --all-namespaces
NAMESPACE              NAME                                 SECRETS   AGE
default                default                              1         53m
kube-node-lease        default                              1         53m
kube-public            default                              1         53m
kube-system            attachdetach-controller              1         53m
kube-system            aws-cloud-provider                   1         53m
kube-system            certificate-controller               1         53m
kube-system            clusterrole-aggregation-controller   1         53m
kube-system            cronjob-controller                   1         53m
kube-system            daemon-set-controller                1         53m
kube-system            default                              1         53m
kube-system            deployment-controller                1         53m
kube-system            disruption-controller                1         53m
kube-system            dns-controller                       1         53m
kube-system            endpoint-controller                  1         53m
kube-system            expand-controller                    1         53m
kube-system            generic-garbage-collector            1         53m
kube-system            horizontal-pod-autoscaler            1         53m
kube-system            job-controller                       1         53m
kube-system            kops-controller                      1         53m
kube-system            kube-dns                             1         53m
kube-system            kube-dns-autoscaler                  1         53m
kube-system            kube-proxy                           1         53m
kube-system            kubernetes-dashboard                 1         36m
kube-system            namespace-controller                 1         53m
kube-system            node-controller                      1         53m
kube-system            persistent-volume-binder             1         53m
kube-system            pod-garbage-collector                1         53m
kube-system            pv-protection-controller             1         53m
kube-system            pvc-protection-controller            1         53m
kube-system            replicaset-controller                1         53m
kube-system            replication-controller               1         53m
kube-system            resourcequota-controller             1         53m
kube-system            route-controller                     1         53m
kube-system            service-account-controller           1         53m
kube-system            service-controller                   1         53m
kube-system            statefulset-controller               1         53m
kube-system            ttl-controller                       1         53m
kubernetes-dashboard   default                              1         34m
kubernetes-dashboard   kubernetes-dashboard                 1         34m
```

Authentication methods:

- X509 Client Certificate: The client presents a certificate to the API server which verifies it using a CA

- Bearer Token: A character sequence put in HTTP Authorization header by the API client e.g.

  Authorization: Bearer 460c809a9e56csb75269

- Authenticating Proxy: Stands between client and API server and adds to request header a "X-Remote-User"

- Static Password File: Usernames and passwords are read from a static auth file by the API server

## API Server Certs and Tokens

When the API Server is booted, it is configured with **crt** and **token** files. We can **jump** onto an API server pod and take a look:

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kc get all --all-namespaces
NAMESPACE     	NAME
kube-system   	pod/dns-controller-5769c5f8b6-24d55
kube-system   	pod/kops-controller-4xv8k
kube-system   	pod/kube-apiserver-ip-172-20-59-15.eu-west-2.compute.internal
```

```bash
kubernetes-backwards at ☸️ backwards.k8s.local took 7s
➜ kc exec -it pod/kube-apiserver-ip-172-20-59-15.eu-west-2.compute.internal -n kube-system /bin/sh

# ps -ef | grep kube-apiserver
/bin/sh: 1: ps: not found
```

```bash
# apt-get update && apt-get install procps

# ps -ef | grep kube-apiserver
root         1     0  2 21:44 ?        00:00:14 /usr/local/bin/kube-apiserver --allow-privileged=true --anonymous-auth=false --apiserver-count=1 --authorization-mode=RBAC
...
--basic-auth-file=/srv/kubernetes/basic_auth.csv
...
file=/srv/kubernetes/ca.crt
...
--token-auth-file=/srv/kubernetes/known_tokens.csv
```

Let's take a look at the **tokens csv** file:

```bash
# cat /srv/kubernetes/known_tokens.csv
abmTsSWcYlkeEOYOJ7EaXPBR5uDcOo4Z,kubelet,kubelet
aE8KRLmDBTWpCy0TINv4wTFTzXsqbCxM,system:controller_manager,system:controller_manager
mCmsj0qjy4hnuXe1JzKiaGk2JqIhJQXf,system:logging,system:logging
0cxaOy5qiPQ6R4ycnfUudcGscYBef0HL,system:dns,system:dns
4TGqBruUMWcGYCNiTVP4nMYnK7jEzIhO,kube,kube
eDhmktk4trRwj2DA5FmU5bhlDfTDDdvu,admin,admin,system:masters
N5UZgAeS7DNH0FyYVDmggSjGHjgG5ykd,kube-proxy,kube-proxy
NdCSAocjpFH9AiI3FMH26HTivVY4Y8uM,system:scheduler,system:scheduler
jcyGqfeWwakxoveAyFHSFWAy98n0ZATb,system:monitoring,system:monitoring
```

It's a csv of 3 fields: the token, user name, user ID - there are optional group names.

And now the **basic auth** file:

```bash
# cat /srv/kubernetes/basic_auth.csv
4TGqBruUMWcGYCNiTVP4nMYnK7jEzIhO,admin,admin,system:masters
```

Which is formatted as: password, user name, user ID - there are also optional group names.

## RBAC

Secure Kubernetes by enabling Role Based Access Control (RBAC) within the cluster. When RBAC is enabled, every API call, after authentication, will need to pass an **authorisation** check. RBAC is enabled upon starting the API server with **--authorization-mode=RBAC**.

RBAC can control **who** can make **what** changes user the k8s API.

![RBAC](images/rbac.png)

Two key concepts:

- Role
- RoleBinding

at the **namespace** level - at the cluster level there is also, ClusterRole and ClusterRoleBinding.

**Role** defines permissions for k8s resources, i.e. combine **verbs** with **resources** e.g.

- verbs: get, list etc.
- resources: pods, services, nodes, deployments, secrets etc.

**RoleBinding** binds a role to **subjects** (user, group, service account) i.e. a role binding **grants** a role's permissions to it subjects.

