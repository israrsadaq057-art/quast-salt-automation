# /srv/salt/quast/security/firewall/policies.sls
# Firewall Policy Configuration
# Network Engineer: Israr Sadaq
#
# This state defines what traffic is ALLOWED or DENIED
# Rules are processed in order (first match wins)

# ============================================================
# SECTION 1: Firewall Policies Data
# ============================================================
{% set policies = pillar.get('firewall_policies', []) %}

# ============================================================
# SECTION 2: Configure Firewall Policies
# ============================================================
configure_firewall_policies:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['fortinet_user'] }}
    - password: {{ pillar['secrets']['fortinet_password'] }}
    - dev_os: fortios
    - template: salt://quast/templates/fortinet/policies.j2
    - template_args:
        context:
          policies: {{ policies | json }}
    - commit_config: true
    - save_config: true

# ============================================================
# SECTION 3: Configure SSL Inspection
# ============================================================
# Decrypts HTTPS traffic to inspect for threats
# Required for blocking social media on students

configure_ssl_inspection:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['fortinet_user'] }}
    - password: {{ pillar['secrets']['fortinet_password'] }}
    - dev_os: fortios
    - template: salt://quast/templates/fortinet/ssl_inspect.j2
    - template_args:
        context:
          certificate: "{{ pillar['secrets']['ssl_certificate'] }}"
          exempt_domains:
            - "*.banking.com"
            - "*.health.gov.pk"
            - "*.google.com"
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_firewall_policies

# ============================================================
# SECTION 4: Configure IPS/IDS
# ============================================================
# Intrusion Prevention System - Blocks attacks in real-time

configure_ips:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['fortinet_user'] }}
    - password: {{ pillar['secrets']['fortinet_password'] }}
    - dev_os: fortios
    - template: salt://quast/templates/fortinet/ips.j2
    - template_args:
        context:
          ips_sensor: "high_security"
          blocked_signatures:
            - "SQL.Injection"
            - "Cross.Site.Scripting"
            - "Command.Injection"
            - "Buffer.Overflow"
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ssl_inspection

# ============================================================
# SECTION 5: Configure SD-WAN (Dual ISPs)
# ============================================================
# Load balances traffic between PTCL and Transworld
# If one ISP fails, traffic automatically switches

configure_sdwan:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['fortinet_user'] }}
    - password: {{ pillar['secrets']['fortinet_password'] }}
    - dev_os: fortios
    - template: salt://quast/templates/fortinet/sdwan.j2
    - template_args:
        context:
          members:
            - name: PTCL
              interface: port1
              gateway: 203.124.10.1
              priority: 10
              weight: 60
            - name: TRANSWORLD
              interface: port2
              gateway: 203.124.11.1
              priority: 20
              weight: 40
          health_check:
            server: "8.8.8.8"
            protocol: "ping"
            interval: 5
            failure_threshold: 3
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ips

# ============================================================
# SECTION 6: Verify Firewall Status
# ============================================================
verify_firewall:
  cmd.run:
    - name: |
        echo "=== HA Status ==="
        get system ha status
        echo ""
        echo "=== Policy Count ==="
        get firewall policy | grep -c "edit"
        echo ""
        echo "=== SD-WAN Status ==="
        diagnose sys sdwan health-check
        echo ""
        echo "=== IPS Status ==="
        get ips monitor
    - shell: /bin/bash
    - runas: root
    - require:
      - napalm_managed: configure_sdwan
