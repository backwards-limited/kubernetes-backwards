# Virtual Environment (Optional)

## Setup

Firstly some [Vagrant](http://sourabhbajaj.com/mac-setup/Vagrant/README.html) setup which will provide a **Linux** virtual environment, no matter which OS you are running on.

If you have issues with setting up Vagrant (in the steps below as I did) this may be because of already having Vagrant configured but with incompatible library versions, firstly run:

```bash
vagrant plugin expunge
```

Now we can proceed:

```bash
cd ~

mkdir ubuntu

cd ubuntu

vagrant init ubuntu/xenial64

vagrant up

vagrant ssh-config

vagrant ssh
```

Your prompt will end up as:

```bash
vagrant@ubuntu-xenial:~$
```

## Kubernetes

At your "new" prompt we shall install Kubernetes client:

```bash
wget https://storage.googleapis.com/kubernetes-release/release/v1.4.3/bin/linux/amd64/kubectl

sudo mv kubectl /usr/local/bin/

sudo chmod +x /usr/local/bin/kubectl
```

## Kops

At your "new" prompt we shall install Kops:

```bash
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64

chmod +x kops-linux-amd64

sudo apt-get install python-pip

sudo pip install awscli
```

When you are done with the environment, don't forget to cleanup:

```bash
vagrant halt
```