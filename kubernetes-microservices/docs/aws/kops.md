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
$ ssh -i video-keypair.pem ec2-user@35.178.250.8

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
[ec2-user@ip-172-31-11-187 ~]$
```

