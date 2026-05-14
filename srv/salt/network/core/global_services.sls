# /srv/salt/quast/network/core/global_services.sls
# Core Switch Global Services Configuration
# Network Engineer: Israr Sadaq
# Date: May 2026
#
# This state configures:
# - NTP (time synchronization)
# - DNS (name resolution)
# - Syslog (central logging)
# - SNMP (monitoring)
# - AAA/RADIUS (authentication)
#
# Data source: /srv/pillar/quast/global.sls

# ============================================================
# SECTION 1: NTP (Network Time Protocol)
# ============================================================
# Ensures all switches have EXACTLY the same time
# Critical for log correlation and certificate validation

configure_ntp:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/ntp.j2
    - template_args:
        context:
          ntp_servers: {{ pillar.get('ntp:servers', []) | json }}
          ntp_iburst: {{ pillar.get('ntp:iburst', true) | json }}
    - commit_config: true
    - save_config: false

# ============================================================
# SECTION 2: DNS (Domain Name System)
# ============================================================
# Allows switches to resolve hostnames
# Example: 'ping google.com' instead of 'ping 142.250.185.46'

configure_dns:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/dns.j2
    - template_args:
        context:
          dns_servers: {{ pillar.get('dns:servers', []) | json }}
          search_domains: {{ pillar.get('dns:search_domains', []) | json }}
          domain_name: {{ pillar.get('organization:domain', 'quast.edu.pk') }}
    - commit_config: true
    - save_config: false
    - require:
      - napalm_managed: configure_ntp

# ============================================================
# SECTION 3: SYSLOG (Centralized Logging)
# ============================================================
# Sends all logs to central server
# Critical for security auditing and troubleshooting

configure_syslog:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/syslog.j2
    - template_args:
        context:
          syslog_servers: {{ pillar.get('syslog:servers', []) | json }}
          syslog_facility: {{ pillar.get('syslog:facility', 'local7') }}
          syslog_severity: {{ pillar.get('syslog:severity', 'informational') }}
    - commit_config: true
    - save_config: false
    - require:
      - napalm_managed: configure_dns

# ============================================================
# SECTION 4: SNMP (Simple Network Management Protocol)
# ============================================================
# Allows monitoring tools to collect device metrics
# Temperature, CPU usage, bandwidth, errors, etc.

configure_snmp:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/snmp.j2
    - template_args:
        context:
          snmp_version: {{ pillar.get('snmp:version', 'v3') }}
          snmp_users: {{ pillar.get('snmp:users', []) | json }}
          snmp_location: {{ pillar.get('snmp:location', 'QUAST Data Center') }}
          snmp_contact: {{ pillar.get('snmp:contact', 'netadmin@quast.edu.pk') }}
    - commit_config: true
    - save_config: false
    - require:
      - napalm_managed: configure_syslog

# ============================================================
# SECTION 5: AAA (Authentication, Authorization, Accounting)
# ============================================================
# Central authentication via RADIUS
# One username/password for ALL switches

configure_aaa:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/aaa.j2
    - template_args:
        context:
          radius_primary: {{ pillar.get('aaa:primary_server') }}
          radius_secondary: {{ pillar.get('aaa:secondary_server') }}
          radius_timeout: {{ pillar.get('aaa:timeout', 5) }}
          radius_retries: {{ pillar.get('aaa:retries', 3) }}
          radius_key: {{ pillar['secrets']['radius_key'] }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_snmp

# ============================================================
# SECTION 6: Verify All Services
# ============================================================
# Checks that services are working correctly

verify_services:
  cmd.run:
    - name: |
        echo "=== NTP Status ==="
        show ntp associations
        echo ""
        echo "=== DNS Status ==="
        show hosts
        echo ""
        echo "=== SNMP Status ==="
        show snmp
        echo ""
        echo "=== AAA Status ==="
        show aaa servers
    - shell: /bin/bash
    - runas: root
    - require:
      - napalm_managed: configure_aaa
