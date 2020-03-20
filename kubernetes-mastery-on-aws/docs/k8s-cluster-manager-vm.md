# Kubernetes Cluster Manager VM

Let's create a VM (locally) to be used to remotely manager a Kubernetes cluster (in our case, on AWS):

```bash
kubernetes-backwards/kubernetes-mastery-on-aws
➜ mkdir k8s

kubernetes-backwards/kubernetes-mastery-on-aws
➜ cd k8s
```

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s
➜ vagrant init ubuntu/xenial64
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment!
```

The following will download everything required to boot an **ubuntu/xenial64** VM:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s
➜ vagrant box add ubuntu/xenial64
==> box: Loading metadata for box 'ubuntu/xenial64'
    box: URL: https://vagrantcloud.com/ubuntu/xenial64
==> box: Adding box 'ubuntu/xenial64' (v20200311.0.0) for provider: virtualbox
    box: Downloading: https://vagrantcloud.com/ubuntu/boxes/xenial64/versions/20200311.0.0/providers/virtualbox.box
    box: Download redirected to host: cloud-images.ubuntu.com
==> box: Successfully added box 'ubuntu/xenial64' (v20200311.0.0) for 'virtualbox'!
```

Now edit the vagrant file (with any editor such as Vim, Sublime, VS Code etc):

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s
➜ code Vagrantfile
```

where we want to duplicate and change the following :

```ruby
# config.vm.network "forwarded_port", guest: 80, host: 8080
```

to

```ruby
config.vm.network "forwarded_port", guest: 8001, host: 8001
```

which configures Vagrant to forward this port from your machine to the guest VM.

Now we can bring up the VM:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s
➜ vagrant up --provider virtualbox
...
```

Let's just double check the VM is up:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s
➜ vagrant status
Current machine states:

default                   running (virtualbox)

