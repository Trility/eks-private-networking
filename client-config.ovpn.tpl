client
dev tun
proto udp
remote ${random_prefix}${client_vpn_endpoint} 443

remote-random-hostname
resolv-retry infinite
nobind
remote-cert-tls server
cipher AES-256-GCM
verb 3
<ca>
${ca_cert}</ca>
<cert>
${client_cert}</cert>
<key>
${private_key}</key>

reneg-sec 0
