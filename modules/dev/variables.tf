variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}

variable "environment" {
  description = "Variable to select environment"

  type = object {
    name = String
    subnet_prefix = String
  }

  default = {
    name = "dev"
    subnet_prefix = "10.0"
  }
}