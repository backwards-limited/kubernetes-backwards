locals = {
  cluster_name                 = "backwards.tech"
  master_autoscaling_group_ids = ["${aws_autoscaling_group.master-eu-west-2a-masters-backwards-tech.id}"]
  master_security_group_ids    = ["${aws_security_group.masters-backwards-tech.id}"]
  masters_role_arn             = "${aws_iam_role.masters-backwards-tech.arn}"
  masters_role_name            = "${aws_iam_role.masters-backwards-tech.name}"
  node_autoscaling_group_ids   = ["${aws_autoscaling_group.nodes-backwards-tech.id}"]
  node_security_group_ids      = ["${aws_security_group.nodes-backwards-tech.id}"]
  node_subnet_ids              = ["${aws_subnet.eu-west-2a-backwards-tech.id}"]
  nodes_role_arn               = "${aws_iam_role.nodes-backwards-tech.arn}"
  nodes_role_name              = "${aws_iam_role.nodes-backwards-tech.name}"
  region                       = "eu-west-2"
  route_table_public_id        = "${aws_route_table.backwards-tech.id}"
  subnet_eu-west-2a_id         = "${aws_subnet.eu-west-2a-backwards-tech.id}"
  vpc_cidr_block               = "${aws_vpc.backwards-tech.cidr_block}"
  vpc_id                       = "${aws_vpc.backwards-tech.id}"
}

output "cluster_name" {
  value = "backwards.tech"
}

output "master_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.master-eu-west-2a-masters-backwards-tech.id}"]
}

output "master_security_group_ids" {
  value = ["${aws_security_group.masters-backwards-tech.id}"]
}

output "masters_role_arn" {
  value = "${aws_iam_role.masters-backwards-tech.arn}"
}

output "masters_role_name" {
  value = "${aws_iam_role.masters-backwards-tech.name}"
}

output "node_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.nodes-backwards-tech.id}"]
}

output "node_security_group_ids" {
  value = ["${aws_security_group.nodes-backwards-tech.id}"]
}

output "node_subnet_ids" {
  value = ["${aws_subnet.eu-west-2a-backwards-tech.id}"]
}

output "nodes_role_arn" {
  value = "${aws_iam_role.nodes-backwards-tech.arn}"
}

output "nodes_role_name" {
  value = "${aws_iam_role.nodes-backwards-tech.name}"
}

output "region" {
  value = "eu-west-2"
}

output "route_table_public_id" {
  value = "${aws_route_table.backwards-tech.id}"
}

output "subnet_eu-west-2a_id" {
  value = "${aws_subnet.eu-west-2a-backwards-tech.id}"
}

output "vpc_cidr_block" {
  value = "${aws_vpc.backwards-tech.cidr_block}"
}

