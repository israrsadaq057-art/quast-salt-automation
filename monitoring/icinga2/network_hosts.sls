# /srv/salt/quast/monitoring/icinga2/network_hosts.sls
# Network Device Monitoring Configuration
# Network Engineer: Israr Sadaq
#
# This state creates monitoring configuration for:
# - Core switches (Nexus 9508)
# - Distribution switches (Catalyst 9400)
# - Access switches (Catalyst 9300)
# - Firewalls (FortiGate)
# - Wireless Controller

# ============================================================
# SECTION 1: Global Templates
# ============================================================
configure_templates:
  file.managed:
    - name: /etc/icinga2/conf.d/templates.conf
    - source: salt://quast/templates/icinga2/templates.conf
    - template: jinja
    - require:
      - service: start_icinga2

# ============================================================
# SECTION 2: Core Switches
# ============================================================
{% set core_switches = pillar.get('core_switches', {}) %}

configure_core_switches:
  file.managed:
    - name: /etc/icinga2/conf.d/hosts/core_switches.conf
    - contents: |
        // ============================================
        // CORE SWITCHES - Nexus 9508
        // Network Engineer: Israr Sadaq
        // ============================================
        
        {% for name, config in core_switches.items() %}
        object Host "{{ name }}" {
          import "generic-host"
          address = "{{ config.mgmt_ip | replace('/24', '') }}"
          vars.os = "Cisco-Nexus"
          vars.snmp_community = "{{ pillar['snmp'].get('community', 'monitoring') }}"
          vars.snmp_version = "2c"
          
          vars.interfaces["mgmt"] = {
            snmp_interface = "1"
            description = "Management Interface"
          }
          
          vars.services = {
            ping = {
              check_command = "ping4"
            }
            snmp = {
              check_command = "snmp"
            }
            cpu = {
              check_command = "snmp-cisco-cpu"
            }
            memory = {
              check_command = "snmp-cisco-mem"
            }
            temperature = {
              check_command = "snmp-cisco-temp"
            }
          }
        }
        {% endfor %}
    - require:
      - file: configure_templates

# ============================================================
# SECTION 3: Distribution Switches
# ============================================================
{% set dist_switches = pillar.get('distribution_switches', {}) %}

configure_dist_switches:
  file.managed:
    - name: /etc/icinga2/conf.d/hosts/distribution_switches.conf
    - contents: |
        // ============================================
        // DISTRIBUTION SWITCHES - Catalyst 9400
        // ============================================
        
        {% for name, config in dist_switches.items() %}
        object Host "{{ name }}" {
          import "generic-switch"
          address = "{{ config.mgmt_ip | replace('/24', '') }}"
          vars.os = "Cisco-IOS"
          vars.snmp_community = "{{ pillar['snmp'].get('community', 'monitoring') }}"
          
          vars.services = {
            ping = {}
            snmp = {}
            uptime = {}
            interface_bundle = {
              interfaces = ["Port-channel100", "Port-channel101"]
            }
            hsrp = {
              check_command = "hsrp"
            }
          }
        }
        {% endfor %}
    - require:
      - file: configure_core_switches

# ============================================================
# SECTION 4: Access Switches (Dynamic from Pillar)
# ============================================================
{% set access_switches = pillar.get('access_switches', {}) %}

configure_access_switches:
  file.managed:
    - name: /etc/icinga2/conf.d/hosts/access_switches.conf
    - contents: |
        // ============================================
        // ACCESS SWITCHES - Catalyst 9300/9200
        // Total: {{ access_switches.keys() | length }} switches
        // ============================================
        
        {% for name, config in access_switches.items() %}
        object Host "{{ name }}" {
          import "generic-access-switch"
          address = "{{ config.mgmt_ip | replace('/24', '') }}"
          vars.location = "{{ config.location }}"
          vars.snmp_community = "{{ pillar['snmp'].get('community', 'monitoring') }}"
          
          vars.services = {
            ping = {}
            snmp = {}
            temperature = {}
            poe_status = {
              check_command = "snmp-cisco-poe"
            }
            port_security = {
              check_command = "port-security"
            }
          }
        }
        {% endfor %}
    - require:
      - file: configure_dist_switches
