## Some Services

## Dashboard

We will follow [AWS dashboard documentation](https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html):

The Kubernetes metrics server is an aggregator of resource usage data in your cluster. The Kubernetes dashboard uses the metrics server to gather metrics for your cluster, such as CPU and memory usage over time.

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s at ☸️ backwards.k8s.local
➜ DOWNLOAD_URL=$(curl -Ls "https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest" | jq -r .tarball_url)

➜ DOWNLOAD_VERSION=$(grep -o '[^/v]*$' <<< $DOWNLOAD_URL)

➜ curl -Ls $DOWNLOAD_URL -o metrics-server-$DOWNLOAD_VERSION.tar.gz

➜ mkdir metrics-server-$DOWNLOAD_VERSION

➜ tar -xzf metrics-server-$DOWNLOAD_VERSION.tar.gz --directory metrics-server-$DOWNLOAD_VERSION --strip-components 1

➜ kubectl apply -f metrics-server-$DOWNLOAD_VERSION/deploy/1.8+/
```

Verify that the `metrics-server` deployment is running the desired number of pods:

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kubectl get deployment metrics-server -n kube-system
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   1/1     1            1           18s
```

Use the following command to deploy the Kubernetes dashboard:

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```

By default, the Kubernetes dashboard user has limited permissions. Create an `eks-admin` service account and cluster role binding that you can use to securely connect to the dashboard with admin-level permissions. See the manifest [eks-admin-service-account.yaml](../k8s/eks-admin-service-account.yaml):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: eks-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: eks-admin
    namespace: kube-system

```

Apply the service account and cluster role binding to the cluster:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s at ☸️ backwards.k8s.local
➜ kubectl apply -f eks-admin-service-account.yaml
serviceaccount/eks-admin created
clusterrolebinding.rbac.authorization.k8s.io/eks-admin created
```

Now that the Kubernetes dashboard is deployed to your cluster, and you have an administrator service account that you can use to view and control your cluster, you can connect to the dashboard with that service account.

Retrieve an authentication token for the `eks-admin` service account. Copy the **authentication token** value from the output. You use this token to connect to the dashboard:

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
Name:         eks-admin-token-4qkwt
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: eks-admin
              kubernetes.io/service-account.uid: b5982040-d106-41ef-99d4-e36baa8c53da

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1042 bytes
namespace:  11 bytes
token:      ...
```

Start the **kubectl proxy**:

```bash
kubernetes-backwards at ☸️ backwards.k8s.local
➜ kubectl proxy
Starting to serve on 127.0.0.1:8001
```

To access the dashboard endpoint, open the following link with a web browser: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login

Choose **Token**, paste the **authentication token**.

## Prometheus

