data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}


module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment.name}-vpc-"
  cidr = "${var.environment.subnet_prefix}.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["${var.environment.subnet_prefix}.101.0/24", "${var.environment.subnet_prefix}.102.0/24", "${var.environment.subnet_prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}


# Autoscaling group

module "blog_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
 
  name = "${var.environment.name}-asg-"

  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = 1
  
  vpc_zone_identifier       = module.blog_vpc.public_subnets
  target_group_arns         = [module.blog_alb.target_groups["ex-instance"].arn]
  security_groups           = [module.blog_sg.security_group_id]

  image_id          = data.aws_ami.app_ami.id
  instance_type     = var.instance_type
  
  tags = {
    Terraform   = "true"
    Environment = var.environment.name
  }
}


module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "${var.environment.name}-alb-"

  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]

   listeners = {
    ex-http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "ex-instance"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

      forward = {
        target_group_key = "ex-instance"
      }
    }
  }

  target_groups = {
    ex-instance = {
      name_prefix      = "blog-"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      target_id        = "target_group_ex-instance_id"
    }
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment.name
  }
}


module "blog_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.environment.name}-sg-"
  description = "Security group for our Blog created by Terraform"
  vpc_id      = module.blog_vpc.vpc_id

  ingress_cidr_blocks     = ["0.0.0.0/0"]
  ingress_rules           = ["http-80-tcp","https-443-tcp", "ssh-tcp"]

  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_rules            = ["all-all"]
  
}