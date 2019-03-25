# Kops

If you have missed previous setups, then apply the following:

```bash
$ brew update && brew install kops
```

Though initially we are going to launch an EC2 instance manually.

![Launching an EC2 instance](../images/launching-an-ec2-instance.png)

---

![AMI selection](../images/ami-selection.png)

---

![Minimal](../images/minimal.png)

Go through the configurations (accepting the defaults) and add a **tag**:

![Tag](../images/tag.png)

and add a bit of security:

![My IP](../images/my-ip.png)

Upon launching, we'll be asked to select or create a **key pair** which will allow us to log into this instance. When a key pair is created, download the key pair file, which is used for login.

![Create keypair](../images/create-keypair.png)

Copy the key pair to the k8s directory with our manifests and then **ssh** onto our instance given by the generated IP address:

![Minimal instance](../images/minimal-instance.png)

```bash
$ chmod go-rwx video-keypair.pem
```

```bash
$ ssh -i video-keypair.pem ec2-user@35.177.7.97
The authenticity of host '35.177.7.97 (35.177.7.97)' can't be established.
ECDSA key fingerprint is SHA256:rz24AbSgSq0zcSOgv1TVk+e+kI7eS82YWnSWTpa2dcw.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '35.177.7.97' (ECDSA) to the list of known hosts.

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
[ec2-user@ip-172-31-10-20 ~]$ curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x ./kops
sudo mv ./kops /usr/local/bin/

[ec2-user@ip-172-31-10-20 ~]$ curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

## Kops IAM User

We can run:

```bash
[ec2-user@ip-172-31-10-20 ~]$ aws iam create-group --group-name kops

aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops

aws iam create-user --user-name kops

aws iam add-user-to-group --user-name kops --group-name kops

aws iam create-access-key --user-name kops
```

Or go through the UI:

![Start IAM](../images/start-iam.png)

Create a **new group**:

![Start create group](../images/start-create-group.png)

---

![Kops group creation](../images/kops-group-creation.png)

---

![Amazon EC2 full access](../images/amazon-ec2-full-access.png)

---

![Amazon Route53 full access](../images/amazon-route53-full-access.png)

---

![Amazon S3 full access](../images/amazon-s3-full-access.png)

---

![IAM full access](../images/iam-full-access.png)

![Amazon VPC full access](../images/amazon-vpc-full-access.png)

The **next step** gives us a review:

![IAM review](../images/iam-review.png)

Now **add user**:

![Add user](../images/add-user.png)

---

![User access type](../images/user-access-type.png)

---

![Add user to group](../images/add-user-to-group.png)

## AWS Configure

```bash
[ec2-user@ip-172-31-10-20 ~]$ aws configure
AWS Access Key ID [None]: AKIAIE6KXD4WFKA33UTQ
AWS Secret Access Key [None]: <your secret>
Default region name [None]: eu-west-2
Default output format [None]:
[ec2-user@ip-172-31-10-20 ~]$
```

```bash
[ec2-user@ip-172-31-10-20 ~]$ aws iam list-users
{
    "Users": [
        {
            "UserName": "kops",
            "Path": "/",
            "CreateDate": "2019-03-25T22:17:24Z",
            "UserId": "AIDAJW7RH5XKHE6VMCY2E",
            "Arn": "arn:aws:iam::890953945913:user/kops"
        }
    ]
}
```

```bash
[ec2-user@ip-172-31-10-20 ~]$ export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
[ec2-user@ip-172-31-10-20 ~]$ export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
```

