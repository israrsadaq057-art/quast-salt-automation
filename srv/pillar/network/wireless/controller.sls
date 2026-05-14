# /srv/pillar/quast/network/wireless/controller.sls
# Wireless Controller Data
# Network Engineer: Israr Sadaq

wireless_controller:
  quast-wlc-01:
    mgmt_ip: 10.10.40.1/24
    ap_manager_ip: 10.10.41.1/24
    virtual_ip: 10.10.41.254
    role: primary

  quast-wlc-02:
    mgmt_ip: 10.10.40.2/24
    ap_manager_ip: 10.10.41.2/24
    virtual_ip: 10.10.41.254
    role: secondary

# WLC Interfaces
wlc_interfaces:
  mgmt:
    name: Vlan10
    description: "Management Interface"
  ap_manager:
    name: Vlan41
    description: "AP Manager Interface"
  virtual:
    name: Vlan41
    description: "Virtual Interface for Anchor"

# SSIDs
wireless_ssids:
  - name: QUAST-FACULTY
    vlan: 100
    security: wpa2-enterprise
    description: "Faculty and Staff WiFi"
    client_limit: 1000

  - name: QUAST-STUDENTS
    vlan: 300
    security: wpa2-personal
    description: "Student WiFi with filtering"
    client_limit: 5000

  - name: QUAST-GUEST
    vlan: 90
    security: open
    description: "Guest WiFi - Captive Portal"
    client_limit: 500

  - name: QUAST-RESEARCH
    vlan: 700
    security: wpa2-enterprise
    description: "Research Lab - High Bandwidth"
    client_limit: 200

# RF Profiles
rf_profiles:
  high-density:
    type: high-density
    description: "Classrooms and Lecture Halls"
  low-density:
    type: low-density
    description: "Offices and Common Areas"

# Access Points (sample - first 10 of 500)
access_points:
  - mac: "a0:b1:c2:d3:e4:f1"
    name: "AP-CS-F1-01"
    location: "CS Building Floor 1 - East"
    ap_group: CS-BUILDING

  - mac: "a0:b1:c2:d3:e4:f2"
    name: "AP-CS-F1-02"
    location: "CS Building Floor 1 - West"
    ap_group: CS-BUILDING

  - mac: "a0:b1:c2:d3:e4:f3"
    name: "AP-CS-F2-01"
    location: "CS Building Floor 2 - East"
    ap_group: CS-BUILDING

  - mac: "a0:b1:c2:d3:e4:f4"
    name: "AP-LIB-01"
    location: "Library - Main Floor"
    ap_group: LIBRARY

  - mac: "a0:b1:c2:d3:e4:f5"
    name: "AP-LIB-02"
    location: "Library - Second Floor"
    ap_group: LIBRARY