output "vpc_id" {
  value = "${aws_vpc.backwards-tech.id}"
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_autoscaling_group" "master-eu-west-2a-masters-backwards-tech" {
  name                 = "master-eu-west-2a.masters.backwards.tech"
  launch_configuration = "${aws_launch_configuration.master-eu-west-2a-masters-backwards-tech.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["${aws_subnet.eu-west-2a-backwards-tech.id}"]

  tag = {
    key                 = "KubernetesCluster"
    value               = "backwards.tech"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "master-eu-west-2a.masters.backwards.tech"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "master-eu-west-2a"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "nodes-backwards-tech" {
  name                 = "nodes.backwards.tech"
  launch_configuration = "${aws_launch_configuration.nodes-backwards-tech.id}"
  max_size             = 2
  min_size             = 2
  vpc_zone_identifier  = ["${aws_subnet.eu-west-2a-backwards-tech.id}"]

  tag = {
    key                 = "KubernetesCluster"
    value               = "backwards.tech"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "nodes.backwards.tech"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "nodes"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_ebs_volume" "a-etcd-events-backwards-tech" {
  availability_zone = "eu-west-2a"
  size              = 20
  type              = "gp2"
  encrypted         = false

  tags = {
    KubernetesCluster                      = "backwards.tech"
    Name                                   = "a.etcd-events.backwards.tech"
    "k8s.io/etcd/events"                   = "a/a"
    "k8s.io/role/master"                   = "1"
    "kubernetes.io/cluster/backwards.tech" = "owned"
  }
}

resource "aws_ebs_volume" "a-etcd-main-backwards-tech" {
  availability_zone = "eu-west-2a"
  size              = 20
  type              = "gp2"
  encrypted         = false

  tags = {
    KubernetesCluster                      = "backwards.tech"
    Name                                   = "a.etcd-main.backwards.tech"
    "k8s.io/etcd/main"                     = "a/a"
    "k8s.io/role/master"                   = "1"
    "kubernetes.io/cluster/backwards.tech" = "owned"
  }
}

resource "aws_iam_instance_profile" "masters-backwards-tech" {
  name = "masters.backwards.tech"
  role = "${aws_iam_role.masters-backwards-tech.name}"
}

resource "aws_iam_instance_profile" "nodes-backwards-tech" {
  name = "nodes.backwards.tech"
  role = "${aws_iam_role.nodes-backwards-tech.name}"
}

resource "aws_iam_role" "masters-backwards-tech" {
  name               = "masters.backwards.tech"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_masters.backwards.tech_policy")}"
}

resource "aws_iam_role" "nodes-backwards-tech" {
  name               = "nodes.backwards.tech"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_nodes.backwards.tech_policy")}"
}

resource "aws_iam_role_policy" "masters-backwards-tech" {
  name   = "masters.backwards.tech"
  role   = "${aws_iam_role.masters-backwards-tech.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_masters.backwards.tech_policy")}"
}

resource "aws_iam_role_policy" "nodes-backwards-tech" {
  name   = "nodes.backwards.tech"
  role   = "${aws_iam_role.nodes-backwards-tech.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_nodes.backwards.tech_policy")}"
}

resource "aws_internet_gateway" "backwards-tech" {
  vpc_id = "${aws_vpc.backwards-tech.id}"

  tags = {
    KubernetesCluster                      = "backwards.tech"
    Name                                   = "backwards.tech"
    "kubernetes.io/cluster/backwards.tech" = "owned"
  }
}

resource "aws_key_pair" "kubernetes-backwards-tech-09dcd772093f0ffce7aef0a8bfe581ad" {
  key_name   = "kubernetes.backwards.tech-09:dc:d7:72:09:3f:0f:fc:e7:ae:f0:a8:bf:e5:81:ad"
  public_key = "${file("${path.module}/data/aws_key_pair_kubernetes.backwards.tech-09dcd772093f0ffce7aef0a8bfe581ad_public_key")}"
}

resource "aws_launch_configuration" "master-eu-west-2a-masters-backwards-tech" {
  name_prefix                 = "master-eu-west-2a.masters.backwards.tech-"
  image_id                    = "ami-0b7083afcef773c47"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.kubernetes-backwards-tech-09dcd772093f0ffce7aef0a8bfe581ad.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.masters-backwards-tech.id}"
  security_groups             = ["${aws_security_group.masters-backwards-tech.id}"]
  associate_public_ip_address = true
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-eu-west-2a.masters.backwards.tech_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 64
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_launch_configuration" "nodes-backwards-tech" {
  name_prefix                 = "nodes.backwards.tech-"
  image_id                    = "ami-0b7083afcef773c47"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.kubernetes-backwards-tech-09dcd772093f0ffce7aef0a8bfe581ad.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.nodes-backwards-tech.id}"
  security_groups             = ["${aws_security_group.nodes-backwards-tech.id}"]
  associate_public_ip_address = true
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_nodes.backwards.tech_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 128
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_route" "0-0-0-0--0" {
  route_table_id         = "${aws_route_table.backwards-tech.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.backwards-tech.id}"
}

resource "aws_route_table" "backwards-tech" {
  vpc_id = "${aws_vpc.backwards-tech.id}"

  tags = {
    KubernetesCluster                      = "backwards.tech"
    Name                                   = "backwards.tech"
    "kubernetes.io/cluster/backwards.tech" = "owned"
    "kubernetes.io/kops/role"              = "public"
  }
}

