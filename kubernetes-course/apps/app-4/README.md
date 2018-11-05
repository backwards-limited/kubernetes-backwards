# App 4 - Web UI

- Minikube

  ```bash
  $ minikube start
  
  $ minikube dashboard
  ```

- Kops - Cluster on cloud such as AWS

  Take a look at the Kops section regarding the "set up". Then:

  ```bash
  $ export AWS_PROFILE=kops
  
  $ kops create cluster \
  --name kubernetes.backwards.limited \
  --dns-zone kubernetes.backwards.limited \
  --zones eu-west-1a \
  --state s3://kops-my-kubernetes \
  --node-count 2 \
  --node-size t2.micro \
  --master-size t2.micro
  
  $ kops update cluster kubernetes.backwards.limited --yes --state=s3://kops-my-kubernetes
  
  $ kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
  secret "kubernetes-dashboard-certs" created
  serviceaccount "kubernetes-dashboard" created
  role "kubernetes-dashboard-minimal" created
  rolebinding "kubernetes-dashboard-minimal" created
  deployment "kubernetes-dashboard" created
  service "kubernetes-dashboard" created
  
  $ kubectl create -f app-4-service-account.yml
  serviceaccount "admin-user" created
  clusterrolebinding "admin-user" created
  
  $ kubectl -n kube-system get secret | grep admin-user
  admin-user-token-bfpgd
  
  kubectl -n kube-system describe secret admin-user-token-bfpgd
  Name:         admin-user-token-bfpgd
  Namespace:    kube-system
  Labels:       <none>
  Annotations:  kubernetes.io/service-account.name=admin-user
                kubernetes.io/service-account.uid=345772fa-e140-11e8-901c-064e0766e5de
  
  Type:  kubernetes.io/service-account-token
  
  Data
  ====
  ca.crt:     1042 bytes
  namespace:  11 bytes
  token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLWJmcGdkIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiIzNDU3NzJmYS1lMTQwLTExZTgtOTAxYy0wNjRlMDc2NmU1ZGUiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06YWRtaW4tdXNlciJ9.qnaBZCC5WDkXMYQIu61B0vku7iU-c5BCxUaK0L6iO_njctTOQmcfRD8ogPM_Lr0iTlEaGbOlWMLbj7jYikrs_CJ7xPxiY1_31ra_IKEn7gZMvdqonMgabp5YBh3vZArI8bhniQgruW04C2h74icqeOhp8h7woflT0RctHZF4nyzjwa1BNcU5Vs9Fko-7CqUWyxhNurCJOQvRqdVFe7_gtq6t4myc6aOoK8wTvaRJk01OTNJYLi3F_hCdXZIP_gBdYwK9QBNcQ2dyX7u-FhkmVc-uiq5zcB847GGi1NzGWvDQoBXX8XTcIzkFPNO7smOuoQiO7UAqc_q2YONtc_cFfQ
      
  $ kubectl proxy
  Starting to serve on 127.0.0.1:8001
  ```

  Finally, navigate to [Kubernetes Web UI](<http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/>) and provide the token:

> ![Web UI](docs/images/web-ui.png)



Regarding the Web UI and AWS there is more/better information at [https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html](https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html)

And don't forget to tear down your cluster when done:

```bash
kops delete cluster kubernetes.backwards.limited --state=s3://kops-my-kubernetes

kops delete cluster kubernetes.backwards.limited --state=s3://kops-my-kubernetes --yes
```



