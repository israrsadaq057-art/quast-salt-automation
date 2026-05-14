# /srv/pillar/quast/monitoring/icinga2.sls
# Icinga2 Monitoring Configuration
# Network Engineer: Israr Sadaq

icinga2:
  master_ip: 10.10.40.100
  satellite_ips:
    - 10.10.40.101
    - 10.10.40.102
  
  # Check intervals (seconds)
  intervals:
    ping: 60
    snmp: 300
    cpu: 300
    memory: 300
    interface: 60
    service: 60

  # Alert thresholds
  thresholds:
    cpu_warning: 75
    cpu_critical: 90
    memory_warning: 80
    memory_critical: 95
    latency_warning: 50
    latency_critical: 100
    packet_loss_warning: 5
    packet_loss_critical: 10
    temperature_warning: 45
    temperature_critical: 60

# SNMP Communities (read-only)
snmp:
  community: monitoring
  version: 2c
  location: "QUAST Data Center, Islamabad"
  contact: "netadmin@quast.edu.pk"

# Grafana integration
grafana:
  enabled: true
  url: https://monitoring.quast.edu.pk
  datasource: Icinga2