resource "aws_route_table_association" "eu-west-2a-backwards-tech" {
  subnet_id      = "${aws_subnet.eu-west-2a-backwards-tech.id}"
  route_table_id = "${aws_route_table.backwards-tech.id}"
}

resource "aws_security_group" "masters-backwards-tech" {
  name        = "masters.backwards.tech"
  vpc_id      = "${aws_vpc.backwards-tech.id}"
  description = "Security group for masters"

  tags = {
    KubernetesCluster                      = "backwards.tech"
    Name                                   = "masters.backwards.tech"
    "kubernetes.io/cluster/backwards.tech" = "owned"
  }
}

resource "aws_security_group" "nodes-backwards-tech" {
  name        = "nodes.backwards.tech"
  vpc_id      = "${aws_vpc.backwards-tech.id}"
  description = "Security group for nodes"

  tags = {
    KubernetesCluster                      = "backwards.tech"
    Name                                   = "nodes.backwards.tech"
    "kubernetes.io/cluster/backwards.tech" = "owned"
  }
}

resource "aws_security_group_rule" "all-master-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-backwards-tech.id}"
  source_security_group_id = "${aws_security_group.masters-backwards-tech.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-master-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-backwards-tech.id}"
  source_security_group_id = "${aws_security_group.masters-backwards-tech.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-node-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-backwards-tech.id}"
  source_security_group_id = "${aws_security_group.nodes-backwards-tech.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "https-external-to-master-0-0-0-0--0" {
  type              = "ingress"
  security_group_id = "${aws_security_group.masters-backwards-tech.id}"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.masters-backwards-tech.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.nodes-backwards-tech.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node-to-master-tcp-1-2379" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-backwards-tech.id}"
  source_security_group_id = "${aws_security_group.nodes-backwards-tech.id}"
  from_port                = 1
  to_port                  = 2379
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-tcp-2382-4000" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-backwards-tech.id}"
  source_security_group_id = "${aws_security_group.nodes-backwards-tech.id}"
  from_port                = 2382
  to_port                  = 4000
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-tcp-4003-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-backwards-tech.id}"
  source_security_group_id = "${aws_security_group.nodes-backwards-tech.id}"
  from_port                = 4003
  to_port                  = 65535
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-udp-1-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-backwards-tech.id}"
  source_security_group_id = "${aws_security_group.nodes-backwards-tech.id}"
  from_port                = 1
  to_port                  = 65535
  protocol                 = "udp"
}

resource "aws_security_group_rule" "ssh-external-to-master-0-0-0-0--0" {
  type              = "ingress"
  security_group_id = "${aws_security_group.masters-backwards-tech.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ssh-external-to-node-0-0-0-0--0" {
  type              = "ingress"
  security_group_id = "${aws_security_group.nodes-backwards-tech.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_subnet" "eu-west-2a-backwards-tech" {
  vpc_id            = "${aws_vpc.backwards-tech.id}"
  cidr_block        = "172.20.32.0/19"
  availability_zone = "eu-west-2a"

  tags = {
    KubernetesCluster                      = "backwards.tech"
    Name                                   = "eu-west-2a.backwards.tech"
    SubnetType                             = "Public"
    "kubernetes.io/cluster/backwards.tech" = "owned"
    "kubernetes.io/role/elb"               = "1"
  }
}

resource "aws_vpc" "backwards-tech" {
  cidr_block           = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    KubernetesCluster                      = "backwards.tech"
    Name                                   = "backwards.tech"
    "kubernetes.io/cluster/backwards.tech" = "owned"
  }
}

resource "aws_vpc_dhcp_options" "backwards-tech" {
  domain_name         = "eu-west-2.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    KubernetesCluster                      = "backwards.tech"
    Name                                   = "backwards.tech"
    "kubernetes.io/cluster/backwards.tech" = "owned"
  }
}

resource "aws_vpc_dhcp_options_association" "backwards-tech" {
  vpc_id          = "${aws_vpc.backwards-tech.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.backwards-tech.id}"
}

terraform = {
  required_version = ">= 0.9.3"
}