The VM is running. To stop this VM, you can run `vagrant halt` to
shut it down forcefully, or you can run `vagrant suspend` to simply
suspend the virtual machine. In either case, to restart it again,
simply run `vagrant up`.
```

We can now SSH into this VM:

```bash
kubernetes-backwards/kubernetes-mastery-on-aws/k8s
➜ vagrant ssh
Welcome to Ubuntu 16.04.6 LTS (GNU/Linux 4.4.0-174-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage


0 packages can be updated.
0 updates are security updates.

New release '18.04.4 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


vagrant@ubuntu-xenial:~$
```

Let's do a **package update** to get our VM up to date:

```bash
vagrant@ubuntu-xenial:~$ sudo apt-get update
...
```

Now update the **time synchronisation** to avoid a cloud provider revoking any API calls when it detects out of synch clocks.

```bash
vagrant@ubuntu-xenial:~$ sudo apt-get install ntp ntpdate ntpstat
...
```

Now set up **ntp** by first stopping ntp:

```bash
vagrant@ubuntu-xenial:~$ sudo service ntp stop
```

Then:

```bash
vagrant@ubuntu-xenial:~$ sudo ntpdate time.nist.gov
17 Mar 15:42:39 ntpdate[3544]: adjust time server 132.163.97.1 offset 0.002725 sec
```

```bash
vagrant@ubuntu-xenial:~$ sudo service ntp status
```

```bash
vagrant@ubuntu-xenial:~$ sudo service ntp start
```

```bash
vagrant@ubuntu-xenial:~$ ntpstat
synchronised to NTP server (85.199.214.100) at stratum 2
   time correct to within 196 ms
   polling server every 64 s
```

(keep running that last command until we see **synchronised**)

Now we want to check AWS connectivity. Install AWS CLI:

```bash
vagrant@ubuntu-xenial:~$ sudo apt-get install python-pip
```

```bash
vagrant@ubuntu-xenial:~$ pip install awscli --user
```

```bash
vagrant@ubuntu-xenial:~$ aws configure
AWS Access Key ID [None]: *****
AWS Secret Access Key [None]: *****
Default region name [None]: eu-west-2
Default output format [None]: json
```

```bash
vagrant@ubuntu-xenial:~$ aws ec2 describe-regions
{
    "Regions": [
        ...
        {
            "OptInStatus": "opt-in-not-required",
            "Endpoint": "ec2.eu-west-1.amazonaws.com",
            "RegionName": "eu-west-1"
        },
        ...
    ]
}
```

and we are connected.

## Deploy Kubernetes Cluster on AWS

We shall use [conjure-up](https://conjure-up.io/):

```bash
vagrant@ubuntu-xenial:~$ sudo snap install conjure-up --classic
```

Let's "conjure up" a Kubernetes cluster by going through a bunch of prompts:

```bash
vagrant@ubuntu-xenial:~$ conjure-up kubernetes
```

![Kubernetes Core](images/conjure-up-0.png)

---

![Choose cloud](images/conjure-up-1.png)

---

![Credentials](images/conjure-up-2.png)

---

![Region](images/conjure-up-3.png)

At this point, you may want to double check pricing for your region:

![Pricing](images/pricing.png)

---

![Controller](images/conjure-up-4.png)

---

![Network plugin](images/conjure-up-5.png)

Next we do not need a **sudo** password:

![Sudo](images/conjure-up-6.png)

---

Finally, accept component defaults and deploy:

![Deploy](images/conjure-up-7.png)

---

![Done](images/conjure-up-done.png)

```bash
vagrant@ubuntu-xenial:~$ juju status
Model                        Controller          Cloud/Region   Version  SLA          Timestamp
conjure-kubernetes-core-e35  conjure-up-aws-2b0  aws/eu-west-2  2.6.10   unsupported  17:55:05Z

App                Version   Status  Scale  Charm              Store       Rev  OS      Notes
aws-integrator     1.16.266  active      1  aws-integrator     jujucharms   28  ubuntu
containerd                   active      2  containerd         jujucharms   61  ubuntu
easyrsa            3.0.1     active      1  easyrsa            jujucharms  296  ubuntu
etcd               3.3.15    active      1  etcd               jujucharms  496  ubuntu
flannel            0.11.0    active      2  flannel            jujucharms  468  ubuntu
kubernetes-master  1.17.4    active      1  kubernetes-master  jujucharms  808  ubuntu  exposed
kubernetes-worker  1.17.3    active      1  kubernetes-worker  jujucharms  634  ubuntu  exposed

Unit                  Workload  Agent  Machine  Public address  Ports           Message
aws-integrator/0*     active    idle   0        3.8.150.168                     Ready
easyrsa/0*            active    idle   0/lxd/0  252.8.64.108                    Certificate Authority connected.
etcd/0*               active    idle   0        3.8.150.168     2379/tcp        Healthy with 1 known peer
kubernetes-master/0*  active    idle   0        3.8.150.168     6443/tcp        Kubernetes master running.
  containerd/1        active    idle            3.8.150.168                     Container runtime available
  flannel/1           active    idle            3.8.150.168                     Flannel subnet 10.1.49.1/24
kubernetes-worker/0*  active    idle   1        3.8.184.47      80/tcp,443/tcp  Kubernetes worker running.
  containerd/0*       active    idle            3.8.184.47                      Container runtime available
  flannel/0*          active    idle            3.8.184.47                      Flannel subnet 10.1.52.1/24

Machine  State    DNS           Inst id              Series  AZ          Message
0        started  3.8.150.168   i-0f562b2c6b653447a  bionic  eu-west-2a  running
0/lxd/0  started  252.8.64.108  juju-c1f8fc-0-lxd-0  bionic  eu-west-2a  Container started
1        started  3.8.184.47    i-098a3c3ca3602cfa2  bionic  eu-west-2b  running
```

Once deployed, go into the AWS console and stop the EC2 instance to reduce its size and restart:

![Micro](images/micro.png)

## AWS IAM

Securely controls access to your AWS resources:

- Who can authenticate (sign in) to your account
- What permissions do the signed in users have (authorization)

When you sign into AWS with your email and password, your identity is called **AWS account root user**.

Use IAM to setup different permissions for different people. IAM also provides credentials to applications running on EC2 instances to access other AWS resources.

**Why is IAM important to Kubernetes?**

- Kubernetes is an application that is running on AWS EC2 instances
- Kubernetes needs to talk to AWS to provision cloud resources e.g. ELB, EBS, EFS, S3, Route 53

How does IAM work for EC2 applications?

![IAM working](images/iam-working.png)