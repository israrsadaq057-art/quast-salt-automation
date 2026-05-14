# /srv/pillar/quast/network/firewall/switches.sls
# Firewall Configuration Data
# Network Engineer: Israr Sadaq

# Firewall HA Configuration
firewall_ha:
  mode: active-passive
  group_id: 1
  heartbeat_interface: port4
  primary_ip: 10.10.60.1
  peer_ip: 10.10.60.2

# Firewall Interfaces
firewall_interfaces:
  port1:
    mode: static
    ip: 203.124.10.2/24
    allowaccess: [ping, https, ssh]
    role: wan
    description: "PTCL ISP Link"
  port2:
    mode: static
    ip: 203.124.11.2/24
    allowaccess: [ping]
    role: wan
    description: "Transworld ISP Link"
  port3:
    mode: static
    ip: 10.10.0.1/20
    allowaccess: [ping, https, ssh]
    role: lan
    description: "LAN Internal Network"

# Firewall Policies (in order)
firewall_policies:
  - id: 1
    name: "Allow DNS from LAN"
    from: LAN
    to: WAN
    source: 10.10.0.0/20
    destination: all
    service: DNS
    action: accept
    log: disable

  - id: 2
    name: "Allow HTTP/HTTPS from LAN"
    from: LAN
    to: WAN
    source: 10.10.0.0/20
    destination: all
    service: HTTP,HTTPS
    action: accept
    log: enable

  - id: 3
    name: "Block Social Media for Students"
    from: LAN
    to: WAN
    source: 10.10.30.0/24
    destination: all
    service: HTTP,HTTPS
    action: deny
    log: enable
    application_list: Social-Media

  - id: 4
    name: "Allow Email for Faculty"
    from: LAN
    to: WAN
    source: 10.10.20.0/24
    destination: all
    service: SMTP,POP3,IMAP
    action: accept

  - id: 5
    name: "Allow VPN Access"
    from: WAN
    to: LAN
    source: 0.0.0.0/0
    destination: 10.10.50.10
    service: IPSEC,SSL-VPN
    action: accept

  - id: 999
    name: "Deny All"
    from: all
    to: all
    source: all
    destination: all
    service: ALL
    action: deny
    log: enable
