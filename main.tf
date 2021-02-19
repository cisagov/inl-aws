
#=================================================
#  VPC and SUBNETS
#=================================================

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc?ref=tags/0.14.0"
  namespace  = "${var.app}"
  name       = "vpc"
  cidr_block = "10.0.0.0/16"
}

locals {
  public_cidr_block  = cidrsubnet(module.vpc.vpc_cidr_block, 1, 0)
  private_cidr_block = cidrsubnet(module.vpc.vpc_cidr_block, 1, 1)
}

module "subnets" {
  source              = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets?ref=tags/0.23.0"
  namespace           = var.app
  name                = "subnet"
  vpc_id              = module.vpc.vpc_id
  igw_id              = module.vpc.igw_id
  cidr_block          = "10.0.0.0/16"
  availability_zones  = ["${var.region}a", "${var.region}b"]
  nat_gateway_enabled = true
}

resource "aws_acm_certificate" "vpn_client_root" {
  private_key       = file("certs/inl-vpn.key")
  certificate_body  = file("certs/inl-vpn.crt")
  certificate_chain = file("certs/ca.crt")
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "INL VPN Endpoint"
  client_cidr_block      = "10.1.0.0/16"
  split_tunnel           = true
  server_certificate_arn = aws_acm_certificate.vpn_client_root.arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client_root.arn
  }

  connection_log_options {
    enabled = false
  }
}

resource "aws_security_group" "vpn_access" {
  vpc_id = module.vpc.vpc_id
  name   = "inl-vpn-sg"

  ingress {
    from_port   = 443
    protocol    = "UDP"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "Incoming VPN Connection"
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn_subnets" {
  count = length(module.subnets.private_subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = module.subnets.private_subnet_ids[count.index]
  # security_groups        = [aws_security_group.vpn_access.id]

  lifecycle {
    ignore_changes = [subnet_id]
  }
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = module.vpc.vpc_cidr_block
  authorize_all_groups   = true
}
