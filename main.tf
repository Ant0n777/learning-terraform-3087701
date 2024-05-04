data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "blog" {
  ami                    = data.aws_ami.app_ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.aws_module_sg.security_group_id]
  key_name = "aws_instance_blog_key"

  tags = {
    Name = "Learning Terraform"
  }
}


module "aws_key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "aws_instance_blog_key"
  create_private_key = true
}


module "aws_module_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "blog"
  description = "Security group for our Blog created by Terraform"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks     = ["0.0.0.0/0"]
  ingress_rules           = ["http-80-tcp","https-443-tcp", "ssh-tcp"]

  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_rules            = ["all-all"]
  
}