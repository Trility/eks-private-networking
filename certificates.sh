#!/bin/bash
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa build-server-full server nopass
./easyrsa build-client-full client1.domain.tld nopass
aws acm import-certificate --certificate fileb://pki/issued/server.crt --private-key fileb://pki/private/server.key --certificate-chain fileb://pki/ca.crt
aws acm import-certificate --certificate fileb://pki/issued/client1.domain.tld.crt --private-key fileb://pki/private/client1.domain.tld.key --certificate-chain fileb://pki/ca.crt
