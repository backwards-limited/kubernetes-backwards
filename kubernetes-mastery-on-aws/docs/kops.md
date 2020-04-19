# Kops

## Create Kops User and Permissions

```bash
➜ aws iam create-group --group-name kops
{
    "Group": {
        "Path": "/",
        "GroupName": "kops",
        "GroupId": "*****",
        "Arn": "arn:aws:iam::*****:group/kops",
        "CreateDate": "2020-03-18T21:59:11+00:00"
    }
}

➜ aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops

➜ aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops

➜ aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops

➜ aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess --group-name kops

➜ aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops

➜ aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops

➜ aws iam create-user --user-name kops
{
    "User": {
        "Path": "/",
        "UserName": "kops",
        "UserId": "*****",
        "Arn": "arn:aws:iam::*****:user/kops",
        "CreateDate": "2020-03-18T22:00:29+00:00"
    }
}

➜ aws iam add-user-to-group --user-name kops --group-name kops

➜ aws iam create-access-key --user-name kops
{
    "AccessKey": {
        "UserName": "kops",
        "AccessKeyId": "*****",
        "Status": "Active",
        "SecretAccessKey": "*****",
        "CreateDate": "2020-03-18T22:00:50+00:00"
    }
}
```

At this point we can create an AWS **profile** to be used in future:

```bash
➜ aws configure --profile kops
AWS Access Key ID [None]: *****
AWS Secret Access Key [None]: *****
Default region name [eu-west-2]:
Default output format [json]:
```

Note that **aws configure** will configure a **default** profile

```bash
➜ bat ~/.aws/credentials
───────┬───────────────────────────────────────────────────────────────────────────────────────
       │ File: /Users/davidainslie/.aws/credentials
───────┼───────────────────────────────────────────────────────────────────────────────────────
   1   │ [default]
   2   │ aws_access_key_id = *****
   3   │ aws_secret_access_key = *****
   4   │
   5   │ [devops]
   6   │ aws_access_key_id = *****
   7   │ aws_secret_access_key = *****
   8   |
   9   | [kops]
   8   │ aws_access_key_id = *****
   9   │ aws_secret_access_key = *****
```

```bash
➜ bat ~/.aws/config
───────┬───────────────────────────────────────────────────────────────────────────────────────
       │ File: /Users/davidainslie/.aws/config
───────┼───────────────────────────────────────────────────────────────────────────────────────
   1   │ [default]
   2   │ region = eu-west-2
   3   │ output = json
   4   │
   5   │ [profile kops]
   6   │ region = eu-west-2
   7   │ output = json
   8   │
   9   │ [profile devops]
  10   │ region = eu-west-2
  11   │ output = json
```

## Create Bucket - Same Name as Cluster

```bash
➜ aws s3api create-bucket --bucket backwards.k8s.local --create-bucket-configuration LocationConstraint=eu-west-2
{
    "Location": "http://backwards.k8s.local.s3.amazonaws.com/"
}

➜ export KOPS_STATE_STORE=s3://backwards.k8s.local
```

## DNS Configuration

As long as the cluster has the .k8s.local at the end of the name Kops will not use Public DNS. e.g.

**backwards.k8s.local**

## Setup Keys

```bash
➜ aws ec2 create-key-pair --key-name backwards-k8s | jq -r '.KeyMaterial' > backwards-k8s.pem

➜ mv backwards-k8s.pem ~/.ssh/ 

➜ chmod 400 ~/.ssh/backwards-k8s.pem

➜ ssh-keygen -y -f ~/.ssh/backwards-k8s.pem > ~/.ssh/backwards-k8s.pub
```

## Create Cluster with Kops

```bash
➜ export AWS_REGION=eu-west-2
➜ export NAME=backwards.k8s.local
➜ export KOPS_STATE_STORE=s3://$NAME
```

