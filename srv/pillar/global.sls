# /srv/pillar/quast/global.sls
# QUAST University - Global Configuration
# Network Engineer: Israr Sadaq
# Date: May 2026

# ============================================================
# ORGANIZATION INFORMATION
# ============================================================
organization:
  name: "Quaid-e-Azam University of Science & Technology"
  short_name: "QUAST"
  domain: "quast.edu.pk"
  location: "Islamabad, Pakistan"
  timezone: "Asia/Karachi"

# ============================================================
# NETWORK SERVICES (Global)
# ============================================================
ntp:
  servers:
    - 0.asia.pool.ntp.org
    - 1.asia.pool.ntp.org
    - 2.asia.pool.ntp.org
    - time.google.com
  iburst: true

dns:
  servers:
    - 10.10.10.10      # Primary Domain Controller
    - 10.10.10.11      # Secondary Domain Controller
    - 8.8.8.8          # Google (backup)
    - 1.1.1.1          # Cloudflare (backup)
  search_domains:
    - quast.edu.pk
    - internal.quast.edu.pk

syslog:
  servers:
    - 10.10.40.50      # Primary Syslog Server
    - 10.10.40.51      # Secondary Syslog Server
  facility: local7
  severity: informational

# ============================================================
# SNMP MONITORING
# ============================================================
snmp:
  version: v3
  users:
    - name: netadmin
      auth_protocol: SHA
      priv_protocol: AES
      read_only: true
  location: "QUAST Data Center, Islamabad"
  contact: "netadmin@quast.edu.pk"

# ============================================================
# AAA / RADIUS
# ============================================================
aaa:
  primary_server: 10.10.40.20
  secondary_server: 10.10.40.21
  timeout: 5
  retries: 3
  deadtime: 10
