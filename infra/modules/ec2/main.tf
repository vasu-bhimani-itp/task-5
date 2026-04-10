locals {
  tag = {
    Name    = var.Name
    Owner   = var.Owner
    Project = var.Project
  }

  account_id = data.aws_caller_identity.current.account_id
}


data "aws_caller_identity" "current" {}



resource "aws_instance" "example" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  key_name                    = var.key_pair
  vpc_security_group_ids      = [aws_security_group.allow_tls.id]
  iam_instance_profile        = var.iam_instance_profile_name

  user_data_base64 = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    aws_region = var.aws_region
    account_id = local.account_id
    repo_name  = var.repo_name
  }))

  volume_tags = local.tag
  tags = {
    uid = "vasubhimani"   
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.main_vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  for_each = toset(var.security_group_allow_port)

  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.value
  ip_protocol       = "tcp"
  to_port           = each.value
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

