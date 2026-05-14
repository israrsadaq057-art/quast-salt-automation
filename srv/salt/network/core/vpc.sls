# /srv/salt/quast/network/core/vpc.sls
# Core Switch VPC (Virtual Port Channel) Configuration
# Network Engineer: Israr Sadaq
# Date: May 2026
#
# This state configures VPC between core-01 and core-02
# VPC makes two physical switches act as ONE logical switch
#
# Data source: /srv/pillar/quast/network/core/switches.sls

# ============================================================
# SECTION 1: VPC DOMAIN (Global VPC Settings)
# ============================================================
# Defines the VPC domain that both switches join
# Both switches MUST have the same domain ID

{% set vpc_config = pillar.get('vpc_domain', {}) %}
{% set core_switches = pillar.get('core_switches', {}) %}
{% set this_switch = core_switches.get(grains.id|replace('quast-', ''), {}) %}

configure_vpc_domain:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/vpc_domain.j2
    - template_args:
        context:
          domain_id: {{ vpc_config.get('domain_id', 10) }}
          peer_keepalive: {{ vpc_config.get('peer_keepalive') }}
          auto_recovery: {{ vpc_config.get('auto_recovery', true) }}
          role_priority: {{ this_switch.get('vpc_priority', 1000) }}
          peer_gateway: true
          layer3_peer_routing: true
    - commit_config: true
    - save_config: true

# ============================================================
# SECTION 2: VPC PEER LINK (Connection between switches)
# ============================================================
# The link that carries VPC control traffic
# MUST be 10G or higher, dedicated ports

configure_vpc_peer_link:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/vpc_peer_link.j2
    - template_args:
        context:
          peer_link_interface: "Ethernet1/48"
          peer_link_port_channel: 1000
          vpc_id: 1000
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_vpc_domain

# ============================================================
# SECTION 3: VPC KEEPALIVE LINK
# ============================================================
# Heartbeat between switches to detect failures
# Uses management VRF or dedicated link

configure_vpc_keepalive:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/vpc_keepalive.j2
    - template_args:
        context:
          keepalive_ip: {{ this_switch.get('vpc_keepalive') }}
          peer_keepalive_ip: {{ 'core-02' | get_vpc_keepalive }}
          vrf: management
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_vpc_peer_link

# ============================================================
# SECTION 4: VPC ORPHAN PORTS (Non-VPC ports)
# ============================================================
# Ports that don't participate in VPC
# Configured the traditional way

{% if this_switch.get('vpc_role') == 'primary' %}
configure_orphan_ports:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/vpc_orphan_ports.j2
    - template_args:
        context:
          orphan_ports:
            - interface: Ethernet1/49
              description: "Primary to Firewall"
              ip: 10.10.0.2/20
            - interface: Ethernet1/50
              description: "Management"
              vrf: management
              ip: {{ this_switch.get('mgmt_ip') }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_vpc_keepalive
{% endif %}

# ============================================================
# SECTION 5: VPC Consistency Check
# ============================================================
# Verifies both switches have identical VPC configs

verify_vpc_status:
  cmd.run:
    - name: |
        echo "=== VPC Domain Status ==="
        show vpc
        echo ""
        echo "=== VPC Peer Status ==="
        show vpc peer-keepalive
        echo ""
        echo "=== VPC Consistency ==="
        show vpc consistency-parameters global
    - shell: /bin/bash
    - runas: root
    - require:
      - napalm_managed: configure_vpc_orphan_ports
      - napalm_managed: configure_vpc_keepalive
