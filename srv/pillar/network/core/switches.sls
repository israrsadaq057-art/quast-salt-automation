# /srv/pillar/quast/network/core/switches.sls
# Core Switches Configuration - Nexus 9508 VPC Pair
# Network Engineer: Israr Sadaq

core_switches:
  core-01:
    hostname: quast-core-01
    mgmt_ip: 10.10.10.1/24
    mgmt_gateway: 10.10.10.254
    vpc_role: primary
    vpc_priority: 2000
    vpc_peer_ip: 172.16.1.2
    vpc_keepalive: 172.16.1.1
    
  core-02:
    hostname: quast-core-02
    mgmt_ip: 10.10.10.2/24
    mgmt_gateway: 10.10.10.254
    vpc_role: secondary
    vpc_priority: 1900
    vpc_peer_ip: 172.16.1.1
    vpc_keepalive: 172.16.1.2

# VPC Domain
vpc_domain:
  domain_id: 10
  peer_keepalive: "172.16.1.1,172.16.1.2"
  auto_recovery: true

# OSPF Configuration
ospf:
  process_id: 10
  router_id: 10.10.10.1
  networks:
    - prefix: 10.10.0.0
      wildcard: 0.0.255.255
      area: 0
    - prefix: 10.100.0.0
      wildcard: 0.15.255.255
      area: 0
  passive_interfaces:
    - Vlan10
    - Vlan20
    - Vlan30
    - Vlan40
    - Vlan50

# Uplinks to Distribution
uplinks:
  to_dist_cs:
    interface: Ethernet1/1
    port_channel: 100
    speed: 40000
    vlans: all
    
  to_dist_eng:
    interface: Ethernet1/2
    port_channel: 101
    speed: 40000
    
  to_dist_lib:
    interface: Ethernet1/3
    port_channel: 102
    speed: 10000

# Link to Firewall
firewall_link:
  interface: Ethernet1/48
  ip: 10.10.0.2/20
  gateway: 10.10.0.1
