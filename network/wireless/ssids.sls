# /srv/salt/quast/network/wireless/ssids.sls
# SSID Configuration for QUAST University
# Network Engineer: Israr Sadaq
#
# This state configures:
# - Faculty WiFi (secure, full access)
# - Student WiFi (filtered, limited bandwidth)
# - Guest WiFi (captive portal, isolated)
# - Research WiFi (high bandwidth, private)
#
# Data source: /srv/pillar/quast/network/wireless/ssids.sls

# ============================================================
# SECTION 1: SSID Data
# ============================================================
{% set ssids = pillar.get('wireless_ssids', []) %}

# ============================================================
# SECTION 2: Configure SSIDs
# ============================================================
configure_ssids:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/ssids.j2
    - template_args:
        context:
          ssids: {{ ssids | json }}
    - commit_config: true
    - save_config: true

# ============================================================
# SECTION 3: Configure Security Policies
# ============================================================
# Different authentication methods per SSID

configure_security_policies:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/security.j2
    - template_args:
        context:
          radius_servers:
            - ip: {{ pillar.get('aaa:primary_server') }}
              key: {{ pillar['secrets']['radius_key'] }}
            - ip: {{ pillar.get('aaa:secondary_server') }}
              key: {{ pillar['secrets']['radius_key'] }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ssids

# ============================================================
# SECTION 4: Configure Bandwidth Limits
# ============================================================
# Prevent users from consuming all bandwidth

configure_bandwidth_limits:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/bandwidth.j2
    - template_args:
        context:
          limits:
            STUDENTS: 10
            GUEST: 2
            FACULTY: 100
            RESEARCH: 500
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_security_policies

# ============================================================
# SECTION 5: Configure Roaming
# ============================================================
# Seamless roaming between APs and campuses

configure_roaming:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/roaming.j2
    - template_args:
        context:
          mobility_group: "QUAST"
          mobility_peers:
            - name: quast-wlc-02
              ip: 10.10.40.2
              group: "QUAST"
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_bandwidth_limits
