# /srv/salt/quast/network/access/base.sls
# Access Switch Base Configuration
# Network Engineer: Israr Sadaq
#
# This state configures:
# - Hostname, management IP
# - Uplink to distribution switch
# - Port security
# - VLAN assignment per port
# - 802.1X authentication
#
# Data source: /srv/pillar/quast/network/access/switches.sls

# ============================================================
# SECTION 1: Access Switch Specific Data
# ============================================================
{% set acc_switch = pillar.get('access_switches', {}).get(grains.id, {}) %}
{% set ports = acc_switch.get('ports', []) %}
{% set default_vlan = acc_switch.get('default_vlan', 300) %}

# ============================================================
# SECTION 2: Hostname and Management
# ============================================================
configure_hostname:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/access/hostname.j2
    - template_args:
        context:
          hostname: {{ grains.id }}
          mgmt_ip: {{ acc_switch.get('mgmt_ip') }}
          mgmt_gateway: 10.10.10.254
          location: {{ acc_switch.get('location', 'Unknown') }}
    - commit_config: true
    - save_config: true

# ============================================================
# SECTION 3: Uplink to Distribution Switch
# ============================================================
configure_uplink:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/access/uplink.j2
    - template_args:
        context:
          uplink_port: {{ acc_switch.get('uplink_port', 'GigabitEthernet1/0/48') }}
          uplink_speed: {{ acc_switch.get('uplink_speed', 10000) }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_hostname

# ============================================================
# SECTION 4: Port Configuration
# ============================================================
# Configure each port with correct VLAN and security

configure_ports:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/access/ports.j2
    - template_args:
        context:
          ports: {{ ports | json }}
          default_vlan: {{ default_vlan }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_uplink

# ============================================================
# SECTION 5: Port Security
# ============================================================
# Prevents unauthorized devices from connecting
# Limits MAC addresses per port

configure_port_security:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/access/port_security.j2
    - template_args:
        context:
          ports: {{ ports | json }}
          max_mac: {{ acc_switch.get('max_mac_per_port', 3) }}
          violation: {{ acc_switch.get('violation_action', 'shutdown') }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ports

# ============================================================
# SECTION 6: 802.1X Authentication (Student VLANs)
# ============================================================
# Students must authenticate before accessing network
# Uses RADIUS server (Active Directory)

{% if acc_switch.get('dot1x_enabled', true) %}
configure_dot1x:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/access/dot1x.j2
    - template_args:
        context:
          radius_primary: {{ pillar.get('aaa:primary_server') }}
          radius_secondary: {{ pillar.get('aaa:secondary_server') }}
          radius_key: {{ pillar['secrets']['radius_key'] }}
          auth_fail_vlan: 999
          guest_vlan: 90
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_port_security
{% endif %}

# ============================================================
# SECTION 7: Storm Control
# ============================================================
# Prevents broadcast storms from crashing the network

configure_storm_control:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/access/storm_control.j2
    - template_args:
        context:
          broadcast_level: {{ acc_switch.get('broadcast_level', 10.0) }}
          multicast_level: {{ acc_switch.get('multicast_level', 10.0) }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_dot1x

# ============================================================
# SECTION 8: Spanning Tree (Prevent Loops)
# ============================================================
configure_spanning_tree:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/access/spanning_tree.j2
    - template_args:
        context:
          mode: rapid-pvst
          portfast_default: true
          bpduguard_default: true
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_storm_control

# ============================================================
# SECTION 9: Verify Access Switch
# ============================================================
verify_access_switch:
  cmd.run:
    - name: |
        echo "=== Uplink Status ==="
        show interface {{ acc_switch.get('uplink_port', 'GigabitEthernet1/0/48') }} | include line protocol
        echo ""
        echo "=== Port Status (First 10 ports) ==="
        show interface status | head -15
        echo ""
        echo "=== Port Security Status ==="
        show port-security | include Total
        echo ""
        echo "=== 802.1X Status ==="
        show authentication sessions summary
    - shell: /bin/bash
    - runas: root
    - require:
      - napalm_managed: configure_spanning_tree
