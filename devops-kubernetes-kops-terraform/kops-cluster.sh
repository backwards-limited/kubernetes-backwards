#!/usr/bin/env bash

kops create cluster \
  --name=backwards.tech \
  --state=s3://backwards.tech \
  --authorization RBAC \
  --zones=eu-west-2a \
  --node-count=2 \
  --node-size=t2.micro \
  --master-size=t2.micro \
  --master-count=1 \
  --dns-zone=backwards.tech \
  --out=backwards-terraform \
  --target=terraform \
  --ssh-public-key=~/.ssh/devops.pub