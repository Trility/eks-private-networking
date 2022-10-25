# AWS VPC & Clientvpn

## Required Tools
 - Terraform
 - Bash
 - AWS VPC Client (Recommended for MacOS)

## Helpful Tools
 - AWS CLI

## Prerequisites
 - Certificates uploaded to ACM
   - Use certificates.sh within the repo with paths to polulate openvpn config file
   - Certs made my Terraform were improperly encrypted for Clientvpn

## Terraform plan/apply creates the following:
 - VPC, Subnets, IGW and NAT Gateway
 - Route53 Inbound Resolver
 - Split Tunnel Clientvpn Endpoint with Mutual Authentication
 - Subnet Associations
 - Security group with ingress/egress rules
