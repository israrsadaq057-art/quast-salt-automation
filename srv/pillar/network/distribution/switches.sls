# /srv/pillar/quast/network/distribution/switches.sls
# Distribution Switch Data
# Network Engineer: Israr Sadaq

distribution_switches:
  quast-dist-cs:
    mgmt_ip: 10.10.20.1/24
    router_id: 10.10.20.1
    hsrp_priority: 110
    uplinks:
      - interface: TenGigabitEthernet1/1/1
        description: "Uplink to Core-01 Port-channel 100"
      - interface: TenGigabitEthernet2/1/1
        description: "Uplink to Core-02 Port-channel 100"
    building: "Computer Science"
    floors: 5
    access_switches: 12

  quast-dist-eng:
    mgmt_ip: 10.10.20.2/24
    router_id: 10.10.20.2
    hsrp_priority: 100
    uplinks:
      - interface: TenGigabitEthernet1/1/1
        description: "Uplink to Core-01 Port-channel 101"
      - interface: TenGigabitEthernet2/1/1
        description: "Uplink to Core-02 Port-channel 101"
    building: "Engineering"
    floors: 4
    access_switches: 8

  quast-dist-lib:
    mgmt_ip: 10.10.20.3/24
    router_id: 10.10.20.3
    hsrp_priority: 90
    uplinks:
      - interface: TenGigabitEthernet1/1/1
        description: "Uplink to Core-01 Port-channel 102"
      - interface: TenGigabitEthernet2/1/1
        description: "Uplink to Core-02 Port-channel 102"
    building: "Library"
    floors: 3
    access_switches: 4
