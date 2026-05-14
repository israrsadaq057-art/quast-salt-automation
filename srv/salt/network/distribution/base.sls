# /srv/salt/quast/network/distribution/base.sls
# Distribution Switch Base Configuration
# Network Engineer: Israr Sadaq
#
# This state configures:
# - Hostname, management IP
# - Uplinks to core switches
# - Basic routing
# - NTP, DNS, Syslog (from global pillar)
#
# Data source: /srv/pillar/quast/network/distribution/switches.sls

# ============================================================
# SECTION 1: Distribution Switch Specific Data
# ============================================================
{% set dist_switch = pillar.get('distribution_switches', {}).get(grains.id, {}) %}
{% set uplinks = dist_switch.get('uplinks', []) %}
{% set vlans = pillar.get('academic_vlans', {}) %}

# ============================================================
# SECTION 2: Hostname and Management IP
# ============================================================
configure_hostname:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/distribution/hostname.j2
    - template_args:
        context:
          hostname: {{ grains.id }}
          mgmt_ip: {{ dist_switch.get('mgmt_ip') }}
          mgmt_gateway: 10.10.10.254
    - commit_config: true
    - save_config: true

# ============================================================
# SECTION 3: Uplinks to Core Switches
# ============================================================
# Port channels provide redundancy and more bandwidth
# Two 40G links = 80G total to core

configure_uplinks:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/distribution/uplinks.j2
    - template_args:
        context:
          uplinks: {{ uplinks | json }}
          port_channel_id: 100
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_hostname

# ============================================================
# SECTION 4: VLAN SVIs (Switch Virtual Interfaces)
# ============================================================
# These are the default gateways for each VLAN
# HSRP provides redundancy between distribution switches

configure_svis:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/distribution/svis.j2
    - template_args:
        context:
          vlans: {{ vlans | json }}
          hsrp_group: 1
          hsrp_priority: {{ dist_switch.get('hsrp_priority', 100) }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_uplinks

# ============================================================
# SECTION 5: Global Services (NTP, DNS, Syslog, SNMP)
# ============================================================
# Same as core switches - inherits from global pillar

configure_global_services:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/global_services.j2
    - template_args:
        context:
          ntp_servers: {{ pillar.get('ntp:servers', []) | json }}
          dns_servers: {{ pillar.get('dns:servers', []) | json }}
          domain_name: {{ pillar.get('organization:domain') }}
          syslog_servers: {{ pillar.get('syslog:servers', []) | json }}
          snmp_location: {{ pillar.get('snmp:location') }}
          snmp_contact: {{ pillar.get('snmp:contact') }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_svis

# ============================================================
# SECTION 6: OSPF Routing
# ============================================================
# Advertise connected VLANs to core switches

configure_ospf:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/distribution/ospf.j2
    - template_args:
        context:
          process_id: 10
          router_id: {{ dist_switch.get('router_id') }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_global_services

# ============================================================
# SECTION 7: Verify Distribution Switch
# ============================================================
verify_distribution:
  cmd.run:
    - name: |
        echo "=== Uplink Status ==="
        show interface port-channel 100
        echo ""
        echo "=== SVI Status ==="
        show ip interface brief | include Vlan
        echo ""
        echo "=== HSRP Status ==="
        show standby brief
        echo ""
        echo "=== OSPF Neighbors ==="
        show ip ospf neighbor
    - shell: /bin/bash
    - runas: root
    - require:
      - napalm_managed: configure_ospf
