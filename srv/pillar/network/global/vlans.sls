# /srv/pillar/quast/network/global/vlans.sls
# Master VLAN Database - Single Source of Truth
# Network Engineer: Israr Sadaq

# ============================================================
# INFRASTRUCTURE VLANs (1-100)
# ============================================================
infrastructure_vlans:
  10:
    name: MGMT
    subnet: 10.10.10.0/24
    gateway: 10.10.10.254
    dhcp: false
    description: "Network device management"
    
  20:
    name: OOB-MGMT
    subnet: 10.10.20.0/24
    gateway: 10.10.20.254
    dhcp: false
    description: "Out-of-band management"
    
  30:
    name: SAN
    subnet: 10.10.30.0/24
    gateway: 10.10.30.254
    dhcp: false
    description: "Storage Area Network"
    
  40:
    name: VMOTION
    subnet: 10.10.40.0/24
    gateway: 10.10.40.254
    dhcp: false
    description: "vSphere vMotion"
    
  50:
    name: VSAN
    subnet: 10.10.50.0/24
    gateway: 10.10.50.254
    dhcp: false
    description: "vSAN Cluster"

# ============================================================
# ACADEMIC VLANs (100-699)
# ============================================================
academic_vlans:
  100:
    name: FACULTY-CS
    subnet: 10.100.100.0/24
    gateway: 10.100.100.254
    dhcp: true
    dhcp_range: "10.100.100.50-10.100.100.200"
    description: "Computer Science Faculty"
    
  101:
    name: FACULTY-EE
    subnet: 10.100.101.0/24
    gateway: 10.100.101.254
    dhcp: true
    description: "Electrical Engineering Faculty"
    
  200:
    name: STAFF-ADMIN
    subnet: 10.100.200.0/24
    gateway: 10.100.200.254
    dhcp: true
    description: "Administration Staff"
    
  300:
    name: STUDENTS-GEN
    subnet: 10.100.0.0/16
    gateway: 10.100.0.254
    dhcp: true
    dhcp_range: "10.100.1.1-10.100.254.254"
    description: "General Student Labs"
    
  301:
    name: STUDENTS-CS
    subnet: 10.101.0.0/16
    gateway: 10.101.0.254
    dhcp: true
    description: "CS Student Labs"
    
  400:
    name: LIBRARY
    subnet: 10.102.0.0/24
    gateway: 10.102.0.254
    dhcp: true
    description: "Central Library"

# ============================================================
# RESEARCH VLANs (700-999)
# ============================================================
research_vlans:
  700:
    name: RESEARCH-AI
    subnet: 10.103.0.0/24
    gateway: 10.103.0.254
    dhcp: false
    description: "AI Research Lab"
    high_bandwidth: true
    
  701:
    name: RESEARCH-HPC
    subnet: 10.103.1.0/24
    gateway: 10.103.1.254
    dhcp: false
    description: "High Performance Computing"
    infiniband: true
    
  702:
    name: RESEARCH-CYBER
    subnet: 10.103.2.0/24
    gateway: 10.103.2.254
    dhcp: false
    description: "Cybersecurity Lab"

# ============================================================
# RESIDENCE VLANs (1000-1999)
# ============================================================
residence_vlans:
  1000:
    name: HOSTEL-1A
    subnet: 10.200.1.0/24
    gateway: 10.200.1.254
    dhcp: true
    description: "Boys Hostel 1 - Wing A"
    
  1010:
    name: HOSTEL-2A
    subnet: 10.200.10.0/24
    gateway: 10.200.10.254
    dhcp: true
    description: "Boys Hostel 2 - Wing A"
    
  1100:
    name: HOSTEL-GIRLS
    subnet: 10.200.100.0/24
    gateway: 10.200.100.254
    dhcp: true
    description: "Girls Hostel"

# ============================================================
# DATA CENTER VLANs (3000-3999)
# ============================================================
datacenter_vlans:
  3001:
    name: DMZ-WEB
    subnet: 10.250.1.0/24
    gateway: 10.250.1.254
    dhcp: false
    description: "Public Web Servers"
    
  3002:
    name: DMZ-APP
    subnet: 10.250.2.0/24
    gateway: 10.250.2.254
    dhcp: false
    description: "Application Servers"
    
  3010:
    name: DB-CLUSTER
    subnet: 10.250.10.0/24
    gateway: 10.250.10.254
    dhcp: false
    description: "Database Cluster"
    
  3100:
    name: BACKUP
    subnet: 10.250.100.0/24
    gateway: 10.250.100.254
    dhcp: false
    description: "Backup Network"

# ============================================================
# TRUNK CONFIGURATION
# ============================================================
trunk_vlans:
  core_to_distribution: [10,20,30,40,50,100,101,200,300,301,400,700,701,702,1000,1010,1100]
  distribution_to_access: [100,101,200,300,301,400]
