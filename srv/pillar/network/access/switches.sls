# /srv/pillar/quast/network/access/switches.sls
# Access Switch Data
# Network Engineer: Israr Sadaq

access_switches:
  # CS Building - Lab 1 (30 student PCs)
  quast-acc-cs-lab1:
    mgmt_ip: 10.10.30.1/24
    location: "CS Building - Lab 1 (Ground Floor)"
    uplink_port: GigabitEthernet1/0/48
    uplink_speed: 10000
    default_vlan: 300
    max_mac_per_port: 3
    violation_action: shutdown
    dot1x_enabled: true
    broadcast_level: 10.0
    multicast_level: 10.0
    ports:
      - name: GigabitEthernet1/0/1
        description: "Student PC 1"
        vlan: 300
      - name: GigabitEthernet1/0/2
        description: "Student PC 2"
        vlan: 300
      # ... up to 30 ports

  # CS Building - Lab 2 (30 student PCs)
  quast-acc-cs-lab2:
    mgmt_ip: 10.10.30.2/24
    location: "CS Building - Lab 2 (First Floor)"
    uplink_port: GigabitEthernet1/0/48
    uplink_speed: 10000
    default_vlan: 300
    max_mac_per_port: 3
    violation_action: shutdown
    dot1x_enabled: true
    ports:
      - name: GigabitEthernet1/0/1
        description: "Student PC 31"
        vlan: 300
      # ... up to 30 ports

  # CS Building - Faculty Area
  quast-acc-cs-faculty:
    mgmt_ip: 10.10.30.10/24
    location: "CS Building - Faculty Offices (Second Floor)"
    uplink_port: GigabitEthernet1/0/48
    uplink_speed: 10000
    default_vlan: 100
    max_mac_per_port: 5
    violation_action: restrict
    dot1x_enabled: false
    ports:
      - name: GigabitEthernet1/0/1
        description: "Dr. Ahmed Office"
        vlan: 100
      - name: GigabitEthernet1/0/2
        description: "Prof. Khan Office"
        vlan: 100
      - name: GigabitEthernet1/0/10
        description: "Department Printer"
        vlan: 70
