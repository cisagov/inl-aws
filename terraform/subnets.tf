module "subnets" {
  source              = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets"
  namespace           = var.app
  name                = "subnet"
  vpc_id              = module.vpc.vpc_id
  igw_id              = module.vpc.igw_id
  cidr_block          = "10.0.0.0/16"
  availability_zones  = ["${var.region}a", "${var.region}b"]
  nat_gateway_enabled = true
}