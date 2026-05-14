# /srv/salt/quast/security/firewall/ha.sls
# FortiGate Firewall High Availability Configuration
# Network Engineer: Israr Sadaq
#
# This state configures Active-Passive HA pair
# If primary fails, secondary takes over automatically
#
# Data source: /srv/pillar/quast/network/firewall/switches.sls

# ============================================================
# SECTION 1: Firewall Specific Data
# ============================================================
{% set firewall = pillar.get('firewall', {}).get(grains.id, {}) %}
{% set ha_config = pillar.get('firewall_ha', {}) %}
{% set interfaces = pillar.get('firewall_interfaces', {}) %}

# ============================================================
# SECTION 2: Configure HA Cluster
# ============================================================
# Primary and Secondary firewalls form a cluster
# They share the same configuration

configure_ha_cluster:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['fortinet_user'] }}
    - password: {{ pillar['secrets']['fortinet_password'] }}
    - dev_os: fortios
    - template: salt://quast/templates/fortinet/ha.j2
    - template_args:
        context:
          ha_mode: {{ ha_config.get('mode', 'active-passive') }}
          group_id: {{ ha_config.get('group_id', 1) }}
          password: {{ pillar['secrets']['ha_sync_password'] }}
          heartbeat_interface: {{ ha_config.get('heartbeat_interface', 'port4') }}
          primary_priority: {{ firewall.get('ha_priority', 200) if grains.id.endswith('pri') else 100 }}
          monitor_interfaces: ["port1", "port2", "port3"]
    - commit_config: true
    - save_config: true

# ============================================================
# SECTION 3: Configure Interfaces
# ============================================================
# WAN, LAN, DMZ, Management interfaces

configure_interfaces:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['fortinet_user'] }}
    - password: {{ pillar['secrets']['fortinet_password'] }}
    - dev_os: fortios
    - template: salt://quast/templates/fortinet/interfaces.j2
    - template_args:
        context:
          interfaces: {{ interfaces | json }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ha_cluster

# ============================================================
# SECTION 4: Configure Zones
# ============================================================
# Zones group interfaces with same security level

configure_zones:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['fortinet_user'] }}
    - password: {{ pillar['secrets']['fortinet_password'] }}
    - dev_os: fortios
    - template: salt://quast/templates/fortinet/zones.j2
    - template_args:
        context:
          zones:
            - name: WAN
              interfaces: ["port1"]
              description: "Internet uplink"
            - name: LAN
              interfaces: ["port2"]
              description: "Internal network"
            - name: DMZ
              interfaces: ["port3"]
              description: "Public servers"
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_interfaces
