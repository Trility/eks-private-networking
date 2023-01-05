data "aws_acm_certificate" "server" {
  domain = "server"
}

data "aws_acm_certificate" "client" {
  domain = "client1.domain.tld"
}

resource "aws_security_group" "vpn_access" {
  vpc_id      = aws_vpc.vpc.id
  description = "clientvpn public access"
  name        = "clientvpn"

  ingress {
    description = "https udp from internet"
    from_port   = 443
    protocol    = "UDP"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  }
  ingress {
    description = "https tcp from internet"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  }
  ingress {
    description = "dns udp from internet"
    from_port   = 53
    protocol    = "UDP"
    to_port     = 53
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  }
  ingress {
    description = "dhs tcp from internet"
    from_port   = 53
    protocol    = "tcp"
    to_port     = 53
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  }
  ingress {
    description = "http tcp from internet"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  }
  egress {
    description = "all outbount"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-egress-sgr
  }
}

resource "aws_route53_resolver_endpoint" "clientvpn" {
  name      = "clientvpn"
  direction = "INBOUND"
  security_group_ids = [
    aws_security_group.vpn_access.id
  ]

  ip_address {
    subnet_id = aws_subnet.public_subnets["usw2-az1-public"].id
  }

  ip_address {
    subnet_id = aws_subnet.public_subnets["usw2-az2-public"].id
  }
}

data "aws_route53_resolver_endpoint" "clientvpn" {
  resolver_endpoint_id = aws_route53_resolver_endpoint.clientvpn.id
}

resource "aws_cloudwatch_log_group" "clientvpn" {
  name              = "clientvpn-${aws_vpc.vpc.id}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "clientvpn" {
  name           = "clientvpn-${aws_vpc.vpc.id}"
  log_group_name = aws_cloudwatch_log_group.clientvpn.name
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  server_certificate_arn = data.aws_acm_certificate.server.arn
  client_cidr_block      = var.cidr_block_clientvpn
  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.clientvpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.clientvpn.name
  }

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = data.aws_acm_certificate.client.arn
  }
  split_tunnel = true
  dns_servers = [
    aws_route53_resolver_endpoint.clientvpn.ip_address.*.ip[0],
    aws_route53_resolver_endpoint.clientvpn.ip_address.*.ip[1]
  ]
  security_group_ids = [aws_security_group.vpn_access.id]
  vpc_id             = aws_vpc.vpc.id
}

resource "aws_ec2_client_vpn_network_association" "subnet_01" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = aws_subnet.public_subnets["usw2-az1-public"].id
}

resource "aws_ec2_client_vpn_network_association" "subnet_02" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = aws_subnet.public_subnets["usw2-az2-public"].id
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = var.cidr_block_vpc
  authorize_all_groups   = true
}

resource "random_string" "clientvpn_prefix" {
  length    = 7
  numeric   = false
  special   = false
  min_lower = 7
}

resource "local_file" "openvpn_config" {
  content = templatefile("${path.module}/client-config.ovpn.tpl", {
    random_prefix       = random_string.clientvpn_prefix.result
    client_vpn_endpoint = "${replace(aws_ec2_client_vpn_endpoint.vpn.dns_name, "*", "")}"
    ca_cert             = file("${path.module}/easy-rsa/easyrsa3/pki/ca.crt")
    private_key         = file("${path.module}/easy-rsa/easyrsa3/pki/private/client1.domain.tld.key")
    client_cert         = file("${path.module}/easy-rsa/easyrsa3/pki/issued/client1.domain.tld.crt")
  })
  filename = pathexpand("~/client-config.ovpn")
}