```bash
➜ kops create cluster \
	--cloud aws \
	--networking kubenet \
	--name $NAME \
	--master-size t2.micro \
	--node-size t3.small \
	--zones eu-west-2a \
	--ssh-public-key ~/.ssh/backwards-k8s.pub \
	--yes
```

Some AWS node prices:

|          | CPU  | Memory | Instance Storage | Price            |
| -------- | ---- | ------ | ---------------- | ---------------- |
| t2.micro | 1    | 1 GiB  | EBS Only         | $0.0116 per Hour |
| t2.small | 1    | 2 GiB  | EBS Only         | $0.023 per Hour  |
| t3.micro | 2    | 1 GiB  | EBS Only         | $0.0104 per Hour |
| t3.small | 2    | 2 GiB  | EBS Only         | $0.0208 per Hour |

## Validate

```bash
➜ kops validate cluster
Using cluster from kubectl context: backwards.k8s.local

Validating cluster backwards.k8s.local

INSTANCE GROUPS
NAME			         ROLE	   MACHINETYPE	 MIN	 MAX	 SUBNETS
master-eu-west-2a	 Master	 t2.micro	     1	   1	   eu-west-2a
nodes			         Node	   t2.micro	     2	   2	   eu-west-2a

NODE STATUS
NAME						                             ROLE	   READY
ip-172-20-37-230.eu-west-2.compute.internal	 node	   True
ip-172-20-44-164.eu-west-2.compute.internal	 master	 True
ip-172-20-61-62.eu-west-2.compute.internal	 node	   True
```

## Deploy First Application onto Kubernetes

```bash
➜ kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml
namespace/kube-ingress created
serviceaccount/nginx-ingress-controller created
clusterrole.rbac.authorization.k8s.io/nginx-ingress-controller created
role.rbac.authorization.k8s.io/nginx-ingress-controller created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-controller created
rolebinding.rbac.authorization.k8s.io/nginx-ingress-controller created
service/nginx-default-backend created
configmap/ingress-nginx created
service/ingress-nginx created
```

```bash
➜ kubectl -n kube-ingress get all
NAME                            TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)                      AGE
service/ingress-nginx           LoadBalancer   100.70.40.195    ad507028f0f7f48f8b1c593f396afcc9-1932950385.eu-west-2.elb.amazonaws.com   80:31422/TCP,443:31381/TCP   95s
service/nginx-default-backend   ClusterIP      100.66.193.129   <none>                                                                    80/TCP                       95s
```

```bash
➜ kubectl create -f https://raw.githubusercontent.com/diegopacheco/k8s-specs/master/aws/go-demo-2.yml
ingress.extensions/go-demo-2 created
service/go-demo-2-db created
service/go-demo-2-api created
```

```bash
➜ kubectl get all
NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
service/go-demo-2-api   ClusterIP   100.67.158.152   <none>        8080/TCP    62s
service/go-demo-2-db    ClusterIP   100.64.222.153   <none>        27017/TCP   62s
service/kubernetes      ClusterIP   100.64.0.1       <none>        443/TCP     15m
```

```bash
➜ CLUSTER_DNS=$(aws elb describe-load-balancers | jq -r '.LoadBalancerDescriptions[1].DNSName')
```

```bash
➜ curl -i "http://$CLUSTER_DNS/demo/hello"
```

## Scaling

To scale our kops cluster we can:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s at ☸️ backwards.k8s.local
➜ kops edit ig nodes
Using cluster from kubectl context: backwards.k8s.local
```

Then:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s at ☸️ backwards.k8s.local
➜ kops update cluster --yes
```

## Destroy the Cluster

```bash
➜ kops delete cluster backwards.k8s.local --yes
```

## Next time...

```bash
➜ export AWS_PROFILE=kops && \
  export AWS_REGION=eu-west-2 && \
  export NAME=backwards.k8s.local && \
  export KOPS_STATE_STORE=s3://$NAME
```

and then run the **kops** command to bring the cluster back up.
