    # ************************
    # vars.tf
    # ************************
     
    variable "AWS_ACCESS_KEY" {}
    variable "AWS_SECRET_KEY" {}
    variable "AWS_REGION" {
      default = "eu-west-2"
    }
    variable "AMIS" {
      type = "map"
      default = {
        # *******************************************
        # https://cloud-images.ubuntu.com/locator/ec2/
        #
        #   London => eu-west-2
        #   OS        => UBUNTU Xenial 16.04 LTS
        #   AMI_ID    => ami-7ad7c21e
        #
        #   AMI shortcut (AMAZON MACHINE IMAGE)
        #
        # *******************************************
        eu-west-2 = "ami-7ad7c21e"
      }
    }
     
    # ************************
    # provider.tf
    # ************************
    provider "aws" {
        access_key = "${var.AWS_ACCESS_KEY}"
        secret_key = "${var.AWS_SECRET_KEY}"
        region = "${var.AWS_REGION}"
    }
     
     
    # ************************
    # instance.tf
    # ************************
    resource "aws_instance" "backwards" {
      ami = "${lookup(var.AMIS, var.AWS_REGION)}"
      tags { Name = "backwards" }
      instance_type = "t2.micro"
      provisioner "local-exec" {
         command = "echo ${aws_instance.backwards.private_ip} >> private_ips.txt"
      }
    }
    output "ip" {
        value = "${aws_instance.backwards.public_ip}"
    }