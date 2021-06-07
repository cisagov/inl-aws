module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc"
  namespace  = "${var.app}"
  name       = "vpc"
  cidr_block = "10.0.0.0/16"
}